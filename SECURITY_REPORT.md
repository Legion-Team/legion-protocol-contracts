# Legion Protocol 安全审计报告

**项目**: Legion Protocol
**审计日期**: 2026-03-17
**审计者**: 金仔五号
**代码库**: https://github.com/Legion-Team/legion-protocol-contracts

---

## 发现的漏洞

### 🔴 漏洞 #1: 签名重放攻击导致无限投资

**严重程度**: HIGH
**赏金估计**: $15,000 - $50,000

#### 位置
`src/sales/LegionAbstractSale.sol` 第 886-891 行

#### 受影响代码
```solidity
function _verifyInvestSignature(bytes calldata _signature) internal view virtual {
    bytes32 _data = keccak256(abi.encodePacked(msg.sender, address(this), block.chainid)).toEthSignedMessageHash();

    if (_data.recover(_signature) != s_addressConfig.legionSigner) {
        revert Errors.LegionSale__InvalidSignature(_signature);
    }
}
```

#### 问题描述
签名验证函数 `_verifyInvestSignature()` 存在严重设计缺陷：

1. **签名不包含投资金额** - 签名只验证了 `msg.sender`, `address(this)`, `block.chainid`，但没有包含 `amount` 参数
2. **没有 nonce** - 同一个签名可以被无限次重用
3. **没有过期时间** - 签名在整个销售期间内都有效

#### 攻击场景
1. Legion 团队为投资者签发一个投资授权签名
2. 投资者使用这个签名调用 `invest(1000 USDC, signature)` 投资 1000 USDC
3. 投资者再次使用相同的签名调用 `invest(10000 USDC, signature)` 投资 10000 USDC
4. 投资者可以无限次重复，直到资金耗尽或达到销售上限
5. 这导致投资者可以投资远超预期的金额

#### 影响
- 投资者可以绕过投资限额
- 破坏公平分配机制
- 可能导致销售提前结束
- 其他投资者的投资机会被剥夺

#### Proof of Concept
```solidity
// See test/exploit/SignatureReplayPOC.t.sol

function test_SignatureReplayAttack() public {
    // Generate a valid signature for the investor
    bytes32 data = keccak256(abi.encodePacked(investor, address(sale), block.chainid)).toEthSignedMessageHash();
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, data);
    bytes memory signature = abi.encodePacked(r, s, v);
    
    // First investment: 1000 USDC
    vm.prank(investor);
    sale.invest(1000 * 1e6, signature);
    
    // REPLAY ATTACK: Use the SAME signature again with different amount!
    vm.prank(investor);
    sale.invest(10000 * 1e6, signature);  // Succeeds with same signature!
    
    // Investor now has 11000 USDC invested instead of intended 1000
}
```

#### 修复建议
```solidity
function _verifyInvestSignature(uint256 _amount, bytes calldata _signature) internal view virtual {
    // Include amount and nonce in signature
    uint256 nonce = s_investorNonces[msg.sender]++;
    bytes32 _data = keccak256(abi.encodePacked(
        msg.sender, 
        address(this), 
        block.chainid,
        _amount,  // Include amount
        nonce     // Include nonce to prevent replay
    )).toEthSignedMessageHash();

    if (_data.recover(_signature) != s_addressConfig.legionSigner) {
        revert Errors.LegionSale__InvalidSignature(_signature);
    }
}
```

---

### 🟠 漏洞 #2: 签名没有过期时间

**严重程度**: MEDIUM

#### 问题描述
签名没有包含时间戳或过期时间，这意味着：
1. 获得签名的投资者可以在销售结束前的任何时间投资
2. 如果销售暂停后重启，旧签名仍然有效
3. 签名被盗后无法使其失效

#### 修复建议
```solidity
function _verifyInvestSignature(
    uint256 _amount, 
    uint256 _deadline,
    bytes calldata _signature
) internal view virtual {
    require(block.timestamp <= _deadline, "Signature expired");
    
    bytes32 _data = keccak256(abi.encodePacked(
        msg.sender, 
        address(this), 
        block.chainid,
        _amount,
        _deadline
    )).toEthSignedMessageHash();

    if (_data.recover(_signature) != s_addressConfig.legionSigner) {
        revert Errors.LegionSale__InvalidSignature(_signature);
    }
}
```

---

## 文件列表

- `test/exploit/SignatureReplayPOC.t.sol` - 签名重放攻击 PoC

---

## 下一步

1. 完成更多漏洞分析
2. 准备提交到 Immunefi / Code4rena

---

**最后更新**: 2026-03-17
