import React, { useState, useEffect } from "react";
import detectEthereumProvider from "@metamask/detect-provider";
import Web3 from "web3";
import FlightSuretyAppArtifact from "./truffle/build/contracts/FlightSuretyApp.json";
import FlightSuretyDataArtifact from "./truffle/build/contracts/FlightSuretyData.json";
import {
  FlightSuretyAppAddress,
  FlightSuretyDataAddress,
} from "./truffle/config";

import "./style.css";

// kindly add your own addresses from ganache to metamask to test
// (0) 0x3024996e12f15b6656f8c13fada6bed60addc3680871a65646afc4b7e7b338b0
// (1) 0xc2763f8c562c682b01e1c757e956699a5bc81f7f24d32b6765a4cb692020015f
// (2) 0x5872de609c64132e7c0860c9039624ec3deb3d9fc850e5a1ec4ce06e348b1055
// (3) 0x81abb1e6fd4e98065a3884aa275d4d91ebde9733698118be39396fbc94ba5d25
// (4) 0x2ea6f7a6c98d48a27522a0cc5797933a2157aeb36d2f9b27b725de4e31e98dde
// (5) 0xf4794bcc3a7464a70ad6257df1454aa34aabf9db069ea2752ff6e96736e2560d
// (6) 0xd5bf56e961757e0b91fddf92623122725ea296ba9d97ac3144cc8121c683e7b1
// (7) 0x8cf4757d1197689d62db990c5d660ee9e0a1a9f76a2b4f2094b6415520e8c634
// (8) 0x04fd8620c14beb6357bdc2f63d1563c63ec263ee7d796df24beab91345494c43
// (9) 0xbf59e6119bfe33c3d8b69b47b748e1b4dd4f8a0a0898632b5edc8423f66240bd

const App = () => {
  const apiUrl = "http://localhost:8000/api/fetchFlightStatus";

  const [web3, setWeb3] = useState(null);
  const [flightDataContract, setFlightDataContract] = useState(null);
  const [flightSuretyAppContract, setFlightSuretyAppContract] = useState(null);
  const [currentAccount, setCurrentAccount] = useState(null);
  const [selectedFlight, setSelectedFlight] = useState(null);
  const [totalAirlines, setTotalAirlines] = useState(0);
  const [totalAirlinesThatCanParticipate, setTotalAirlinesThatCanParticipate] =
    useState(0);
  const [newAirline, setNewAirline] = useState("");
  const [airline, setSelectedAirline] = useState("");
  const [airlineToBeFunded, setAirlineToBeFunded] = useState("");
  const [newPassenger, setNewPassenger] = useState("");
  const [contractOwner, setContractOwner] = useState("");
  const [newContractStatus, setNewContractStatus] = useState(null);
  const [passengerWantingToWithdraw, setPassengerWantingToWithdraw] =
    useState("");

  const [operationalStatus, setOperationalStatus] = useState(false);
  const [flightStatus, setFlightStatus] = useState(null);
  //all events

  const allFlights = [
    {
      name: "BCD Airlines",
      timestamp: "2024-03-07T10:47:20.257Z",
      insuranceAmount: 0.1,
    },
    {
      name: "XYZ Airlines",
      timestamp: "2024-04-07T10:47:20.257Z",
      insuranceAmount: 0.2,
    },
    {
      name: "ABC Airlines",
      timestamp: "2024-05-07T10:47:20.257Z",
      insuranceAmount: 0.3,
    },
    {
      name: "DEF Airlines",
      timestamp: "2024-06-07T10:47:20.257Z",
      insuranceAmount: 0.4,
    },
    {
      name: "GHI Airlines",
      timestamp: "2024-07-07T10:47:20.257Z",
      insuranceAmount: 0.5,
    },
    {
      name: "JKL Airlines",
      timestamp: "2024-08-07T10:47:20.257Z",
      insuranceAmount: 0.6,
    },
    {
      name: "MNO Airlines",
      timestamp: "2024-09-07T10:47:20.257Z",
      insuranceAmount: 0.7,
    },
    {
      name: "PQR Airlines",
      timestamp: "2024-10-07T10:47:20.257Z",
      insuranceAmount: 0.8,
    },
    {
      name: "STU Airlines",
      timestamp: "2024-11-07T10:47:20.257Z",
      insuranceAmount: 0.9,
    },
    {
      name: "VWX Airlines",
      timestamp: "2024-12-07T10:47:20.257Z",
      insuranceAmount: 1.0,
    },
  ];

  const initWeb3 = async () => {
    if (window.ethereum || window.web3) {
      // use the injected provider from Metamask
      const _web3 = new Web3(window.ethereum || window.web3.currentProvider);
      const _flightSuretyDataContract = new _web3.eth.Contract(
        FlightSuretyDataArtifact.abi,
        FlightSuretyDataAddress
      );
      const _flightSuretyAppContract = new _web3.eth.Contract(
        FlightSuretyAppArtifact.abi,
        FlightSuretyAppAddress
      );
      setWeb3(_web3);
      setFlightDataContract(_flightSuretyDataContract);
      setFlightSuretyAppContract(_flightSuretyAppContract);
      try {
        // request account access if needed
        await window.eth_requestAccounts;
        const account = await window.ethereum.request({
          method: "eth_requestAccounts",
        });
        setCurrentAccount(account[0]);
      } catch (error) {
        console.error(error);
        console.log("User denied account access");
      }
    } else {
      console.log(
        "No web3 detected. Install MetaMask or use a web3-enabled browser."
      );
    }
  };

  const connectWallet = async () => {
    const provider = await detectEthereumProvider();
    if (provider) {
      // From now on, this should always be true:
      provider === window.ethereum;
      console.log("Ethereum successfully detected!");
    } else {
      console.error("Please install MetaMask!");
    }
  };

  //function to handle account changes
  const handleAccountsChanged = (accounts) => {
    if (accounts.length > 0) {
      const newAccount = accounts[0];
      setCurrentAccount(newAccount);
      // Do something with the new account if needed
      console.log("Connected account changed:", newAccount);
    } else {
      // Handle the case when no account is connected
      setCurrentAccount("");
      console.log("No account connected");
    }
  };

  useEffect(() => {
    initWeb3();
    connectWallet();
    getOwner();
    fetchOperationalStatus();
    totalAirlinesCount();
    totalAirlinesThatCanParticipateCount();
    // Event listener for account changes
    window.ethereum.on("accountsChanged", handleAccountsChanged);
    // Clean up the event listener when the component unmounts
    return () => {
      window.ethereum.removeListener("accountsChanged", handleAccountsChanged);
    };
  }, [currentAccount]);

  const totalAirlinesCount = async () => {
    try {
      const count = await flightDataContract.methods.totalAirlines().call({
        from: currentAccount,
        gas: 2000000,
        // blockNumber: "latest",
      });
      console.log("Total airlines: ", parseInt(count, 10));
      setTotalAirlines(parseInt(count, 10));
    } catch (err) {
      console.error(err);
    }
  };

  const totalAirlinesThatCanParticipateCount = async () => {
    try {
      const count = await flightDataContract.methods
        .totalAirlinesAbleToParticipate()
        .call({
          from: currentAccount,
          gas: 2000000,
          // blockNumber: "latest",
        });
      console.log("Total airlines that can participate: ", parseInt(count, 10));
      setTotalAirlinesThatCanParticipate(parseInt(count, 10));
    } catch (err) {
      console.error(err);
    }
  };

  const returnIfValueIsNotPassedIn = (str) => {
    if (str.length === 0) {
      alert("Please enter in a value ");
      return;
    }
  };

  // register an airline
  const registerAirline = async (airline) => {
    // Check if the airline is empty
    // convert to checksum address
    try {
      returnIfValueIsNotPassedIn(airline);
      let airlineAddress = web3.utils.toChecksumAddress(airline);
      const isAirline = await flightDataContract.methods
        .isAnAirline(airlineAddress)
        .call({
          from: currentAccount,
          gas: 2000000,
          // blockNumber: "latest",
        });

      if (isAirline) {
        alert("This address is already an airline");
        return;
      } else {
        const registerTx = await flightDataContract.methods
          .registerAirline(airlineAddress)
          .send({
            from: currentAccount,
            gas: 2000000,
          });
        await checkForEvents(
          registerTx,
          "AirlineRegistered",
          flightDataContract
        );
        totalAirlinesCount();
      }
    } catch (err) {
      console.error(err);
    }
  };

  // fund an airline, for ailines that are already registered, only airlines
  const fundAirline = async (airline) => {
    try {
      returnIfValueIsNotPassedIn(airline);
      let airlineAddress = web3.utils.toChecksumAddress(airline); // convert to checksum address
      // check if the address is an airline first
      const isAirline = await flightDataContract.methods
        .isAnAirline(airlineAddress)
        .call({
          from: currentAccount,
          gas: 2000000,
          // blockNumber: "latest",
        });

      if (!isAirline) {
        alert("This address is not an airline");
        return;
      } else {
        // fund the airline
        const fundedTx = await flightSuretyAppContract.methods
          .allowAirlineParticipate(airlineAddress)
          .send({
            from: currentAccount,
            value: web3.utils.toWei("10", "ether"),
            blockNumber: "latest",
            gas: 2000000,
          });
        await checkForEvents(
          fundedTx,
          "AirlineCanParticipate",
          flightDataContract
        );
        totalAirlinesThatCanParticipateCount();
      }
    } catch (error) {
      console.error(error.message);
    }
  };

  // create a passenger
  const createPassenger = async (passenger) => {
    returnIfValueIsNotPassedIn(passenger);
    let passengerAddress = web3.utils.toChecksumAddress(passenger);

    try {
      const isPassenger = await flightDataContract.methods
        .thisIsAPassenger(passengerAddress)
        .call({
          from: currentAccount,
          gas: 2000000,
          // blockNumber: "latest",
        });

      if (isPassenger) {
        alert("This address is already a passenger");
        return;
      }

      const passengerTx = await flightDataContract.methods
        .createPassenger(passengerAddress)
        .send({
          from: currentAccount,
          gas: 2000000,
        });
      await checkForEvents(passengerTx, "PassengerCreated", flightDataContract);
      setNewPassenger("");
    } catch (err) {
      console.error(err.message);
    }
  };

  const buyInsurance = async (passenger) => {
    returnIfValueIsNotPassedIn(passenger);
    let passengerAddress = web3.utils.toChecksumAddress(passenger);
    let name = selectedFlight && selectedFlight.name;

    console.log("Passenger Address: ", passengerAddress);
    console.log("Name: ", name);

    console.log(
      "Insurance Amount in wei: ",
      web3.utils.toWei(selectedFlight.insuranceAmount.toFixed(18), "ether")
    );

    // // console.log({ insuranceAmount, name });

    console.log("Passenger Address: ", passengerAddress);
    console.log("Name: ", name);
    try {
      const isPassenger = await flightDataContract.methods
        .thisIsAPassenger(passengerAddress)
        .call({
          from: currentAccount,
          gas: 2000000,
          // blockNumber: "latest",
        });

      if (!isPassenger) {
        alert("This address is not a passenger");
        return;
      } else {
        const buyInsuranceTx = await flightSuretyAppContract.methods
          .buyInsurance(passengerAddress, name)
          .send({
            from: passengerAddress,
            value: web3.utils.toWei(
              selectedFlight.insuranceAmount.toFixed(18),
              "ether"
            ),
            gas: 2000000,
          });
        await checkForEvents(
          buyInsuranceTx,
          "InsurancePurchased",
          flightDataContract
        );
      }
    } catch (err) {
      console.error(err.message);
    }
  };

  //switch to an account that is a passenger and has bought insurance
  //widhdraw from wallet, this will allow the cash to be visible in the passenger balance
  const withdrawInsurance = async (passenger) => {
    returnIfValueIsNotPassedIn(passenger);
    let passengerAddress = web3.utils.toChecksumAddress(passenger);
    try {
      const withdrawTx = await flightSuretyAppContract.methods
        .withdrawFromWallet(passengerAddress)
        .send({
          from: currentAccount,
          gas: 2000000,
        });
      console.log({ withdrawTx });
      await checkForEvents(withdrawTx, "PayoutSuccessful", flightDataContract);
    } catch (err) {
      console.error(err.message);
    }
  };

  const fetchFlightStatus = async (airline) => {
    try {
      returnIfValueIsNotPassedIn(airline);
      let airlineAddress = web3.utils.toChecksumAddress(airline); // convert to checksum address

      const isAirline = await flightDataContract.methods
        .isAnAirline(airlineAddress)
        .call({
          from: currentAccount,
          gas: 2000000,
          // blockNumber: "latest",
        });

      const data = {
        flight: selectedFlight.name,
        airline: airlineAddress,
        timestamp: Date.now(selectedFlight.timestamp),
      };

      if (!isAirline) {
        alert("This address is not an airline");
        return;
      }
      console.log({ data, airlineAddress });

      const response = await fetch(apiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });

      const flightStatus = await response.json();

      if (flightStatus.flightStatus?.code === 20) {
        let passengerAddress =
          newPassenger && web3.utils.toChecksumAddress(newPassenger);
        alert(
          "Flight is delayed, and you will be credited with 1.5x insurance amount"
        );
        try {
          if (newPassenger) {
            // call this with an airline address that can participate, this are the airlines that can only credit the passenger wallet
            await creditPassengerWallet(
              20,
              passengerAddress,
              selectedFlight.name
            );
          } else {
            alert("Please enter your address to credit your wallet");
          }
        } catch (err) {
          console.error(err.message);
        }
      }

      console.log({ flightStatus });
      setFlightStatus(flightStatus);
      setSelectedAirline("");
    } catch (err) {
      console.error(err.message);
    }
  };

  const getOwner = async () => {
    try {
      const owner = await flightSuretyAppContract.methods
        .getcontractOwner()
        .call({
          from: currentAccount,
          gas: 2000000,
        });
      console.log("Owner: ", owner);
      setContractOwner(owner);
    } catch (err) {
      console.error(err.message);
    }
  };

  const creditPassengerWallet = async (code, passenger, flightName) => {
    try {
      const creditTx = await flightSuretyAppContract.methods
        .creditPassengersWallet(code, passenger, flightName)
        .send({
          from: currentAccount, // this is the airline address that can participate
          gas: 2000000,
        });
      console.log({ creditTx });
      await checkForEvents(
        creditTx,
        "PassengerWalletCredited",
        flightDataContract
      );
    } catch (err) {
      console.error(err.message);
    }
  };

  const changeContractOperationalStatus = async (val) => {
    console.log(val.toLowerCase() === "true" ? true : false);
    try {
      const changeStatusTx = await flightSuretyAppContract.methods
        .setOperatingStatusOfContract(
          val.toLowerCase() === "true" ? true : false
          // val === "true" ? true : false
        )
        .send({
          from: currentAccount,
          gas: 2000000,
        });

      console.log({ changeStatusTx });

      // await checkForEvents(
      //   changeStatusTx,
      //   "OperationalStatusChanged",
      //   flightDataContract
      // );

      // await checkForEvents(
      //   changeStatusTx,
      //   "ResetStatusOfVotersToZero",
      //   flightDataContract
      // );

      // await checkForEvents(
      //   changeStatusTx,
      //   "OpearationalStatusVoteRecorded",
      //   flightDataContract
      // );

      fetchOperationalStatus();
    } catch (err) {
      console.error(err.message);
    }
  };

  // fetch operational status
  const fetchOperationalStatus = async () => {
    try {
      const status = await flightDataContract.methods.isOperational().call({
        from: currentAccount,
        gas: 3000000,
        blockNumber: "latest",
      });
      console.log("Operational status: ", status);
      setOperationalStatus(status);
    } catch (err) {
      console.error(err);
    }
  };

  const checkForEvents = async (tx, eventName, contract) => {
    try {
      const receipt = await web3.eth.getTransactionReceipt(tx.transactionHash);
      const event = await contract.getPastEvents(eventName, {
        fromBlock: receipt.blockNumber,
        toBlock: receipt.blockNumber,
      });
      if (event) alert(eventName + " event emitted");
    } catch (err) {
      console.log(err);
    }
  };

  return (
    <div className="bg-outer">
      <h1>Flight Surety Dapp</h1>
      <div className="container">
        <div>
          <p>
            Airline Count : &nbsp;
            {totalAirlines}
          </p>
          <p>
            Airlines that can participate : &nbsp;
            {totalAirlinesThatCanParticipate}
          </p>

          <p>OperationalStatus:</p>
          {operationalStatus ? (
            <p style={{ color: "green" }}>Operational</p>
          ) : (
            <p style={{ color: "red" }}>Not Operational</p>
          )}

          <button onClick={fetchOperationalStatus}>
            Fetch Operational Status
          </button>
          {/* register airline start */}
          <form onSubmit={(e) => e.preventDefault()}>
            <label className="flight-header">Register an airline:</label>
            <input
              type="text"
              value={newAirline || ""}
              onChange={(e) => setNewAirline(e.target.value)}
              placeholder="Enter airline address"
            />

            <button onClick={() => registerAirline(newAirline)}>
              Register Airline
            </button>
          </form>
          {/* register airline end */}
          {/* fund airline start */}
          <form
            onSubmit={(e) => {
              e.preventDefault();
            }}
          >
            <label className="flight-header">Fund an airline:</label>
            <br />
            <input
              type="text"
              value={airlineToBeFunded || ""}
              onChange={(e) => setAirlineToBeFunded(e.target.value)}
              placeholder="Enter airline address"
            />
            <br />

            <button onClick={() => fundAirline(airlineToBeFunded)}>
              Fund Airline
            </button>
          </form>
          {/* fund airline end */}

          <form
            onSubmit={(e) => {
              e.preventDefault();
            }}
          >
            <label className="flight-header">
              Change Contract Operational Status:
            </label>

            <select
              value={newContractStatus || ""}
              defaultValue=""
              onChange={(e) => setNewContractStatus(e.target.value)}
            >
              <option value="" disabled selected>
                Select a status
              </option>
              <option value={true}>Operational</option>
              <option value={false}>Not Operational</option>
            </select>
            <br />
            <br />
            <button
              onClick={() => changeContractOperationalStatus(newContractStatus)}
            >
              Change Status
            </button>
          </form>
        </div>

        {/*  */}

        <div>
          <form
            onSubmit={(e) => {
              e.preventDefault();
            }}
          >
            <label className="flight-header">Create a passenger:</label>
            <br />

            <input
              type="text"
              value={newPassenger || ""}
              onChange={(e) => setNewPassenger(e.target.value)}
              placeholder="Enter passenger address"
            />
          </form>

          <button onClick={() => createPassenger(newPassenger)}>
            Create Passenger
          </button>

          {selectedFlight && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
              }}
            >
              <label className="flight-header">Buy Insurance:</label>
              <br />
              <small
                style={{
                  color: "yellow",
                }}
              >
                Flight name and Insurance amount will be prefilled after
                selecting a flight
              </small>
              <input
                type="text"
                value={newPassenger || ""}
                onChange={(e) => setNewPassenger(e.target.value)}
                placeholder="Enter passenger address"
              />
              <br />
              <button onClick={() => buyInsurance(newPassenger)}>
                Buy Insurance
              </button>
            </form>
          )}

          {/* 

              
          */}

          <form
            onSubmit={(e) => {
              e.preventDefault();
            }}
          >
            <label className="flight-header">Select a flight:</label>
            <select
              value={selectedFlight ? selectedFlight.timestamp : ""}
              onChange={(e) => {
                const flight = allFlights.find(
                  (flight) => flight.timestamp === e.target.value
                );
                setSelectedFlight(flight);
              }}
            >
              <option value="" disabled selected>
                Select a flight
              </option>
              {allFlights.map((flight, index) => {
                return (
                  <option key={index} value={flight.timestamp} option>
                    {flight.name} -{" "}
                    {new Date(flight.timestamp).toLocaleString()} - Insurance
                    Amount- {flight.insuranceAmount} ETH
                  </option>
                );
              })}
            </select>

            <label className="flight-header">Airline:</label>
            <br />

            <input
              type="text"
              value={airline || ""}
              onChange={(e) => setSelectedAirline(e.target.value)}
              placeholder="Enter airline address"
            />
          </form>

          <button onClick={() => fetchFlightStatus(airline)}>
            Fetch Flight Status
          </button>

          <p>
            Status for Flight {selectedFlight && selectedFlight.name}: &nbsp;
            &nbsp;
          </p>

          {flightStatus && (
            <p
              style={{
                color: flightStatus.flightStatus?.code !== 20 ? "gray" : "red",
              }}
            >
              <span className="badge">
                {flightStatus.flightStatus?.description}
              </span>
            </p>
          )}

          <input
            type="text"
            value={newPassenger || ""}
            onChange={(e) => setNewPassenger(e.target.value)}
            placeholder="If your flight is delayed, enter your address to credit your wallet"
          />

          <form
            onSubmit={(e) => {
              e.preventDefault();
            }}
          >
            <label className="flight-header">Withdraw from wallet:</label>
            <br />
            <input
              type="text"
              value={passengerWantingToWithdraw || ""}
              onChange={(e) => setPassengerWantingToWithdraw(e.target.value)}
              placeholder="passenger address that wants to withdraw, make sure you have bought insurance first"
            />
            <br />
            <button
              onClick={() => withdrawInsurance(passengerWantingToWithdraw)}
            >
              Withdraw
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default App;
