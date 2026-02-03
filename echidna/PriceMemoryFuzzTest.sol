// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {X59, epsilonX59, thirtyTwoX59} from "../contracts/utilities/X59.sol";
import {X216, epsilonX216, oneX216} from "../contracts/utilities/X216.sol";
import {X15, zeroX15, oneX15} from "../contracts/utilities/X15.sol";
import {PriceLibrary} from "../contracts/utilities/Price.sol";

/// @notice DELIBERATELY BUGGY VERSION for sanity check (Q6)
/// This contract has an intentional bug to verify Echidna can catch it
/// BUG: We flip one bit in sqrtPrice storage to corrupt data
contract PriceBuggyTest {
    using PriceLibrary for uint256;
    
    /// @notice Fuzz test with deliberate bug in sqrtPrice storage
    /// Echidna SHOULD find this bug and report failure
    function echidna_storePrice_with_bug() public returns (bool) {
        // Generate random values internally
        uint256 randomBase = uint256(uint160(address(this))) ^ block.timestamp;
        X59 logPrice = X59.wrap(int256((randomBase % ((2 ** 64) - 1)) + 1));
        X216 sqrtPrice = X216.wrap(int256(((randomBase * 3) % ((1 << 216) - 1)) + 1));
        X216 sqrtInversePrice = X216.wrap(int256(((randomBase * 7) % ((1 << 216) - 1)) + 1));
        
        uint256 pricePointer;
        assembly {
            pricePointer := mload(0x40)
            mstore(0x40, add(pricePointer, 64))
        }
        
        // Store price correctly first
        pricePointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // DELIBERATE BUG: Flip one bit in sqrtPrice to corrupt it
        assembly {
            let corruptedSqrt := mload(add(pricePointer, 3))
            mstore(add(pricePointer, 3), xor(corruptedSqrt, 1)) // Flip LSB
        }
        
        // This SHOULD FAIL due to our deliberate bug
        return (pricePointer.log() == logPrice && 
                pricePointer.sqrt(false) == sqrtPrice && // This will fail!
                pricePointer.sqrt(true) == sqrtInversePrice);
    }
}

/// @notice Advanced memory safety test for Price.sol (Q7)
/// Tests random memory pointers and verifies surrounding memory is not corrupted
contract PriceMemoryFuzzTest {
    using PriceLibrary for uint256;
    
    // Test constants
    X59 constant sampleX59 = X59.wrap(0xF00FF00FF00FF00F);
    X216 constant sampleX216 = X216.wrap(0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF);
    X15 constant sampleX15 = X15.wrap(0xF00F);
    
    /// @notice Memory safety test with random pointer and surrounding memory verification
    function echidna_storePrice_memory_safety() public returns (bool) {
        // Generate random values internally
        uint256 randomBase = uint256(uint160(address(this))) ^ block.timestamp;
        X59 logPrice = X59.wrap(int256((randomBase % ((2 ** 64) - 1)) + 1));
        X216 sqrtPrice = X216.wrap(int256(((randomBase * 3) % ((1 << 216) - 1)) + 1));
        X216 sqrtInversePrice = X216.wrap(int256(((randomBase * 7) % ((1 << 216) - 1)) + 1));
        
        // Generate a safe random pointer (must be >= 32 and have space around it)
        uint256 pricePointer = 32 + ((randomBase * 11) % 1000);
        
        // Populate surrounding memory with known patterns
        uint256 beforePattern = 0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF;
        uint256 afterPattern = 0xCAFEBABECAFEBABECAFEBABECAFEBABECAFEBABECAFEBABECAFEBABECAFEBABE;
        
        // Store patterns in surrounding memory (32 bytes before and after)
        assembly {
            mstore(sub(pricePointer, 32), beforePattern)
            mstore(add(pricePointer, 64), afterPattern)
        }
        
        // Store the price using the function being tested
        pricePointer.storePrice(logPrice, sqrtPrice, sqrtInversePrice);
        
        // Read back the stored values
        X59 logResult = pricePointer.log();
        X216 sqrtResult = pricePointer.sqrt(false);
        X216 sqrtInverseResult = pricePointer.sqrt(true);
        
        // Verify surrounding memory was NOT corrupted
        uint256 beforeCheck;
        uint256 afterCheck;
        assembly {
            beforeCheck := mload(sub(pricePointer, 32))
            afterCheck := mload(add(pricePointer, 64))
        }
        
        // Return true only if all checks pass
        return (logResult == logPrice && 
                sqrtResult == sqrtPrice && 
                sqrtInverseResult == sqrtInversePrice &&
                beforeCheck == beforePattern &&
                afterCheck == afterPattern);
    }
    
    /// @notice Extended test with height parameter and larger memory area
    function echidna_storePrice_with_height_memory_safety() public returns (bool) {
        // Generate random values internally
        uint256 randomBase = uint256(uint160(address(this))) ^ block.timestamp;
        X15 heightPrice = X15.wrap(uint16((randomBase % 32768)));
        X59 logPrice = X59.wrap(int256((randomBase % ((2 ** 64) - 1)) + 1));
        X216 sqrtPrice = X216.wrap(int256(((randomBase * 3) % ((1 << 216) - 1)) + 1));
        X216 sqrtInversePrice = X216.wrap(int256(((randomBase * 7) % ((1 << 216) - 1)) + 1));
        
        // Generate safe random pointer (must be >= 34 for height version)
        uint256 pricePointer = 34 + ((randomBase * 13) % 1000);
        
        // Populate larger surrounding area with known patterns
        uint256 beforePattern = 0x1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF;
        uint256 afterPattern = 0xFEDCBA0987654321FEDCBA0987654321FEDCBA0987654321FEDCBA0987654321;
        
        // Store patterns in surrounding memory (64 bytes before and after for safety)
        assembly {
            mstore(sub(pricePointer, 64), beforePattern)
            mstore(add(pricePointer, 64), afterPattern)
        }
        
        // Store the price with height using the function being tested
        pricePointer.storePrice(heightPrice, logPrice, sqrtPrice, sqrtInversePrice);
        
        // Read back all stored values
        X15 heightResult = pricePointer.height();
        X59 logResult = pricePointer.log();
        X216 sqrtResult = pricePointer.sqrt(false);
        X216 sqrtInverseResult = pricePointer.sqrt(true);
        
        // Verify surrounding memory was NOT corrupted
        uint256 beforeCheck;
        uint256 afterCheck;
        assembly {
            beforeCheck := mload(sub(pricePointer, 64))
            afterCheck := mload(add(pricePointer, 64))
        }
        
        // Return true only if all checks pass
        return (heightResult == heightPrice &&
                logResult == logPrice && 
                sqrtResult == sqrtPrice && 
                sqrtInverseResult == sqrtInversePrice &&
                beforeCheck == beforePattern &&
                afterCheck == afterPattern);
    }
}
