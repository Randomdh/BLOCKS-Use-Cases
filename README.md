# BLOCKS-Use-Cases

Here's a description of each function in the Escrow contract:

createJob: This function allows a client to create a new job by providing the freelancer's address, the arbitrator's address, the amount to be paid for the job, and the payment method (ETH or BLOCKS tokens). The function also transfers the specified amount from the client's account to the contract, either as Ether or as BLOCKS tokens. It then increments the job ID and creates a new Job struct with the specified details, setting its state to Created. Finally, it emits a JobCreated event with the relevant job details.

lockJob: This function allows the freelancer assigned to a job to lock the job, indicating that they have started working on it. The function checks that the caller is the assigned freelancer and that the job is in the Created state. If these conditions are met, the function updates the job's state to Locked and emits a JobLocked event.

releaseJob: This function allows the client who created a job to release the funds to the freelancer when the job is completed. The function checks that the caller is the client and that the job is in the Locked state. If these conditions are met, it transfers the job's amount to the freelancer using the specified payment method (ETH or BLOCKS tokens). The function then updates the job's state to Release and emits a JobRelease event.

cancelJob: This function allows the client who created a job to cancel the job and refund their deposited funds. The function checks that the caller is the client and that the job is in the Created state. If these conditions are met, it transfers the job's amount back to the client using the specified payment method (ETH or BLOCKS tokens). The function then updates the job's state to Cancelled and emits a JobCancelled event.

In addition to these primary functions, the contract also includes several modifiers (onlyClient, onlyFreelancer, and onlyArbitrator) to restrict access to certain functions based on the caller's role.
