# Security Vulnerability Report V3 - Legion Protocol

## Date: 2026-03-20
## Auditor: fujijin

---

## 🟠 MEDIUM: Vesting Controller 可以通过 emergencyTransferOwnership 夺取合约控制权

**Location**: `src/vesting/LegionLinearVesting.sol:98-103`

**Impact**:
- vestingController 可以调用 `emergencyTransferOwnership` 转移合约所有权
- 一旦所有权转移，攻击者可以提取 vesting 合约中的所有代币
- vestingController 通常是项目方地址，但如果被攻击，用户的 vesting 代币将被盗

**Code**:
```solidity
function emergencyTransferOwnership(address newOwner) external onlyVestingController {
    if (newOwner == address(0)) {
        revert OwnableInvalidOwner(address(0));
    }
    _transferOwnership(newOwner);
}
```

**Attack Scenario**:
1. vestingController 地址被攻击或内部人员作恶
2. 调用 `emergencyTransferOwnership(attacker_address)`
3. 攻击者获得合约所有权后，调用 `release()` 提取所有 vesting 代币

**Recommended Fix**:
- 删除此危险函数，或
- 添加时间锁机制 (Timelock)，让用户有时间退出
- 添加多签机制

---

## 🟡 LOW: Position Merge 时未完全删除 position 数据

**Location**: `src/sales/LegionAbstractSale.sol:609-622`

**Impact**:
- 当 receiver 已有 position 时，会 merge 两个 position，但旧 position 的某些数据可能未被清理
- 虽然 storage 被 delete，但可能存在数据残留

**Code**:
```solidity
if (positionIdTo != 0) {
    // Load the investor positions
    InvestorPosition memory positionToBurn = s_investorPositions[_positionId];
    InvestorPosition storage positionToUpdate = s_investorPositions[positionIdTo];
    
    // ... merge logic ...
    
    // Delete the burned position
    delete s_investorPositions[_positionId];
    
    // Burn the investor position from the `from` address
    _burnInvestorPosition(_from);
}
```

---

## 📋 Summary

| Vulnerability | Severity | Status |
|--------------|-----------|--------|
| Admin权限过度集中 (emergencyWithdraw) | HIGH | In PR #29 |
| 缺少Reentrancy保护 | MEDIUM | In PR #29 |
| Position授权转账无限制 | MEDIUM | In PR #29 |
| Vesting Controller 所有权转移风险 | MEDIUM | NEW |
| Position Merge 数据清理 | LOW | NEW |

---

## Recommendations

1. **HIGH**: 移除 `emergencyTransferOwnership` 函数或添加时间锁
2. **MEDIUM**: 添加 reentrancy guard 到所有写入函数
3. **MEDIUM**: 签名授权需要包含 from 地址确认和过期时间
