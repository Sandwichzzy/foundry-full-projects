// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract RawVrfMinProxyFactory {
    address public implementation;
    address[] public proxies;

    event ProxyCreated(address proxyAddress, address implementation);

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createProxy(bytes32 salt) external returns (address proxy) {
        bytes memory creationCode = getMinimalProxyCreationCode(implementation);
        assembly {
            proxy := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        proxies.push(proxy);

        emit ProxyCreated(proxy, implementation);
    }

    // 生成最小代理的创建字节码
    function getMinimalProxyCreationCode(address _implementation) public pure returns (bytes memory) {
        return abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73", _implementation, hex"5af43d82803e903d91602b57fd5bf3"
        );
    }

    function getProxies() external view returns (address[] memory) {
        return proxies;
    }

    function computeProxyAddress(bytes32 salt) external view returns (address) {
        bytes memory creationCode = getMinimalProxyCreationCode(implementation);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(creationCode)));
        return address(uint160(uint256(hash)));
    }
}
