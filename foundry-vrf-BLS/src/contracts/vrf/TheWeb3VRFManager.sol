// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../interfaces/ITheWeb3VRFManager.sol";
import "../../interfaces/IBLSApkRegistry.sol";

contract TheWeb3VRFManager is Initializable, OwnableUpgradeable, ITheWeb3VRFManager {
    struct RequestStatus {
        bool fulfilled;
        uint256[] randomWords;
    }

    uint256[] public requestIds;
    uint256 public lastRequestId;
    address public theWeb3Address;

    IBLSApkRegistry public blsRegistry;

    mapping(uint256 => RequestStatus) public requestMapping;

    uint256[100] private slot;

    modifier onlyTheWebThree() {
        require(
            msg.sender == theWeb3Address,
            "TheWeb3VRFManager.onlyTheWebThree: only theweb3 address can call this function"
        );
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, address _theWeb3Address, address _blsRegistry) public initializer {
        __Ownable_init(initialOwner);
        theWeb3Address = _theWeb3Address;
        blsRegistry = IBLSApkRegistry(_blsRegistry);
    }

    function requestRandomWords(uint256 requestId, uint256 numWords) external {
        requestMapping[requestId] = RequestStatus({fulfilled: false, randomWords: new uint256[](0)});
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords, address(this));
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords,
        bytes32 msgHash,
        uint256 referenceBlockNumber,
        IBLSApkRegistry.VrfNoSignerAndSignature memory params
    ) external onlyTheWebThree {
        blsRegistry.checkSignatures(msgHash, referenceBlockNumber, params);

        requestMapping[requestId] = RequestStatus({fulfilled: true, randomWords: randomWords});

        emit FillRandomWords(requestId, randomWords);
    }

    function getRequestStatus(uint256 requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        RequestStatus memory status = requestMapping[requestId];
        return (status.fulfilled, status.randomWords);
    }

    function setTheWeb3Address(address _theWeb3Address) external onlyOwner {
        theWeb3Address = _theWeb3Address;
    }
}
