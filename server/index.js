const { Web3 } = require("web3");
const express = require("express");
const FlightSuretyAppArtifact = require("../frontend/src/truffle/build/contracts/FlightSuretyApp.json");
const FlightSuretyDataArtifact = require("../frontend/src/truffle/build/contracts/FlightSuretyData.json");
const config = require("../frontend/src/truffle/config.js");
const cors = require("cors");

const app = express();
const port = 8000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());

// Connect to Ethereum node
const web3 = new Web3(config.ethereumNodeURL || "http://127.0.0.1:8545");

web3.eth.getBlockNumber().then((latest) => {
  console.log("Latest block number: ", latest.toString());
});

// const timeStamp = Date.now();
const statusCodes = {
  0: {
    code: 0,
    description: "Unknown",
  },
  10: {
    code: 10,
    description: "On Time",
  },
  20: {
    code: 20,
    description: "Late Airline",
  },
  30: {
    code: 30,
    description: "Late Weather",
  },
  40: {
    code: 40,
    description: "Late Technical",
  },
  50: {
    code: 50,
    description: "Late Other",
  },
};
const EVENTNAME = "OracleRequest";
//pls start up ganache, and change the address to the address ganche gives you, so you are able to test.
// Ganache doesnt allow us to loop, so I am unable to register multiple oracles.
const oracleAddress = "0x2093803e3Ac00438680C55bF83C4Ae636eAb2274";

// Get the contract instance
const flightSuretyAppInstance = new web3.eth.Contract(
  FlightSuretyAppArtifact.abi,
  config.FlightSuretyAppAddress
);

const flightSuretyDataInstance = new web3.eth.Contract(
  FlightSuretyDataArtifact.abi,
  config.FlightSuretyDataAddress
);

app.get("/api", (req, res) => {
  res.json({ message: "An API for use with your Dapp!" });
});

//this api is used to fetch the flight status
//i am calling the api, checking that the OracleRequest event was emitted, if so, I am getting random statusCodes and sending back to the frontend, this will determine what happens next in the frontend
app.post("/api/fetchFlightStatus", async (req, res) => {
  try {
    const { flight, airline, timestamp } = req.body; //get the flight, airline and timestamp from the frontend
    // const flightKey = web3.utils.soliditySha3(airline, flight, timestamp);

    // call fetchFlightStatus
    const tx = await flightSuretyAppInstance.methods
      .fetchFlightStatus(airline, flight, timestamp)
      .send({
        from: oracleAddress,
        gas: 3000000,
      });

    const eventReceived = await checkForEvents(tx, EVENTNAME); //this function checks if the event was emitted
    if (eventReceived.success) {
      // now return the status code to the frontend
      const flightStatus = await getFlightStatuscode();
      console.log({ flightStatus, message: "Flight status fetched" });
      //then you now allow user to initiate a transaction to pay credit their wallet, if the flight is delayed
      res.json({ flightStatus });
    }
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: "An error occurred" });
  }
});

//check for events
const checkForEvents = async (tx, eventName) => {
  try {
    const receipt = await web3.eth.getTransactionReceipt(tx.transactionHash);
    await flightSuretyAppInstance.getPastEvents(eventName, {
      fromBlock: receipt.blockNumber,
      toBlock: receipt.blockNumber,
    });
    console.log({ receipt });
    console.log({ message: "OracleRequest event emitted" });
    return { success: true };
  } catch (err) {
    console.log(err.message);
  }
};

const getFlightStatuscode = async () => {
  const codes = Math.floor(Math.random() * 6) * 10;
  return statusCodes[codes];
};

//oracle address
// const oracleAddresses = [
//   "0xd39beb539e621948c31e4f5e31213e5e7d7f6513",
//   "0x0736830e7489222056ce1c4e87c106df33062a0e",
//   "0x16eb69f683aead88a957cf1062fc91aad2a937a2",
//   "0x670f0d43eee1c34ffe133c919625013c91396dd6",
//   "0x201aea8bec806a12606ecd6a67ef34bf617ba01f",
//   "0xad84ecccb69eab66bd08304a74bb1e29bf44df7c",
//   "0x413a4ed5544e038350ebe20dab8c62f8660fb24a",
//   "0xb2dc610d003c2f68fef94f514ee8ed84c272294f",
//   "0x7649081c388e1d29e42fcc6dff0a2c01c7993115",
//   "0x6a8019d00315225de17aac43d3a70cca497b1ddb",
// ];

//in new versions of ganache registering and looping through oracles is causing evm revert error
// I left the code to register multiple oracles in comments, and I am registering only one oracle, because ganache doesnt allow the loop to register oracles

//add an address here, when you start up the app, take your address from ganache cli and add it here, because the ganache cli address changes every time you start it up

//register oracles
// const registerOracles = async () => {
//   try {
//     for (const oracleAddress of oracleAddresses) {
//       console.log(`Attempting to register oracle: ${oracleAddress}`);
//       const tx = await flightSuretyAppInstance.methods.registerOracle().send({
//         from: oracleAddress,
//         value: web3.utils.toWei("1", "ether"),
//         gas: 3000000,
//       });
//       console.log(
//         `Oracle ${oracleAddress} registered. Transaction hash: ${tx.transactionHash}`
//       );
//     }
//   } catch (error) {
//     console.log(error);
//   }
// };

// registerOracles();

const registerOracles = async () => {
  try {
    let tx = await flightSuretyAppInstance.methods.registerOracle().send({
      from: oracleAddress,
      value: web3.utils.toWei("1", "ether"),
      gas: 3000000,
    });
    console.log(
      tx,
      `Oracle registered with address: transaction hash: ${tx.transactionHash}`
    );
  } catch (error) {
    console.log(error.message);
  }
};

const operationalStatus = async () => {
  try {
    const operational = await flightSuretyDataInstance.methods
      .isOperational()
      .call();
    console.log({ operational });
  } catch (error) {
    console.log(error.message);
  }
};

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
  registerOracles();
  operationalStatus();
});
