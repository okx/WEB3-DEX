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
        // Step 1: Approve tokens for spending
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

        // Step 7: Execute the swap
        uint256 returnAmount = dexRouter.smartSwapByInvest(
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData,
            msg.sender
        );

        // returnAmount contains the actual tokens received
    }
}
