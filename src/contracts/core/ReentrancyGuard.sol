// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LockManager} from "./LockManager.sol";

/**
 * @title ReentrancyGuard
 * @notice 继承式防重入合约。在业务函数上添加 `nonReentrant(selector)` 修饰器即可自动加/解锁。
 */
abstract contract ReentrancyGuard {
    /*-----------------------------------------------------*
     * 状态
     *-----------------------------------------------------*/
    LockManager public immutable manager;

    constructor(LockManager _manager) {
        manager = _manager;
    }

    /*-----------------------------------------------------*
     * 错误 / 事件
     *-----------------------------------------------------*/
    error ReentrancyDetected(bytes4 selector, bytes32 slotHash);
    error UnlockFault(bytes4 selector, bytes32 slotHash);

    /*-----------------------------------------------------*
     * 内部实现
     *-----------------------------------------------------*/
    function _detect(bytes4 selector) private {
        bytes32[] memory slots = manager.getSlots(address(this), selector);
        uint256 len = slots.length;
        for (uint256 i; i < len; ++i) {
            if (!manager.lock(address(this), slots[i])) {
                revert ReentrancyDetected(selector, slots[i]);
            }
        }
    }

    function _clear(bytes4 selector) private {
        bytes32[] memory slots = manager.getSlots(address(this), selector);
        uint256 len = slots.length;
        for (uint256 i; i < len; ++i) {
            if (!manager.unlock(address(this), slots[i])) {
                revert UnlockFault(selector, slots[i]);
            }
        }
    }

    /*-----------------------------------------------------*
     * 修饰器：自动加/解锁
     *-----------------------------------------------------*/
    modifier nonReentrant(bytes4 selector) {
        _detect(selector);
        _;
        _clear(selector);
    }
}
