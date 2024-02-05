// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// interface IFlightSuretyData {
//     function registerAirline(address newAirline) external;
//     function isOperational() external view returns (bool);
//     function setOperatingStatus(bool mode) external;
//     function buy(address pasenger, string memory flighName) external payable;
//     function creditInsurees(uint statusCode, address passenger, string memory flightName) external;
//     function pay(address  passenger) external payable ;
//   //function fund(address newAirline) external payable;
//     function getFlightKey(address airline,string memory flight,uint256 timestamp)external  pure returns (bytes32);
//    function isAnAirline(address airline) external view returns (bool);
//   function votedBefore(address airline, address voter) external view returns (bool);

// }

// contract FlightSuretyData is IFlightSuretyData  {

//   address private contractOwner; // Account used to deploy contract
//   //set this to private back
//   bool public  operational = true; // Blocks all state changes throughout the contract if false
//   uint public airlineregFee = 10 ether;

//     struct Airline {
//         bool registered;
//         uint voteCount;
//         mapping(address => bool) votes;
//         bool ableToParticipate;
//     } 

//   struct Passenger {
//     bool isPassenger;
//     uint wallet;
//     address payable owner;
//     mapping(string => uint) flightNameToAmountOfInsurancePaid;
//   }

//   uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;


//     mapping(address => Airline) public airlines; //address => Airline mapping
//     mapping(address => Passenger) public passengers; //address => Passenger mapping
//     uint public totalAirlines;
//     uint public totalAirlinesAbleToParticipate;
//     uint public totalPassengers;
//     address[] public allAirlines;
//     address[] public allPassengers;
//     address[] public airlineAbleToParticipate; 
//     address[] public airlineThatHaveVotedForContractStatusChange;
//     /********************************************************************************************/
//   /*                                       EVENT DEFINITIONS                                  */
//   /********************************************************************************************/

//     event AirlineRegistered(address newAirline);
//     event VoteRecorded(address voter, address votee, string message);
//     event PassengerCreated(address newPassenger);
//     event InsurancePurchased(address passenger, string flightName);
//     event PassengerWalletCredited(address passenger, string flightName, string message);
//     event PayoutSuccessful(address passenger);
//     event AirlineCanParticipate(address airline);
//     event OpearationalStatusVoteRecorded(address airline, string message);
//     event OperationalStatusChanged();
//     event ResetStatusOfVotersToZero();


//     modifier onlyExistingAirlines() {
//         require(airlines[msg.sender].registered, "Only existing airlines can call this function");
//         _;
//     }

//   modifier isAPassenger() {
//     require(passengers[msg.sender].isPassenger, "Must be a passenger");
//     _;
//   }
    

//     // modifier airlineHasNotVoted(address newAirline) {
//     //     require(!airlines[newAirline].votes[msg.sender], "This airline has already voted for the new airline");
//     //     _;
//     // }

//      modifier airlineHasNotVoted(address newAirline) virtual  {
//         require(!airlines[newAirline].votes[msg.sender], "This airline has voted before");
//         _;
//     }

  
//      /**
//    * @dev Modifier that requires the "operational" boolean variable to be "true"
//    *      This is used on all state changing functions to pause the contract in
//    *      the event there is an issue that needs to be fixed
//    */
//   modifier requireIsOperational() {
//     require(operational, "Contract is currently not operational");
//     _; // All modifiers require an "_" which indicates where the function body will be added
//   }
//     /**
//    * @dev Modifier that requires the "ContractOwner" account to be the function caller
//    */
//   modifier requireContractOwner() {
//     require(msg.sender == contractOwner, "Caller is not contract owner");
//     _;
//   }

//     //use this for all the function that handlles money
//   modifier mustBeAbleToParticipate (address newAirline) { //use this on all other functions
//     require(airlines[newAirline].ableToParticipate, "Airline isn't able to participate, an airline must pay 10 Eth to be able to");
//     _;
//   }

//     constructor () payable {
//         contractOwner = msg.sender;

//         //register airline
//         airlines[msg.sender].registered = true;
//         allAirlines.push(msg.sender);
//         totalAirlines++;
//         emit AirlineRegistered(msg.sender);
//     }   

//     function registerAirline(address newAirline) external override  requireIsOperational onlyExistingAirlines airlineHasNotVoted(newAirline) {
//         require(!airlines[newAirline].registered, "The new airline is already registered");
//         // If less than 4 airlines, register the new airline directly
//         if (totalAirlines < 4) {
//             airlines[newAirline].registered = true;
//             totalAirlines++;
//             allAirlines.push(newAirline);
//             emit AirlineRegistered(msg.sender);
//         } else {
//             // If 4 or more airlines, initiate the voting process
//             airlines[newAirline].voteCount++;
//             airlines[newAirline].votes[msg.sender] = true;
//             emit VoteRecorded(msg.sender, newAirline, "Airline will be added after consensus is met");

//             // Check if more than 50% of the existing airlines have voted
//             if (airlines[newAirline].voteCount * 2 >= totalAirlines) { //if the total airline is even, the vote count will be rounded up
//                 airlines[newAirline].registered = true;
//                 totalAirlines++;
//                 allAirlines.push(msg.sender);
//                 emit AirlineRegistered(msg.sender);
//             }
//         }
//     }


//     //  function registerAirline(address newAirline) external override  {
//     //     require(!airlines[newAirline].registered, "The new airline is already registered");

//     //     // If less than 4 airlines, register the new airline directly
//     //     if (totalAirlines < 4) {
//     //         airlines[newAirline].registered = true;
//     //         totalAirlines++;
//     //         allAirlines.push(newAirline);
//     //         emit AirlineRegistered(msg.sender);
//     //     } else {
//     //         // If 4 or more airlines, initiate the voting process
//     //         airlines[newAirline].voteCount++;
//     //         airlines[newAirline].votes[msg.sender] = true;
//     //         emit VoteRecorded(msg.sender, newAirline, "Airline will be added after consensus is met");

//     //         // Check if more than 50% of the existing airlines have voted
//     //         if (airlines[newAirline].voteCount >= totalAirlines / 2) {
//     //             airlines[newAirline].registered = true;
//     //             totalAirlines++;
//     //             allAirlines.push(msg.sender);
//     //             emit AirlineRegistered(msg.sender);
//     //         }
//     //     }
//     // }

    

//     /**
//    * @dev Get operating status of contract
//    *
//    * @return A bool that is the current operating status
//    */
//   function isOperational() external view returns (bool) {
//     return operational;
//   }
//   /**]
//    * @dev Sets contract operations on/off
//    *
//    * When operational mode is disabled, all write transactions except for this one will fail
//    */

//   //  only airlines that are able to participate will be able to change this.
//   // so this will change when 50% of airlines able to participate have voted.
//   // if 50% or more have voted then this can be changed
//   /////////////////////////
//   function setOperatingStatus(bool mode) external onlyExistingAirlines mustBeAbleToParticipate(msg.sender) {
//      require(mode != operational, "New mode must be different from existing mode");
//      require(totalAirlinesAbleToParticipate >= 2, "There has to be at least 2 airliens able to participate, to set contract status"); //so everyone will not be locked out if we have one bad actor
//     //only airlines able to participate can call this.
//     bool isDuplicate = false; // Check if caller has already called this function
//     for(uint c = 0; c < airlineThatHaveVotedForContractStatusChange.length; c++){
//       if(airlineThatHaveVotedForContractStatusChange[c] == msg.sender){
//         isDuplicate = true;
//         break;
//       }
//     }
//     require(!isDuplicate, "Caller has voted before");
//     airlineThatHaveVotedForContractStatusChange.push(msg.sender);
//     emit OpearationalStatusVoteRecorded(msg.sender, "After 50% of the total airline able to participate has voted, the status would change");
//     //50% of airline able to partcipate are the ones that can set the operational status of the contract
//     if(hasReachedMajority()){
//         operational = mode; //setting the operational status
//         emit OperationalStatusChanged();
//         resetVoting();
//         emit ResetStatusOfVotersToZero();
//     }
//   }
//    //at least 50% of airlines able to participate has voted => bool
//   function hasReachedMajority() internal view returns (bool) {
//     return airlineThatHaveVotedForContractStatusChange.length * 2 >= totalAirlinesAbleToParticipate;
//   }

// // Function to reset the voting process of the operational status
//   function resetVoting() internal {
//       delete airlineThatHaveVotedForContractStatusChange;
//   }
//   /////////////////////////

//    function isAnAirline(address airline) external override view returns (bool) {
//         return airlines[airline].registered;
//   }

//   function thisIsAPassenger(address passenger) external  view returns (bool){
//     return passengers[passenger].isPassenger;
//   }

//   function votedBefore(address newAirline, address voter) external override view returns (bool) {
//     return airlines[newAirline].votes[voter];
//   }

//   function createPassenger (address passenger) public requireIsOperational {
//       Passenger storage newPassenger = passengers[passenger];
//       if(newPassenger.owner == address(0)){
//         newPassenger.isPassenger = true;
//         newPassenger.owner = payable(msg.sender);
//         newPassenger.wallet = 0;
//         newPassenger.flightNameToAmountOfInsurancePaid["DefaultFlight"] = 0;
//       }
//       totalPassengers++;
//       emit PassengerCreated(passenger);
//     }
// /**
//   //pasaengers can purchase insurance, if their flight is delayed or cancelled, they can get paid.
//    * @dev Buy insurance for a flight i:e 
//    *
//    */ //only addresses that are marked as passengers can call this
//   function buy(address passenger, string memory flightName) external payable requireIsOperational isAPassenger {
//     require(msg.value > 0 && msg.value <= 1 ether, "Insurance Amount must be greater than 0 and less than 1 eth"); //ensure that the amount tendered is less than 1eth

//     Passenger storage newPassenger = passengers[passenger];
//     //set the passenger owner and flightNameToAmountOfInsureancePaid mapping
//       newPassenger.owner = payable(passenger);
//       newPassenger.flightNameToAmountOfInsurancePaid[flightName] = msg.value;
//       emit InsurancePurchased(passenger, flightName);
//   }
//   /**
//    *  @dev Credits payouts to insurees
//    */ //credit the passengers wallet based on if the status code is 20, meaning their flight is missed, credit them with 1.5 * what the paid to buy the insurance
//   function creditInsurees(uint statusCode, address passenger, string memory flightName) external requireIsOperational onlyExistingAirlines mustBeAbleToParticipate(msg.sender)  {
//     require(statusCode == STATUS_CODE_LATE_AIRLINE, "Airline has to be cancelled to credit passengers wallet");
//     if(statusCode == STATUS_CODE_LATE_AIRLINE){
//     //get the amount paid to buy the insurance, by putting in the parameters
//     uint amount = getAmountPaidByPassengerForInsurance(passenger, flightName);
//     //multiply the amount by 1.5
//      amount = amount * 150 / 100;
//     //credit the pasengers wallet
//     passengers[passenger].wallet += amount;
//     emit PassengerWalletCredited(passenger, flightName, "Passenger walet has been credited for cancelation of a flight");
//     }
//   }

//   function getAmountPaidByPassengerForInsurance (address passenger, string memory flightName) internal view returns (uint amount) {
//     return passengers[passenger].flightNameToAmountOfInsurancePaid[flightName];
//   }

//   /**
//    *  @dev Transfers eligible payout funds to insuree
//    *
//    */ //passengers can pay themselves from the money in their wallet
//   function pay(address  passenger) external payable requireIsOperational isAPassenger {
    
//     uint  amountInWallet = passengers[passenger].wallet;
//     if(amountInWallet > 0){
//       //get owner of wallet
//       address payable ownerOfWallet = passengers[passenger].owner;
//       //set the wallet to 0 first
//       passengers[passenger].wallet = 0;
//       //transfer to the wallet
//       ownerOfWallet.transfer(amountInWallet);
//       //emit event
//       emit PayoutSuccessful(passenger);
//     }
//   }
//   /**
//    * @dev Initial funding for the insurance. Unless there are too many delayed flights
//    *      resulting in insurance payouts, the contract should be self-sustaining
//    *
//    */ //so the airlines will call this, to pay the require 10eth to the contract to make sure they are able participate
//   function fund(address airline) external payable requireIsOperational onlyExistingAirlines {
//      require(airlines[airline].ableToParticipate == false, "Airline is already able to participate"); //check that airline hasnt paid the required 10eth to join before
//      require(msg.value >= airlineregFee, "Insufficient Ether sent");
//     //      // Using transfer with an explicit value to avoid reentrancy issues
//         uint excessAmount = msg.value - airlineregFee;
//     //     //send excess amount back to airline
//         if(excessAmount > 0) {
//           payable(airline).transfer(excessAmount); //transfer the balance back
//         }
//         airlines[airline].ableToParticipate = true;
//         totalAirlinesAbleToParticipate++;
//         airlineAbleToParticipate.push(airline);
//         emit AirlineCanParticipate(airline);


//   }

//   function getFlightKey(
//     address airline,
//     string memory flight,
//     uint256 timestamp
//   ) external  pure virtual   returns (bytes32) {
//     return keccak256(abi.encodePacked(airline, flight, timestamp));
//   }


//    /**
//  * @dev Fallback function for funding smart contract.
//  */

//  receive() external payable requireIsOperational {
//     // Check if the Ether amount is greater than or equal to 10 ether
//     require(msg.value >= airlineregFee, "Insufficient Ether sent");
//      //register airline
//         airlines[msg.sender].registered = true;
//         //make them able to participate
//         airlines[msg.sender].ableToParticipate = true;

//         //push to the list of airlines
//         allAirlines.push(msg.sender);

//         airlineAbleToParticipate.push(msg.sender);

//         //increment airlineCount
//         totalAirlines++;
//         totalAirlinesAbleToParticipate++;
//         //emit events
//         emit AirlineRegistered(msg.sender);
//         emit AirlineCanParticipate(msg.sender);
//   }
// }



pragma solidity ^0.8.0;

interface IFlightSuretyDataInterface {
    function registerAirline(address newAirline) external;
    function isOperational() external view returns (bool);
    function setOperatingStatus(bool mode) external;
    function buy(address pasenger, string memory flighName) external payable;
    function creditInsurees(uint statusCode, address passenger, string memory flightName) external;
    function pay(address  passenger) external payable ;
  function fund(address newAirline) external payable;
  function getFlightKey(address airline,string memory flight,uint256 timestamp)external  pure returns (bytes32);
  function isAnAirline(address airline) external view returns (bool);
  function votedBefore(address airline, address voter) external view returns (bool);
  function airlineIsableToParticipate(address airline) external view  returns (bool);
  function createPassenger (address passenger) external;
  function thisIsAPassenger(address passenger) external  view returns (bool);

}

contract FlightSuretyData is IFlightSuretyDataInterface  {

  address private contractOwner; // Account used to deploy contract
  //set this to private back
  bool public  operational = true; // Blocks all state changes throughout the contract if false
  uint public airlineregFee = 10 ether;

    struct Airline {
        bool registered;
        uint voteCount;
        mapping(address => bool) votes;
        bool ableToParticipate;
    } 

  struct Passenger {
    bool isPassenger;
    uint wallet;
    address payable owner;
    mapping(string => uint) flightNameToAmountOfInsurancePaid;
  }

  uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;


    mapping(address => Airline) public airlines; //address => Airline mapping
    mapping(address => Passenger) public passengers; //address => Passenger mapping
    uint public totalAirlines;
    uint public totalAirlinesAbleToParticipate;
    uint public totalPassengers;
    address[] public allAirlines;
    address[] public allPassengers;
    address[] public airlineAbleToParticipate; 
    address[] public airlineThatHaveVotedForContractStatusChange;
    /********************************************************************************************/
  /*                                       EVENT DEFINITIONS                                  */
  /********************************************************************************************/

    event AirlineRegistered(address newAirline);
    event VoteRecorded(address voter, address votee, string message);
    event PassengerCreated(address newPassenger);
    event InsurancePurchased(address passenger, string flightName);
    event PassengerWalletCredited(address passenger, string flightName, string message);
    event PayoutSuccessful(address passenger);
    event AirlineCanParticipate(address airline);
    event OpearationalStatusVoteRecorded(address airline, string message);
    event OperationalStatusChanged();
    event ResetStatusOfVotersToZero();


    modifier onlyExistingAirlines() {
        require(airlines[msg.sender].registered, "Only existing airlines can call this function");
        _;
    }

  modifier isAPassenger() {
    require(passengers[msg.sender].isPassenger, "Must be a passenger");
    _;
  }
    

    // modifier airlineHasNotVoted(address newAirline) {
    //     require(!airlines[newAirline].votes[msg.sender], "This airline has already voted for the new airline");
    //     _;
    // }

     modifier airlineHasNotVoted(address newAirline) virtual  {
        require(!airlines[newAirline].votes[msg.sender], "This airline has voted before");
        _;
    }

  
     /**
   * @dev Modifier that requires the "operational" boolean variable to be "true"
   *      This is used on all state changing functions to pause the contract in
   *      the event there is an issue that needs to be fixed
   */
  modifier requireIsOperational() {
    require(operational, "Contract is currently not operational");
    _; // All modifiers require an "_" which indicates where the function body will be added
  }
    /**
   * @dev Modifier that requires the "ContractOwner" account to be the function caller
   */
  modifier requireContractOwner() {
    require(msg.sender == contractOwner, "Caller is not contract owner");
    _;
  }

    //use this for all the function that handlles money
  modifier mustBeAbleToParticipate (address newAirline) { //use this on all other functions
    require(airlines[newAirline].ableToParticipate, "Airline isn't able to participate, an airline must pay 10 Eth to be able to");
    _;
  }

    constructor () payable {
        contractOwner = msg.sender;

        //register airline
        airlines[msg.sender].registered = true;
        allAirlines.push(msg.sender);
        totalAirlines++;
        emit AirlineRegistered(msg.sender);
    }   

    function registerAirline(address newAirline) external override  requireIsOperational onlyExistingAirlines airlineHasNotVoted(newAirline) {
        require(!airlines[newAirline].registered, "The new airline is already registered");
        // If less than 4 airlines, register the new airline directly
        if (totalAirlines < 4) {
            airlines[newAirline].registered = true;
            totalAirlines++;
            allAirlines.push(newAirline);
            emit AirlineRegistered(msg.sender);
        } else {
            // If 4 or more airlines, initiate the voting process
            airlines[newAirline].voteCount++;
            airlines[newAirline].votes[msg.sender] = true;
            emit VoteRecorded(msg.sender, newAirline, "Airline will be added after consensus is met");

            // Check if more than 50% of the existing airlines have voted
            if (airlines[newAirline].voteCount * 2 >= totalAirlines) { //if the total airline is even, the vote count will be rounded up
                airlines[newAirline].registered = true;
                totalAirlines++;
                allAirlines.push(msg.sender);
                emit AirlineRegistered(msg.sender);
            }
        }
    }


    /**
   * @dev Get operating status of contract
   *
   * @return A bool that is the current operating status
   */
  function isOperational() external view returns (bool) {
    return operational;
  }
  /**]
   * @dev Sets contract operations on/off
   *
   * When operational mode is disabled, all write transactions except for this one will fail
   */

  //  only airlines that are able to participate will be able to change this.
  // so this will change when 50% of airlines able to participate have voted.
  // if 50% or more have voted then this can be changed
  /////////////////////////
  function setOperatingStatus(bool mode) external override  {
     require(mode != operational, "New mode must be different from existing mode");
     require(totalAirlinesAbleToParticipate >= 2, "There has to be at least 2 airliens able to participate, to set contract status"); //so everyone will not be locked out if we have one bad actor
    //only airlines able to participate can call this.
    bool isDuplicate = false; // Check if caller has already called this function
    for(uint c = 0; c < airlineThatHaveVotedForContractStatusChange.length; c++){
      if(airlineThatHaveVotedForContractStatusChange[c] == msg.sender){
        isDuplicate = true;
        break;
      }
    }
    require(!isDuplicate, "Caller has voted before");
    airlineThatHaveVotedForContractStatusChange.push(msg.sender);
    emit OpearationalStatusVoteRecorded(msg.sender, "After 50% of the total airline able to participate has voted, the status would change");
    //50% of airline able to partcipate are the ones that can set the operational status of the contract
    if(hasReachedMajority()){
        operational = mode; //setting the operational status
        emit OperationalStatusChanged();
        resetVoting();
        emit ResetStatusOfVotersToZero();
    }
  }
   //at least 50% of airlines able to participate has voted => bool
  function hasReachedMajority() internal view returns (bool) {
    return airlineThatHaveVotedForContractStatusChange.length * 2 >= totalAirlinesAbleToParticipate;
  }

// Function to reset the voting process of the operational status
  function resetVoting() internal {
      delete airlineThatHaveVotedForContractStatusChange;
  }
  /////////////////////////

   function isAnAirline(address airline) external override view returns (bool) {
        return airlines[airline].registered;
  }

  function thisIsAPassenger(address passenger) external  view returns (bool){
    return passengers[passenger].isPassenger;
  }

  function votedBefore(address airline, address voter) external  view returns (bool) {
    return airlines[airline].votes[voter];
  }
 
  function airlineIsableToParticipate(address airline) external view  returns (bool) {
    return airlines[airline].ableToParticipate;
  }

  // modifier requireIsOperational() {
  //   require(operational, "Contract is currently not operational");
  //   _; // All modifiers require an "_" which indicates where the function body will be added
  // }

  function createPassenger (address passenger) external override  {
    require(!passengers[passenger].isPassenger, "This user is already a passenger");
      Passenger storage newPassenger = passengers[passenger];
      if(newPassenger.owner == address(0)){
        newPassenger.isPassenger = true;
        newPassenger.owner = payable(passenger);
        newPassenger.wallet = 0;
        newPassenger.flightNameToAmountOfInsurancePaid["DefaultFlight"] = 0;
      }
      totalPassengers++;
      emit PassengerCreated(passenger);
    }
/**
  //pasaengers can purchase insurance, if their flight is delayed or cancelled, they can get paid.
   * @dev Buy insurance for a flight i:e 
   *
   */ //only addresses that are marked as passengers can call this
  function buy(address passenger, string memory flightName) external payable override {
    require(msg.value > 0 && msg.value <= 1 ether, "Insurance Amount must be greater than 0 and less than 1 eth"); //ensure that the amount tendered is less than 1eth
    Passenger storage newPassenger = passengers[passenger];
    //set the passenger owner and flightNameToAmountOfInsureancePaid mapping
      newPassenger.owner = payable(passenger);
      newPassenger.flightNameToAmountOfInsurancePaid[flightName] = msg.value;
      emit InsurancePurchased(passenger, flightName);
  }
  /**
   *  @dev Credits payouts to insurees
   */ //credit the passengers wallet based on if the status code is 20, meaning their flight is missed, credit them with 1.5 * what the paid to buy the insurance
  function creditInsurees(uint statusCode, address passenger, string memory flightName) external override    {
    require(statusCode == STATUS_CODE_LATE_AIRLINE, "Airline has to be cancelled to credit passengers wallet");
    if(statusCode == STATUS_CODE_LATE_AIRLINE){
    //get the amount paid to buy the insurance, by putting in the parameters
    uint amount = getAmountPaidByPassengerForInsurance(passenger, flightName);
    //multiply the amount by 1.5
     amount = amount * 150 / 100;
    //credit the pasengers wallet
    passengers[passenger].wallet += amount;
    emit PassengerWalletCredited(passenger, flightName, "Passenger walet has been credited for cancelation of a flight");
    }
  }

  function getAmountPaidByPassengerForInsurance (address passenger, string memory flightName) internal view returns (uint amount) {
    return passengers[passenger].flightNameToAmountOfInsurancePaid[flightName];
  }

  /**
   *  @dev Transfers eligible payout funds to insuree
   *
   */ //passengers can pay themselves from the money in their wallet
  function pay(address  passenger) external payable override  {
    uint  amountInWallet = passengers[passenger].wallet;
    require(amountInWallet > 0, "Passengers wallet is empty"); //passengers wallet must not be empty

    if(amountInWallet > 0){
      //get owner of wallet
      address payable ownerOfWallet = passengers[passenger].owner;
      //set the wallet to 0 first
      passengers[passenger].wallet = 0;
      //transfer to the wallet
      ownerOfWallet.transfer(amountInWallet);
      //emit event
      emit PayoutSuccessful(passenger);
    }
  }
  /**
   * @dev Initial funding for the insurance. Unless there are too many delayed flights
   *      resulting in insurance payouts, the contract should be self-sustaining
   *
   */ //so the airlines will call this, to pay the require 10eth to the contract to make sure they are able participate
  function fund(address airline) external payable override   {
     require(airlines[airline].ableToParticipate == false, "Airline is already able to participate"); //check that airline hasnt paid the required 10eth to join before
     require(msg.value >= airlineregFee, "Insufficient Ether sent");
    //      // Using transfer with an explicit value to avoid reentrancy issues
        uint excessAmount = msg.value - airlineregFee;
    //     //send excess amount back to airline
        if(excessAmount > 0) {
          payable(airline).transfer(excessAmount); //transfer the balance back
        }
        airlines[airline].ableToParticipate = true;
        totalAirlinesAbleToParticipate++;
        airlineAbleToParticipate.push(airline);
        emit AirlineCanParticipate(airline);
  }

  function getFlightKey(
    address airline,
    string memory flight,
    uint256 timestamp
  ) external  pure virtual   returns (bytes32) {
    return keccak256(abi.encodePacked(airline, flight, timestamp));
  }


   /**
 * @dev Fallback function for funding smart contract.
 */

 receive() external payable requireIsOperational {
    // Check if the Ether amount is greater than or equal to 10 ether
    require(msg.value >= airlineregFee, "Insufficient Ether sent");
     //register airline
        airlines[msg.sender].registered = true;
        //make them able to participate
        airlines[msg.sender].ableToParticipate = true;

        //push to the list of airlines
        allAirlines.push(msg.sender);

        airlineAbleToParticipate.push(msg.sender);

        //increment airlineCount
        totalAirlines++;
        totalAirlinesAbleToParticipate++;
        //emit events
        emit AirlineRegistered(msg.sender);
        emit AirlineCanParticipate(msg.sender);
  }
}
