// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title LockManager
 * @dev 使用 *单字节* 锁标志：slotHash -> 0/1。相比位图实现，逻辑更直观，
 *      但请注意：在 EVM 中 `uint8`、`uint64` 等都占用完整 32 byte 存储槽，
 *      因此此修改意在「语义上」表达两态标志，而非实际节省存储 gas。
 */
contract LockManager {
    struct SelectorInfo {
        bytes32[] slots;
    }

    /*-----------------------------------------------------------------* 
     | 数据结构                                                         |
     |-----------------------------------------------------------------|
     | _selectorMap  —— 函数 -> 写入 slot 列表                         |
     | _lockFlag     —— slotHash -> 1 (locked) / 0 (unlocked)           |
     *-----------------------------------------------------------------*/
    mapping(address => mapping(bytes4 => SelectorInfo)) private _selectorMap;
    mapping(address => mapping(bytes32 => uint8)) private _lockFlag;

    /*-----------------------------------------------------------------* 
     | 事件                                                            |
     *-----------------------------------------------------------------*/
    event Locked(address indexed target, bytes32 indexed slotHash);
    event Unlocked(address indexed target, bytes32 indexed slotHash);

    /*------------------------- 管理员接口 ----------------------------*/
    function registerSlots(address target, bytes4 selector, bytes32[] calldata slots) external {
        _selectorMap[target][selector].slots = slots;
    }

    /*------------------------- 查询接口 ------------------------------*/
    function getSlots(address target, bytes4 selector) external view returns (bytes32[] memory) {
        return _selectorMap[target][selector].slots;
    }

    /*------------------------- 锁操作 -------------------------------*/
    function lock(address target, bytes32 slotHash) external returns (bool) {
        if (_lockFlag[target][slotHash] == 1) return false; // 已锁
        _lockFlag[target][slotHash] = 1;
        emit Locked(target, slotHash);
        return true;
    }

    function unlock(address target, bytes32 slotHash) external returns (bool) {
        if (_lockFlag[target][slotHash] == 0) return false; // 未锁
        delete _lockFlag[target][slotHash]; // 置 0
        emit Unlocked(target, slotHash);
        return true;
    }
}
