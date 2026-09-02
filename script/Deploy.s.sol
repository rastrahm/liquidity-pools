// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";

import {MockERC20} from "../src/mocks/MockERC20.sol";

/**
 * @title Deploy
 * @notice Deploy local de tokens demo para desarrollo (fase 0).
 * @dev Fase 6 añadirá LiquidityPoolFactory + pools. Ejecutar:
 *      `forge script script/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast`
 */
contract Deploy is Script {
    uint256 internal constant MINT_AMOUNT = 1_000_000 ether;

    /**
     * @notice Despliega MockERC20 de prueba y acuña al deployer.
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

        vm.stopBroadcast();

        console2.log("Underlying", address(underlying));
        console2.log("Deployer", deployer);
    }
}
