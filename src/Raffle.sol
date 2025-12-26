// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title A sample Raffle Contract
 * @author Khushi Barnwal
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */
contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /* Errors */
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );
    error Raffle__TransferFailed();
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__RaffleNotOpen();

    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State variables */
    // Chainlink VRF Variables
    uint256 private immutable I_SUBSCRIPTION_ID;
    bytes32 private immutable I_GAS_LANE;
    uint32 private immutable I_CALLBACK_GAS_LIMIT;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    uint256 private immutable I_INTERVAL;
    uint256 private immutable I_ENTRANCE_FEE;
    uint256 private sLastTimeStamp;
    address private sRecentWinner;
    address payable[] private sPlayers;
    RaffleState private sRaffleState;

    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);

    /* Functions */
    constructor(
        uint256 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        I_GAS_LANE = gasLane;
        I_INTERVAL = interval;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_ENTRANCE_FEE = entranceFee;
        sRaffleState = RaffleState.OPEN;
        sLastTimeStamp = block.timestamp;
        I_CALLBACK_GAS_LIMIT = callbackGasLimit;
        // uint256 balance = address(this).balance;
        // if (balance > 0) {
        //     payable(msg.sender).transfer(balance);
        // }
    }

    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough value sent");
        // require(s_raffleState == RaffleState.OPEN, "Raffle is not open");
        if (msg.value < I_ENTRANCE_FEE) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (sRaffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        sPlayers.push(payable(msg.sender));
        // Emit an event when we update a dynamic array or mapping
        // Named events with the function name reversed
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = RaffleState.OPEN == sRaffleState;
        bool timePassed = ((block.timestamp - sLastTimeStamp) > I_INTERVAL);
        bool hasPlayers = sPlayers.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                sPlayers.length,
                uint256(sRaffleState)
            );
        }

        sRaffleState = RaffleState.CALCULATING;
        // Will revert if subscription is not set and funded.
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: I_GAS_LANE,
                subId: I_SUBSCRIPTION_ID,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: I_CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        // Quiz... is this redundant?
        emit RequestedRaffleWinner(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] calldata randomWords
    ) internal override {
        // s_players size 10
        // randomNumber 202
        // 202 % 10 ? what's doesn't divide evenly into 202?
        // 20 * 10 = 200
        // 2
        // 202 % 10 = 2
        uint256 indexOfWinner = randomWords[0] % sPlayers.length;
        address payable recentWinner = sPlayers[indexOfWinner];
        sRecentWinner = recentWinner;
        sPlayers = new address payable[](0);
        sRaffleState = RaffleState.OPEN;
        sLastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success, "Transfer failed");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Functions
     */
    function getRaffleState() public view returns (RaffleState) {
        return sRaffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return sRecentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return sPlayers[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return sLastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return I_INTERVAL;
    }

    function getEntranceFee() public view returns (uint256) {
        return I_ENTRANCE_FEE;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return sPlayers.length;
    }

    function getGasLane() public view returns (bytes32) {
        return I_GAS_LANE;
    }

    function getCallbackGasLimit() public view returns (uint32) {
        return I_CALLBACK_GAS_LIMIT;
    }

    function getSubscriptionId() public view returns (uint256) {
        return I_SUBSCRIPTION_ID;
    }

    function getVrfCoordinator() public view returns (address) {
        return address(s_vrfCoordinator);
    }
}
