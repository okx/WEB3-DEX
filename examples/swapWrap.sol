import "../contracts/8/DexRouter.sol";
// import "../contracts/8/libraries/PMMLib.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SmartSwap {
    using SafeERC20 for IERC20;
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant _WETH =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
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

    function performTokenSwap(
        bool unwrap,
        uint256 amount,
        uint256 orderId
    ) external payable {
        if (unwrap) {
            // step1 : approve WETH
            IERC20(_WETH).safeApprove(tokenApprove, amount);
        }
        // step2 : encode rawData
        uint256 rawData = uint256(
            bytes32(
                abi.encodePacked(
                    uint8(unwrap ? 0x80 : 0x00),
                    uint120(0),
                    uint128(amount)
                )
            )
        );
        // Step 7: Execute the swap
        bytes memory swapData = abi.encodeWithSelector(
            dexRouter.swapWrap.selector,
            orderId,
            rawData
        );
        // Step 8: Execute the swap with commission
        bytes memory data = bytes.concat(
            swapData,
            _getCommissionInfo(true, true, true, unwrap ? _WETH : _ETH)
        );
        (bool s, bytes memory res) = address(dexRouter).call(data);
        require(s, string(res));
        // returnAmount contains the actual tokens received
    }
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
        return
            _hasNextRefer
                ? abi.encode(last, middle, first)
                : abi.encode(middle, first);
    }
}
