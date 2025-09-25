// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 引入 Chainlink 预言机接口（用于 ETH/USD 价格转换）
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title FundMe - 众筹合约（支持锁定期、目标金额和退款机制）
 * @dev 功能：
 *      1. 投资者可在锁定期内存入 ETH（最低 100 USD）
 *      2. 若达到目标金额（1000 USD），所有者可在锁定期后提款
 *      3. 若未达到目标，投资者可在锁定期后退款
 *      4. 支持 ERC20 代币扩展（预留接口）

    * ------------------------------------------------
    * 1. 创建一个收款函数
    * 2. 记录投资人并且查看
    * 3. 在锁定期内，达到目标值，生产商可以提款
    * 4. 在锁定期内，没有达到目标值，投资人在锁定期以后退款
 */
contract FundMe {
    // --- 状态变量 ---
    mapping(address => uint256) public fundersToAmount;  // 投资者地址 → 存款金额（wei）
    uint256 constant public MINIMUM_VALUE = 100 * 10 ** 18;  // 最小存款金额：100 USD（18 位精度）
    AggregatorV3Interface internal dataFeed;  // Chainlink ETH/USD 预言机实例
    uint256 constant public TARGET = 1000 * 10 ** 18;  // 众筹目标：1000 USD
    address public owner;  // 合约所有者（生产商）
    uint256 public deploymentTimestamp;  // 合约部署时间戳
    uint256 public lockTime;   // 锁定期时长（秒）
    address public erc20Addr;  // 预留：ERC20 代币地址（扩展用）
    bool public getFundSuccess = false;  // 标志：是否已成功提款

    // --- 修饰器 ---
    modifier windowClosed() {
        require(block.timestamp >= deploymentTimestamp + lockTime, "window is not closed");  // 检查是否超过锁定期
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "this function can only be called by owner");  // 检查调用者是否为所有者
        _;
    }

    /**
     * @dev 构造函数：初始化预言机、所有者和锁定期
     * @param _lockTime 锁定期时长（秒）
     */
    constructor(uint256 _lockTime) {
        // Sepolia 测试网 ETH/USD 预言机地址
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        owner = msg.sender;  // 部署者为所有者
        deploymentTimestamp = block.timestamp;  // 记录部署时间
        lockTime = _lockTime;  // 设置锁定期
    }

    /**
     * @dev 投资者存入 ETH
     * @notice 调用时需附带 ETH（msg.value），且金额 ≥ 100 USD
     */
    function fund() external payable {
        // 1. 检查存款金额是否 ≥ 100 USD
        require(convertEthToUsd(msg.value) >= MINIMUM_VALUE, "Send more ETH");
        // 2. 检查是否在锁定期内
        require(block.timestamp < deploymentTimestamp + lockTime, "window is closed");
        // 3. 记录投资者存款金额
        fundersToAmount[msg.sender] += msg.value;  // 注意：应使用 += 避免覆盖之前存款
    }

    /**
     * @dev 获取 Chainlink 最新 ETH/USD 价格（原始数据）
     * @return 价格（int，8 位精度，如 2000000000 = 2000.00 USD/ETH）
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        (/* uint80 roundID */, int answer, /* uint startedAt */, /* uint timeStamp */, /* uint80 answeredInRound */) =
            dataFeed.latestRoundData();
        return answer;
    }

    /**
     * @dev 将 ETH 金额转换为 USD（内部函数）
     * @param ethAmount ETH 金额（wei）
     * @return USD 金额（18 位精度）
     */
    function convertEthToUsd(uint256 ethAmount) internal view returns(uint256) {
        uint256 ethPrice = uint256(getChainlinkDataFeedLatestAnswer());  // 获取 ETH/USD 价格
        return ethAmount * ethPrice / (10 ** 8);  // 转换为 USD（调整精度）
    }

    /**
     * @dev 所有者转让合约所有权
     * @param newOwner 新所有者地址
     */
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    /**
     * @dev 所有者提取资金（仅在锁定期后且达到目标金额时可用）
     * @notice 使用 call 进行 ETH 转账（支持智能合约接收）
     */
    function getFund() external windowClosed onlyOwner {
        // 1. 检查是否达到目标金额（1000 USD）
        require(convertEthToUsd(address(this).balance) >= TARGET, "Target is not reached");
        // 2. 转账 ETH 给所有者（使用 call 避免 Gas 限制）
        bool success;
        (success, ) = payable(owner).call{value: address(this).balance}("");
        require(success, "transfer tx failed");
        // 3. 重置状态
        fundersToAmount[owner] = 0;  // 注意：此处应重置所有投资者的记录，而非仅所有者
        getFundSuccess = true;  // 标记提款成功
    }

    /**
     * @dev 投资者退款（仅在锁定期后且未达到目标金额时可用）
     */
    function refund() external windowClosed {
        // 1. 检查是否未达到目标金额
        require(convertEthToUsd(address(this).balance) < TARGET, "Target is reached");
        // 2. 检查投资者是否有存款记录
        require(fundersToAmount[msg.sender] != 0, "there is no fund for you");
        // 3. 退还 ETH
        bool success;
        (success, ) = payable(msg.sender).call{value: fundersToAmount[msg.sender]}("");
        require(success, "transfer tx failed");
        // 4. 清除存款记录
        fundersToAmount[msg.sender] = 0;
    }

    /**
     * @dev 设置投资者存款金额（预留接口，仅 ERC20 代币地址可调用）
     * @param funder 投资者地址
     * @param amountToUpdate 更新后的存款金额（wei）
     */
    function setFunderToAmount(address funder, uint256 amountToUpdate) external {
        require(msg.sender == erc20Addr, "you do not have permission to call this function");
        fundersToAmount[funder] = amountToUpdate;
    }

    /**
     * @dev 所有者设置 ERC20 代币地址（扩展用）
     * @param _erc20Addr ERC20 代币地址
     */
    function setErc20Addr(address _erc20Addr) public onlyOwner {
        erc20Addr = _erc20Addr;
    }
}