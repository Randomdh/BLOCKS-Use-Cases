// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8 .0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";

contract Escrow is Ownable, ReentrancyGuard {
    uint256 public percentageFee = 5;

    address public blocksTokenAddress = 0x17f4A652Fa758002dC184529A75E00017da12048;
    IERC777 public blocksToken = IERC777(blocksTokenAddress);

    enum State {
        Created,
        Locked,
        Disputed,
        Release,
        Cancelled
    }
    enum PaymentMethod {
        BLOCKS
    }

    struct Job {
        address client;
        address payable freelancer;
        address arbitrator;
        uint256 amount;
        PaymentMethod paymentMethod;
        State state;
    }

    struct JobData {
        string jobTitle;
        string jobDescription;
        uint256 deadline;
    }

    mapping(bytes32 => Job) public jobs;
    mapping(bytes32 => JobData) public jobDataMapping;

    event JobCreated(bytes32 indexed jobId, address indexed client, address indexed freelancer, address arbitrator, uint256 amount);
    event JobLocked(bytes32 indexed jobId);
    event JobDisputed(bytes32 indexed jobId);
    event JobResolved(bytes32 indexed jobId);
    event JobRelease(bytes32 indexed jobId);
    event JobCancelled(bytes32 indexed jobId);
    event BlocksTokenAddressUpdated(address indexed newBlocksTokenAddress);

    modifier onlyClient(bytes32 jobId) {
        require(msg.sender == jobs[jobId].client, "Only the client can perform this action");
        _;
    }

    modifier onlyFreelancer(bytes32 jobId) {
        require(msg.sender == jobs[jobId].freelancer, "Only the freelancer can perform this action");
        _;
    }

    modifier onlyArbitrator(bytes32 jobId) {
        require(msg.sender == jobs[jobId].arbitrator, "Only the arbitrator can perform this action");
        _;
    }

    function withdrawFees() public onlyOwner {
        uint256 balance = blocksToken.balanceOf(address(this));
        require(balance > 0, "No fees to withdraw");

        blocksToken.send(owner(), balance, ""); // Using send to transfer BLOCKS tokens
    }

    function generateJobId(address client, address freelancer) internal view returns(bytes32) {
        return keccak256(abi.encodePacked(client, freelancer, block.timestamp));
    }

    function calculateFee(uint256 amount) private view returns(uint256) {
        return (amount * percentageFee) / 100;
    }

    function createJob(
        address payable freelancer,
        address arbitrator,
        uint256 amount,
        JobData memory jobData
    ) public nonReentrant {
        require(freelancer != address(0), "Freelancer address cannot be zero");
        require(arbitrator != address(0), "Arbitrator address cannot be zero");
        require(amount > 0, "Amount cannot be zero");

        bytes32 jobId = generateJobId(msg.sender, freelancer);

        jobs[jobId] = Job({
            client: msg.sender,
            freelancer: freelancer,
            arbitrator: arbitrator,
            amount: amount,
            paymentMethod: PaymentMethod.BLOCKS,
            state: State.Created
        });

        uint256 totalAmount = amount + calculateFee(amount);
        blocksToken.send(msg.sender, totalAmount, ""); // Use the send function of the BLOCKS token to transfer

        bytes memory data = abi.encode(jobData); // Encode the job data as bytes
        blocksToken.send(address(this), calculateFee(amount), data); // Use the send function of the BLOCKS token to transfer the fee with job data

        emit JobCreated(jobId, msg.sender, freelancer, arbitrator, amount);
    }

    function openDispute(bytes32 jobId) public onlyClient(jobId) {
        require(jobs[jobId].state == State.Locked, "Job must be in Locked state");

        jobs[jobId].state = State.Disputed;

        emit JobDisputed(jobId);
    }

    function resolveDispute(bytes32 jobId, uint256 clientAmount, uint256 freelancerAmount) public onlyArbitrator(jobId) {
        require(jobs[jobId].state == State.Disputed, "Job must be in Disputed state");
        require(clientAmount >= 0 && freelancerAmount >= 0, "Amounts must be greater than or equal to zero");
        require(clientAmount + freelancerAmount == jobs[jobId].amount, "The sum of amounts must equal the job's amount");


        blocksToken.send(jobs[jobId].freelancer, freelancerAmount, ""); // Use the send function of the BLOCKS token
        blocksToken.send(jobs[jobId].client, clientAmount, ""); // Use the send function of the BLOCKS token

        jobs[jobId].state = State.Release;

        emit JobResolved(jobId);
    }

    function releaseJob(bytes32 jobId) public onlyClient(jobId) {
        require(jobs[jobId].state == State.Locked, "Job must be in Locked state");

        blocksToken.send(jobs[jobId].freelancer, jobs[jobId].amount, ""); // Use the send function of the BLOCKS token

        jobs[jobId].state = State.Release;

        emit JobRelease(jobId);
    }

    function cancelJob(bytes32 jobId) public onlyClient(jobId) {
        require(jobs[jobId].state == State.Created, "Job must be in Created state");

        blocksToken.send(jobs[jobId].client, jobs[jobId].amount, ""); // Use the send function of the BLOCKS token

        jobs[jobId].state = State.Cancelled;

        emit JobCancelled(jobId);
    }

    function setBlocksTokenAddress(address newBlocksTokenAddress) public onlyOwner {
        require(newBlocksTokenAddress != address(0), "New BlocksToken address cannot be zero");
        blocksTokenAddress = newBlocksTokenAddress;
        blocksToken = IERC777(blocksTokenAddress); // Update the blocksToken instance
        emit BlocksTokenAddressUpdated(newBlocksTokenAddress);
    }
}
