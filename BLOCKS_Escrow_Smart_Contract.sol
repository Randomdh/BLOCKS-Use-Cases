// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface BlocksToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Escrow {
    enum State { Created, Locked, Release, Cancelled }

    struct Job {
        address client;
        address payable freelancer;
        address arbitrator;
        uint256 amount;
        State state;
    }

    mapping(bytes32 => Job) public jobs;

    event JobCreated(bytes32 indexed jobId, address indexed client, address indexed freelancer, address arbitrator, uint256 amount);
    event JobLocked(bytes32 indexed jobId);
    event JobRelease(bytes32 indexed jobId);
    event JobCancelled(bytes32 indexed jobId);

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

    function createJob(bytes32 jobId, address payable freelancer, address arbitrator) public payable {
        require(jobs[jobId].client == address(0), "Job already exists");
        require(freelancer != address(0), "Freelancer address cannot be zero");
        require(arbitrator != address(0), "Arbitrator address cannot be zero");
        require(msg.value > 0, "Amount cannot be zero");

        jobs[jobId] = Job({
            client: msg.sender,
            freelancer: freelancer,
            arbitrator: arbitrator,
            amount: msg.value,
            state: State.Created
        });

        emit JobCreated(jobId, msg.sender, freelancer, arbitrator, msg.value);
    }

    function lockJob(bytes32 jobId) public onlyFreelancer(jobId) {
        require(jobs[jobId].state == State.Created, "Job must be in Created state");
        require(BlocksToken(0x8a6D4C8735371EBAF8874fBd518b56Edd66024eB).balanceOf(jobs[jobId].freelancer) >= jobs[jobId].amount, "Freelancer must have enough BLOCKS tokens");

        jobs[jobId].state = State.Locked;

        emit JobLocked(jobId);
    }

    function releaseJob(bytes32 jobId) public onlyClient(jobId) {
        require(jobs[jobId].state == State.Locked, "Job must be in Locked state");

        jobs[jobId].freelancer.transfer(jobs[jobId].amount);

        jobs[jobId].state = State.Release;

        emit JobRelease(jobId);
    }

    function cancelJob(bytes32 jobId) public onlyClient(jobId) {
        require(jobs[jobId].state == State.Created, "Job must be in Created state");

        payable(jobs[jobId].client).transfer(jobs[jobId].amount);

        jobs[jobId].state = State.Cancelled;

        emit JobCancelled(jobId);
    }
}
