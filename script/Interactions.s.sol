//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Raffle} from "../src/Raffle.sol";
import {Script, console} from "lib/forge-std/src/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mock/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId,) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console.log("Creating subscription on VRF Coordinator:", vrfCoordinator);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Subscription created with ID:", subId);
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using VRF Coordinator: ", vrfCoordinator);
        console.log("Using Link Token: ", linkToken);
        if (block.chainid == LOCAL_CHAINID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encodePacked(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentContract) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        addConsumer(address(this), vrfCoordinator, subId);
    }

    function addConsumer(address contractToAddVRF, address vrfCoordinator, uint256 subscriptionId) public {
        console.log("Adding consumer contract:", contractToAddVRF);
        console.log("To VRF Coordinator:", vrfCoordinator);
        console.log("To subscription ID:", subscriptionId);
        console.log("On chain ID:", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subscriptionId, contractToAddVRF);
        vm.stopBroadcast();
        console.log("Consumer added successfully.");
    }

    function run() external {
        address mostRecentContract = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentContract);
    }
}
