// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";

import {LiquidityPoolFactory} from "../src/LiquidityPoolFactory.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

/**
 * @title Deploy
 * @notice Deploy local: MockERC20 + LiquidityPoolFactory + pool inicial.
 * @dev `forge script script/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast`
 */
contract Deploy is Script {
    uint256 internal constant MINT_AMOUNT = 1_000_000 ether;
    uint256 internal constant LOCK_DURATION = 1 days;

    /**
     * @notice Despliega underlying demo, factory y un pool registrado.
     */
    function run() external {
        uint256 pk = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address deployer = vm.addr(pk);

        vm.startBroadcast(pk);

        MockERC20 underlying = new MockERC20("Pool Underlying", "UND");
        underlying.mint(deployer, MINT_AMOUNT);

        LiquidityPoolFactory factory = new LiquidityPoolFactory(LOCK_DURATION);
        address pool = factory.createPool(address(underlying));

        vm.stopBroadcast();

        console2.log("Underlying", address(underlying));
        console2.log("Factory", address(factory));
        console2.log("Pool", pool);
        console2.log("LockDuration", LOCK_DURATION);
        console2.log("Deployer", deployer);
    }
}
