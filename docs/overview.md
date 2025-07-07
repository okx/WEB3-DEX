# WEB3-DEX Router Overview

## What is WEB3-DEX Router?

WEB3-DEX Router is a sophisticated DEX aggregation and routing system that enables optimal token swapping across multiple decentralized exchanges (DEXs) and protocols. It acts as a unified interface for executing complex multi-path swaps, providing users with the best possible rates by splitting orders across different liquidity sources.

## Architecture Overview

The WEB3-DEX Router follows a modular architecture designed for extensibility and gas optimization:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User/DApp     │───▶│   DexRouter.sol  │───▶│  Adapter Layer  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                         │
                              ▼                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │ Commission & ETH │    │ DEX Protocols   │
                       │    Management    │    │ (80+ Supported) │
                       └──────────────────┘    └─────────────────┘
```

## High-Level Components

### Core Router Contract
- **DexRouter.sol**: The main entry point contract that orchestrates all swap operations
- **Version**: v1.0.4-toB-commission
- **Features**: Smart routing, batch execution, commission handling, multi-protocol support

### Base Router Components
- **UnxswapRouter**: Handles Uniswap V2-style swaps with optimized routing
- **UnxswapV3Router**: Specialized for Uniswap V3 protocol interactions
- **WrapETHSwap**: Manages ETH/WETH wrapping and unwrapping operations
- **CommissionLib**: Implements commission fee collection and distribution

### Adapter Ecosystem
The router supports **80+ DEX protocols** through dedicated adapter contracts:

#### Major DEX Protocols
- **Uniswap**: V1, V2, V3 adapters
- **Pancakeswap**: V2 and V3 adapters
- **Curve**: Multiple curve variants (V2, StableNG, TNG, TriOpt)
- **Balancer**: V1, V2, and Composable adapters
- **1inch**: V1 and limit order adapters
- **DODO**: V1, V2, V3 adapters
- **SushiSwap**: Trident adapter
- **Kyber**: Classic and Elastic adapters

#### Specialized Protocols
- **Lending Protocols**: Aave V2/V3, Compound V2/V3
- **Yield Protocols**: Yearn, Pendle, Rocket Pool
- **Stablecoin Protocols**: Frax, DAI savings, stEUR
- **Cross-chain**: Multichain, Synapse
- **Derivatives**: GMX, Synthetix
- **Others**: 50+ additional protocols

### Support Libraries
- **SafeERC20**: Secure token transfers
- **UniversalERC20**: Unified ETH/ERC20 handling
- **TickMath**: Uniswap V3 mathematical operations
- **PMMLib**: Price-Making Market operations
- **CommonUtils**: Shared utility functions

## High-Level Functionality

### Smart Routing
- **Multi-path execution**: Split orders across multiple DEXs simultaneously
- **Batch processing**: Execute multiple swaps in a single transaction
- **Optimal pricing**: Find the best rates across all available liquidity sources
- **Slippage protection**: Configurable minimum return amounts

### Order Management
- **Order ID tracking**: Unique identifiers for swap operations
- **Deadline enforcement**: Time-based order expiration
- **Refund handling**: Automated refund of unused tokens
- **Commission integration**: Built-in fee collection system

### Advanced Features
- **Investment swaps**: Specialized swaps for investment contracts
- **Native token handling**: Seamless ETH/WETH conversion
- **Emergency controls**: Admin functions for system management
- **Gas optimization**: Efficient batch execution and path optimization

### Supported Swap Types
1. **Simple swaps**: Direct token-to-token exchanges
2. **Multi-hop swaps**: Complex routing through multiple protocols
3. **Split swaps**: Divide orders across multiple paths
4. **Investment swaps**: Specialized for investment contract integration

## Source Code Location

### Repository Structure
```
WEB3-DEX/
├── contracts/8/
│   ├── DexRouter.sol          # Main router contract
│   ├── UnxswapRouter.sol      # Uniswap V2 router
│   ├── UnxswapV3Router.sol    # Uniswap V3 router
│   ├── adapter/               # 80+ DEX adapters
│   │   ├── UniV3Adapter.sol
│   │   ├── PancakeswapV3Adapter.sol
│   │   ├── CurveAdapter.sol
│   │   └── ...
│   ├── interfaces/            # Protocol interfaces
│   ├── libraries/             # Utility libraries
│   └── utils/                 # Utility contracts
├── hardhat.config.js          # Hardhat configuration
└── package.json               # Dependencies
```

### Key Files
- **Main Contract**: `contracts/8/DexRouter.sol`
- **Adapter Interfaces**: `contracts/8/interfaces/IAdapter.sol`
- **Commission Logic**: `contracts/8/libraries/CommissionLib.sol`
- **Utility Libraries**: `contracts/8/libraries/CommonUtils.sol`

## Integration Guide

### Contract Deployment
The router system consists of multiple contracts that need to be deployed in sequence:

1. **Library contracts**: Deploy utility and commission libraries
2. **Adapter contracts**: Deploy protocol-specific adapters
3. **Main router**: Deploy the DexRouter with all dependencies
4. **Configuration**: Set up adapter addresses and system parameters

### Prerequisites
- **Solidity**: Version 0.8.17
- **Framework**: Hardhat development environment
- **Dependencies**: See `package.json` for required packages

### Contract Addresses
Integration requires the following contract addresses:
- **DexRouter**: Main router contract address
- **ApproveProxy**: Token approval proxy contract
- **WNativeRelayer**: Native token wrapper contract
- **Adapter contracts**: Addresses for each supported DEX
- **Utility contracts**: Helper contracts for token handling

### Code Artifacts and Distribution
Currently, the WEB3-DEX Router is distributed as smart contract source code:
- **Source Code**: Available in this repository
- **Contract Deployments**: Deploy contracts to your target networks
- **No NPM Package**: This is a smart contract system, not a JavaScript library
- **Integration**: Direct smart contract interaction or ABI integration

### Integration Steps
1. **Install dependencies**: `npm install`
2. **Deploy contracts**: Use Hardhat deployment scripts
3. **Configure adapters**: Set up adapter contracts for desired DEXs
4. **Set permissions**: Configure admin and priority addresses
5. **Test integration**: Verify swap functionality

### Development Setup
```bash
# Clone the repository
git clone <repository-url>
cd WEB3-DEX

# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to network
npx hardhat run scripts/deploy.js --network <network-name>
```

## Network Support

The router system is designed to work across multiple EVM-compatible networks:
- **Ethereum Mainnet**
- **Binance Smart Chain**
- **Polygon**
- **Arbitrum**
- **Avalanche**
- **And other EVM chains**

## Security Features

- **Deadline checks**: All swaps must complete before specified deadlines
- **Minimum return enforcement**: Slippage protection on all trades
- **Access controls**: Admin functions for system management
- **Secure token handling**: Using OpenZeppelin's SafeERC20
- **Reentrancy protection**: Built-in protection against reentrancy attacks

