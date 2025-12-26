// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
//import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DeployRaffleTest is Test {
    DeployRaffle internal deployer;

    function setUp() external {
        deployer = new DeployRaffle();
    }

    /*//////////////////////////////////////////////////////////////
                            BASIC DEPLOY
    //////////////////////////////////////////////////////////////*/

    function test_RunDeploysRaffleAndConfig() external {
        (Raffle raffle, HelperConfig helperConfig) = deployer.run();

        assertTrue(address(raffle) != address(0));
        assertTrue(address(helperConfig) != address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        CONFIG INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function test_RunCreatesSubscriptionIfMissing() external {
        (, HelperConfig helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

        // Subscription must exist after run()
        assertGt(config.subscriptionId, 0);
        assertTrue(config.vrfCoordinatorV2_5 != address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        RAFFLE CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function test_RaffleConstructorParamsMatchConfig() external {
        (Raffle raffle, HelperConfig helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

        assertEq(raffle.getEntranceFee(), config.raffleEntranceFee);
        assertEq(raffle.getInterval(), config.automationUpdateInterval);
        assertEq(raffle.getGasLane(), config.gasLane);
        assertEq(raffle.getCallbackGasLimit(), config.callbackGasLimit);
        assertEq(raffle.getSubscriptionId(), config.subscriptionId);
        assertEq(address(raffle.getVrfCoordinator()), config.vrfCoordinatorV2_5);
    }

    /*//////////////////////////////////////////////////////////////
                        MULTIPLE RUNS SAFE
    //////////////////////////////////////////////////////////////*/

    function test_RunIsIdempotent() external {
        deployer.run();
        (Raffle raffle2,) = deployer.run();

        // Should still deploy a valid raffle
        assertTrue(address(raffle2) != address(0));
    }

    function test_HelperConfigIsUpdatedAfterRun() external {
        (, HelperConfig helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

        assertGt(config.subscriptionId, 0);
        assertTrue(config.vrfCoordinatorV2_5 != address(0));
        assertTrue(config.account != address(0));
    }

    function test_SubscriptionIsReusedOnSecondRun() external {
        (, HelperConfig helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config1 = helperConfig.getConfigByChainId(block.chainid);

        uint256 subscriptionIdBefore = config1.subscriptionId;

        deployer.run();

        HelperConfig.NetworkConfig memory config2 = helperConfig.getConfigByChainId(block.chainid);

        assertEq(config2.subscriptionId, subscriptionIdBefore);
    }

    function test_RaffleConstructorParamsAreNonZero() external {
        (Raffle raffle,) = deployer.run();

        assertTrue(address(raffle.getVrfCoordinator()) != address(0));
        assertTrue(raffle.getSubscriptionId() != 0);
        assertTrue(raffle.getCallbackGasLimit() > 0);
        assertTrue(raffle.getInterval() > 0);
        assertTrue(raffle.getEntranceFee() > 0);
    }

    function test_ConfigConstantsRemainUnchanged() external {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory beforeConfig = helperConfig.getConfigByChainId(block.chainid);

        deployer.run();

        HelperConfig.NetworkConfig memory afterConfig = helperConfig.getConfigByChainId(block.chainid);

        assertEq(afterConfig.gasLane, beforeConfig.gasLane);
        assertEq(afterConfig.raffleEntranceFee, beforeConfig.raffleEntranceFee);
        assertEq(afterConfig.callbackGasLimit, beforeConfig.callbackGasLimit);
        assertEq(afterConfig.automationUpdateInterval, beforeConfig.automationUpdateInterval);
    }

    function test_DoesNotCreateNewSubscriptionIfAlreadyExists() external {
        // First run creates the subscription
        deployer.run();

        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory configBefore = helperConfig.getConfigByChainId(block.chainid);

        uint256 subscriptionIdBefore = configBefore.subscriptionId;

        // Second run should NOT create a new one
        deployer.run();

        HelperConfig.NetworkConfig memory configAfter = helperConfig.getConfigByChainId(block.chainid);

        assertEq(configAfter.subscriptionId, subscriptionIdBefore);
    }

    function test_VRFCoordinatorIsContract() external {
        (, HelperConfig helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

        uint256 size;
        address coordinator = config.vrfCoordinatorV2_5;

        assembly {
            size := extcodesize(coordinator)
        }

        assertGt(size, 0);
    }

    function test_RaffleUsesSameSubscriptionAsHelperConfig() external {
        (Raffle raffle, HelperConfig helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

        assertEq(raffle.getSubscriptionId(), config.subscriptionId);
    }

    function test_RaffleEconomicParamsAreSane() external {
        (Raffle raffle,) = deployer.run();

        assertGt(raffle.getInterval(), 0);
        assertGt(raffle.getEntranceFee(), 0);
    }

    function test_ScriptOnlyUpdatesCurrentChainConfig() external {
        HelperConfig helperConfig = new HelperConfig();

        // Simulate another chain config existing
        uint256 fakeChainId = 999;
        HelperConfig.NetworkConfig memory fakeConfig = helperConfig.getConfigByChainId(block.chainid);

        helperConfig.setConfig(fakeChainId, fakeConfig);

        deployer.run();

        HelperConfig.NetworkConfig memory unchangedConfig = helperConfig.getConfigByChainId(fakeChainId);

        assertEq(unchangedConfig.subscriptionId, fakeConfig.subscriptionId);
    }

    function test_EachRunDeploysNewRaffleInstance() external {
        (Raffle raffle1,) = deployer.run();
        (Raffle raffle2,) = deployer.run();

        assertTrue(address(raffle1) != address(raffle2));
    }

    /*//////////////////////////////////////////////////////////////
                    BRANCH TESTS AND STATEMENTS
    //////////////////////////////////////////////////////////////*/
    function testRunCreatesSubscriptionWhenNoneExists() external {
        (Raffle raffle, HelperConfig helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // subscription should now exist
        assertGt(config.subscriptionId, 0);

        // raffle deployed
        assertTrue(address(raffle) != address(0));

        // raffle config matches helper config
        assertEq(raffle.getEntranceFee(), config.raffleEntranceFee);
        assertEq(raffle.getInterval(), config.automationUpdateInterval);
    }

    function testRunSkipsSubscriptionCreationWhenAlreadyExists() external {
        // First run → creates subscription
        (, HelperConfig helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory originalConfig = helperConfig.getConfig();

        // Second run → should reuse subscription
        (Raffle raffle,) = deployer.run();

        HelperConfig.NetworkConfig memory newConfig = helperConfig.getConfig();

        // subscription id should not change
        assertEq(newConfig.subscriptionId, originalConfig.subscriptionId);

        // raffle still deployed
        assertTrue(address(raffle) != address(0));
    }

    function testHelperConfigReturnedIsValid() external {
        (, HelperConfig helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        assertGt(config.callbackGasLimit, 0);
        assertGt(config.raffleEntranceFee, 0);
        assertGt(config.automationUpdateInterval, 0);
        assertTrue(config.vrfCoordinatorV2_5 != address(0));
    }

    function testRaffleUsesCorrectVRFCoordinator() external {
        (Raffle raffle, HelperConfig helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        assertEq(raffle.getVrfCoordinator(), config.vrfCoordinatorV2_5);
    }

    function testMultipleRunsDeployMultipleRaffles() external {
        (Raffle raffle1,) = deployer.run();
        (Raffle raffle2,) = deployer.run();

        assertTrue(address(raffle1) != address(raffle2));
    }

    function testRunDoesNotRevert() external {
        deployer.run();
    }
}
