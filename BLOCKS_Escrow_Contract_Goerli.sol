// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface BlocksToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Escrow {
    address public blocksTokenAddress = 0x17f4A652Fa758002dC184529A75E00017da12048;

    enum State { Created, Locked, Release, Cancelled }

    struct Job {
        address client;
        address payable freelancer;
        address arbitrator;
        uint256 amount;
        State state;
        bool useBlocks;
    }

    mapping(bytes32 => Job) public jobs;

    event JobCreated(bytes32 indexed jobId, address indexed client, address indexed freelancer, address arbitrator, uint256 amount, bool useBlocks);
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

    function createJob(bytes32 jobId, address payable freelancer, address arbitrator, bool useBlocks) public payable {
        require(jobs[jobId].client == address(0), "Job already exists");
        require(freelancer != address(0), "Freelancer address cannot be zero");
        require(arbitrator != address(0), "Arbitrator address cannot be zero");
        require(msg.value > 0, "Amount cannot be zero");

        jobs[jobId] = Job({
            client: msg.sender,
            freelancer: freelancer,
            arbitrator: arbitrator,
            amount: msg.value,
            state: State.Created,
            useBlocks: useBlocks
        });

        emit JobCreated(jobId, msg.sender, freelancer, arbitrator, msg.value, useBlocks);
    }

    function lockJob(bytes32 jobId) public onlyFreelancer(jobId) {
        require(jobs[jobId].state == State.Created, "Job must be in Created state");
        require(BlocksToken(blocksTokenAddress).balanceOf(jobs[jobId].freelancer) >= jobs[jobId].amount, "Freelancer must have enough BLOCKS tokens");

        jobs[jobId].state = State.Locked;

        emit JobLocked(jobId);
    }

    function releaseJob(bytes32 jobId) public onlyClient(jobId) {
        require(jobs[jobId].state == State.Locked, "Job must be in Locked state");

        if (jobs[jobId].useBlocks) {
            BlocksToken(blocksTokenAddress).transfer(jobs[jobId].freelancer, jobs[jobId].amount);
        } else {
            jobs[jobId].freelancer.transfer(jobs[jobId].amount);
        }

        jobs[jobId].state = State.Release;

        emit JobRelease(jobId);
    }

    function cancelJob(bytes32 jobId) public onlyClient(jobId) {
        require(jobs[jobId].state == State.Created, "Job must be in Created state");

        if (jobs[jobId].useBlocks) {
            BlocksToken(blocksTokenAddress).transfer(jobs[jobId].client, jobs[jobId].amount);
        } else {
            payable(jobs[jobId].client).transfer(jobs[jobId].amount);
        }

        jobs[jobId].state = State.Cancelled;

        emit JobCancelled(jobId);
    }
}
