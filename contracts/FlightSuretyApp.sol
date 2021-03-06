pragma solidity >=0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

// import "../constracts/FlightSuretyData.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    FlightSuretyData private flightSuretyData;

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    // How many are required in order for the multiparty call to bee executed.
    uint256 constant M = 4;

    address private contractOwner; // Account used to deploy contract
    mapping(address => UserProfile) userProfiles;
    mapping(bytes32 => Flight) flights;
    bool private operational = true;

    address[] multiCalls = new address[](0);

    // for Rate Limiting
    uint256 private enabled = block.timestamp;

    // fo Re-entrancy Guard
    uint256 private counter = 1;

    struct UserProfile {
        bool isRegistered;
        bool isAdmin;
    }

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
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
        // Modify to call data contract's status
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

    modifier rateLimit(uint256 time) {
        require(block.timestamp >= enabled, "Rate Limiting in effect");
        enabled = enabled.add(time);
        _;
    }

    modifier entrancyGuard() {
        counter = counter.add(1);
        uint256 guard = counter;
        _;
        require(guard == counter, "That is not allowed");
    }

    function safeWidthDraw(uint256 amount) external rateLimit(30 minutes) {}

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
     * @dev Contract constructor
     *
     */
    constructor(address dataContract) public {
        contractOwner = msg.sender;

        // First airline is registered when contract is deployed.
        flightSuretyData = FlightSuretyData(dataContract);
        flightSuretyData.registerAirline(msg.sender);
        multiCalls.push(msg.sender);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public returns (bool) {
        return operational; // Modify to call data contract's status
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *
     */

    function registerAirline(address airlineAddress) external returns (bool success, uint256 votes) {
        
        // FIXME: not working

        bool isDuplicate = false;
        for (uint256 c = 0; c < multiCalls.length; c++) {
            if (multiCalls[c] == msg.sender) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "Caller has already called this function.");

        multiCalls.push(msg.sender);
        if (multiCalls.length >= M) {
            flightSuretyData.registerAirline(airlineAddress);
            multiCalls = new address[](0);
        }
        return (success, 0);
    }

    /**
        * @dev This is used to check if the Airline is registered in Test
     */ 
    function isRegisteredAirline(address airlineAddress) external returns (bool) {
        return flightSuretyData.isRegisteredAirline(airlineAddress);
    }    

    /**
     * @dev Register a future flight for insuring.
     *
     */

    function registerFlight(address airlineAddress, uint256 timestamp) external {
        bytes32 flightKey = keccak256(abi.encodePacked(airlineAddress, timestamp));
        flights[flightKey] = Flight({
            isRegistered: true,
            statusCode: STATUS_CODE_UNKNOWN,
            updatedTimestamp: timestamp,
            airline: airlineAddress
        });
    }

    /**
     * @dev Called after oracle has updated flight status
     *
     */

    function processFlightStatus(
        address airline,
        string memory flight,
        uint256 timestamp,
        uint8 statusCode,
        bool verified
    ) internal {
        // FIXME: I'm not sure what I have to do with this Function.
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(
        address airline,
        string flight,
        uint256 timestamp
    ) external {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key =
            keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
            requester: msg.sender,
            isOpen: true
        });

        emit OracleRequest(index, airline, flight, timestamp);
    }

    function purchaseFlightInsurance(
        address passengersAddress,
        address airlineAddress,
        uint256 purchasedAmount
    ) external {
        flightSuretyData.purchaseFlightInsurance(
            passengersAddress,
            airlineAddress,
            purchasedAmount
        );
    }

    // transfer eth to passenger's address
    function refundEth(
        address airlineAddress,
        address flightAddress,
        uint256 timestamp,
        address passengersAddress
    ) external {
        // FIXME:
        flightSuretyData.payoutFundsToInsuree(
            passengersAddress
        );
    }

    // region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
        // uint8 statusCode;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester; // Account that requested status
        bool isOpen; // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses; // Mapping key is the status code reported
        // This lets us group responses and identify
        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status,
        bool verified
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

    // Register an oracle with the contract
    function registerOracle() external payable {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

    function getMyIndexes() external view returns (uint8[3]) {
        require(
            oracles[msg.sender].isRegistered,
            "Not registered as an oracle"
        );

        return oracles[msg.sender].indexes;
    }

    /*
    function getOracle(address account)
        external
        view
        requireContractOwner
        returns (uint8[3])
    {
        return oracles[account];
    }
    */

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp,
        uint8 statusCode
    ) external {
        require(
            (oracles[msg.sender].indexes[0] == index) ||
                (oracles[msg.sender].indexes[1] == index) ||
                (oracles[msg.sender].indexes[2] == index),
            "Index does not match oracle request"
        );

        bytes32 key =
            keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(
            oracleResponses[key].isOpen,
            "Flight or timestamp do not match oracle request"
        );

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        // emit OracleReport(airline, flight, timestamp, statusCode);
        if (
            oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES
        ) {
            emit FlightStatusInfo(airline, flight, timestamp, statusCode, true);

            // Handle flight status as appropriate
            bytes32 flightKey = keccak256(abi.encodePacked(flight, timestamp));
            flights[flightKey] = Flight(true, statusCode, timestamp, airline);
        } else {
            // oracle submitting response but MIN_RESPONSES threshold not reached
            emit FlightStatusInfo(
                airline,
                flight,
                timestamp,
                statusCode,
                false
            );
        }
    }

    function getFlightKey(
        address airline,
        string flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns (uint8[3]) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random =
            uint8(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            blockhash(block.number - nonce++),
                            account
                        )
                    )
                ) % maxValue
            );

        if (nonce > 250) {
            nonce = 0; // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    function setOperatingStatus(bool mode) external requireContractOwner {
        // setOperatingStatus does not have to implement multiparty
        // The function setOperatingStatus is already implemented in the boilerplate and there it no need to do anything else
        operational = mode;
    }
    // endregion
}

contract FlightSuretyData {
    function registerAirline(address airlineAddress) external;

    // buy()
    function purchaseFlightInsurance(
        address passengersAddress,
        address airlineAddress,
        uint256 purchasedAmount
    ) external;

    // ???
    // function creditInsurees() external;

    // pay()
    function payoutFundsToInsuree(
        address passengersAddress
    ) external;

    // fund()
    function initialFunding() external;

    function isRegisteredAirline(address airlineAddress) external returns (bool);
}
