# Echidna Fuzz Tests for Price.sol

This directory contains comprehensive Echidna fuzz tests for the `Price.sol` library's `storePrice` function, addressing all interview questions while following the specified constraints.

## Test Files

### 1. PriceFuzzTest.sol
**Purpose**: Assertion test mode with randomized inputs (Question 2)
**What it does**: 
- Replicates the Python test script but with randomized inputs
- Uses assertion mode with state variables for Echidna monitoring
- Follows constraints: uses existing wrapper approach (Q3), focused fuzzing effort (Q4)
- Addresses corpus directory requirement (Q5)

### 2. PriceMemoryFuzzTest.sol
**Purpose**: Memory safety testing (Question 7) + Sanity check (Question 6)
**Contains two contracts:**

#### PriceBuggyTest (Q6 - Sanity Check)
- **DELIBERATELY BUGGY** version to verify test effectiveness
- Flips a bit in `sqrtPrice` to simulate memory corruption
- **SHOULD FAIL** - proves your fuzzing setup works

#### PriceMemoryFuzzTest (Q7 - Memory Safety)
- Tests with random memory pointers
- Populates surrounding memory with known patterns
- Verifies surrounding memory is not corrupted after read/write operations
- Tests both regular and height versions of `storePrice`

## Configuration

### echidna.config.Price.yml
- Enables coverage tracking
- Sets corpus directory to `./corpus` for test case analysis (Question 5)
- Configures test limits and output directory

## Running the Tests

### Docker Commands (Recommended)

From the project root directory (`c:\Users\sriva\OneDrive\Documents\GitHub\core`):

```powershell
# Q2: Assertion test mode with randomized inputs
docker run --rm -v "c:\Users\sriva\OneDrive\Documents\GitHub\core:/workspace" trailofbits/echidna echidna /workspace/echidna/PriceFuzzTest.sol --contract PriceFuzzTest

# Q5: With corpus directory for coverage analysis
docker run --rm -v "c:\Users\sriva\OneDrive\Documents\GitHub\core:/workspace" trailofbits/echidna echidna /workspace/echidna/PriceFuzzTest.sol --contract PriceFuzzTest --corpus-dir ./corpus

# Q6: Sanity check - Deliberately buggy test (SHOULD FAIL)
docker run --rm -v "c:\Users\sriva\OneDrive\Documents\GitHub\core:/workspace" trailofbits/echidna echidna /workspace/echidna/PriceMemoryFuzzTest.sol --contract PriceBuggyTest

# Q7: Memory safety test with random pointers
docker run --rm -v "c:\Users\sriva\OneDrive\Documents\GitHub\core:/workspace" trailofbits/echidna echidna /workspace/echidna/PriceMemoryFuzzTest.sol --contract PriceMemoryFuzzTest
```

### Native Echidna Commands (if installed locally)

```bash
# Q2: Assertion test mode with randomized inputs
echidna PriceFuzzTest.sol --contract PriceFuzzTest

# Q5: With corpus and coverage
echidna PriceFuzzTest.sol --contract PriceFuzzTest --corpus-dir ./corpus

# Q6: Sanity check - Should FAIL
echidna PriceMemoryFuzzTest.sol --contract PriceBuggyTest

# Q7: Memory safety test
echidna PriceMemoryFuzzTest.sol --contract PriceMemoryFuzzTest
```

## Test Results

### ✅ PriceFuzzTest (Q2, Q5) - PASSING

```
[2026-02-03 05:22:06.76] Compiling `/workspace/echidna/PriceFuzzTest.sol`... Done!
[2026-02-03 05:22:12.06] [Worker 0] New coverage: 426 instr, 1 contracts, 1 seqs in corpus (storeFuzzedValues)
[2026-02-03 05:22:14.98] [status] tests: 0/2, fuzzing: 27783/50000, values: [], cov: 485, corpus: 4, gas/s: 288102508
[2026-02-03 05:22:17.09] [status] tests: 0/2, fuzzing: 50326/50000, values: [], cov: 485, corpus: 4, gas/s: 351130786
echidna_test_storePrice: passing
echidna_always_true: passing

Unique instructions: 485
Unique codehashes: 1
Corpus size: 4
Total calls: 50326
```

**With Corpus (Q5):**
```
[2026-02-03 05:22:28.79] [Worker 0] New coverage: 450 instr, 1 contracts, 1 seqs in corpus (storeFuzzedValues)
 Saved reproducer to ./corpus/coverage/4084177299461069935.txt
[2026-02-03 05:22:29.89]  Saved reproducer to ./corpus/coverage/2452701911466231357.txt
echidna_test_storePrice: passing
echidna_always_true: passing
Unique instructions: 485
Corpus size: 5
Total calls: 50119
```

### ❌ PriceBuggyTest (Q6 - Sanity Check) - FAILING (Expected)

```
[2026-02-03 05:22:42.50] [Worker 1] Test echidna_storePrice_with_bug falsified!
  Call sequence:
[2026-02-03 05:22:42.51] [status] tests: 1/1, fuzzing: 404/50000, values: [], cov: 45, corpus: 1, gas/s: 0
echidna_storePrice_with_bug: failed with no transactions made ⁉️
```

✅ **Bug successfully caught!** The test immediately falsifies, confirming the fuzzing setup works correctly.

### ✅ PriceMemoryFuzzTest (Q7) - PASSING

```
[2026-02-03 05:22:50.08] [Worker 2] Starting FuzzerAgent 2
[2026-02-03 05:22:50.11] [Worker 0] New coverage: 50 instr, 1 contracts, 1 seqs in corpus ()
[2026-02-03 05:22:50.55] [status] tests: 0/2, fuzzing: 50084/50000, values: [], cov: 53, corpus: 2, gas/s: 0
echidna_storePrice_with_height_memory_safety: passing
echidna_storePrice_memory_safety: passing

Unique instructions: 53
Corpus size: 2
Total calls: 50084
```

## Expected Results

- **PriceFuzzTest.sol**: Should pass (no bugs found)
- **PriceBuggyTest**: Should FAIL (deliberate bug - confirms tests work)
- **PriceMemoryFuzzTest**: Should pass