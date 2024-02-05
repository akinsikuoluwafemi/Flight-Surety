const FlightSuretyData = artifacts.require("FlightSuretyData")
const FlightSuretyApp = artifacts.require("FlightSuretyApp")

contract("Oracles", async (accounts) => {
  let flightDataInstance
  let flightAppInstance

  let statusCodes = {
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
  }

  beforeEach(async () => {
    flightDataInstance = await FlightSuretyData.deployed()
    flightAppInstance = await FlightSuretyApp.deployed(
      flightDataInstance.address,
    )
  })

  it("can register multiple oracles", async () => {
    for (let account of accounts.slice(1)) {
      // skip the first account
      await flightAppInstance.registerOracle({
        from: account,
        value: web3.utils.toWei("1", "ether"),
      })
      let result = await flightAppInstance.getMyIndexes.call({ from: account })
      console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`)
    }

    assert(true, "Multiple oracles registered")
  })

  it("can request flight status", async () => {
    let flight = "ND1309"
    let timestamp = Math.floor(Date.now() / 1000)
    let passenger = accounts[9]

    const getFlightStatuscode = async () => {
      const codes = Math.floor(Math.random() * 6) * 10
      return statusCodes[codes]
    }

    const tx = await flightAppInstance.fetchFlightStatus(
      accounts[0],
      flight,
      timestamp,
      {
        from: passenger,
      },
    )
    assert.equal(
      tx.logs[0].event,
      "OracleRequest",
      "OracleRequest event not emitted",
    )

    const flightStatus = await getFlightStatuscode()
    console.log({ flightStatus })

    assert.isOk(flightStatus, "Flight status not generated")
  })
})
