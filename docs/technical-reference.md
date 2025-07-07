# WEB3-DEX Router Technical Reference

## Contract Overview

The WEB3-DEX Router is a sophisticated smart contract system that provides DEX aggregation and optimal routing capabilities. This document provides complete technical specifications for all exported interfaces and functions.

> **📝 Auto-Generated Documentation**: This technical reference is automatically generated from Solidity NatSpec comments in the source code using `solidity-docgen`. For the most up-to-date information, refer to the source contracts.

### Main Contract
- **Name**: DexRouter
- **Version**: v1.0.4-toB-commission
- **Solidity Version**: 0.8.17
- **License**: MIT

## Core Interfaces

### BaseRequest Structure
```solidity
struct BaseRequest {
    uint256 fromToken;        // Source token (address encoded as uint256)
    address toToken;          // Destination token address
    uint256 fromTokenAmount;  // Amount of source token to swap
    uint256 minReturnAmount;  // Minimum amount of destination token to receive
    uint256 deadLine;         // UNIX timestamp deadline for the swap
}
```

### RouterPath Structure
```solidity
struct RouterPath {
    address[] mixAdapters;    // Array of adapter contract addresses
    address[] assetTo;        // Array of intermediate token addresses
    uint256[] rawData;        // Array of encoded routing data
    bytes[] extraData;        // Array of additional data for adapters
    uint256 fromToken;        // Source token (address encoded as uint256)
}
```

## Public Functions

### Smart Swap Functions

#### `smartSwapByOrderId`
Executes a smart swap based on the given order ID, supporting complex multi-path swaps.

```solidity
function smartSwapByOrderId(
    uint256 orderId,
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `orderId` (uint256): Unique identifier for the swap order
- `baseRequest` (BaseRequest): Base parameters for the swap
- `batchesAmount` (uint256[]): Array of amounts for each batch
- `batches` (RouterPath[][]): Array of routing paths for each batch
- `extraData` (PMMLib.PMMSwapRequest[]): Additional PMM swap data

**Returns:**
- `returnAmount` (uint256): Total amount of destination tokens received

**Modifiers:**
- `payable`: Can receive ETH for ETH swaps
- `isExpired(baseRequest.deadLine)`: Validates deadline

**Events:**
- `SwapOrderId(orderId)`: Emitted when swap starts
- `OrderRecord(fromToken, toToken, origin, fromAmount, returnAmount)`: Emitted when swap completes

#### `smartSwapTo`
Executes a smart swap directly to a specified receiver address.

```solidity
function smartSwapTo(
    uint256 orderId,
    address receiver,
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `orderId` (uint256): Unique identifier for the swap order
- `receiver` (address): Address to receive the output tokens
- `baseRequest` (BaseRequest): Base parameters for the swap
- `batchesAmount` (uint256[]): Array of amounts for each batch
- `batches` (RouterPath[][]): Array of routing paths for each batch
- `extraData` (PMMLib.PMMSwapRequest[]): Additional PMM swap data

**Returns:**
- `returnAmount` (uint256): Total amount of destination tokens received

**Requirements:**
- `receiver` must not be address(0)
- Deadline must not be expired

#### `smartSwapByInvest`
Executes a swap tailored for investment purposes, adjusting swap amounts based on the contract's balance.

```solidity
function smartSwapByInvest(
    BaseRequest memory baseRequest,
    uint256[] memory batchesAmount,
    RouterPath[][] memory batches,
    PMMLib.PMMSwapRequest[] memory extraData,
    address to
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `baseRequest` (BaseRequest): Base parameters for the swap
- `batchesAmount` (uint256[]): Array of amounts for each batch
- `batches` (RouterPath[][]): Array of routing paths for each batch
- `extraData` (PMMLib.PMMSwapRequest[]): Additional PMM swap data
- `to` (address): Address where swapped tokens will be sent

**Returns:**
- `returnAmount` (uint256): Total amount of destination tokens received

**Special Features:**
- Automatically adjusts batch amounts based on contract balance
- Designed for investment contract integration

#### `smartSwapByInvestWithRefund`
Enhanced investment swap with separate refund address.

```solidity
function smartSwapByInvestWithRefund(
    BaseRequest memory baseRequest,
    uint256[] memory batchesAmount,
    RouterPath[][] memory batches,
    PMMLib.PMMSwapRequest[] memory extraData,
    address to,
    address refundTo
) public payable returns (uint256 returnAmount)
```

**Parameters:**
- `baseRequest` (BaseRequest): Base parameters for the swap
- `batchesAmount` (uint256[]): Array of amounts for each batch
- `batches` (RouterPath[][]): Array of routing paths for each batch
- `extraData` (PMMLib.PMMSwapRequest[]): Additional PMM swap data
- `to` (address): Address where swapped tokens will be sent
- `refundTo` (address): Address for refunding unused tokens

**Returns:**
- `returnAmount` (uint256): Total amount of destination tokens received

**Requirements:**
- `fromToken` must not be ETH (address(0))
- `refundTo` must not be address(0)
- `to` must not be address(0)
- `fromTokenAmount` must be greater than 0

### Unxswap Functions

#### `unxswapByOrderId`
Executes a token swap using the Unxswap protocol based on a specified order ID.

```solidity
function unxswapByOrderId(
    uint256 srcToken,
    uint256 amount,
    uint256 minReturn,
    bytes32[] calldata pools
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `srcToken` (uint256): Source token (address encoded with order ID)
- `amount` (uint256): Amount of source token to swap
- `minReturn` (uint256): Minimum amount of tokens expected to receive
- `pools` (bytes32[]): Array of pool identifiers for routing

**Returns:**
- `returnAmount` (uint256): Amount of destination tokens received

**Features:**
- Automatically extracts order ID from `srcToken` parameter
- Optimized for Uniswap V2-style pools

#### `unxswapTo`
Executes a token swap using the Unxswap protocol, sending output to a specified receiver.

```solidity
function unxswapTo(
    uint256 srcToken,
    uint256 amount,
    uint256 minReturn,
    address receiver,
    bytes32[] calldata pools
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `srcToken` (uint256): Source token (address encoded with order ID)
- `amount` (uint256): Amount of source token to swap
- `minReturn` (uint256): Minimum amount of tokens expected to receive
- `receiver` (address): Address to receive the output tokens
- `pools` (bytes32[]): Array of pool identifiers for routing

**Returns:**
- `returnAmount` (uint256): Amount of destination tokens received

**Requirements:**
- `receiver` must not be address(0)

### Uniswap V3 Functions

#### `uniswapV3SwapTo`
Executes a swap using the Uniswap V3 protocol.

```solidity
function uniswapV3SwapTo(
    uint256 receiver,
    uint256 amount,
    uint256 minReturn,
    uint256[] calldata pools
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `receiver` (uint256): Receiver address (encoded with order ID)
- `amount` (uint256): Amount of source token to swap
- `minReturn` (uint256): Minimum amount of tokens to receive
- `pools` (uint256[]): Array of pool identifiers for V3 routing

**Returns:**
- `returnAmount` (uint256): Amount of tokens received after swap

**Features:**
- Handles ETH/WETH wrapping automatically
- Supports complex multi-hop V3 routes
- Integrated commission handling

## Internal Functions

### `_smartSwapInternal`
Core internal function that executes the smart swap logic.

```solidity
function _smartSwapInternal(
    BaseRequest memory baseRequest,
    uint256[] memory batchesAmount,
    RouterPath[][] memory batches,
    address payer,
    address refundTo,
    address receiver
) private returns (uint256 returnAmount)
```

**Parameters:**
- `baseRequest` (BaseRequest): Base swap parameters
- `batchesAmount` (uint256[]): Batch amounts
- `batches` (RouterPath[][]): Routing paths
- `payer` (address): Address providing tokens
- `refundTo` (address): Address for refunds
- `receiver` (address): Address receiving tokens

**Returns:**
- `returnAmount` (uint256): Total tokens received

### `_exeHop`
Executes a series of swaps across multiple hops.

```solidity
function _exeHop(
    address payer,
    address refundTo,
    address receiver,
    bool isToNative,
    uint256 batchAmount,
    RouterPath[] memory hops
) private
```

**Parameters:**
- `payer` (address): Address providing tokens
- `refundTo` (address): Address for refunds
- `receiver` (address): Address receiving tokens
- `isToNative` (bool): Whether to convert to native ETH
- `batchAmount` (uint256): Amount to swap
- `hops` (RouterPath[]): Array of hop routes

### `_exeForks`
Executes multiple adapters for a transaction pair.

```solidity
function _exeForks(
    address payer,
    address refundTo,
    address to,
    uint256 batchAmount,
    RouterPath memory path,
    bool noTransfer
) private
```

**Parameters:**
- `payer` (address): Address providing tokens
- `refundTo` (address): Address for refunds
- `to` (address): Address receiving tokens
- `batchAmount` (uint256): Amount to transfer
- `path` (RouterPath): Routing path
- `noTransfer` (bool): Whether to skip token transfer

### `_exeAdapter`
Executes a single adapter call.

```solidity
function _exeAdapter(
    bool reverse,
    address adapter,
    address to,
    address poolAddress,
    bytes memory moreinfo,
    address refundTo
) internal
```

**Parameters:**
- `reverse` (bool): Whether to call sellQuote or sellBase
- `adapter` (address): Adapter contract address
- `to` (address): Recipient address
- `poolAddress` (address): Pool contract address
- `moreinfo` (bytes): Additional data for adapter
- `refundTo` (address): Address for refunds

## Utility Functions

### `_transferInternal`
Handles internal token transfers.

```solidity
function _transferInternal(
    address payer,
    address to,
    address token,
    uint256 amount
) private
```

**Parameters:**
- `payer` (address): Address providing tokens
- `to` (address): Address receiving tokens
- `token` (address): Token contract address
- `amount` (uint256): Amount to transfer

### `_transferTokenToUser`
Transfers tokens to user with ETH/WETH handling.

```solidity
function _transferTokenToUser(address token, address to) private
```

**Parameters:**
- `token` (address): Token contract address
- `to` (address): Address receiving tokens

**Features:**
- Automatically unwraps WETH to ETH when needed
- Handles both ERC20 and native token transfers

### `_bytes32ToAddress`
Converts uint256 to address.

```solidity
function _bytes32ToAddress(uint256 param) private pure returns (address result)
```

**Parameters:**
- `param` (uint256): Value to convert

**Returns:**
- `result` (address): Extracted address

## Events

### `SwapOrderId`
Emitted when a swap operation starts.

```solidity
event SwapOrderId(uint256 orderId);
```

**Parameters:**
- `orderId` (uint256): Unique identifier for the swap

### `OrderRecord`
Emitted when a swap operation completes.

```solidity
event OrderRecord(
    address indexed fromToken,
    address indexed toToken,
    address indexed origin,
    uint256 fromAmount,
    uint256 returnAmount
);
```

**Parameters:**
- `fromToken` (address): Source token address
- `toToken` (address): Destination token address
- `origin` (address): Transaction origin address
- `fromAmount` (uint256): Amount of source token
- `returnAmount` (uint256): Amount of destination token received

## Error Codes

### Common Errors
- `"Route: expired"`: Swap deadline has passed
- `"Route: fromTokenAmount must be > 0"`: Invalid input amount
- `"Route: number of batches should be <= fromTokenAmount"`: Invalid batch configuration
- `"length mismatch"`: Array length mismatch
- `"Min return not reached"`: Insufficient output amount
- `"not addr(0)"`: Invalid zero address
- `"totalWeight can not exceed 10000 limit"`: Invalid weight configuration
- `"transfer native token failed"`: ETH transfer failed

### Investment-Specific Errors
- `"Invalid source token"`: ETH not allowed for investment swaps
- `"refundTo is address(0)"`: Invalid refund address
- `"to is address(0)"`: Invalid recipient address
- `"fromTokenAmount is 0"`: Invalid input amount

## Constants

### Address Masks
```solidity
uint256 private constant _ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
uint256 private constant _REVERSE_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
uint256 private constant _WEIGHT_MASK = 0x00000000000000000000000000000000000000000000000000000000ffffffff;
uint256 private constant _ORDER_ID_MASK = 0x0000000000000000000000000000000000000000000000000000000000000000;
uint256 private constant _ONE_FOR_ZERO_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
```

### System Constants
```solidity
uint256 private constant _DENOMINATOR = 1_000_000_000;
uint256 private constant _NUMERATOR_OFFSET = 160;
address private constant _ETH = address(0);
```

## Commission System

### CommissionInfo Structure
```solidity
struct CommissionInfo {
    uint256 rate;           // Commission rate in basis points
    address receiver;       // Address to receive commission
    bool enabled;          // Whether commission is enabled
}
```

### Commission Functions
The router includes built-in commission handling:

- `_getCommissionInfo()`: Gets current commission configuration
- `_doCommissionFromToken()`: Handles commission on input token
- `_doCommissionToToken()`: Handles commission on output token

## Security Features

### Access Control
- Deadline validation on all swap functions
- Zero address checks for critical parameters
- Overflow protection using SafeMath operations

### Slippage Protection
- Minimum return amount validation
- Automatic slippage calculation
- Deadline enforcement

### Reentrancy Protection
- Built-in reentrancy guards
- Secure external calls
- State updates before external calls

## Gas Optimization

### Batch Operations
- Multiple swaps in single transaction
- Optimized loop structures
- Efficient memory management

### Assembly Optimizations
- Low-level address extraction
- Optimized bit operations
- Efficient data packing

## Integration Examples

### Basic Integration
```solidity
// Initialize router
IDexRouter router = IDexRouter(routerAddress);

// Prepare swap request
BaseRequest memory request = BaseRequest({
    fromToken: uint256(uint160(tokenA)),
    toToken: tokenB,
    fromTokenAmount: amount,
    minReturnAmount: minReturn,
    deadLine: block.timestamp + 300
});

// Execute swap
uint256 result = router.smartSwapByOrderId(
    orderId,
    request,
    batchAmounts,
    batches,
    extraData
);
```

### Advanced Integration
```solidity
// Multi-path swap configuration
RouterPath[][] memory batches = new RouterPath[][](2);
batches[0] = uniswapPath;
batches[1] = curvePath;

uint256[] memory batchAmounts = new uint256[](2);
batchAmounts[0] = amount / 2;
batchAmounts[1] = amount / 2;

// Execute with custom receiver
uint256 result = router.smartSwapTo(
    orderId,
    receiver,
    request,
    batchAmounts,
    batches,
    extraData
);
```

## Version Information

- **Current Version**: v1.0.4-toB-commission
- **Solidity Version**: 0.8.17
- **License**: MIT
- **Last Updated**: Current deployment

## Support and Documentation

For additional information and support:
- **Overview**: [overview.md](overview.md)
- **Implementation Guides**: [guides.md](guides.md)
- **Source Code**: Available in the repository
- **Community**: Developer support channels 