// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../libraries/BN254.sol";

interface IBLSApkRegistry {
    //用于VRF验证
    struct VrfNoSignerAndSignature {
        BN254.G1Point[] nonSignerPubKeys; // 未签名者的公钥列表
        BN254.G2Point apkG2; // G2点的聚合公钥
        BN254.G1Point sigma; // BLS签名
        uint256 totalTwStake; // 总TW质押
        uint256 totalBtcStake; // 总BTC质押
    }

    //记录APK（聚合公钥）的更新历史
    struct ApkUpdate {
        bytes24 apkHash;
        uint32 updateBlockNumber;
        uint32 nextUpdateBlockNumber;
    }

    // 注册公钥时的参数
    struct PubkeyRegistrationParams {
        BN254.G1Point pubkeyRegistrationSignature; // 注册签名（G1点）
        BN254.G1Point pubkeyG1; // G1点的公钥
        BN254.G2Point pubkeyG2; // G2点的公钥
    }

    //记录总质押量
    struct StakeTotals {
        uint256 totalTwStake;
        uint256 totalBtcStake;
    }

    event NewPubkeyRegistration(address indexed operator, BN254.G1Point pubkeyG1, BN254.G2Point pubkeyG2);

    event OperatorAdded(address operator, bytes32 operatorId);

    event OperatorRemoved(address operator, bytes32 operatorId);

    function registerOperator(address operator) external;

    function deregisterOperator(address operator) external;

    function registerBLSPublicKey(
        address operator,
        PubkeyRegistrationParams calldata params,
        BN254.G1Point memory msgHash
    ) external returns (bytes32);

    function checkSignatures(bytes32 msgHash, uint256 referenceBlockNumber, VrfNoSignerAndSignature memory params)
        external
        view
        returns (StakeTotals memory, bytes32);

    function getRegisteredPubkey(address operator) external view returns (BN254.G1Point memory, bytes32);

    function addOrRemoveBlsRegisterWhitelist(address operator, bool isAdd) external;

    function getPubkeyRegMessageHash(address operator) external view returns (BN254.G1Point memory);
}
