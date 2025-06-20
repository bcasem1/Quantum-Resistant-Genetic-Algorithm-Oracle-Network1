// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Quantum-Resistant Genetic Algorithm Oracle Network
    struct DataVersion {
        bytes32 dataHash;
        uint256 timestamp;
        uint256 confidence;
        bool isQuantumResistant;
    }


    uint256 public minimumStake;
    uint256 public totalProviders;
    uint256 public totalStaked;
    bytes32[] public dataKeys;

    uint256 public rewardPool;
    uint256 public rewardThreshold = 150;
    uint256 public rewardAmount;

    bool public submissionsPaused = false;

    // Events
    event DataSubmitted(bytes32 indexed dataKey, address indexed provider, uint256 timestamp);
    event ProviderRegistered(address indexed provider, uint256 stakeAmount);
    event ProviderDeregistered(address indexed provider);
    event StakeWithdrawn(address indexed provider, uint256 amount);
    event DataUpdated(bytes32 indexed dataKey, address indexed provider, uint256 timestamp);
    event ReputationSlashed(address indexed provider, uint256 amount);
    event ReputationBoosted(address indexed provider, uint256 amount);
    event ReputationChanged(address indexed provider, int256 change, uint256 newReputation);
    event RewardFunded(uint256 amount);
    event RewardPaid(address indexed provider, uint256 amount);
    event RewardSettingsUpdated(uint256 newThreshold, uint256 newAmount);
    event SubmissionsPaused();
    event SubmissionsUnpaused();
    event ProviderToppedUp(address indexed provider, uint256 amount);
    event DataDeleted(bytes32 indexed dataKey);
    event EmergencyWithdrawal(uint256 amount);
    event ProviderBlacklisted(address indexed provider);
    event ProviderUnblacklisted(address indexed provider);
 event DataSubmitted(bytes32 indexed dataKey, address indexed provider, uint256 timestamp);
    event ProviderRegistered(address indexed provider, uint256 stakeAmount);
    event ProviderDeregistered(address indexed provider);
    event StakeWithdrawn(address indexed provider, uint256 amount);
    event DataUpdated(bytes32 indexed dataKey, address indexed provider, uint256 timestamp);
    event ReputationSlashed(address indexed provider, uint256 amount);
    event ReputationBoosted(address indexed provider, uint256 amount);
    event ReputationChanged(address indexed provider, int256 change, uint256 newReputation);
    event RewardFunded(uint256 amount);
    event RewardPaid(address indexed provider, uint256 amount);
    event RewardSettingsUpdated(uint256 newThreshold, uint256 newAmount);
    event SubmissionsPaused();
    event SubmissionsUnpaused();
    event ProviderToppedUp(address indexed provider, uint256 amount);
    event DataDeleted(bytes32 indexed dataKey);
    event EmergencyWithdrawal(uint256 amount);
    event ProviderBlacklisted(address indexed provider);
    event ProviderUnblacklisted(address indexed provider);
    constructor(uint256 _minimumStake) Ownable(msg.sender) {
        minimumStake = _minimumStake;
    }

    function registerProvider() external payable nonReentrant {
        require(msg.value >= minimumStake, "Insufficient stake amount");
        require(!providers[msg.sender].isActive, "Already registered");
        require(!blacklisted[msg.sender], "Provider is blacklisted");

        providers[msg.sender] = OracleProvider({
            providerAddress: msg.sender,
            reputation: 100,
            stakeAmount: msg.value,
            isActive: true
        })

    function submitData(
        bytes32 dataKey,
        bytes32 dataHash,
        uint256 confidence,
        bool isQuantumResistant
    ) external nonReentrant {
        require(!submissionsPaused, "Submissions paused");
        require(providers[msg.sender].isActive, "Inactive provider");
        require(confidence <= 100, "Confidence must be 0-100");
        require(!_dataKeyExists(dataKey), "Data key exists");

        dataRegistry[dataKey] = GeneticDataPoint({
            dataHash: dataHash,
            timestamp: block.timestamp,
            confidence: confidence,
            provider: msg.sender,
            isQuantumResistant: isQuantumResistant
        });

        dataKeys.push(dataKey);
        lastActive[msg.sender] = block.timestamp;

        emit DataSubmitted(dataKey, msg.sender, block.timestamp);

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
        require(providers[msg.sender].isActive, "Inactive provider");
        require(dataRegistry[dataKey].provider == msg.sender, "Not original provider");
        require(newConfidence <= 100, "Confidence must be 0-100");

        GeneticDataPoint storage current = dataRegistry[dataKey];
        dataHistory[dataKey].push(DataVersion({
            dataHash: current.dataHash,
            timestamp: current.timestamp,
            confidence: current.confidence,
            isQuantumResistant: current.isQuantumResistant
        }));

        dataRegistry[dataKey] = GeneticDataPoint({
            dataHash: newDataHash,
            timestamp: block.timestamp,
            confidence: newConfidence,
            provider: msg.sender,
            isQuantumResistant: isQuantumResistant
        });

        lastActive[msg.sender] = block.timestamp;
        emit DataUpdated(dataKey, msg.sender, block.timestamp);
    }

    function deregisterProvider() external nonReentrant {
        OracleProvider storage provider = providers[msg.sender];
        require(provider.isActive, "Not active");

        uint256 amount = provider.stakeAmount;
        provider.isActive = false;
        provider.stakeAmount = 0;

        totalProviders--;
        totalStaked -= amount;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Withdraw failed");

        emit ProviderDeregistered(msg.sender);
        emit StakeWithdrawn(msg.sender, amount);
    }

    function topUpStake() external payable nonReentrant {
        require(providers[msg.sender].isActive, "Not active");
        require(msg.value > 0, "Zero amount");

        providers[msg.sender].stakeAmount += msg.value;
        totalStaked += msg.value;

        emit ProviderToppedUp(msg.sender, msg.value);
    }

    // View
    function getData(bytes32 dataKey) external view returns (GeneticDataPoint memory) {
        return dataRegistry[dataKey];
    }

    function getAllDataKeys() external view returns (bytes32[] memory) {
        return dataKeys;
    }

    function getProvider(address providerAddress) external view returns (OracleProvider memory) {
        return providers[providerAddress];
    }

    function getDataHistory(bytes32 dataKey) external view returns (DataVersion[] memory) {
        return dataHistory[dataKey];
    }

    // Admin
    function setMinimumStake(uint256 _minimumStake) external onlyOwner {
        minimumStake = _minimumStake;
    }

    function slashReputation(address provider, uint256 amount) external onlyOwner {
        require(providers[provider].isActive, "Not active");
        uint256 current = providers[provider].reputation;
        providers[provider].reputation = amount >= current ? 0 : current - amount;
        emit ReputationSlashed(provider, amount);
        emit ReputationChanged(provider, -int256(amount), providers[provider].reputation);
    }

    function boostReputation(address provider, uint256 amount) external onlyOwner {
        require(providers[provider].isActive, "Not active");
        providers[provider].reputation += amount;
        emit ReputationBoosted(provider, amount);
        emit ReputationChanged(provider, int256(amount), providers[provider].reputation);
    }

    function decayReputation(address provider) external onlyOwner {
        require(providers[provider].isActive, "Not active");
        require(block.timestamp > lastActive[provider] + 30 days, "Decay period not reached");

        uint256 decay = providers[provider].reputation / 10;
        providers[provider].reputation -= decay;

        emit ReputationSlashed(provider, decay);
        emit ReputationChanged(provider, -int256(decay), providers[provider].reputation);
    }

    function fundRewardPool() external payable onlyOwner {
        require(msg.value > 0, "No ETH");
        rewardPool += msg.value;
        emit RewardFunded(msg.value);
    }

    function setRewardSettings(uint256 _threshold, uint256 _amount) external onlyOwner {
        rewardThreshold = _threshold;
        rewardAmount = _amount;
        emit RewardSettingsUpdated(_threshold, _amount);
    }

    function pauseSubmissions() external onlyOwner {
        submissionsPaused = true;
        emit SubmissionsPaused();
    }

    function unpauseSubmissions() external onlyOwner {
        submissionsPaused = false;
        emit SubmissionsUnpaused();
    }

    function deleteData(bytes32 dataKey) external onlyOwner {
        require(_dataKeyExists(dataKey), "Key not found");
        delete dataRegistry[dataKey];
        delete dataHistory[dataKey];

        for (uint i = 0; i < dataKeys.length; i++) {
            if (dataKeys[i] == dataKey) {
                dataKeys[i] = dataKeys[dataKeys.length - 1];
                dataKeys.pop();
                break;
            }
        }

        emit DataDeleted
