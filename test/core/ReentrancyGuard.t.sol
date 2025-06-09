// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../src/contracts/core/LockManager.sol";
import "../../src/contracts/Vault.sol";

/*--------------------------------------------------------------*
 * 攻击合约：尝试在 fallback 中二次调用 withdraw 实现重入。
 *--------------------------------------------------------------*/
contract ReentrancyAttacker {
    Vault public immutable vault;
    bool private reentered;

    constructor(Vault _vault) {
        vault = _vault;
    }

    function attack() external payable {
        vault.withdraw(0.1 ether);
    }

    receive() external payable {
        if (!reentered) {
            reentered = true;
            vault.withdraw(0.1 ether); // 尝试二次重入
        }
    }

    fallback() external payable {
        if (!reentered) {
            reentered = true;
            vault.withdraw(0.1 ether); // 尝试二次重入
        }
    }
}

/*--------------------------------------------------------------*
 * 测试：验证正常提取成功、重入被阻挡。
 *--------------------------------------------------------------*/
contract ReentrancyGuardTest is Test {
    LockManager manager;
    Vault vault;
    ReentrancyAttacker attacker;

    function setUp() public {
        manager = new LockManager();
        vault = new Vault{value: 1 ether}(manager);
        attacker = new ReentrancyAttacker(vault);
        vm.deal(address(attacker), 1 ether);
    }

    function testWithdrawSucceeds() public {
        uint256 balBefore = address(this).balance;
        vault.withdraw(0.2 ether);
        assertEq(address(this).balance, balBefore + 0.2 ether);
    }

    function testReentrancyBlocked() public {
        vm.expectRevert();
        attacker.attack{value: 0.1 ether}();
    }

    receive() external payable {}
    fallback() external payable {}
}
