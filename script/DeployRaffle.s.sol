//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "lib/forge-std/src/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

        if (networkConfig.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (networkConfig.subscriptionId, networkConfig.vrfCoordinator) =
                createSubscription.createSubscription(networkConfig.vrfCoordinator);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                networkConfig.vrfCoordinator, networkConfig.subscriptionId, networkConfig.link
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            networkConfig.entranceFee,
            networkConfig.interval,
            networkConfig.vrfCoordinator,
            networkConfig.gasLane,
            networkConfig.subscriptionId,
            networkConfig.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), networkConfig.vrfCoordinator, networkConfig.subscriptionId);

        return (raffle, helperConfig);
    }
}
