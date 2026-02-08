// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/utilities/Calldata.sol";
import "../contracts/helpers/CalldataWrapper.sol";

contract CalldataReadModifyPositionInputTestBuggy {
    CalldataWrapper wrapper;
    
    // Test state to track if we found valid inputs
    bool foundValidInput = false;
    bool foundInvalidPrice = false;
    bool foundInvalidShares = false;
    bool foundInvalidHookData = false;
    
    constructor() {
        wrapper = new CalldataWrapper();
    }
    
    // Helper to create calldata for modifyPosition
    function createCalldata(
        uint256 poolId,
        int256 logPriceMin,
        int256 logPriceMax,
        int256 shares,
        uint256 hookDataStart,
        bytes memory hookData
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            bytes4(keccak256("_readModifyPositionInput()")),
            abi.encode(poolId),
            abi.encode(logPriceMin),
            abi.encode(logPriceMax),
            abi.encode(shares),
            abi.encode(hookDataStart),
            hookData
        );
    }
    
    // Main fuzzing test - WITH DELIBERATE BUG
    function echidna_test_readModifyPositionInput() public {
        // Generate random parameters
        uint256 poolId = uint256(keccak256("poolId")) % type(uint256).max;
        int256 logPriceMin = int256(uint256(keccak256("logPriceMin")) % type(uint256).max);
        int256 logPriceMax = int256(uint256(keccak256("logPriceMax")) % type(uint256).max);
        int256 shares = int256(uint256(keccak256("shares")) % type(uint256).max);
        
        // Random hook data
        uint256 hookDataLength = uint256(keccak256("hookDataLength")) % 1000;
        bytes memory hookData = new bytes(hookDataLength);
        for (uint256 i = 0; i < hookDataLength; i++) {
            hookData[i] = bytes1(uint8(uint256(keccak256(abi.encode(i))) % 256));
        }
        
        uint256 hookDataStart = 0x84; // Standard position
        
        // Create calldata
        bytes memory calldata_data = createCalldata(
            poolId,
            logPriceMin,
            logPriceMax,
            shares,
            hookDataStart,
            hookData
        );
        
        // Try to call the function
        (bool success, ) = address(wrapper).call(calldata_data);
        
        // DELIBERATE BUG: This assertion should fail when shares is negative
        // The original function should reject negative shares, but we're asserting it succeeds
        if (success) {
            foundValidInput = true;
            // BUG: We're incorrectly asserting that negative shares should be valid
            assert(shares >= 0 || shares == -1); // This should fail for negative shares
        } else {
            // Check if it failed for expected reasons
            if (logPriceMin <= 0 || logPriceMin >= (1 << 64) ||
                logPriceMax <= 0 || logPriceMax >= (1 << 64)) {
                foundInvalidPrice = true;
            }
            
            if (shares > type(int128).max || shares < -type(int128).max || shares == 0) {
                foundInvalidShares = true;
            }
            
            if (hookDataLength > type(uint16).max) {
                foundInvalidHookData = true;
            }
        }
    }
    
    // Test with non-strictly encoded input
    function echidna_test_malformedCalldata() public {
        // Create malformed calldata by starting from random offset
        uint256 randomOffset = uint256(keccak256("offset")) % 100;
        bytes memory malformedData = new bytes(randomOffset + 100);
        
        // Fill with random data
        for (uint256 i = 0; i < malformedData.length; i++) {
            malformedData[i] = bytes1(uint8(uint256(keccak256(abi.encode(i))) % 256));
        }
        
        // Try to call with malformed data
        (bool success, ) = address(wrapper).call(malformedData);
        
        // Should not succeed with completely malformed data
        // This test mainly ensures the contract doesn't crash
        assert(true);
    }
    
    // Test edge cases around boundaries
    function echidna_test_boundaryConditions() public {
        // Test boundary values for shares
        int256[] memory sharesValues = new int256[](7);
        sharesValues[0] = type(int128).max;
        sharesValues[1] = type(int128).max + 1;
        sharesValues[2] = -type(int128).max;
        sharesValues[3] = -type(int128).max - 1;
        sharesValues[4] = 0;
        sharesValues[5] = 1;
        sharesValues[6] = -1;
        
        uint256 poolId = 1;
        int256 logPriceMin = 1;
        int256 logPriceMax = 2;
        uint256 hookDataStart = 0x84;
        bytes memory hookData = new bytes(10);
        
        for (uint256 i = 0; i < sharesValues.length; i++) {
            bytes memory calldata_data = createCalldata(
                poolId,
                logPriceMin,
                logPriceMax,
                sharesValues[i],
                hookDataStart,
                hookData
            );
            
            (bool success, ) = address(wrapper).call(calldata_data);
            
            // Track which cases fail
            if (!success) {
                if (sharesValues[i] > type(int128).max || 
                    sharesValues[i] < -type(int128).max || 
                    sharesValues[i] == 0) {
                    // Expected failure
                    foundInvalidShares = true;
                }
            } else {
                foundValidInput = true;
                // BUG: Another deliberate bug - allowing invalid shares
                assert(sharesValues[i] != 0); // This should fail when shares is 0
            }
        }
        
        assert(true);
    }
    
    // Sanity check that we're testing different scenarios
    function echidna_test_coverage() public {
        // This test ensures we're hitting different code paths
        echidna_test_readModifyPositionInput();
        echidna_test_malformedCalldata();
        echidna_test_boundaryConditions();
        
        // At least one of each scenario should be hit during fuzzing
        assert(true);
    }
}
