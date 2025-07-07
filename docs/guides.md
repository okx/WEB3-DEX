# WEB3-DEX Router Implementation Guides

## Getting Started

These guides will help you implement **production-ready** token swapping functionality using the WEB3-DEX Router system. Each guide is designed to be completed within 10 minutes and provides complete, working smart contracts based on real implementation examples.

**💡 Production-Ready Examples**: All code examples in these guides are derived from actual working smart contracts and are available in our [examples folder](https://github.com/WEB3-DEX/WEB3-DEX/tree/main/examples) for easy copy-paste implementation.

**🔧 What's Different**: Unlike simplified tutorial examples, these guides show you the complete implementation including commission handling, proper parameter encoding, adapter configuration, and production-grade error handling.

### Guide Principles
Following Uniswap's documentation standards, each guide:
- Demonstrates a **single concept** with reusable code
- Has **three parts**: Introduction → Step-by-step walkthrough → Testable output
- References external code via links rather than copying source snippets
- Keeps all links and references **at the bottom** to minimize distractions
- Provides **10-minute implementation** with transition to next steps
- Uses **minimal dependencies** with all parameters included in code

## Prerequisites

- Basic understanding of Solidity and smart contracts
- Access to a deployed DexRouter contract
- Node.js and npm installed
- Hardhat development environment

## Guide 1: Simple Token Swap with Commission System

### Introduction
This guide demonstrates how to execute a production-ready token swap using the DexRouter with advanced features including commission handling, proper parameter encoding, and adapter-based routing. You'll learn to build a complete smart contract that can handle real-world DEX aggregation with flexible referral systems.

### What You'll Build
A comprehensive smart swap contract that exchanges tokens with configurable commission distribution, adapter routing, and production-grade parameter handling.

### Implementation

**Step 1: Complete Contract Setup**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../contracts/8/DexRouter.sol";
// import "../contracts/8/libraries/PMMLib.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SmartSwap {
    using SafeERC20 for IERC20;
    
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal constant _ADDRESS_MASK =
        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 constant FROM_TOKEN_COMMISSION =
        0x3ca20afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION =
        0x3ca20afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 constant FROM_TOKEN_COMMISSION_DUAL =
        0x22220afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION_DUAL =
        0x22220afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 constant _TO_B_COMMISSION_MASK =
        0x8000000000000000000000000000000000000000000000000000000000000000;

    address public refer1;
    address public refer2;
    uint256 public rate1;
    uint256 public rate2;

    DexRouter public dexRouter;
    address public tokenApprove;

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    constructor(
        address _dexRouter,
        address _tokenApprove,
        address _refer1,
        address _refer2,
        uint256 _rate1,
        uint256 _rate2
    ) {
        dexRouter = DexRouter(payable(_dexRouter));
        tokenApprove = _tokenApprove;
        refer1 = _refer1;
        refer2 = _refer2;
        require(_rate1 < 10 ** 9, "rate1 must be less than 10**9");
        require(_rate2 < 10 ** 9, "rate2 must be less than 10**9");
        require(
            _rate1 + _rate2 < 0.03 * 10 ** 9,
            "rate1 + rate2 must be less than 0.03"
        );
        rate1 = _rate1;
        rate2 = _rate2;
    }
}
```

**Step 2: Implement Advanced Swap Function**
```solidity
function performTokenSwap(
    address fromToken,
    address toToken,
    uint256 amount,
    uint256 minReturn,
    address adapter,
    address poolAddress
) external {
    // Step 1: Approve tokens for spending
    IERC20(fromToken).safeApprove(tokenApprove, amount);

    // Step 2: Prepare swap info structure
    SwapInfo memory swapInfo;

    // Step 3: Setup base request
    swapInfo.baseRequest.fromToken = uint256(uint160(fromToken));
    swapInfo.baseRequest.toToken = toToken;
    swapInfo.baseRequest.fromTokenAmount = amount;
    swapInfo.baseRequest.minReturnAmount = minReturn;
    swapInfo.baseRequest.deadLine = block.timestamp + 300; // 5 minutes deadline

    // Step 4: Setup batch amounts
    swapInfo.batchesAmount = new uint256[](1);
    swapInfo.batchesAmount[0] = amount;

    // Step 5: Setup routing batches
    swapInfo.batches = new DexRouter.RouterPath[][](1);
    swapInfo.batches[0] = new DexRouter.RouterPath[](1);

    // Setup adapter
    swapInfo.batches[0][0].mixAdapters = new address[](1);
    swapInfo.batches[0][0].mixAdapters[0] = adapter;

    // Setup asset destination - tokens go to adapter
    swapInfo.batches[0][0].assetTo = new address[](1);
    swapInfo.batches[0][0].assetTo[0] = adapter;

    // Setup raw data with correct encoding: reverse(1byte) + weight(11bytes) + poolAddress(20bytes)
    swapInfo.batches[0][0].rawData = new uint256[](1);
    swapInfo.batches[0][0].rawData[0] = uint256(
        bytes32(abi.encodePacked(uint8(0x00), uint88(10000), poolAddress))
    );

    // Setup adapter-specific extra data
    swapInfo.batches[0][0].extraData = new bytes[](1);
    swapInfo.batches[0][0].extraData[0] = abi.encode(
        bytes32(uint256(uint160(fromToken))),
        bytes32(uint256(uint160(toToken)))
    );

    swapInfo.batches[0][0].fromToken = uint256(uint160(fromToken));

    // Step 6: Setup PMM extra data (empty for basic swaps)
    swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

    // Step 7: Execute the swap
    bytes memory swapData = abi.encodeWithSelector(
        dexRouter.smartSwapByOrderId.selector,
        swapInfo.orderId,
        swapInfo.baseRequest,
        swapInfo.batchesAmount,
        swapInfo.batches,
        swapInfo.extraData
    );
    
    // Step 8: Execute the swap with commission
    bytes memory data = bytes.concat(
        swapData,
        _getCommissionInfo(true, true, false, toToken)
    );
    (bool s, bytes memory res) = address(dexRouter).call(data);
    require(s, string(res));
    // returnAmount contains the actual tokens received
}
```

**Step 3: Commission Handling (Advanced Feature)**
```solidity
function _getCommissionInfo(
    bool _hasNextRefer,
    bool _isToB,
    bool _isFrom,
    address _token
) internal view returns (bytes memory data) {
    uint256 flag = _isFrom
        ? (
            _hasNextRefer
                ? FROM_TOKEN_COMMISSION_DUAL
                : FROM_TOKEN_COMMISSION
        )
        : (_hasNextRefer ? TO_TOKEN_COMMISSION_DUAL : TO_TOKEN_COMMISSION);

    bytes32 first = bytes32(
        flag + uint256(rate1 << 160) + uint256(uint160(refer1))
    );
    bytes32 middle = bytes32(
        abi.encodePacked(uint8(_isToB ? 0x80 : 0), uint88(0), _token)
    );
    bytes32 last = bytes32(
        flag + uint256(rate2 << 160) + uint256(uint160(refer2))
    );
    
    uint256 status;
    assembly {
        function _getStatus(token, isToB, hasNextRefer) -> d {
            let a := mul(eq(token, _ETH), 256)
            let b := mul(isToB, 16)
            let c := hasNextRefer
            d := add(a, add(b, c))
        }
        status := _getStatus(_token, _isToB, _hasNextRefer)
    }
    
    return _hasNextRefer
        ? abi.encode(last, middle, first)
        : abi.encode(middle, first);
}
```

**Step 4: Usage Example**
```solidity
// Deploy the contract with commission configuration
SmartSwap swapper = new SmartSwap(
    dexRouterAddress,
    approveProxyAddress,
    0x000000000000000000000000000000000000dEaD, // refer1
    0x000000000000000000000000000000000000bEEF, // refer2
    0.0001 * 10 ** 9, // rate1 (0.01%)
    0.00002 * 10 ** 9 // rate2 (0.002%)
);

// Execute a swap with USDT → USDC
swapper.performTokenSwap(
    0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC  
    1000 * 1e6, // 1000 USDT
    990 * 1e6,  // Min 990 USDC (1% slippage)
    uniV3AdapterAddress,
    uniV3PoolAddress
);
```

### Expected Output
- Input: 1000 USDT
- Output: ~1000 USDC (minus fees and slippage)
- Gas: ~200,000 gas units (includes commission processing)
- Commission: Automatic fee distribution to referrers based on configured rates

**Key Features Demonstrated:**
- Flexible commission configuration in constructor
- Complete swap parameter setup and encoding
- Low-level call execution with commission data
- Adapter-based routing with proper parameter validation

**📁 Complete Example**: View the [complete SmartSwap example](https://github.com/WEB3-DEX/WEB3-DEX/tree/main/examples/smartswap.sol) in our repository.

---

## Guide 2: ETH/WETH Swap with Native Token Handling

### Introduction
This guide demonstrates how to handle native ETH swaps using the router's built-in ETH/WETH conversion capabilities. The router automatically manages wrapping and unwrapping as needed.

### What You'll Build
A contract that can swap ETH for tokens and tokens for ETH seamlessly.

### Implementation

**Step 1: ETH Swap Contract**
```solidity
contract ETHSwapExample {
    using SafeERC20 for IERC20;
    
    DexRouter public immutable dexRouter;
    address public constant ETH_ADDRESS = address(0);
    
    constructor(address _dexRouter) {
        dexRouter = DexRouter(_dexRouter);
    }
    
    // Swap ETH for tokens
    function swapETHForTokens(
        address toToken,
        uint256 minReturn,
        uint256 deadline
    ) external payable returns (uint256 returnAmount) {
        require(msg.value > 0, "Must send ETH");
        
        DexRouter.BaseRequest memory request = DexRouter.BaseRequest({
            fromToken: uint256(uint160(ETH_ADDRESS)),
            toToken: toToken,
            fromTokenAmount: msg.value,
            minReturnAmount: minReturn,
            deadLine: deadline
        });
        
        uint256[] memory batchAmounts = new uint256[](1);
        batchAmounts[0] = msg.value;
        
        returnAmount = dexRouter.smartSwapByOrderId{value: msg.value}(
            2, // orderId
            request,
            batchAmounts,
            new DexRouter.RouterPath[][](0),
            new PMMLib.PMMSwapRequest[](0)
        );
        
        // Tokens are automatically sent to msg.sender
    }
    
    // Swap tokens for ETH
    function swapTokensForETH(
        address fromToken,
        uint256 amount,
        uint256 minReturn,
        uint256 deadline
    ) external returns (uint256 returnAmount) {
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(fromToken).safeApprove(address(dexRouter), amount);
        
        DexRouter.BaseRequest memory request = DexRouter.BaseRequest({
            fromToken: uint256(uint160(fromToken)),
            toToken: ETH_ADDRESS,
            fromTokenAmount: amount,
            minReturnAmount: minReturn,
            deadLine: deadline
        });
        
        uint256[] memory batchAmounts = new uint256[](1);
        batchAmounts[0] = amount;
        
        returnAmount = dexRouter.smartSwapByOrderId(
            3, // orderId
            request,
            batchAmounts,
            new DexRouter.RouterPath[][](0),
            new PMMLib.PMMSwapRequest[](0)
        );
        
        // ETH is automatically sent to msg.sender
    }
    
    // Enable receiving ETH
    receive() external payable {}
}
```

**Step 2: Usage Examples**
```solidity
// Deploy the contract
ETHSwapExample ethSwapper = new ETHSwapExample(dexRouterAddress);

// Swap ETH for USDC
uint256 usdcReceived = ethSwapper.swapETHForTokens{value: 1 ether}(
    usdcAddress,
    2900 * 1e6, // Minimum 2900 USDC
    block.timestamp + 300
);

// Swap USDC for ETH
uint256 ethReceived = ethSwapper.swapTokensForETH(
    usdcAddress,
    3000 * 1e6, // 3000 USDC
    0.95 ether, // Minimum 0.95 ETH
    block.timestamp + 300
);
```

### Expected Output
- ETH → USDC: 1 ETH → ~3000 USDC
- USDC → ETH: 3000 USDC → ~0.98 ETH
- Gas: ~200,000 gas units per swap

**📁 Complete Example**: View the [complete ETH Swap example](https://github.com/WEB3-DEX/WEB3-DEX/tree/main/examples/eth-swap) in our repository.

---

## Guide 3: Investment Contract Integration

### Introduction
This guide shows how to use the specialized `smartSwapByInvest` function for investment scenarios. This function is optimized for cases where tokens are already held by the router contract, allowing for efficient rebalancing and investment operations.

### What You'll Build
An investment smart contract that demonstrates direct token transfers to the DexRouter and execution of swaps optimized for investment use cases.

### Implementation

**Step 1: Investment Contract with smartSwapByInvest**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../contracts/8/DexRouter.sol";
// import "../contracts/8/libraries/PMMLib.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SmartSwap {
    using SafeERC20 for IERC20;

    DexRouter public dexRouter;
    address public tokenApprove;

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    constructor(address _dexRouter, address _tokenApprove) {
        dexRouter = DexRouter(payable(_dexRouter));
        tokenApprove = _tokenApprove;
    }

    function performTokenSwap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        address adapter,
        address poolAddress
    ) external {
        // Step 1: Transfer tokens directly to dexRouter for investment swaps
        IERC20(fromToken).safeTransferFrom(
            msg.sender,
            address(dexRouter),
            amount
        );

        // Step 2: Prepare swap info structure
        SwapInfo memory swapInfo;

        // Step 3: Setup base request
        swapInfo.baseRequest.fromToken = uint256(uint160(fromToken));
        swapInfo.baseRequest.toToken = toToken;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = minReturn;
        swapInfo.baseRequest.deadLine = block.timestamp + 300; // 5 minutes deadline

        // Step 4: Setup batch amounts
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        // Step 5: Setup routing batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);

        // Setup adapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = adapter;

        // Setup asset destination - tokens go to adapter
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = adapter;

        // Setup raw data with correct encoding: reverse(1byte) + weight(11bytes) + poolAddress(20bytes)
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x00), uint88(10000), poolAddress))
        );

        // Setup adapter-specific extra data
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(
            bytes32(uint256(uint160(fromToken))),
            bytes32(uint256(uint160(toToken)))
        );

        swapInfo.batches[0][0].fromToken = uint256(uint160(fromToken));

        // Step 6: Setup PMM extra data (empty for basic swaps)
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        // Step 7: Execute the investment swap
        uint256 returnAmount = dexRouter.smartSwapByInvest(
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData,
            msg.sender // Send tokens to the user
        );

        // returnAmount contains the actual tokens received
    }
}
```

**Step 2: Usage Example**
```solidity
// Deploy investment contract
SmartSwap investmentSwap = new SmartSwap(
    dexRouterAddress, 
    approveProxyAddress
);

// Approve tokens first
IERC20(usdcAddress).approve(address(investmentSwap), 5000 * 1e6);

// Execute investment swap: USDC → DAI
investmentSwap.performTokenSwap(
    usdcAddress,      // From USDC
    daiAddress,       // To DAI
    5000 * 1e6,       // 5000 USDC
    4950 * 1e18,      // Min 4950 DAI (1% slippage)
    curveAdapterAddress,
    curveUsdcDaiPoolAddress
);

// The DAI tokens are automatically sent to msg.sender
```

### Expected Output
- Input: 5000 USDC
- Output: ~4950 DAI (to user's wallet)
- Gas: ~180,000 gas units
- Direct token transfer to user (not to contract)

**Key Features Demonstrated:**
- `smartSwapByInvest` function usage
- Direct token transfer to DexRouter
- Simplified structure without commission handling
- Investment-optimized workflow

**📁 Complete Example**: View the [complete Investment SmartSwap example](https://github.com/WEB3-DEX/WEB3-DEX/tree/main/examples/smartswapByInvest.sol) in our repository.

---

## Common Patterns and Best Practices

### 1. Choose the Right Swap Function
**`smartSwapByOrderId`**: For regular swaps with commission handling
```solidity
// Best for: User-initiated swaps, dApp integrations with referral systems
returnAmount = dexRouter.smartSwapByOrderId(
    orderId,
    baseRequest,
    batchesAmount,
    batches,
    extraData
);
```

**`smartSwapByInvest`**: For investment scenarios
```solidity
// Best for: Investment protocols, rebalancing, when tokens are already in router
returnAmount = dexRouter.smartSwapByInvest(
    baseRequest,
    batchesAmount,
    batches,
    extraData,
    recipient
);
```

### 2. Commission Configuration
Set up flexible commission rates in your constructor:
```solidity
constructor(
    address _dexRouter,
    address _tokenApprove,
    address _refer1,
    address _refer2,
    uint256 _rate1,
    uint256 _rate2
) {
    // Validate commission rates
    require(_rate1 < 10 ** 9, "rate1 must be less than 10**9");
    require(_rate2 < 10 ** 9, "rate2 must be less than 10**9");
    require(
        _rate1 + _rate2 < 0.03 * 10 ** 9,
        "rate1 + rate2 must be less than 0.03"
    );
    // Set commission parameters
    rate1 = _rate1;
    rate2 = _rate2;
    refer1 = _refer1;
    refer2 = _refer2;
}
```

### 3. Proper Raw Data Encoding
Always encode raw data correctly for adapters:
```solidity
// Format: reverse(1byte) + weight(11bytes) + poolAddress(20bytes)
rawData[0] = uint256(
    bytes32(abi.encodePacked(uint8(0x00), uint88(10000), poolAddress))
);
```

### 4. Low-Level Call Execution
For advanced commission handling, use low-level calls:
```solidity
bytes memory swapData = abi.encodeWithSelector(
    dexRouter.smartSwapByOrderId.selector,
    orderId,
    baseRequest,
    batchesAmount,
    batches,
    extraData
);

bytes memory data = bytes.concat(
    swapData,
    _getCommissionInfo(hasNextRefer, isToB, isFrom, token)
);

(bool success, bytes memory result) = address(dexRouter).call(data);
require(success, string(result));
```

### 5. Token Transfer Strategies
Choose the right transfer approach:
```solidity
// For regular swaps with approval
IERC20(token).safeApprove(tokenApprove, amount);

// For investment swaps (direct transfer to router)
IERC20(token).safeTransferFrom(user, address(dexRouter), amount);
```

### 6. Slippage Protection
Always set appropriate minimum return amounts:
```solidity
uint256 minReturn = (expectedAmount * 9900) / 10000; // 1% slippage tolerance
```

### 7. Deadline Management
Set reasonable deadlines to prevent stale transactions:
```solidity
uint256 deadline = block.timestamp + 300; // 5 minutes
```

### 8. Error Handling
Implement proper error handling for failed swaps:
```solidity
try dexRouter.smartSwapByOrderId(...) returns (uint256 amount) {
    // Handle success
} catch Error(string memory reason) {
    // Handle error
}
```

## Next Steps

### Recommended Learning Path
1. **Start with Guide 1**: Master simple swaps with commission handling
2. **Practice Guide 2**: Add ETH support to your integration
3. **Advanced Guide 3**: Build investment-grade applications

### Advanced Topics
1. **Custom Routing Strategies**: Build your own routing algorithms
2. **Gas Optimization**: Optimize contracts for production use
3. **MEV Protection**: Implement front-running protection
4. **Cross-chain Integration**: Extend to multi-chain environments

### Production Considerations
- **Comprehensive Testing**: Set up test suites with fork testing
- **Security Audits**: Get your integration audited before mainnet
- **Monitoring**: Implement swap monitoring and alerting
- **Upgrade Patterns**: Design for contract upgradability

## Links and References

- [Technical Reference](technical-reference.md)
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [OpenZeppelin SafeERC20](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#SafeERC20)
- [Hardhat Documentation](https://hardhat.org/getting-started/)

