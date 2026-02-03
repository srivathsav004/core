// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X59, epsilonX59, thirtyTwoX59} from "../contracts/utilities/X59.sol";
import {X216, epsilonX216, oneX216} from "../contracts/utilities/X216.sol";
import {PriceLibrary} from "../contracts/utilities/Price.sol";

/// @notice Echidna fuzz test for Price.sol storePrice function
/// This test replicates the Python test_storePrice1 but with randomized inputs
/// Follows constraints: uses existing wrapper, focused fuzzing, corpus directory
contract PriceFuzzTest {
    using PriceLibrary for uint256;
    
    // Test constants equivalent to Python test values
    X59 constant sampleX59 = X59.wrap(0xF00FF00FF00FF00F);
    X216 constant sampleX216 = X216.wrap(0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF);
    
    // State variables to store fuzzed inputs and results
    X59 public lastLogPrice;
    X216 public lastSqrtPrice;
    X216 public lastSqrtInversePrice;
    
    /// @notice Stateful fuzz test - Echidna calls this with random uint256 values
    /// It stores the values and the property check happens in echidna_test_storePrice
    function storeFuzzedValues(
        uint256 logPriceUint,
        uint256 sqrtPriceUint,
        uint256 sqrtInversePriceUint
    ) public {
        // Constrain inputs to valid ranges and cast to proper types
        // X59: 0 < logPrice < 2^64
        lastLogPrice = X59.wrap(int256((logPriceUint % ((2 ** 64) - 1)) + 1));
        // X216: 1 <= sqrtPrice < 2^216
        lastSqrtPrice = X216.wrap(int256((sqrtPriceUint % ((1 << 216) - 1)) + 1));
        // X216: 1 <= sqrtInversePrice < 2^216
        lastSqrtInversePrice = X216.wrap(int256((sqrtInversePriceUint % ((1 << 216) - 1)) + 1));
    }
    
    /// @notice Property check - called by Echidna after state transitions
    /// Echidna will fuzz the parameters of storeFuzzedValues
    function echidna_test_storePrice() public view returns (bool) {
        // Skip check if values haven't been set yet
        if (X59.unwrap(lastLogPrice) == 0) return true;
        
        // Use the stored fuzzed values
        X59 logPrice = lastLogPrice;
        X216 sqrtPrice = lastSqrtPrice;
        X216 sqrtInversePrice = lastSqrtInversePrice;
        
        // Allocate memory for price storage (minimal setup - Q4 constraint)
        uint256 pricePointer;
        assembly {
            pricePointer := mload(0x40)
            mstore(0x40, add(pricePointer, 64))
        }
        
        // Store the price using the function being tested
        pricePointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // Read back the stored values
        X59 logResult = pricePointer.log();
        X216 sqrtResult = pricePointer.sqrt(false);
        X216 sqrtInverseResult = pricePointer.sqrt(true);
        
        // Return true only if all assertions pass
        return (logResult == logPrice && sqrtResult == sqrtPrice && sqrtInverseResult == sqrtInversePrice);
    }
    
    /// @notice Sanity check target - should always return true
    function echidna_always_true() public pure returns (bool) {
        return true;
    }
}
