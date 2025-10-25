// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

contract OracleMock {
    uint256 private nonce;

    struct Request {
        address sender;
        bytes request;
        bytes response;
        bool fulfilled;
    }

    Request[] public requests;

    event RandomNumberRequested(address indexed requester, uint256 requestId);
    event RandomNumberFulfilled(uint256 requestId, uint256[3] numbers);

    function requestRandomNumbers() external returns (uint256 requestId) {
        // 创建请求
        Request memory newRequest =
            Request({sender: msg.sender, request: abi.encode("requestRandomNumbers"), response: "", fulfilled: false});

        requests.push(newRequest);
        requestId = requests.length - 1;

        emit RandomNumberRequested(msg.sender, requestId);

        fulfillRandomNumbers(requestId);

        return requestId;
    }

    function fulfillRandomNumbers(uint256 requestId) public {
        require(requestId < requests.length, "Invalid request ID");
        require(!requests[requestId].fulfilled, "Request already fulfilled");

        // 模拟生成三个随机数字(1-6)
        uint256[3] memory randomNumbers;
        for (uint8 i = 0; i < 3; i++) {
            randomNumbers[i] =
                (uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, nonce, i))) % 6) + 1;
        }
        nonce++;

        // 更新请求状态
        requests[requestId].response = abi.encode(randomNumbers);
        requests[requestId].fulfilled = true;

        emit RandomNumberFulfilled(requestId, randomNumbers);

        // 调用回调函数
        callback(requests[requestId]);
    }

    function callback(Request memory request) internal {
        // 被其他组件触发去进行对 `request` 的 callback
        // 被条件触发后(例如达到阈值, 时间到了), 这个函数会去 call subscriber 的目标函数
        address callbackTarget = request.sender;
        bytes4 selector = bytes4(keccak256("receiveCallback(bytes)"));
        bytes memory payload = abi.encodeWithSelector(selector, request.response);
        (bool success, bytes memory returnData) = callbackTarget.call(payload);
        if (!success) {
            // 如果调用失败，输出更详细的错误信息
            if (returnData.length > 0) {
                assembly {
                    let returndata_size := mload(returnData)
                    revert(add(32, returnData), returndata_size)
                }
            } else {
                revert("Callback failed: Unknown error");
            }
        }
    }

    function getRequest(uint256 requestId) external view returns (Request memory) {
        require(requestId < requests.length, "Invalid request ID");
        return requests[requestId];
    }
}
