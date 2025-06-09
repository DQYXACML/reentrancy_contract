// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LockManager} from "./core/LockManager.sol";
import {ReentrancyGuard} from "./core/ReentrancyGuard.sol";

/**
 * @title Vault
 * @dev 继承 ReentrancyGuard，使用 `nonReentrant` 一行完成防护。
 */
contract Vault is ReentrancyGuard {
    // selector 常量 (withdraw(uint256))
    bytes4 private constant SELECTOR_WITHDRAW = bytes4(keccak256("withdraw(uint256)"));

    constructor(LockManager _manager) payable ReentrancyGuard(_manager) {
        // 示范：将 storage slot 0 登记到 withdraw()
        bytes32[] memory slots = new bytes32[](1);
        slots[0] = bytes32(uint256(0));
        _manager.registerSlots(address(this), SELECTOR_WITHDRAW, slots);
    }

    /*------------------------  业务函数  ------------------------*/
    function deposit() external payable {}

    function withdraw(uint256 amt) external nonReentrant(SELECTOR_WITHDRAW) {
        require(address(this).balance >= amt, "Balance too low");
        (bool ok,) = msg.sender.call{value: amt}("");
        require(ok, "ETH send failed");
    }

    receive() external payable {}
    fallback() external payable {}
}
