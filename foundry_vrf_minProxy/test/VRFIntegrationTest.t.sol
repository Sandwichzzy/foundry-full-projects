// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {VrfManager} from "../src/vrf/VrfManager.sol";
import {VrfMinProxyFactory} from "../src/VrfMinProxyFactory.sol";
import {MockVrfOracle} from "../src/Mocks/MockVrfOracle.sol";

contract VRFIntegrationTest is Test {
    VrfMinProxyFactory public factory;
    VrfManager public implementation;
    MockVrfOracle public mockOracle;
    VrfManager public vrfManagerProxy;

    // Test accounts
    address public owner = address(0x1);
    address public oracleOperator = address(0x2);
    address public user = address(0x3);

    // Oracle keys for testing - 修复：使用正确的私钥
    uint256 public constant ORACLE_PRIVATE_KEY = 0x2222222222222222222222222222222222222222222222222222222222222222;
    address public oracleSigner;

    // Events to test
    event OracleRequestSent(uint256 indexed requestId, uint256 indexed oracleRequestId, uint256 numWords);
    event SignatureVerified(uint256 indexed requestId, address signer);
    event FillRandomWords(uint256 requestId, uint256[] randomWords);

    function setUp() public {
        oracleSigner = vm.addr(ORACLE_PRIVATE_KEY);

        vm.startPrank(owner);

        // Deploy MockVrfOracle with proper signer
        mockOracle = new MockVrfOracle(oracleSigner);
        mockOracle.setOracleOperator(oracleOperator);

        // Deploy VrfManager implementation
        implementation = new VrfManager();

        // Deploy VrfMinProxyFactory
        factory = new VrfMinProxyFactory(address(implementation));

        // Create proxy using create2
        bytes32 salt = keccak256("test_project");
        address proxyAddress = factory.createProxy(salt);

        // Initialize proxy with correct three parameters
        vrfManagerProxy = VrfManager(proxyAddress);
        vrfManagerProxy.initialize(owner, address(mockOracle), oracleSigner);

        vm.stopPrank();
    }

    function testFactoryDeployment() public view {
        // Test factory deployment
        assertEq(factory.implementation(), address(implementation), "Factory should have correct implementation");

        address[] memory proxies = factory.getProxies();
        assertEq(proxies.length, 1, "Should have one proxy created");
        assertEq(proxies[0], address(vrfManagerProxy), "Proxy address should match");
    }

    function testProxyInitialization() public view {
        // Test proxy initialization

        assertEq(vrfManagerProxy.vrfOracleAddress(), address(mockOracle), "Oracle address should be set");
        assertEq(vrfManagerProxy.oraclePublicKey(), oracleSigner, "Oracle public key should be set");
    }

    function testCompleteSignatureVerificationFlow() public {
        console.log("=== Testing Complete Signature Verification Flow ===");

        // Step 1: Request random words
        uint256 requestId = 1;
        uint256 numWords = 3;
        _requestRandomWords(requestId, numWords);

        // Step 2-4: Oracle work and signature verification
        uint256 oracleRequestId = 1;
        uint256 seed = 12345;
        bytes memory signature = _simulateOracleWork(requestId, oracleRequestId, seed, numWords);

        // Step 5-6: Fulfill request and verify results
        _fulfillAndVerifyRequest(requestId, oracleRequestId, seed, signature, numWords);

        console.log("=== Complete Flow Test PASSED ===\n");
    }

    function _requestRandomWords(uint256 requestId, uint256 numWords) internal {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, false);
        emit OracleRequestSent(requestId, 1, numWords);

        vrfManagerProxy.requestRandomWords(requestId, numWords);
        console.log("Step 1: Requested", numWords, "random words with ID:", requestId);

        // Verify request status using getRequestDetails
        (bool fulfilled, uint256[] memory randomWords,,,) = vrfManagerProxy.getRequestDetails(requestId);
        assertFalse(fulfilled, "Request should not be fulfilled yet");
        assertEq(randomWords.length, 0, "No random words should be available yet");

        vm.stopPrank();
    }

    function _simulateOracleWork(uint256 requestId, uint256 oracleRequestId, uint256 seed, uint256 numWords)
        internal
        view
        returns (bytes memory signature)
    {
        // Simulate Oracle offchain work
        (uint256[] memory generatedWords, uint256 timestamp,, bytes32 ethSignedMessageHash) =
            mockOracle.simulateOffchainWork(oracleRequestId, seed);

        console.log("Step 2: Oracle generated", generatedWords.length, "random words");
        assertEq(generatedWords.length, numWords, "Should generate correct number of words");

        // Create signature with Oracle private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_PRIVATE_KEY, ethSignedMessageHash);
        signature = abi.encodePacked(r, s, v);
        console.log("Step 3: Oracle created signature");

        // Verify signature before submission
        (bool isValid, address recoveredSigner) =
            vrfManagerProxy.verifySignature(requestId, generatedWords, timestamp, signature);

        assertTrue(isValid, "Signature should be valid");
        assertEq(recoveredSigner, oracleSigner, "Recovered signer should match Oracle signer");
        console.log("Step 4: Signature verification PASSED");
    }

    function _fulfillAndVerifyRequest(
        uint256 requestId,
        uint256 oracleRequestId,
        uint256 seed,
        bytes memory signature,
        uint256 expectedNumWords
    ) internal {
        // Get expected words before fulfillment
        (uint256[] memory expectedWords,,,) = mockOracle.simulateOffchainWork(oracleRequestId, seed);

        // Oracle submits signed random words
        vm.startPrank(oracleOperator);

        vm.expectEmit(true, false, false, false);
        emit SignatureVerified(requestId, oracleSigner);

        vm.expectEmit(true, false, false, false);
        emit FillRandomWords(requestId, expectedWords);

        mockOracle.fulfillRequestWithSignature(oracleRequestId, seed, signature);
        console.log("Step 5: Oracle successfully fulfilled request");

        vm.stopPrank();

        // Verify final state using getRequestDetails
        (bool finalFulfilled, uint256[] memory finalWords,,,) = vrfManagerProxy.getRequestDetails(requestId);
        assertTrue(finalFulfilled, "Request should be fulfilled");
        assertEq(finalWords.length, expectedNumWords, "Should have correct number of final words");

        for (uint256 i = 0; i < finalWords.length; i++) {
            assertEq(finalWords[i], expectedWords[i], "Final words should match generated words");
            assertTrue(finalWords[i] > 0, "Random words should be non-zero");
        }

        console.log("Step 6: Request successfully completed with", finalWords.length, "random words");
    }

    function testMultipleProxiesCreation() public {
        vm.startPrank(owner);

        // Create multiple proxies for different projects
        string[] memory projectNames = new string[](3);
        projectNames[0] = "project_alpha";
        projectNames[1] = "project_beta";
        projectNames[2] = "project_gamma";

        address[] memory proxyAddresses = new address[](3);

        for (uint256 i = 0; i < projectNames.length; i++) {
            bytes32 salt = keccak256(abi.encodePacked(projectNames[i]));
            proxyAddresses[i] = factory.createProxy(salt);

            VrfManager proxy = VrfManager(proxyAddresses[i]);
            proxy.initialize(owner, address(mockOracle), oracleSigner);

            console.log("Created proxy for", projectNames[i], "at:", proxyAddresses[i]);
        }

        // Verify all proxies are created
        address[] memory allProxies = factory.getProxies();
        assertEq(allProxies.length, 4, "Should have 4 total proxies (1 from setUp + 3 new)");

        // Test each proxy can compute deterministic addresses
        for (uint256 i = 0; i < projectNames.length; i++) {
            bytes32 salt = keccak256(abi.encodePacked(projectNames[i]));
            address computedAddress = factory.computeProxyAddress(salt);
            assertEq(computedAddress, proxyAddresses[i], "Computed address should match created address");
        }

        vm.stopPrank();

        console.log("Multiple proxies creation test PASSED");
    }
}
