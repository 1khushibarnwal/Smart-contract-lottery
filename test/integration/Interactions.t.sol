// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CreateSubscription, AddConsumer, FundSubscription} from "../../script/Interactions.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
//import {LinkToken} from "../mocks/LinkToken.sol";

contract CreateSubscriptionTest is Test {
    CreateSubscription internal createSub;
    HelperConfig internal helperConfig;

    function setUp() external {
        createSub = new CreateSubscription();
        helperConfig = new HelperConfig();
    }

    function testCreateSubscriptionUsingConfig() external {
        (uint256 subId, address vrfCoordinator) = createSub.createSubscriptionUsingConfig();

        assertGt(subId, 0);
        assertTrue(vrfCoordinator != address(0));
    }

    function testCreateSubscriptionDirectCall() external {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        (uint256 subId, address vrfCoordinator) = createSub.createSubscription(config.vrfCoordinatorV25, config.account);

        assertGt(subId, 0);
        assertEq(vrfCoordinator, config.vrfCoordinatorV25);
    }
}

contract AddConsumerTest is Test {
    CreateSubscription internal createSub;
    AddConsumer internal addConsumer;
    HelperConfig internal helperConfig;

    function setUp() external {
        createSub = new CreateSubscription();
        addConsumer = new AddConsumer();
        helperConfig = new HelperConfig();
    }

    function testAddConsumerToSubscription() external {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        (uint256 subId,) = createSub.createSubscription(config.vrfCoordinatorV25, config.account);

        address fakeConsumer = address(123);

        addConsumer.addConsumer(fakeConsumer, config.vrfCoordinatorV25, subId, config.account);
        // If no revert → consumer added successfully
        assertTrue(true);
    }
}

contract FundSubscriptionTest is Test {
    FundSubscription internal fundSub;
    HelperConfig internal helperConfig;

    function setUp() external {
        fundSub = new FundSubscription();
        helperConfig = new HelperConfig();
    }

    function testFundSubscriptionCreatesSubIfMissing() external {
        fundSub.fundSubscriptionUsingConfig();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        assertGt(config.subscriptionId, 0);
    }

    function testFundSubscriptionOnLocalChain() external {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            fundSub.fundSubscriptionUsingConfig();
            config = helperConfig.getConfig();
        }

        fundSub.fundSubscription(config.vrfCoordinatorV25, config.subscriptionId, config.link, config.account);

        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(config.vrfCoordinatorV25);

        (uint96 balance,,,,) = coordinator.getSubscription(config.subscriptionId);
        assertGt(balance, 0);
    }

    // function testFundSubscriptionOnNonLocalChain() external {
    //     vm.chainId(11155111); // Sepolia-like

    //     HelperConfig.NetworkConfig memory config = helperConfig
    //         .getConfigByChainId(block.chainid);

    //     fundSub.fundSubscription(
    //         config.vrfCoordinatorV2_5,
    //         config.subscriptionId,
    //         config.link,
    //         config.account
    //     );

    //     // If no revert → Link transfer path executed
    //     assertTrue(true);
    // }
}
