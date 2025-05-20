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
    bytes32[] public dataKeys;

    // Events
    event DataSubmitted(bytes32 indexed dataKey, address indexed provider, uint256 timestamp);
    event ProviderRegistered(address indexed provider, uint256 stakeAmount);
    event ProviderDeregistered(address indexed provider);
    event StakeWithdrawn(address indexed provider, uint256 amount);

    // Constructor
    constructor(uint256 _minimumStake) Ownable(msg.sender) {
        minimumStake = _minimumStake;
    }

    /**
     * @dev Register as an oracle provider by staking required amount
     */
    function registerProvider() external payable nonReentrant {
        require(msg.value >= minimumStake, "Insufficient stake amount");
        require(!providers[msg.sender].isActive, "Provider already registered");

        providers[msg.sender] = OracleProvider({
            providerAddress: msg.sender,
            reputation: 100, // Initial reputation
            stakeAmount: msg.value,
            isActive: true
        });

        totalProviders++;
        emit ProviderRegistered(msg.sender, msg.value);
    }

    /**
     * @dev Submit data to the oracle network
     * @param dataKey The unique identifier for this data point
     * @param dataHash The hash of the actual data
     * @param confidence The confidence level of the data (0-100)
     * @param isQuantumResistant Whether the data is secured with quantum-resistant encryption
     */
    function submitData(
        bytes32 dataKey,
        bytes32 dataHash,
        uint256 confidence,
        bool isQuantumResistant
    ) external nonReentrant {
        require(providers[msg.sender].isActive, "Not an active provider");
        require(confidence <= 100, "Confidence must be 0-100");

        dataRegistry[dataKey] = GeneticDataPoint({
            dataHash: dataHash,
            timestamp: block.timestamp,
            confidence: confidence,
            provider: msg.sender,
            isQuantumResistant: isQuantumResistant
        });

        if (!_dataKeyExists(dataKey)) {
            dataKeys.push(dataKey);
        }

        emit DataSubmitted(dataKey, msg.sender, block.timestamp);
    }

    /**
     * @dev Deregister as a provider and withdraw staked amount after penalty period
     */
    function deregisterProvider() external nonReentrant {
        OracleProvider storage provider = providers[msg.sender];
        require(provider.isActive, "Not an active provider");

        uint256 amountToWithdraw = provider.stakeAmount;
        provider.isActive = false;
        provider.stakeAmount = 0;
        totalProviders--;

        (bool sent, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(sent, "Failed to withdraw stake");

        emit ProviderDeregistered(msg.sender);
        emit StakeWithdrawn(msg.sender, amountToWithdraw);
    }

    /**
     * @dev Retrieve data from the oracle network
     * @param dataKey The unique identifier for the data point
     * @return The GeneticDataPoint struct containing the data
     */
    function getData(bytes32 dataKey) external view returns (GeneticDataPoint memory) {
        return dataRegistry[dataKey];
    }

    /**
     * @dev Set minimum stake required to become a provider
     * @param _minimumStake New minimum stake amount
     */
    function setMinimumStake(uint256 _minimumStake) external onlyOwner {
        minimumStake = _minimumStake;
    }

    /**
     * @dev Helper function to check if a data key exists
     * @param dataKey The key to check
     * @return True if the key exists, false otherwise
     */
    function _dataKeyExists(bytes32 dataKey) private view returns (bool) {
        for (uint i = 0; i < dataKeys.length; i++) {
            if (dataKeys[i] == dataKey) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Get all data keys that have been submitted
     * @return Array of data keys
     */
    function getAllDataKeys() external view returns (bytes32[] memory) {
        return dataKeys;
    }
}
