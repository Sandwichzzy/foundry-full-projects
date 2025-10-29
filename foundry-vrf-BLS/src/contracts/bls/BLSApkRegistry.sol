// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

import {IBLSApkRegistry} from "../../interfaces/IBLSApkRegistry.sol";
import {BN254} from "../../libraries/BN254.sol";

/// @custom:oz-upgrades-from EmptyContract
contract BLSApkRegistry is Initializable, IBLSApkRegistry, OwnableUpgradeable, EIP712Upgradeable, UUPSUpgradeable {
    //零公钥的哈希，用于防止注册零公钥
    bytes32 internal constant ZERO_PK_HASH = hex"ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5";
    // 用于EIP712签名的类型哈希
    bytes32 public constant PUBKEY_REGISTRATION_TYPEHASH = keccak256("BN254PubkeyRegistration(address operator)");
    uint256 internal constant PAIRING_EQUALITY_CHECK_GAS = 120000; //配对检查的gas限制

    address public whitelistManager; //白名单管理器地址，可以管理注册白名单
    address public vrfManagerAddress; //VRF管理器地址，可以注册和注销操作员。

    mapping(address => bytes32) public operatorToPubkeyHash; //操作员地址到其公钥哈希的映射。
    mapping(bytes32 => address) public pubkeyHashToOperator; //公钥哈希到操作员地址的映射。
    mapping(address => BN254.G1Point) public operatorToPubkey; //操作员地址到其公钥（G1点）的映射。

    BN254.G1Point public currentApk; //当前的聚合公钥（G1点）
    ApkUpdate[] public apkHistory; //聚合公钥的更新历史。

    mapping(address => bool) public blsRegisterWhitelist; //可以注册BLS公钥的白名单地址

    using BN254 for BN254.G1Point;

    modifier onlyWhitelistManagerManager() {
        require(
            msg.sender == whitelistManager,
            "BLSApkRegistry.onlyRelayerManager: caller is not the relayer manager address"
        );
        _;
    }

    modifier onlyVrfManager() {
        require(
            msg.sender == vrfManagerAddress,
            "BLSApkRegistry.onlyRelayerManager: caller is not the relayer manager address"
        );
        _;
    }

    function initialize(address _initialOwner, address _whitelistManager, address _vrfManagerAddress)
        external
        initializer
    {
        __Ownable_init(_initialOwner);
        __UUPSUpgradeable_init();
        _disableInitializers(); // 禁用后续初始化
    }

    function initializeV2(address _whitelistManager, address _vrfManagerAddress) external reinitializer(2) {
        // __Ownable_init(_initialOwner);
        __EIP712_init("BLSApkRegistry", "v0.0.1");
        // __UUPSUpgradeable_init();
        whitelistManager = _whitelistManager;
        vrfManagerAddress = _vrfManagerAddress;
        _initializeApk();
    }

    /**
     * @dev Registers an operator within the system.
     *
     * 此函数允许最终性中继管理器向系统中添加一个操作员。
     * 系统将检索该操作员的公钥，并用于更新相关的聚合公钥（APK）。
     *
     * @param operator The address of the operator to be registered.
     */
    function registerOperator(address operator) public onlyVrfManager {
        (BN254.G1Point memory pubkey,) = getRegisteredPubkey(operator);

        _processApkUpdate(pubkey);

        emit OperatorAdded(operator, operatorToPubkeyHash[operator]);
    }

    //由VRF管理器调用，注销操作员。它会将操作员的公钥从聚合公钥中减去。
    function deregisterOperator(address operator) public onlyVrfManager {
        (BN254.G1Point memory pubkey,) = getRegisteredPubkey(operator);

        _processApkUpdate(pubkey.negate());
        emit OperatorRemoved(operator, operatorToPubkeyHash[operator]);
    }

    //由白名单地址调用，注册BLS公钥。它验证注册签名，确保公钥非零且未被注册，然后存储公钥。
    function registerBLSPublicKey(
        address operator,
        PubkeyRegistrationParams calldata params,
        BN254.G1Point calldata pubkeyRegistrationMessageHash
    ) external returns (bytes32) {
        // 1. 检查调用者是否在白名单中。
        require(
            blsRegisterWhitelist[msg.sender],
            "BLSApkRegistry.registerBLSPublicKey: this address have not permission to register bls key"
        );
        // 2. 计算公钥哈希，并检查公钥非零且未被注册。
        bytes32 pubkeyHash = BN254.hashG1Point(params.pubkeyG1);
        require(pubkeyHash != ZERO_PK_HASH, "BLSApkRegistry.registerBLSPublicKey: cannot register zero pubkey");
        require(
            operatorToPubkeyHash[operator] == bytes32(0),
            "BLSApkRegistry.registerBLSPublicKey: operator already registered pubkey"
        );

        // 3. 生成随机挑战值gamma（防止rogue key攻击）
        uint256 gamma = uint256(
            keccak256(
                abi.encodePacked(
                    params.pubkeyRegistrationSignature.X,
                    params.pubkeyRegistrationSignature.Y,
                    params.pubkeyG1.X,
                    params.pubkeyG1.Y,
                    params.pubkeyG2.X,
                    params.pubkeyG2.Y,
                    pubkeyRegistrationMessageHash.X,
                    pubkeyRegistrationMessageHash.Y
                )
            )
        ) % BN254.FR_MODULUS;

        // 4. 验证注册签名：通过配对操作验证提供的G1签名和G2公钥是否匹配，同时验证G1和G2公钥对应同一个私钥。
        // 具体验证： pairing(sigma + pubkeyG1 * gamma, -G2) == pairing(messageHash + G1 * gamma, pubkeyG2)
        //e(σ + γ·pk₁, -g₂) · e(H(m) + γ·g₁, pk₂) = 1
        //e(σ, -g₂) · e(H(m), pk₂) = 1 和 e(pk₁, -g₂) · e(g₁, pk₂) = 1
        // 这里使用了一个随机数gamma来将两个配对等式合并为一个，以提高效率。
        require(
            BN254.pairing(
                params.pubkeyRegistrationSignature.plus(params.pubkeyG1.scalar_mul(gamma)),
                BN254.negGeneratorG2(),
                pubkeyRegistrationMessageHash.plus(BN254.generatorG1().scalar_mul(gamma)),
                params.pubkeyG2
            ),
            "BLSApkRegistry.registerBLSPublicKey: either the G1 signature is wrong, or G1 and G2 private key do not match"
        );

        operatorToPubkey[operator] = params.pubkeyG1;
        operatorToPubkeyHash[operator] = pubkeyHash;
        pubkeyHashToOperator[pubkeyHash] = operator;

        emit NewPubkeyRegistration(operator, params.pubkeyG1, params.pubkeyG2);

        return pubkeyHash;
    }

    //检查签名（checkSignatures)
    function checkSignatures(bytes32 msgHash, uint256 referenceBlockNumber, VrfNoSignerAndSignature memory params)
        public
        view
        returns (StakeTotals memory, bytes32)
    {
        //检查参考区块号是否有效。
        require(
            referenceBlockNumber < uint32(block.number), "BLSSignatureChecker.checkSignatures: invalid reference block"
        );
        // 1. 计算签名者的聚合公钥
        BN254.G1Point memory signerApk = BN254.G1Point(0, 0);
        bytes32[] memory nonSignersPubkeyHashes;
        if (params.nonSignerPubKeys.length > 0) {
            nonSignersPubkeyHashes = new bytes32[](params.nonSignerPubKeys.length);
            for (uint256 j = 0; j < params.nonSignerPubKeys.length; j++) {
                nonSignersPubkeyHashes[j] = params.nonSignerPubKeys[j].hashG1Point();
                signerApk = currentApk.plus(params.nonSignerPubKeys[j].negate());
            }
        } else {
            signerApk = currentApk;
        }

        // 2. 验证签名
        (bool pairingSuccessful, bool signatureIsValid) =
            trySignatureAndApkVerification(msgHash, signerApk, params.apkG2, params.sigma);

        require(pairingSuccessful, "BLSSignatureChecker.checkSignatures: pairing precompile call failed");
        require(signatureIsValid, "BLSSignatureChecker.checkSignatures: signature is invalid");
        // 3. 生成签名记录哈希
        bytes32 signatoryRecordHash = keccak256(abi.encodePacked(referenceBlockNumber, nonSignersPubkeyHashes));

        StakeTotals memory stakeTotals =
            StakeTotals({totalTwStake: params.totalTwStake, totalBtcStake: params.totalBtcStake});

        return (stakeTotals, signatoryRecordHash);
    }

    function addOrRemoveBlsRegisterWhitelist(address register, bool isAdd) external onlyWhitelistManagerManager {
        require(register != address(0), "BLSApkRegistry.addOrRemoverBlsRegisterWhitelist: operator address is zero");
        blsRegisterWhitelist[register] = isAdd;
    }

    function trySignatureAndApkVerification(
        bytes32 msgHash,
        BN254.G1Point memory apk,
        BN254.G2Point memory apkG2,
        BN254.G1Point memory sigma
    ) public view returns (bool pairingSuccessful, bool siganatureIsValid) {
        uint256 gamma = uint256(
            keccak256(
                abi.encodePacked(
                    msgHash, apk.X, apk.Y, apkG2.X[0], apkG2.X[1], apkG2.Y[0], apkG2.Y[1], sigma.X, sigma.Y
                )
            )
        ) % BN254.FR_MODULUS;
        (pairingSuccessful, siganatureIsValid) = BN254.safePairing(
            sigma.plus(apk.scalar_mul(gamma)),
            BN254.negGeneratorG2(),
            BN254.hashToG1(msgHash).plus(BN254.generatorG1().scalar_mul(gamma)),
            apkG2,
            PAIRING_EQUALITY_CHECK_GAS
        );
    }

    // 更新聚合公钥（_processApkUpdate）
    function _processApkUpdate(BN254.G1Point memory point) internal {
        BN254.G1Point memory newApk;
        uint256 historyLength = apkHistory.length;
        require(historyLength != 0, "BLSApkRegistry._processApkUpdate: quorum does not exist");
        // 获取当前聚合公钥，加上或减去一个点（注册时加，注销时减）。
        newApk = currentApk.plus(point);
        //更新当前聚合公钥。
        currentApk = newApk;
        bytes24 newApkHash = bytes24(BN254.hashG1Point(newApk));

        //更新历史记录：如果当前区块已经有更新，则更新当前区块的APK哈希，否则新增一个历史记录。
        ApkUpdate storage lastUpdate = apkHistory[historyLength - 1];
        if (lastUpdate.updateBlockNumber == uint32(block.number)) {
            lastUpdate.apkHash = newApkHash;
        } else {
            lastUpdate.nextUpdateBlockNumber = uint32(block.number);
            apkHistory.push(
                ApkUpdate({apkHash: newApkHash, updateBlockNumber: uint32(block.number), nextUpdateBlockNumber: 0})
            );
        }
    }

    function _initializeApk() internal {
        require(apkHistory.length == 0, "BLSApkRegistry.initializeApk: apk already exists");
        apkHistory.push(
            ApkUpdate({apkHash: bytes24(0), updateBlockNumber: uint32(block.number), nextUpdateBlockNumber: 0})
        );
    }

    function getRegisteredPubkey(address operator) public view returns (BN254.G1Point memory, bytes32) {
        BN254.G1Point memory pubkey = operatorToPubkey[operator];
        bytes32 pubkeyHash = operatorToPubkeyHash[operator];
        require(pubkeyHash != bytes32(0), "BLSApkRegistry.getRegisteredPubkey: operator is not registered");
        return (pubkey, pubkeyHash);
    }

    function getPubkeyRegMessageHash(address operator) public view returns (BN254.G1Point memory) {
        return BN254.hashToG1(_hashTypedDataV4(keccak256(abi.encode(PUBKEY_REGISTRATION_TYPEHASH, operator))));
    }

    function getPubkeyHash(address operator) public view returns (bytes32) {
        return operatorToPubkeyHash[operator];
    }

    // UUPS升级授权函数，只有owner可以升级
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
