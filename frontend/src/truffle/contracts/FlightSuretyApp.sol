// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FlightSuretyData.sol";


/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp  {

    IFlightSuretyDataInterface private flightSuretyData;

/********************************************************************************************/
  /*                                       CONSTRUCTOR                                        */
  /********************************************************************************************/


   
  /**
   * @dev Contract constructor
   */
  constructor(address _dataContractAddress)  {
    flightSuretyData = IFlightSuretyDataInterface(_dataContractAddress);
    contractOwner = msg.sender;
  }

  

  //  constructor()  {
  //   contractOwner == msg.sender;
  // }

  /********************************************************************************************/
  /*                                       DATA VARIABLES                                     */
  /********************************************************************************************/

  event DebugLog(string message);

  // Flight status codes
  uint8 private constant STATUS_CODE_UNKNOWN = 0;
  uint8 private constant STATUS_CODE_ON_TIME = 10;
  uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
  uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
  uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
  uint8 private constant STATUS_CODE_LATE_OTHER = 50;

  address private contractOwner; // Account used to deploy contract

  struct Flight { //a struct Flight, to know the shape of a Flight
    bool isRegistered;
    uint8 statusCode;
    uint256 updatedTimestamp;
    address airline;
  }

  //an oracle struct
  struct Oracle {
    bool isRegistered;
    uint8[3] indexes; //[9,3,4]
  }

  // Model for responses from oracles
  struct ResponseInfo {
    address requester; // Account that requested status
    bool isOpen; // If open, oracle responses are accepted
    mapping(uint8 => address[]) responses; // Mapping key is the status code reported
    // This lets us group responses and identify
    // the response that majority of the oracles
  }

   mapping(bytes32 => Flight) private flights; //a mapping of bytes32 to Flight

   


  // Incremented to add pseudo-randomness at various points
  uint8 private nonce = 0;

  // Fee to be paid when registering oracle
  uint256 public constant REGISTRATION_FEE = 1 ether;

  // Number of oracles that must respond for valid status
  uint256 private constant MIN_RESPONSES = 3;

  // Track all registered oracles
  mapping(address => Oracle) private oracles;

  // Track all oracle responses
  // Key = hash(index, flight, timestamp)
  mapping(bytes32 => ResponseInfo) private oracleResponses;

  // Event fired each time an oracle submits a response
  event FlightStatusInfo(
    address airline,
    string flight,
    uint256 timestamp,
    uint8 status
  );

  event OracleReport(
    address airline,
    string flight,
    uint256 timestamp,
    uint8 status
  );

  // Event fired when flight status request is submitted
  // Oracles track this and if they have a matching index
  // they fetch data and submit a response
  event OracleRequest(
    uint8 index,
    address airline,
    string flight,
    uint256 timestamp
  );


  /********************************************************************************************/
  /*                                       FUNCTION MODIFIERS                                 */
  /********************************************************************************************/

  // Modifiers help avoid duplication of code. They are typically used to validate something
  // before a function is allowed to be executed.

  // /**
  //  * @dev Modifier that requires the "operational" boolean variable to be "true"
  //  *      This is used on all state changing functions to pause the contract in
  //  *      the event there is an issue that needs to be fixed
  //  */
  // modifier requireIsOperational() {
  //   // Modify to call data contract's status
  //   require(true, "Contract is currently not operational");
  //   _; // All modifiers require an "_" which indicates where the function body will be added
  // }

  /**
   * @dev Modifier that requires the "ContractOwner" account to be the function caller
   */
  modifier requireContractOwner() {
    require(msg.sender == contractOwner, "Caller is not contract owner");
    _;
  }

  modifier onlyExistingAirlines()   {
    // Define your onlyAirlines modifier logic here
    require(flightSuretyData.isAnAirline(msg.sender), "Only airlines can call this function");
    _;
}

modifier airlineHasNotVoted(address airline)   {
    require(flightSuretyData.votedBefore(airline, msg.sender), "This airline has already voted for the new airline");
    _;
}

modifier airlineCanParticipate() {
    require(flightSuretyData.airlineIsableToParticipate(msg.sender), "Airline hasnt paid the required fee to join");
    _;
}

modifier isContractOperational() {
  require(flightSuretyData.isOperational(), "Contract must be operational");
  _;
}

modifier shouldBeAPassenger() {
  require(flightSuretyData.thisIsAPassenger(msg.sender), "This must be a passenger");
  _;
}

  
  function setOperatingStatusOfContract(bool mode) public onlyExistingAirlines airlineCanParticipate  {
    flightSuretyData.setOperatingStatus(mode);
  }

  //airline can will click this to pa the require 10eth
  function allowAirlineParticipate(address airline) public payable isContractOperational onlyExistingAirlines {
    // flightSuretyData.fund(msg.sender);
    // Ensure that the sent value is at least 10 ETH
    require(msg.value >= 10 ether, "Insufficient Ether sent");
    // Call the fund function in the data contract
    flightSuretyData.fund{value: msg.value}(airline);
  }

  function createPassengers (address passenger) public isContractOperational {
    require(msg.sender == passenger, "Caller must be the same address passed in");
    flightSuretyData.createPassenger(passenger);
  }

  function buyInsurance (address passenger, string memory flightName) public payable  isContractOperational shouldBeAPassenger {
    require(msg.value > 0 && msg.value <= 1 ether, "Airline insurance must be greater than 0 and at most 1 eth"); //ensure that the amount tendered is less than 1eth
    require(msg.sender == passenger, "Caller must be equal to passenger filled in");

   // Call the buy function in the data contract with the required parameters
    flightSuretyData.buy{value: msg.value}(passenger, flightName);
  }

  // this would be called by the backend if the status code is 20 i.e passengers flight status is cancelled
  function creditPassengersWallet(uint statusCode, address passenger, string memory flightName)  public isContractOperational onlyExistingAirlines airlineCanParticipate {
    flightSuretyData.creditInsurees(statusCode, passenger, flightName);
  }

  //passengers can withdraw what is in their wallet.
  function withdrawFromWallet(address  passenger) public payable  isContractOperational shouldBeAPassenger {
    require(msg.sender == passenger, "Caller is different from the passenger filled in");
    flightSuretyData.pay(passenger);
  }

  function getcontractOwner () public view returns (address owner)  {
    return contractOwner;
  }

  /********************************************************************************************/
  /*                                     SMART CONTRACT FUNCTIONS                             */
  /********************************************************************************************/



  /**
   * @dev Add an airline to the registration queue
   *
   */
  // function registerAnAirline(address airline) public  isContractOperational onlyExistingAirlines airlineHasNotVoted(airline){
  //   flightSuretyData.registerAirline(airline);
  // }

  /**
   * @dev Register a future flight for insuring.
   * passengers can run this
   */ //user will register a flight, in the ui, you can picked from a list or available flights etc
   //passenger can register flight, firstly with a statuscode of unknown 0
  function registerFlight(uint8 code, uint timestamp, address airline) external {

     bytes32 key = keccak256(abi.encodePacked(code, airline, timestamp));

    Flight memory newFlight = Flight({
      isRegistered: true,
      statusCode: code,
      updatedTimestamp: timestamp,
      airline: airline
    });

    flights[key] = newFlight;
  }

  /**
   * @dev Called after oracle has updated flight status
   *
   */ //after the oracle returns with a result this is called, so after i run a fetch and return a status code randomly, I will call the function, if the status code is 20, I can initiate a payout to the passenger
   //so we look for passengers that have purchased insurance for this particular flight and see how much they paid and give them 1.5 x what they paid for the insurance
   //this will be called from the backend
  function processFlightStatus(
    address airline,
    string memory flight,
    uint256 timestamp,
    uint8 statusCode
  ) internal pure {
    //call the function you defined in the DataContract here
    // creditInsurees(uint statusCode, address passenger, string memory flightName)
    
  }


  // Generate a request for oracles to fetch flight information
  //this is a function that will be triggered from the ui and it will generate the event that will then be picked up by the oracles and then respond to them
  function fetchFlightStatus(address airline,string memory flight,uint256 timestamp) external {
    uint8 index = getRandomIndex(msg.sender);

    // Generate a unique key for storing the request
    bytes32 key = keccak256(
      abi.encodePacked(index, airline, flight, timestamp)
    );

    // Create a storage variable to store the ResponseInfo struct
    ResponseInfo storage responseInfo = oracleResponses[key];
    if (responseInfo.requester == address(0)) {
        responseInfo.requester = msg.sender;
        responseInfo.isOpen = true;
    }

    // just check for an OracleRequest in the backend, when you see this, respond to it with the available status codes
    emit OracleRequest(index, airline, flight, timestamp); //getting an oracle request 
  }


  // Register an oracle with the contract
  function registerOracle() external payable {
    // Require registration fee
    require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

    uint8[3] memory indexes = generateIndexes(msg.sender);

    oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
  }

  function getMyIndexes() external view returns (uint8[3] memory) {
    require(oracles[msg.sender].isRegistered, "Not registered as an oracle");
    return oracles[msg.sender].indexes;
  }

  // Called by oracle when a response is available to an outstanding request
  // For the response to be accepted, there must be a pending request that is open
  // and matches one of the three Indexes randomly assigned to the oracle at the
  // time of registration (i.e. uninvited oracles are not welcome)
  function submitOracleResponse(uint8 index,address airline,string memory flight,uint256 timestamp,uint8 statusCode) external {
    require(
      (oracles[msg.sender].indexes[0] == index) ||
        (oracles[msg.sender].indexes[1] == index) ||
        (oracles[msg.sender].indexes[2] == index),
      "Index does not match oracle request"
    ); //check to see if the index passed in matches either index in the oracle struct, if it doesnt return. an array

    bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); //create a key
    require(oracleResponses[key].isOpen,"Flight or timestamp do not match oracle request");

    oracleResponses[key].responses[statusCode].push(msg.sender);

    // Information isn't considered verified until at least MIN_RESPONSES
    // oracles respond with the *** same *** information
    emit OracleReport(airline, flight, timestamp, statusCode);
    if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {
      emit FlightStatusInfo(airline, flight, timestamp, statusCode);

      // Handle flight status as appropriate
      processFlightStatus(airline, flight, timestamp, statusCode);
    }
  }

  function getFlightKey(address airline,string memory flight,uint256 timestamp) external  pure    returns (bytes32) {
    return keccak256(abi.encodePacked(airline, flight, timestamp));
  }

  // Returns array of three non-duplicating integers from 0-9
  function generateIndexes(address account) internal   returns (uint8[3] memory) {
    uint8[3] memory indexes;
    indexes[0] = getRandomIndex(account); //get first item in array

    indexes[1] = indexes[0]; //set second item to first
    while (indexes[1] == indexes[0]) { //loop, that while second item equals first 
      indexes[1] = getRandomIndex(account); //set another value for second item
    }

    indexes[2] = indexes[1]; //set third item to second item
    while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) { //loop and say, while third item equals first item or third item equals second item
      indexes[2] = getRandomIndex(account); //change third item to another one
    }

    return indexes;  //making sure they are different values
  }

  // Returns a single integers from 0-9 randomly
  function getRandomIndex(address account) internal returns (uint8) {
    uint8 maxValue = 10;

    // Pseudo random number...the incrementing nonce adds variation
    uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

    if (nonce > 250) {
      nonce = 0; // Can only fetch blockhashes for last 256 blocks so we adapt
    }

    return random;
  }

}
