import React, { useState, useEffect } from "react";
import Web3 from "web3";
import "./App.css";

const CONTRACT_ADDRESS = "0x444C2e6A5DdBCFb8CC0927920Af38639323a0b57";

const ABI = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "jobId",
        type: "uint256"
      }
    ],
    name: "JobCancelled",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "jobId",
        type: "uint256"
      },
      {
        indexed: true,
        internalType: "address",
        name: "client",
        type: "address"
      },
      {
        indexed: true,
        internalType: "address",
        name: "freelancer",
        type: "address"
      },
      {
        indexed: false,
        internalType: "address",
        name: "arbitrator",
        type: "address"
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256"
      }
    ],
    name: "JobCreated",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "jobId",
        type: "uint256"
      }
    ],
    name: "JobLocked",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "uint256",
        name: "jobId",
        type: "uint256"
      }
    ],
    name: "JobRelease",
    type: "event"
  },
  {
    inputs: [],
    name: "blocksTokenAddress",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "jobId",
        type: "uint256"
      }
    ],
    name: "cancelJob",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "address payable",
        name: "freelancer",
        type: "address"
      },
      {
        internalType: "address",
        name: "arbitrator",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256"
      },
      {
        internalType: "enum Escrow.PaymentMethod",
        name: "paymentMethod",
        type: "uint8"
      }
    ],
    name: "createJob",
    outputs: [],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256"
      }
    ],
    name: "jobs",
    outputs: [
      {
        internalType: "address",
        name: "client",
        type: "address"
      },
      {
        internalType: "address payable",
        name: "freelancer",
        type: "address"
      },
      {
        internalType: "address",
        name: "arbitrator",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256"
      },
      {
        internalType: "enum Escrow.State",
        name: "state",
        type: "uint8"
      },
      {
        internalType: "enum Escrow.PaymentMethod",
        name: "paymentMethod",
        type: "uint8"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "jobId",
        type: "uint256"
      }
    ],
    name: "lockJob",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "jobId",
        type: "uint256"
      }
    ],
    name: "releaseJob",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  }
];

function App() {
  const [web3, setWeb3] = useState(null);
  const [accounts, setAccounts] = useState([]);
  const [contract, setContract] = useState(null);

  useEffect(() => {
    async function setupWeb3() {
      if (window.ethereum) {
        try {
          const web3Instance = new Web3(window.ethereum);
          const accounts = await window.ethereum.request({
            method: "eth_requestAccounts"
          });
          const escrowContract = new web3Instance.eth.Contract(
            ABI,
            CONTRACT_ADDRESS
          );
          setWeb3(web3Instance);
          setAccounts(accounts);
          setContract(escrowContract);
        } catch (err) {
          console.error("Error connecting to Ethereum:", err);
        }
      } else {
        alert("Please install MetaMask or another Ethereum wallet provider");
      }
    }

    setupWeb3();
  }, []);

  async function createJob() {
    const freelancerAddress = document.getElementById("freelancerAddress")
      .value;
    const arbitratorAddress = document.getElementById("arbitratorAddress")
      .value;
    const amount = document.getElementById("amount").value;
    const paymentMethod = document.getElementById("paymentMethod").value;

    if (!freelancerAddress || !arbitratorAddress || !amount || !paymentMethod) {
      alert("Please fill all fields.");
      return;
    }

    let paymentMethodValue;
    if (paymentMethod.toLowerCase() === "eth") {
      paymentMethodValue = 0;
    } else if (paymentMethod.toLowerCase() === "blocks") {
      paymentMethodValue = 1;
    } else {
      alert('Invalid payment method. Use "ETH" or "BLOCKS".');
      return;
    }

    const amountInWei = web3.utils.toWei(amount, "ether");

    try {
      await contract.methods
        .createJob(
          freelancerAddress,
          arbitratorAddress,
          amountInWei,
          paymentMethodValue
        )
        .send({
          from: accounts[0],
          value: paymentMethodValue === 0 ? amountInWei : "0"
        });
      alert("Job created successfully");
    } catch (err) {
      console.error("Error creating job:", err);
      alert("Error creating job");
    }
  }

  async function lockJob() {
    const jobId = document.getElementById("lockJobId").value;
    try {
      await contract.methods.lockJob(jobId).send({ from: accounts[0] });
      alert("Job locked successfully");
    } catch (err) {
      console.error("Error locking job:", err);
      alert("Error locking job");
    }
  }

  async function releaseJob() {
    const jobId = document.getElementById("releaseJobId").value;
    try {
      await contract.methods.releaseJob(jobId).send({ from: accounts[0] });
      alert("Job released successfully");
    } catch (err) {
      console.error("Error releasing job:", err);
      alert("Error releasing job");
    }
  }

  async function cancelJob() {
    const jobId = document.getElementById("cancelJobId").value;
    try {
      await contract.methods.cancelJob(jobId).send({ from: accounts[0] });
      alert("Job cancelled successfully");
    } catch (err) {
      console.error("Error cancelling job:", err);
      alert("Error cancelling job");
    }
  }

  return (
    <div className="container">
      <h1>Escrow App</h1>
      <div className="section">
        <h2>Create Job</h2>
        <input id="freelancerAddress" placeholder="Freelancer Address" />
        <input id="arbitratorAddress" placeholder="Arbitrator Address" />
        <select id="paymentMethod">
          <option value="">Choose Payment Method</option>
          <option value="ETH">Ethereum</option>
          <option value="BLOCKS">BLOCKS</option>
        </select>
        <input id="amount" placeholder="Amount" />
        <button onClick={createJob}>Create Job</button>
      </div>
      <div className="section">
        <h2>Lock Job</h2>
        <input id="lockJobId" placeholder="Job ID" />
        <button onClick={lockJob}>Lock Job</button>
      </div>
      <div className="section">
        <h2>Release Job</h2>
        <input id="releaseJobId" placeholder="Job ID" />
        <button onClick={releaseJob}>Release Job</button>
      </div>
      <div className="section">
        <h2>Cancel Job</h2>
        <input id="cancelJobId" placeholder="Job ID" />
        <button onClick={cancelJob}>Cancel Job</button>
      </div>
    </div>
  );
}
export default App;
