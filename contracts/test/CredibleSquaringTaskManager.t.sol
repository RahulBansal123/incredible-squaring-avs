// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../src/IncredibleSquaringServiceManager.sol" as incsqsm;
import {IncredibleSquaringTaskManager} from "../src/IncredibleSquaringTaskManager.sol";
import {BLSMockAVSDeployer} from "@eigenlayer-middleware/test/utils/BLSMockAVSDeployer.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "forge-std/console.sol";

contract IncredibleSquaringTaskManagerTest is BLSMockAVSDeployer {
    incsqsm.IncredibleSquaringServiceManager sm;
    incsqsm.IncredibleSquaringServiceManager smImplementation;
    IncredibleSquaringTaskManager tm;
    IncredibleSquaringTaskManager tmImplementation;

    uint32 public constant TASK_RESPONSE_WINDOW_BLOCK = 30;
    address aggregator =
        address(uint160(uint256(keccak256(abi.encodePacked("aggregator")))));
    address generator =
        address(uint160(uint256(keccak256(abi.encodePacked("generator")))));

    // axiom-related constants (hardcoded for goerli)
    address public constant AXIOM_V2_QUERY_GOERLI_ADDR =
        0x28CeE427fCD58e5EF1cE4C93F877b621E2Db66df;
    // TODO: update this query schema to the query schema given by https://repl.axiom.xyz/
    //       for the query we end up making.
    bytes32 public constant AXIOM_QUERY_SCHEMA = 0x0;
    uint64 public constant AXIOM_CHAIN_ID = 5;

    function setUp() public {
        _setUpBLSMockAVSDeployer();

        tmImplementation = new IncredibleSquaringTaskManager(
            incsqsm.IBLSRegistryCoordinatorWithIndices(
                address(registryCoordinator)
            ),
            TASK_RESPONSE_WINDOW_BLOCK,
            AXIOM_V2_QUERY_GOERLI_ADDR
        );

        // Third, upgrade the proxy contracts to use the correct implementation contracts and initialize them.
        tm = IncredibleSquaringTaskManager(
            address(
                new TransparentUpgradeableProxy(
                    address(tmImplementation),
                    address(proxyAdmin),
                    abi.encodeWithSelector(
                        tm.initialize.selector,
                        pauserRegistry,
                        serviceManagerOwner,
                        aggregator,
                        generator,
                        AXIOM_CHAIN_ID,
                        AXIOM_QUERY_SCHEMA
                    )
                )
            )
        );
    }

    function testCreateNewTask() public {
        bytes memory quorumNumbers = new bytes(0);
        cheats.prank(generator, generator);
        tm.createNewTask(2, 100, quorumNumbers);
        assertEq(tm.latestTaskNum(), 1);
    }

    function test_axiomV2Callback() public {
        uint256 queryId = 0;
        // TODO: make this an actual result
        bytes32[] memory axiomResults = new bytes32[](1);
        axiomResults[
            0
        ] = 0x00000000000000000000000000000000000000000000000100000000009707DF;
        bytes memory extraData = new bytes(0);
        cheats.prank(AXIOM_V2_QUERY_GOERLI_ADDR);
        tm.axiomV2Callback(
            AXIOM_CHAIN_ID,
            AXIOM_V2_QUERY_GOERLI_ADDR,
            AXIOM_QUERY_SCHEMA,
            queryId,
            axiomResults,
            extraData
        );
        // TODO: check that something changed in the contract..
        // assertEq(counter.number(), 1);
    }
}
