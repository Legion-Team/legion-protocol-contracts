# Security Vulnerability Report - Legion Protocol

## Date: 2026-03-19
## Auditor: 金仔五号

---

## 🔴 HIGH: Admin权限过度集中 - EmergencyWithdraw

**Location**: `src/sales/LegionAbstractSale.sol:474-479`

**Impact**: 
- 管理员可以提取任意代币到任意地址
- 无任何时间锁或多签限制
- 可能导致用户资金被盗

**Code**:
```solidity
function emergencyWithdraw(address receiver, address token, uint256 amount) external virtual onlyLegion {
    emit EmergencyWithdraw(receiver, token, amount);
    SafeTransferLib.safeTransfer(token, receiver, amount);
}
```

**Attack Scenario**:
1. `legionBouncer` 账户被攻击或内部人员作恶
2. 调用 `emergencyWithdraw(receiver, attacker, amount)`
3. 提取合约内所有代币到任意地址

**Recommended Fix**:
- 添加时间锁 (Timelock)
- 添加多签机制
- 限制可提取的代币类型和数量

---

## 🟠 MEDIUM: 缺少 Reentrancy 保护

**Location**: 整个 `LegionAbstractSale` 合约

**Impact**:
- 多个写入函数未使用 `nonReentrant` 修饰符
- 可能遭受重入攻击

**Affected Functions**:
- `refund()` (L.167)
- `invest()` 
- `claimTokenAllocation()`
- `withdrawRaisedCapital()`

**Recommended Fix**:
```solidity
import {ReentrancyGuard} from "@openzeppelin/...";
contract LegionAbstractSale is ... ReentrancyGuard {
    function refund() external nonReentrant whenNotPaused ...
}
```

---

## 🟠 MEDIUM: Position 授权转账无限制

**Location**: `src/sales/LegionAbstractSale.sol:537-558`

**Impact**:
- 授权签名可转让任意用户的 position
- 签名可被滥用转移他人资产

**Code**:
```solidity
function transferInvestorPositionWithAuthorization(
    address from,
    address to,
    uint256 positionId,
    bytes calldata transferSignature
) external virtual override whenNotPaused whenSaleNotCanceled 
    whenRefundPeriodIsOver whenSaleResultsNotPublished {
    _verifyTransferSignature(from, to, positionId, s_addressConfig.legionSigner, transferSignature);
    _verifyCanTransferInvestorPosition(positionId);
    _burnOrTransferInvestorPosition(from, to, positionId);
}
```

**Issue**: 
- 签名不包含 `from` 地址的授权确认
- 攻击者可以诱骗签名者授权转移其 position

**Recommended Fix**:
- 签名中包含 `from` 地址确认
- 添加 nonce 防止重放
- 签名设置过期时间

---

## 🟡 LOW: 合约暂停后无法恢复

**Location**: `pause()/unpause()`

**Impact**:
- `onlyLegion` 可永久暂停合约
- 无自动恢复机制

---

## 📋 Summary

| Vulnerability | Severity | Status |
|--------------|-----------|--------|
| Signature Replay (已报告) | HIGH | In PR #27 |
| Admin权限过度集中 | HIGH | NEW |
| 缺少Reentrancy保护 | MEDIUM | NEW |
| Position授权转账无限制 | MEDIUM | NEW |
| 合约暂停风险 | LOW | NEW |
