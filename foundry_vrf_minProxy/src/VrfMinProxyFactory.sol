// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

//Clones 库实现 EIP-1167 标准
import "@openzeppelin/contracts/proxy/Clones.sol";

contract VrfMinProxyFactory {
    using Clones for address;

    address public implementation;
    address[] public proxies;

    event ProxyCreated(address proxyAddress, address implementationAddress);

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createProxy(bytes32 salt) external returns (address) {
        address proxy = implementation.cloneDeterministic(salt);
        proxies.push(proxy);
        emit ProxyCreated(proxy, implementation);
        return proxy;
    }

    function getProxies() external view returns (address[] memory) {
        return proxies;
    }

    function computeProxyAddress(bytes32 salt) external view returns (address) {
        return implementation.predictDeterministicAddress(salt, address(this));
    }
}
