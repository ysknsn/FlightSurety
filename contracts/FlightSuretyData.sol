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
    uint256 private totalFundedEth = 0 ether;

    mapping(address => Airline) airlines;
    mapping(address => uint256) authorizedContracts;

    //Every new airline that is registered is not funded. The airlines need to submit their funds after registration
    //Every airline that want to register another airline needs to be funded. If A wants to register B, then A must be a register airline that already paid the funds
    struct Airline {
        bool isRegistered;
        address airlineaddress;
        // bool isFunded;
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
        airlines[msg.sender] = Airline({
            isRegistered: true,
            airlineaddress: airlineAddress
        });
    }

    /**
     * @dev Buy insurance for a flight
     *
     */

    function purchaseFlightInsurance() external payable {
        // buy – buy insurance for one flight for one person
        // buyInsurance let's the passenger to buy an insurance. It works like this:
        // Passenger pays and the ether is stored in the FlightSuretyData contract >> FlightSuretyData registers the insurance

        
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees() external pure {
        // creditInsurees – credit all insurees of one flight


        // TODO: I don't know what this function is used for.
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function payoutFundsToInsuree(
        address airlineAddress,
        address flightAddress,
        uint256 timestamp,
        address passengersAddress
    ) external pure {
        // pay – you should check that we have enough money for payment using require()
    }

    // function fund() {}

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */

    function initialFunding() public payable {}

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    // function() external payable {
    //     fund();
    // }

    function isAirline(address airline) public view returns (bool) {
        return airlines[airline].isRegistered;
    }

    function authorizeContracts(address dataContracts)
        external
        requireContractOwner
    {
        authorizedContracts[dataContracts] = 1;
    }

    function deauthorizedContracts(address dataContracts)
        external
        requireContractOwner
    {
        delete authorizedContracts[dataContracts];
    }
}
