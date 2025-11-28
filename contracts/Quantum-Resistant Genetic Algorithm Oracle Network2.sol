// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title QuantumResistantGeneticAlgorithmOracleNetwork2
 * @dev Simplified on-chain registry for GA oracle jobs and results, with external off-chain solver
 * @notice Contracts submit GA optimization jobs; an authorized oracle posts back results
 */
contract QuantumResistantGeneticAlgorithmOracleNetwork2 {
    address public owner;
    address public oracle;    // trusted off-chain GA solver / relayer

    enum JobStatus {
        Pending,
        Fulfilled,
        Cancelled
    }

    struct GAJob {
        uint256 id;
        address requester;
        string  problemURI;     // description / dataset location (IPFS/HTTPS/etc.)
        string  configURI;      // GA configuration parameters (population, mutation, etc.)
        uint256 createdAt;
        JobStatus status;
        string  bestSolutionURI; // URI or encoded representation of best chromosome
        int256  bestFitness;     // fitness score (higher is better, or domain-specific)
    }

    uint256 public nextJobId;

    // jobId => GAJob
    mapping(uint256 => GAJob) public jobs;

    // requester => jobIds
    mapping(address => uint256[]) public jobsOf;

    event OracleUpdated(address indexed newOracle);
    event JobSubmitted(
        uint256 indexed id,
        address indexed requester,
        string problemURI,
        string configURI,
        uint256 timestamp
    );
    event JobFulfilled(
        uint256 indexed id,
        string bestSolutionURI,
        int256 bestFitness,
        uint256 timestamp
    );
    event JobCancelled(uint256 indexed id, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "Only oracle");
        _;
    }

    modifier jobExists(uint256 id) {
        require(jobs[id].requester != address(0), "Job not found");
        _;
    }

    modifier onlyRequester(uint256 id) {
        require(jobs[id].requester == msg.sender, "Not requester");
        _;
    }

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = _oracle;
    }

    /**
     * @dev Submit a new GA optimization job
     * @param problemURI URI pointing to problem description / dataset
     * @param configURI URI with GA parameters/config
     */
    function submitJob(string calldata problemURI, string calldata configURI)
        external
        returns (uint256 id)
    {
        require(bytes(problemURI).length > 0, "Problem URI required");

        id = nextJobId++;
        jobs[id] = GAJob({
            id: id,
            requester: msg.sender,
            problemURI: problemURI,
            configURI: configURI,
            createdAt: block.timestamp,
            status: JobStatus.Pending,
            bestSolutionURI: "",
            bestFitness: 0
        });

        jobsOf[msg.sender].push(id);

        emit JobSubmitted(id, msg.sender, problemURI, configURI, block.timestamp);
    }

    /**
     * @dev Oracle posts back GA result for a job
     * @param id Job identifier
     * @param bestSolutionURI Encoded best chromosome / solution URI
     * @param bestFitness Fitness score associated with best solution
     */
    function fulfillJob(
        uint256 id,
        string calldata bestSolutionURI,
        int256 bestFitness
    )
        external
        onlyOracle
        jobExists(id)
    {
        GAJob storage job = jobs[id];
        require(job.status == JobStatus.Pending, "Not pending");

        job.bestSolutionURI = bestSolutionURI;
        job.bestFitness = bestFitness;
        job.status = JobStatus.Fulfilled;

        emit JobFulfilled(id, bestSolutionURI, bestFitness, block.timestamp);
    }

    /**
     * @dev Requester can cancel a pending job (no effect on oracle off-chain)
     */
    function cancelJob(uint256 id)
        external
        jobExists(id)
        onlyRequester(id)
    {
        GAJob storage job = jobs[id];
        require(job.status == JobStatus.Pending, "Not pending");
        job.status = JobStatus.Cancelled;

        emit JobCancelled(id, block.timestamp);
    }

    /**
     * @dev Get all job ids submitted by a requester
     */
    function getJobsOf(address requester) external view returns (uint256[] memory) {
        return jobsOf[requester];
    }

    /**
     * @dev Owner can update oracle address
     */
    function updateOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Zero address");
        oracle = newOracle;
        emit OracleUpdated(newOracle);
    }

    /**
     * @dev Transfer ownership of the oracle network contract
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}
