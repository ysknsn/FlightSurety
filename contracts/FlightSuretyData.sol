pragma solidity >=0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false

    // The Data contract will hold the fund
    uint256 private funds = 0 ether;

    mapping(address => Airline) airlines;

    // store all insurance status.
    mapping(address => Insurance) insurances;

    mapping(address => uint256) authorizedContracts;

    //Every new airline that is registered is not funded. The airlines need to submit their funds after registration
    //Every airline that want to register another airline needs to be funded.
    //If A wants to register B, then A must be a register airline that already paid the funds
    struct Airline {
        bool isRegistered;
        bool isFunded;
        address airlineAddress;
    }

    struct Insurance {
        address passengersAddress;
        bool isPaid;
        uint256 purchasedAmount;
        address airlineAddress;
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor() public {
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

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

    modifier isCallerAuthorized() {
        require(
            authorizedContracts[msg.sender] == 1,
            "Caller is not authorized"
        );
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */

    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */

    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */

    function registerAirline(address airlineAddress) external {
        // require(airlines[msg.sender].isFunded, "This airline has no funsds");
        airlines[airlineAddress].isRegistered = true;
        airlines[airlineAddress].airlineAddress = airlineAddress;
    }

    function isRegisteredAirline(address airlineAddress) returns (bool) {  
        // FIXME: I don't know how to check if the mapping exists.
        // bool isExists = bytes(airlines[airlineAddress]).length > 0;
        // require(isExists, "There is no Airline with that address.");

        return airlines[airlineAddress].isRegistered;
    }

    /**
     * @dev Buy insurance for a flight
     *
     */

    function purchaseFlightInsurance(address passengersAddress, address airlineAddress, uint256 purchasedAmount) external payable {
        // buy – buy insurance for one flight for one person
        // buyInsurance let's the passenger to buy an insurance. It works like this:
        // Passenger pays and the ether is stored in the FlightSuretyData contract >> FlightSuretyData registers the insurance

        // passengersAddress
        insurances[passengersAddress] = Insurance({
            passengersAddress: passengersAddress,
            isPaid: false, 
            purchasedAmount: purchasedAmount,
            airlineAddress: airlineAddress
        });
        funds = funds + purchasedAmount;
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees() external {
        // creditInsurees – credit all insurees of one fligh

        // FIXME: I don't know what this function is used for.
        // What exactly does "credit" mean?
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function payoutFundsToInsuree(
        address passengersAddress
    ) external {
        // pay – you should check that we have enough money for payment using require()
        uint256 purchasedAmount = insurances[passengersAddress].purchasedAmount;
        // FIXME: TypeError: Operator * not compatible with types uint256 and rational_const 3 / 2
        uint256 payoutAmount = purchasedAmount;// * 1.5;
        require(funds >= payoutAmount, "There is not enough ETH to payout");

        insurances[passengersAddress].isPaid = true;
        funds = funds - payoutAmount;
        passengersAddress.transfer(payoutAmount);
    }

    function fund(address airlineAddress) public payable {
        // Airline can be registered, but does not participate in contract until it submits funding of 10 ether
        require(msg.value >= 10, "You must have a minimum of 10 eth to register.");

        // FIXME: 
        funds = funds + msg.value;
        airlines[airlineAddress].isFunded = true;
        airlines[airlineAddress].airlineAddress = airlineAddress;
    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */

    function initialFunding() public payable {
        // FIXME: 
        funds = funds + msg.value;
    }

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    // function() external payable {
        // FIXME: This line makes an ERROR
        // fund();
    // }

    function isAirline(address airline) public view returns (bool) {
        return airlines[airline].isRegistered;
    }

    function authorizeContracts(address dataContracts) external requireContractOwner {
        authorizedContracts[dataContracts] = 1;
    }

    function deauthorizedContracts(address dataContracts)
        external
        requireContractOwner
    {
        delete authorizedContracts[dataContracts];
    }
}
