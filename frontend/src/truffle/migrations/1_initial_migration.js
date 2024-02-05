const FlightSuretyData = artifacts.require("FlightSuretyData")
const FlightSuretyApp = artifacts.require("FlightSuretyApp")

//update the config.js file with the new contract addresses
const fs = require("fs")
const path = require("path")

module.exports = async function (deployer, network, accounts) {
  // Deploy FlightSuretyData and send 1 ETH
  await deployer.deploy(FlightSuretyData, {
    value: web3.utils.toWei("1", "ether"),
  })
  // Deploy FlightSuretyApp and pass the address of FlightSuretyData
  await deployer.deploy(FlightSuretyApp, FlightSuretyData.address)

  // Construct the absolute path to the config file
  const configFilePath = path.join(__dirname, "../config.js")
  //update the config.js file with the new contract addresses
  const updatedConfig = `module.exports = {
    FlightSuretyAppArtifact: "${path.join(__dirname, "./build/contracts/FlightSuretyApp.json")}",
    FlightSuretyDataArtifact: "${path.join(__dirname, "./build/contracts/FlightSuretyData.json")}",
    ethereumNodeURL: "http://127.0.0.1:8545",
    FlightSuretyAppAddress: "${FlightSuretyApp.address}",
    FlightSuretyDataAddress: "${FlightSuretyData.address}"
  };`

  fs.writeFileSync(configFilePath, updatedConfig, { encoding: "utf-8" })
  console.log("Config file updated with new contract addresses.")
}
