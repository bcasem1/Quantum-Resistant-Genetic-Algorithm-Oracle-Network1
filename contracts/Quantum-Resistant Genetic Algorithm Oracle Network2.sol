// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Quantum-Resistant Genetic Algorithm Oracle Network
 * @dev A decentralized oracle network that uses quantum-resistant algorithms and genetic optimization
 * to provide secure and evolving data feeds to blockchain applications.
 */
contract Project is Ownable, ReentrancyGuard {
    // Structures
    struct GeneticDataPoint {
        bytes32 dataHash;
        uint256 timestamp;
        uint256 confidence;
        address provider;
        bool isQuantumResistant;
    }

    struct OracleProvider {
        address providerAddress;
        uint256 reputation;
        uint256 stakeAmount;
        bool isActive;
    }

    // State variables
    mapping(bytes32 => GeneticDataPoint) public dataRegistry;
    mapping(address => OracleProvider) public providers;
    uint256 public minimumStake;
    uint256 public totalProviders;
    uint256 public totalStaked;
    bytes32[] public dataKeys;

    // Reward-related state
    uint256 public rewardPool;
    uint256 public rewardThreshold = 150;
    uint256 public rewardAmount = 0.01 ether;

    // Events
    event DataSubmitted(bytes32 indexed dataKey, address indexed provider, uint256 timestamp);
    event ProviderRegistered(address indexed provider, uint256 stakeAmount);
    event ProviderDeregistered(address indexed provider);
    event StakeWithdrawn(address indexed provider, uint256 amount);
    event DataUpdated(bytes32 indexed dataKey, address indexed provider, uint256 timestamp);
    event ReputationSlashed(address indexed provider, uint256 amount);
    event ReputationBoosted(address indexed provider, uint256 amount);
    event RewardFunded(uint256 amount);
    event RewardPaid(address indexed provider, uint256 amount);
    event RewardSettingsUpdated(uint256 newThreshold, uint256 newAmount);

    // Constructor
    constructor(uint256 _minimumStake) Ownable(msg.sender) {
        minimumStake = _minimumStake;
    }

    function registerProvider() external payable nonReentrant {
        require(msg.value >= minimumStake, "Insufficient stake amount");
        require(!providers[msg.sender].isActive, "Provider already registered");

        providers[msg.sender] = OracleProvider({
            providerAddress: msg.sender,
            reputation: 100,
            stakeAmount: msg.value,
            isActive: true
        });

        totalProviders++;
        totalStaked += msg.value;

        emit ProviderRegistered(msg.sender, msg.value);
    }

    function submitData(
        bytes32 dataKey,
        bytes32 dataHash,
        uint256 confidence,
        bool isQuantumResistant
    ) external nonReentrant {
        require(providers[msg.sender].isActive, "Not an active provider");
        require(confidence <= 100, "Confidence must be 0-100");
        require(!_dataKeyExists(dataKey), "Data key already exists. Use updateData");

        dataRegistry[dataKey] = GeneticDataPoint({
            dataHash: dataHash,
            timestamp: block.timestamp,
            confidence: confidence,
            provider: msg.sender,
            isQuantumResistant: isQuantumResistant
        });

        dataKeys.push(dataKey);

        emit DataSubmitted(dataKey, msg.sender, block.timestamp);

        // Auto reward logic
        if (providers[msg.sender].reputation >= rewardThreshold && rewardPool >= rewardAmount) {
            rewardPool -= rewardAmount;
            (bool sent, ) = payable(msg.sender).call{value: rewardAmount}("");
            require(sent, "Reward transfer failed");
            emit RewardPaid(msg.sender, rewardAmount);
        }
    }

    function updateData(
        bytes32 dataKey,
        bytes32 newDataHash,
        uint256 newConfidence,
        bool isQuantumResistant
    ) external nonReentrant {
        require(providers[msg.sender].isActive, "Not an active provider");
        require(dataRegistry[dataKey].provider == msg.sender, "Only original provider can update");
        require(newConfidence <= 100, "Confidence must be 0-100");

        dataRegistry[dataKey] = GeneticDataPoint({
            dataHash: newDataHash,
            timestamp: block.timestamp,
            confidence: newConfidence,
            provider: msg.sender,
            isQuantumResistant: isQuantumResistant
        });

        emit DataUpdated(dataKey, msg.sender, block.timestamp);
    }

    function deregisterProvider() external nonReentrant {
        OracleProvider storage provider = providers[msg.sender];
        require(provider.isActive, "Not an active provider");

        uint256 amountToWithdraw = provider.stakeAmount;
        provider.isActive = false;
        provider.stakeAmount = 0;
        totalProviders--;
        totalStaked -= amountToWithdraw;

        (bool sent, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(sent, "Failed to withdraw stake");

        emit ProviderDeregistered(msg.sender);
        emit StakeWithdrawn(msg.sender, amountToWithdraw);
    }

    function getData(bytes32 dataKey) external view returns (GeneticDataPoint memory) {
        return dataRegistry[dataKey];
    }

    function setMinimumStake(uint256 _minimumStake) external onlyOwner {
        minimumStake = _minimumStake;
    }

    function slashReputation(address providerAddress, uint256 amount) external onlyOwner {
        require(providers[providerAddress].isActive, "Provider not active");

        if (amount >= providers[providerAddress].reputation) {
            providers[providerAddress].reputation = 0;
        } else {
            providers[providerAddress].reputation -= amount;
        }

        emit ReputationSlashed(providerAddress, amount);
    }

    function boostReputation(address providerAddress, uint256 amount) external onlyOwner {
        require(providers[providerAddress].isActive, "Provider not active");

        providers[providerAddress].reputation += amount;
        emit ReputationBoosted(providerAddress, amount);
    }

    function _dataKeyExists(bytes32 dataKey) private view returns (bool) {
        for (uint i = 0; i < dataKeys.length; i++) {
            if (dataKeys[i] == dataKey) {
                return true;
            }
        }
        return false;
    }

    function getAllDataKeys() external view returns (bytes32[] memory) {
        return dataKeys;
    }

    // New: Fund the reward pool
    function fundRewardPool() external payable onlyOwner {
        require(msg.value > 0, "Must send ETH");
        rewardPool += msg.value;
        emit RewardFunded(msg.value)
    }

    // New: Configure reward settings
    function setRewardSettings(uint256 _threshold, uint256 _amount) external onlyOwner {
        rewardThreshold = _threshold;
        rewardAmount = _amount;
        emit RewardSettingsUpdated(_threshold, _amount);
    }
}
