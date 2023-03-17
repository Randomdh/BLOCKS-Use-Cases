// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

interface BlocksToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Escrow {
    using Counters for Counters.Counter;
    Counters.Counter private _jobIds;

    address public blocksTokenAddress = 0x17f4A652Fa758002dC184529A75E00017da12048;

    enum State { Created, Locked, Release, Cancelled }
    enum PaymentMethod { ETH, BLOCKS }

    struct Job {
        address client;
        address payable freelancer;
        address arbitrator;
        uint256 amount;
        State state;
        PaymentMethod paymentMethod;
    }

    mapping(uint256 => Job) public jobs;

    event JobCreated(uint256 indexed jobId, address indexed client, address indexed freelancer, address arbitrator, uint256 amount);
    event JobLocked(uint256 indexed jobId);
    event JobRelease(uint256 indexed jobId);
    event JobCancelled(uint256 indexed jobId);

    modifier onlyClient(uint256 jobId) {
        require(msg.sender == jobs[jobId].client, "Only the client can perform this action");
        _;
    }

    modifier onlyFreelancer(uint256 jobId) {
        require(msg.sender == jobs[jobId].freelancer, "Only the freelancer can perform this action");
        _;
    }

    modifier onlyArbitrator(uint256 jobId) {
        require(msg.sender == jobs[jobId].arbitrator, "Only the arbitrator can perform this action");
        _;
    }

    function createJob(address payable freelancer, address arbitrator, uint256 amount, PaymentMethod paymentMethod) public payable {
        require(freelancer != address(0), "Freelancer address cannot be zero");
        require(arbitrator != address(0), "Arbitrator address cannot be zero");
        require(amount > 0, "Amount cannot be zero");
        require(uint8(paymentMethod) <= 1, "Invalid payment method");

        if (paymentMethod == PaymentMethod.ETH) {
            require(msg.value >= amount, "Insufficient ETH sent for the job");
        } else {
            require(BlocksToken(blocksTokenAddress).transferFrom(msg.sender, address(this), amount), "Failed to transfer BLOCKS tokens");
        }

        _jobIds.increment();
        uint256 jobId = _jobIds.current();

        jobs[jobId] = Job({
            client: msg.sender,
            freelancer: freelancer,
            arbitrator: arbitrator,
            amount: amount,
            state: State.Created,
            paymentMethod: paymentMethod
        });

        emit JobCreated(jobId, msg.sender, freelancer, arbitrator, amount);
    }

    function lockJob(uint256 jobId) public onlyFreelancer(jobId) {
        require(jobs[jobId].state == State.Created, "Job must be in Created state");

        jobs[jobId].state = State.Locked;

        emit JobLocked(jobId);
    }

    function releaseJob(uint256 jobId) public onlyClient(jobId) {
        require(jobs[jobId].state == State.Locked, "Job must be in Locked state");

        if (jobs[jobId].paymentMethod == PaymentMethod.ETH) {
                    jobs[jobId].freelancer.transfer(jobs[jobId].amount);
        } else {
        BlocksToken(blocksTokenAddress).transfer(jobs[jobId].freelancer, jobs[jobId].amount);
    }

    jobs[jobId].state = State.Release;

    emit JobRelease(jobId);
}

    function cancelJob(uint256 jobId) public onlyClient(jobId) {
        require(jobs[jobId].state == State.Created, "Job must be in Created state");

        if (jobs[jobId].paymentMethod == PaymentMethod.ETH) {
            payable(jobs[jobId].client).transfer(jobs[jobId].amount);
        } else {
            BlocksToken(blocksTokenAddress).transfer(jobs[jobId].client, jobs[jobId].amount);
        }

        jobs[jobId].state = State.Cancelled;

        emit JobCancelled(jobId);
    }
}
