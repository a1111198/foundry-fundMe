// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // The address of the Chainlink ETH/USD price feed
    NetworkConfiguration public activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int public constant INITIAL_ANSWER = 2000e8;

    struct NetworkConfiguration {
        address priceFeed;
    }

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getMainnetNetworkConfiguration();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaNetworkConfiguration();
        } else {
            activeNetworkConfig = getAnvilNetworkConfiguration();
        }
    }

    function getSepoliaNetworkConfiguration()
        public
        pure
        returns (NetworkConfiguration memory)
    {
        return
            NetworkConfiguration({
                priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            });
    }

    function getMainnetNetworkConfiguration()
        public
        pure
        returns (NetworkConfiguration memory)
    {
        return
            NetworkConfiguration({
                priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            });
    }

    function getAnvilNetworkConfiguration()
        internal
        returns (NetworkConfiguration memory)
    {
        if (address(activeNetworkConfig.priceFeed) != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(
            DECIMALS,
            INITIAL_ANSWER
        );
        vm.stopBroadcast();

        return NetworkConfiguration({priceFeed: address(mockV3Aggregator)});
    }
}
