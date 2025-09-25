// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;  // 使用 Solidity 0.8.20 及以上版本（包含安全修复）

// 引入 HelloWorld 合约
import { HelloWorld } from "./HelloWorld.sol";

contract HelloWorldFactory {
    // 状态变量：存储最新创建的 HelloWorld 合约实例（单个）
    HelloWorld public hw;

    // 动态数组：存储所有创建的 HelloWorld 合约实例
    HelloWorld[] public hws;

    /**
     * @dev 创建新的 HelloWorld 合约实例并存储
     */
    function createHelloWorld() public {
        hw = new HelloWorld();  // 部署新实例
        hws.push(hw);           // 将新实例添加到数组
    }

    /**
     * @dev 根据索引返回 HelloWorld 合约实例
     * @param _index 数组索引
     * @return 对应的 HelloWorld 合约实例
     */
    function getHelloWorldByIndex(uint256 _index) public view returns (HelloWorld) {
        return hws[_index];  // 直接返回数组中的实例（无边界检查）
    }

    /**
     * @dev 代理调用指定 HelloWorld 实例的 sayHello 函数
     * @param _index HelloWorld 实例的索引
     * @param _id 查询的 ID
     * @return 拼接后的问候语
     */
    function callSayHelloFromFactory(uint256 _index, uint256 _id)
        public
        view
        returns (string memory)
    {
        return hws[_index].sayHello(_id);  // 代理调用
    }

    /**
     * @dev 代理调用指定 HelloWorld 实例的 setHelloWorld 函数
     * @param _index HelloWorld 实例的索引
     * @param newString 新的问候语文本
     * @param _id 关联的 ID
     */
    function callSetHelloWorldFromFactory(
        uint256 _index,
        string memory newString,
        uint256 _id
    ) public {
        hws[_index].setHelloWorld(newString, _id);  // 代理调用
    }
}