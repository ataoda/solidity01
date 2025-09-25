// SPDX许可证标识符，声明代码遵循MIT许可证
// 使用Solidity 0.8.20版本
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FundToken {
    // 1. 通证的名字
    string public tokenName; // 存储通证名称的变量
    // 2. 通证的简称
    string public tokenSymbol; // 存储通证符号（简称）的变量
    // 3. 通证的发行总量
    uint256 public totalSupply; // 发行的总通证数量
    // 4. 合约的拥有者地址
    address public owner; // 合约的部署者地址（所有者）
    // 5. 每个地址的通证余额
    mapping(address => uint256) public balances; // 地址到余额的映射关系

    // 构造函数，在部署合约时初始化
    constructor(string memory _tokenName, string memory _tokenSymbol) {
        tokenName = _tokenName; // 设置通证名称
        tokenSymbol = _tokenSymbol; // 设置通证简称
        owner = msg.sender; // 设置部署合约的地址为所有者
    }

    // 发行通证函数，任何人都可以调用
    function mint(uint256 amountToMint) public {
        balances[msg.sender] += amountToMint; // 增加调用者的余额
        totalSupply += amountToMint; // 增加总供应量
    }

    // 转账函数，将通证从调用者转到支付目标地址
    function transfer(address payee, uint256 amount) public {
        require(balances[msg.sender] >= amount, "You do not have enough balance to transfer"); // 检查余额是否足够
        balances[msg.sender] -= amount; // 扣除调用者余额
        balances[payee] += amount; // 增加收款人的余额
    } 

    // 查询某个地址的通证余额
    function balanceOf(address addr) public view returns(uint256) {
        return balances[addr]; // 返回对应地址的余额
    }
}