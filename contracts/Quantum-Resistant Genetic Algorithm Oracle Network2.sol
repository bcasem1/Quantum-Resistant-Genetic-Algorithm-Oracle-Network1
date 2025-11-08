Mappings and state variables
    mapping(address => OracleProvider) public providers;
    mapping(bytes32 => GeneticDataPoint) public dataRegistry;
    mapping(bytes32 => DataVersion[]) public dataHistory;
    mapping(address => bool) public blacklisted;
    mapping(address => uint256) public lastActive;

    uint256 public minimumStake;
    uint256 public totalProviders;
    uint256 public totalStaked;
    bytes32[] public dataKeys;

    uint256 public rewardPool;
    uint256 public rewardThreshold = 150;
    uint256 public rewardAmount;

    bool public submissionsPaused = false;

    View Functions
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

    Utility
    function _dataKeyExists(bytes32 key) internal view returns (bool) {
        return dataRegistry[key].timestamp != 0;
    }

    receive() external payable {
        rewardPool += msg.value;
        emit RewardFunded(msg.value);
    }

    fallback() external payable {
        rewardPool += msg.value;
    }
}

// 
End
// 
