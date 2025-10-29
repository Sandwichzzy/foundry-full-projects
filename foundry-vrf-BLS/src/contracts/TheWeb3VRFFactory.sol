// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./vrf/TheWeb3VRFManager.sol";

contract TheWeb3VRFFactory {
    using Clones for address;

    address public implementation;
    address[] public proxies;

    event ProxyCreated(address proxyAddress, address implementation);

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function createVrfMinProxy(bytes32 salt, address theWeb3Address, address blsRegistry) external returns (address) {
        address minProxyAddress = implementation.cloneDeterministic(salt);
        proxies.push(minProxyAddress);
        TheWeb3VRFManager(minProxyAddress).initialize(msg.sender, theWeb3Address, blsRegistry);
        emit ProxyCreated(minProxyAddress, implementation);
        return minProxyAddress;
    }

    function getProxies() external view returns (address[] memory) {
        return proxies;
    }

    function computeProxyAddress(bytes32 salt) external view returns (address) {
        return implementation.predictDeterministicAddress(salt, address(this));
    }
}
