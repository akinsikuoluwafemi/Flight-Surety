const FlightSuretyData = artifacts.require("FlightSuretyData")
const FlightSuretyApp = artifacts.require("FlightSuretyApp")

contract("Flight Surety Tests", async (accounts) => {
  let flightDataInstance
  let flightAppInstance
  let airline1 = accounts[0]
  let airline2 = accounts[1]
  let airline3 = accounts[2]
  let airline4 = accounts[3]
  let airline5 = accounts[4]
  let airline6 = accounts[5]
  let airline7 = accounts[6]
  let passenger1 = accounts[7]
  let passenger2 = accounts[8]
  let passenger3 = accounts[9]

  beforeEach(async () => {
    flightDataInstance = await FlightSuretyData.deployed()
    flightAppInstance = await FlightSuretyApp.deployed(
      flightDataInstance.address,
    )
  })

  it("should register first airline when contract is deployed", async () => {
    let result = await flightDataInstance.isAnAirline(airline1)
    assert.equal(result, true, "First airline is not registered")
  })

  it("(multiparty) has correct initial isOperational() value", async () => {
    // Get operating status
    let status = await flightDataInstance.isOperational.call()
    assert.equal(status, true, "Incorrect initial operating status value")
  })

  it("(multiparty) can register an airline if the contract is operational", async () => {
    //register airline
    await flightDataInstance.registerAirline(airline2, {
      from: airline1,
    })

    let totalAirlines = await flightDataInstance.totalAirlines.call()
    assert.equal(
      totalAirlines.toNumber() === 2,
      true,
      "Airline was not registered",
    )
  })

  it("(multiparty) can not register an airline if the contract is not operational", async () => {
    // register airlines and allow two airlines to be able to participate, then set the contract to not operational, then try and register another airline, it should fail
    const newStatus = false
    let reverted = false
    //register airline3
    await flightDataInstance.registerAirline(airline3, {
      from: airline2,
    })
    //make airline1 to be able to participate
    await flightAppInstance.allowAirlineParticipate(airline1, {
      from: airline1,
      value: web3.utils.toWei("10", "ether"),
    })

    // make airline 2 to be able to participate
    await flightAppInstance.allowAirlineParticipate(airline2, {
      from: airline2,
      value: web3.utils.toWei("10", "ether"),
    })

    //set the contract to not operational
    await flightDataInstance.setOperatingStatus(newStatus, {
      from: airline1,
    })

    const status = await flightDataInstance.isOperational.call()

    assert.equal(status, newStatus, "Operational status was not set to false")

    assert.isFalse(status, "Contract is not operational")

    //try to register airline3
    try {
      await flightDataInstance.registerAirline(airline4, {
        from: airline3,
      })
    } catch (err) {
      reverted = true
    }
    assert.equal(
      reverted,
      true,
      "Airline was registered when contract was not operational",
    )
  })

  it("airline can participate", async () => {
    //setting the contract to operational
    await flightDataInstance.setOperatingStatus(true, {
      from: airline1,
    })

    //is airline 3 an airline
    const tx = await flightDataInstance.isAnAirline(airline3)
    console.log({ tx })
    const contractStatus = await flightDataInstance.isOperational.call()
    console.log({ contractStatus })

    const txParticipatingAirlinesBefore =
      await flightDataInstance.totalAirlinesAbleToParticipate.call()
    console.log({
      txParticipatingAirlinesBefore: txParticipatingAirlinesBefore.toNumber(),
    })

    // make airline 3 to be able to participate
    await flightAppInstance.allowAirlineParticipate(airline3, {
      from: airline3,
      value: web3.utils.toWei("10", "ether"),
    })

    const txParticipatingAirlinesAfter =
      await flightDataInstance.totalAirlinesAbleToParticipate.call()
    console.log({
      txParticipatingAirlinesAfter: txParticipatingAirlinesAfter.toNumber(),
    })

    assert(
      txParticipatingAirlinesAfter.toNumber() >
        txParticipatingAirlinesBefore.toNumber(),
      "Number of participating airlines did not increase",
    )
  })
})
