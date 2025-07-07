# WEB3-DEX Router Implementation Guides

## Getting Started

These guides will help you implement token swapping functionality using the WEB3-DEX Router system. Each guide is designed to be completed within 10 minutes and provides working code examples.

**💡 Complete Code Examples**: All code examples in these guides are available in our [example repository](https://github.com/WEB3-DEX/examples) for easy copy-paste implementation.

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

## Guide 1: Simple Token Swap

### Introduction
This guide demonstrates how to execute a basic token swap using the DexRouter. You'll learn to swap one ERC20 token for another using the optimal routing provided by the aggregator.

### What You'll Build
A simple swap function that exchanges USDC for DAI with slippage protection.

### Implementation

**Step 1: Contract Setup**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IDexRouter {
    struct BaseRequest {
        uint256 fromToken;
        address toToken;
        uint256 fromTokenAmount;
        uint256 minReturnAmount;
        uint256 deadLine;
    }
    
    struct RouterPath {
        address[] mixAdapters;
        address[] assetTo;
        uint256[] rawData;
        bytes[] extraData;
        uint256 fromToken;
    }
    
    function smartSwapByOrderId(
        uint256 orderId,
        BaseRequest calldata baseRequest,
        uint256[] calldata batchesAmount,
        RouterPath[][] calldata batches,
        bytes[] calldata extraData
    ) external payable returns (uint256 returnAmount);
}

contract SimpleSwapExample {
    using SafeERC20 for IERC20;
    
    IDexRouter public immutable dexRouter;
    
    constructor(address _dexRouter) {
        dexRouter = IDexRouter(_dexRouter);
    }
}
```

**Step 2: Implement Swap Function**
```solidity
function swapTokens(
    address fromToken,
    address toToken,
    uint256 amount,
    uint256 minReturn,
    uint256 deadline
) external returns (uint256 returnAmount) {
    // Transfer tokens from user to this contract
    IERC20(fromToken).safeTransferFrom(msg.sender, address(this), amount);
    
    // Approve the router to spend tokens
    IERC20(fromToken).safeApprove(address(dexRouter), amount);
    
    // Prepare swap parameters
    IDexRouter.BaseRequest memory request = IDexRouter.BaseRequest({
        fromToken: uint256(uint160(fromToken)),
        toToken: toToken,
        fromTokenAmount: amount,
        minReturnAmount: minReturn,
        deadLine: deadline
    });
    
    // Simple single-path swap
    uint256[] memory batchAmounts = new uint256[](1);
    batchAmounts[0] = amount;
    
    // Execute the swap
    returnAmount = dexRouter.smartSwapByOrderId(
        0, // orderId
        request,
        batchAmounts,
        new IDexRouter.RouterPath[][](0), // Will be populated by router
        new bytes[](0) // extraData
    );
    
    // Transfer result tokens to user
    IERC20(toToken).safeTransfer(msg.sender, returnAmount);
}
```

**Step 3: Usage Example**
```solidity
// Deploy the contract
SimpleSwapExample swapper = new SimpleSwapExample(dexRouterAddress);

// Execute a swap
uint256 usdcAmount = 1000 * 1e6; // 1000 USDC
uint256 minDaiReturn = 990 * 1e18; // Minimum 990 DAI (1% slippage)
uint256 deadline = block.timestamp + 300; // 5 minutes

uint256 daiReceived = swapper.swapTokens(
    usdcAddress,
    daiAddress,
    usdcAmount,
    minDaiReturn,
    deadline
);
```

### Expected Output
- Input: 1000 USDC
- Output: ~1000 DAI (minus fees and slippage)
- Gas: ~150,000 gas units

**📁 Complete Example**: View the [complete SimpleSwap example](https://github.com/WEB3-DEX/examples/tree/main/simple-swap) in our repository.

---

## Guide 2: Multi-Path Swap with Batch Execution

### Introduction
This guide shows how to split a large order across multiple DEXs to minimize price impact and get better rates. The router will automatically distribute your order across the best available liquidity sources.

### What You'll Build
A batch swap function that splits a large order across multiple protocols for optimal pricing.

### Implementation

**Step 1: Multi-Path Swap Contract**
```solidity
contract MultiPathSwapExample {
    using SafeERC20 for IERC20;
    
    IDexRouter public immutable dexRouter;
    
    constructor(address _dexRouter) {
        dexRouter = IDexRouter(_dexRouter);
    }
    
    function executeMultiPathSwap(
        address fromToken,
        address toToken,
        uint256 totalAmount,
        uint256 minReturn,
        uint256 deadline,
        uint256[] calldata batchWeights,
        address[] calldata adapters,
        bytes[] calldata routingData
    ) external returns (uint256 returnAmount) {
        // Transfer tokens from user
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), totalAmount);
        IERC20(fromToken).safeApprove(address(dexRouter), totalAmount);
        
        // Prepare base request
        IDexRouter.BaseRequest memory request = IDexRouter.BaseRequest({
            fromToken: uint256(uint160(fromToken)),
            toToken: toToken,
            fromTokenAmount: totalAmount,
            minReturnAmount: minReturn,
            deadLine: deadline
        });
        
        // Calculate batch amounts based on weights
        uint256[] memory batchAmounts = new uint256[](batchWeights.length);
        for (uint256 i = 0; i < batchWeights.length; i++) {
            batchAmounts[i] = (totalAmount * batchWeights[i]) / 10000; // weights in basis points
        }
        
        // Prepare routing paths
        IDexRouter.RouterPath[][] memory batches = new IDexRouter.RouterPath[][](batchWeights.length);
        for (uint256 i = 0; i < batchWeights.length; i++) {
            batches[i] = new IDexRouter.RouterPath[](1);
            batches[i][0] = IDexRouter.RouterPath({
                mixAdapters: _toArray(adapters[i]),
                assetTo: _toArray(address(this)),
                rawData: new uint256[](1),
                extraData: _toArray(routingData[i]),
                fromToken: uint256(uint160(fromToken))
            });
        }
        
        // Execute multi-path swap
        returnAmount = dexRouter.smartSwapByOrderId(
            1, // orderId
            request,
            batchAmounts,
            batches,
            new bytes[](0)
        );
        
        // Transfer result to user
        IERC20(toToken).safeTransfer(msg.sender, returnAmount);
    }
    
    function _toArray(address item) private pure returns (address[] memory) {
        address[] memory array = new address[](1);
        array[0] = item;
        return array;
    }
    
    function _toArray(bytes calldata item) private pure returns (bytes[] memory) {
        bytes[] memory array = new bytes[](1);
        array[0] = item;
        return array;
    }
}
```

**Step 2: Usage Example**
```solidity
// Deploy the contract
MultiPathSwapExample multiSwapper = new MultiPathSwapExample(dexRouterAddress);

// Prepare batch parameters
uint256[] memory weights = new uint256[](3);
weights[0] = 4000; // 40% to Uniswap V3
weights[1] = 3500; // 35% to Curve
weights[2] = 2500; // 25% to Balancer

address[] memory adapters = new address[](3);
adapters[0] = uniV3AdapterAddress;
adapters[1] = curveAdapterAddress;
adapters[2] = balancerAdapterAddress;

bytes[] memory routingData = new bytes[](3);
routingData[0] = abi.encode(uniV3PoolAddress, 3000); // 0.3% fee tier
routingData[1] = abi.encode(curvePoolAddress, 0);
routingData[2] = abi.encode(balancerPoolAddress, balancerPoolId);

// Execute multi-path swap
uint256 ethAmount = 10 ether;
uint256 minUsdcReturn = 29000 * 1e6; // Minimum 29,000 USDC

uint256 usdcReceived = multiSwapper.executeMultiPathSwap(
    address(0), // ETH
    usdcAddress,
    ethAmount,
    minUsdcReturn,
    block.timestamp + 300,
    weights,
    adapters,
    routingData
);
```

### Expected Output
- Input: 10 ETH
- Output: ~30,000 USDC distributed across 3 DEXs
- Gas: ~400,000 gas units

**📁 Complete Example**: View the [complete MultiPath example](https://github.com/WEB3-DEX/examples/tree/main/multi-path-swap) in our repository.

---

## Guide 3: ETH/WETH Swap with Native Token Handling

### Introduction
This guide demonstrates how to handle native ETH swaps using the router's built-in ETH/WETH conversion capabilities. The router automatically manages wrapping and unwrapping as needed.

### What You'll Build
A contract that can swap ETH for tokens and tokens for ETH seamlessly.

### Implementation

**Step 1: ETH Swap Contract**
```solidity
contract ETHSwapExample {
    using SafeERC20 for IERC20;
    
    IDexRouter public immutable dexRouter;
    address public constant ETH_ADDRESS = address(0);
    
    constructor(address _dexRouter) {
        dexRouter = IDexRouter(_dexRouter);
    }
    
    // Swap ETH for tokens
    function swapETHForTokens(
        address toToken,
        uint256 minReturn,
        uint256 deadline
    ) external payable returns (uint256 returnAmount) {
        require(msg.value > 0, "Must send ETH");
        
        IDexRouter.BaseRequest memory request = IDexRouter.BaseRequest({
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
            new IDexRouter.RouterPath[][](0),
            new bytes[](0)
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
        
        IDexRouter.BaseRequest memory request = IDexRouter.BaseRequest({
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
            new IDexRouter.RouterPath[][](0),
            new bytes[](0)
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

**📁 Complete Example**: View the [complete ETH Swap example](https://github.com/WEB3-DEX/examples/tree/main/eth-swap) in our repository.

---

## Guide 4: Investment Contract Integration

### Introduction
This guide shows how to integrate the router with investment contracts, allowing for automated rebalancing and portfolio management using the specialized investment swap functions.

### What You'll Build
An investment contract that can automatically rebalance a portfolio by swapping tokens based on target allocations.

### Implementation

**Step 1: Investment Contract**
```solidity
contract InvestmentPortfolio {
    using SafeERC20 for IERC20;
    
    IDexRouter public immutable dexRouter;
    address public owner;
    
    struct Asset {
        address token;
        uint256 targetAllocation; // In basis points (10000 = 100%)
    }
    
    Asset[] public assets;
    mapping(address => bool) public allowedTokens;
    
    constructor(address _dexRouter) {
        dexRouter = IDexRouter(_dexRouter);
        owner = msg.sender;
    }
    
    function addAsset(address token, uint256 targetAllocation) external {
        require(msg.sender == owner, "Only owner");
        assets.push(Asset(token, targetAllocation));
        allowedTokens[token] = true;
    }
    
    function rebalancePortfolio(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        uint256 deadline
    ) external returns (uint256 returnAmount) {
        require(allowedTokens[fromToken] && allowedTokens[toToken], "Token not allowed");
        
        // Transfer tokens to this contract
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), amount);
        
        // Approve router to spend our tokens
        IERC20(fromToken).safeApprove(address(dexRouter), amount);
        
        // Prepare investment swap request
        IDexRouter.BaseRequest memory request = IDexRouter.BaseRequest({
            fromToken: uint256(uint160(fromToken)),
            toToken: toToken,
            fromTokenAmount: amount,
            minReturnAmount: minReturn,
            deadLine: deadline
        });
        
        // Use investment swap function
        uint256[] memory batchAmounts = new uint256[](1);
        batchAmounts[0] = amount;
        
        returnAmount = dexRouter.smartSwapByInvest(
            request,
            batchAmounts,
            new IDexRouter.RouterPath[][](0),
            new bytes[](0),
            address(this) // Tokens stay in contract
        );
        
        emit Rebalanced(fromToken, toToken, amount, returnAmount);
    }
    
    function getPortfolioValue() external view returns (uint256 totalValue) {
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 balance = IERC20(assets[i].token).balanceOf(address(this));
            totalValue += balance; // Simplified - would need price oracle in real implementation
        }
    }
    
    event Rebalanced(address indexed from, address indexed to, uint256 amountIn, uint256 amountOut);
}
```

**Step 2: Usage Example**
```solidity
// Deploy investment contract
InvestmentPortfolio portfolio = new InvestmentPortfolio(dexRouterAddress);

// Add assets to portfolio
portfolio.addAsset(usdcAddress, 4000); // 40% USDC
portfolio.addAsset(daiAddress, 3000);  // 30% DAI
portfolio.addAsset(wethAddress, 3000); // 30% WETH

// Rebalance: swap excess USDC for DAI
uint256 daiReceived = portfolio.rebalancePortfolio(
    usdcAddress,
    daiAddress,
    5000 * 1e6, // 5000 USDC
    4950 * 1e18, // Min 4950 DAI
    block.timestamp + 300
);
```

### Expected Output
- Automatic portfolio rebalancing
- Tokens remain in investment contract
- Gas: ~250,000 gas units

**📁 Complete Example**: View the [complete Investment Integration example](https://github.com/WEB3-DEX/examples/tree/main/investment-portfolio) in our repository.

---

## Common Patterns and Best Practices

### 1. Slippage Protection
Always set appropriate minimum return amounts:
```solidity
uint256 minReturn = (expectedAmount * 9900) / 10000; // 1% slippage tolerance
```

### 2. Deadline Management
Set reasonable deadlines to prevent stale transactions:
```solidity
uint256 deadline = block.timestamp + 300; // 5 minutes
```

### 3. Token Approval
Always approve the exact amount needed:
```solidity
IERC20(token).safeApprove(address(dexRouter), amount);
```

### 4. Error Handling
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
1. **Start with Guide 1**: Master simple swaps before moving to complex routing
2. **Practice Guide 2**: Learn batch execution for better price discovery
3. **Implement Guide 3**: Add ETH support to your integration
4. **Advanced Guide 4**: Build investment-grade applications

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

