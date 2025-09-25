// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;  // 使用 Solidity 0.8.20 及以上版本（防止已知漏洞）

contract HelloWorld {
    // 状态变量：存储默认问候语
    string strVar = "Hello World";

    // 定义结构体：包含短语、ID 和地址
    struct Info {
        string phrase;   // 问候语文本
        uint256 id;      // 标识符
        address addr;    // 关联的地址（通常为调用者）
    }

    // 动态数组：存储所有 Info 结构体（目前未使用）
    Info[] infos;

    // 映射：通过 ID 查询 Info 结构体（key: ID → value: Info）
    mapping(uint256 id => Info info) public infoMapping;

    /**
     * @dev 根据 ID 返回问候语
     * @param _id 查询的 ID
     * @return 拼接后的问候语
     */
    function sayHello(uint256 _id) public view returns(string memory) {
        // 如果映射中无记录（addr 为零地址），返回默认问候语
        if(infoMapping[_id].addr == address(0x0)) {
            return addinfo(strVar);
        } else {
            // 否则返回自定义问候语
            return addinfo(infoMapping[_id].phrase);
        }
    }

    /**
     * @dev 设置新的问候语并存储到映射中
     * @param newString 新问候语文本
     * @param _id 关联的 ID
     */
    function setHelloWorld(string memory newString, uint256 _id) public {
        // 创建新的 Info 结构体并存储（msg.sender 为调用者地址）
        Info memory info = Info(newString, _id, msg.sender);
        infoMapping[_id] = info;
    }

    /**
     * @dev 内部函数：拼接问候语后缀
     * @param helloWorldStr 原始问候语
     * @return 拼接后的完整问候语
     */
    function addinfo(string memory helloWorldStr) internal pure returns(string memory) {
        return string.concat(helloWorldStr, " from Frank's contract.");
    }
}