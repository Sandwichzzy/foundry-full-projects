// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IVrfManager} from "../interface/IVrfManager.sol";

contract VrfManager is IVrfManager, Initializable, OwnableUpgradeable {
    struct RequestStatus {
        bool fulfilled;
        uint256[] randomWords;
    }

    uint256[] public requestIds;
    uint256 public lastRequestId;
    address public dappLinkAddress;
    // IBLSApkRegistry public blsRegistry;
    mapping(uint256 => RequestStatus) public requestMapping;
    uint256[100] private slot;

    constructor() {
        _disableInitializers();
    }

    modifier only

    function initialize(address initialOwner, address _dappLinkAddress) public initializer {
        __Ownable_init(initialOwner); // 初始化OwnableUpgradeable
        dappLinkAddress = _dappLinkAddress;
    }
}
