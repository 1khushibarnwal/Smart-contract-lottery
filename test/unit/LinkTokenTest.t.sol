// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {LinkToken, ERC677Receiver} from "../mocks/LinkToken.sol";

contract MockERC677Receiver is ERC677Receiver {
    address public lastSender;
    uint256 public lastValue;
    bytes public lastData;

    function onTokenTransfer(address _sender, uint256 _value, bytes calldata _data) external override {
        lastSender = _sender;
        lastValue = _value;
        lastData = _data;
    }
}

contract LinkTokenTest is Test {
    LinkToken internal link;
    MockERC677Receiver internal receiver;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public {
        link = new LinkToken();
        receiver = new MockERC677Receiver();
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function test_InitialSupplyMintedToDeployer() public view {
        assertEq(link.balanceOf(address(this)), link.INITIAL_SUPPLY());
    }

    function test_Metadata() public view {
        assertEq(link.name(), "LinkToken");
        assertEq(link.symbol(), "LINK");
        assertEq(link.decimals(), 18);
    }

    /*//////////////////////////////////////////////////////////////
                                MINT
    //////////////////////////////////////////////////////////////*/

    function test_MintIncreasesBalance() public {
        link.mint(alice, 100 ether);

        assertEq(link.balanceOf(alice), 100 ether);
    }

    function test_MintIncreasesTotalSupply() public {
        uint256 supplyBefore = link.totalSupply();

        link.mint(alice, 50 ether);

        assertEq(link.totalSupply(), supplyBefore + 50 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        transferAndCall (EOA)
    //////////////////////////////////////////////////////////////*/

    function test_TransferAndCall_ToEOA() public {
        link.transferAndCall(alice, 10 ether, "hello");

        assertEq(link.balanceOf(alice), 10 ether);
    }

    /*//////////////////////////////////////////////////////////////
                    transferAndCall (Contract)
    //////////////////////////////////////////////////////////////*/

    function test_TransferAndCall_ToContract_TransfersTokens() public {
        link.transferAndCall(address(receiver), 25 ether, "");

        assertEq(link.balanceOf(address(receiver)), 25 ether);
    }

    function test_TransferAndCall_CallsOnTokenTransfer() public {
        bytes memory data = abi.encode("foundry");

        link.transferAndCall(address(receiver), 1 ether, data);

        assertEq(receiver.lastSender(), address(this));
        assertEq(receiver.lastValue(), 1 ether);
        assertEq(receiver.lastData(), data);
    }

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    function test_TransferAndCall_EmitsCustomTransferEvent() public {
        bytes memory data = hex"deadbeef";

        vm.expectEmit(true, true, false, true);
        emit LinkToken.Transfer(address(this), alice, 5 ether, data);

        link.transferAndCall(alice, 5 ether, data);
    }
}
