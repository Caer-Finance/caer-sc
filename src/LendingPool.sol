// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IInterchainGasPaymaster} from "@hyperlane-xyz/interfaces/IInterchainGasPaymaster.sol";

import {IFactory} from "./interfaces/IFactory.sol";
import {IPosition} from "./interfaces/IPosition.sol";

import {ICaerBridgeTokenSender} from "./interfaces/ICaerBridgeTokenSender.sol";
import {IHelperTestnet} from "./interfaces/IHelperTestnet.sol";
import {ILPRouter} from "./interfaces/ILPRouter.sol";
import {IBridgeRouter} from "./interfaces/IBridgeRouter.sol";
import {ILPRouterDeployer} from "./interfaces/ILPRouterDeployer.sol";

// TODO: Mint Token
contract LendingPool is ReentrancyGuard {
    using SafeERC20 for IERC20;

    error InsufficientCollateral();
    error InsufficientLiquidity();
    error InsufficientShares();
    error LTVExceedMaxAmount();
    error PositionAlreadyCreated();
    error TokenNotAvailable();
    error ZeroAmount();
    error InsufficientBorrowShares();
    error amountSharesInvalid();

    event SupplyLiquidity(address indexed user, uint256 amount, uint256 shares);
    event WithdrawLiquidity(address indexed user, uint256 amount, uint256 shares);
    event SupplyCollateral(address indexed user, uint256 amount);
    event RepayWithCollateralByPosition(address indexed user, uint256 amount, uint256 shares);
    event CreatePosition(address indexed user, address indexed positionAddress);
    event BorrowDebtCrosschain(
        address indexed user, uint256 amount, uint256 userAmount, uint256 shares, uint256 chainId
    );

    address public factory;
    address public router;
    address public protocol;

    constructor(address _collateralToken, address _borrowToken, address _factory, address _protocol, uint256 _ltv) {
        address lendingPoolRouterDeployer = IFactory(factory).lendingPoolRouterDeployer();
        router = ILPRouterDeployer(lendingPoolRouterDeployer).deployLendingPoolRouter(
            address(this), _factory, _collateralToken, _borrowToken, _ltv
        );
        factory = _factory;
        protocol = _protocol;
    }

    modifier positionRequired() {
        _positionRequired();
        _;
    }

    modifier updateInterest() {
        _updateInterest();
        _;
    }

    function _updateInterest() internal {
        ILPRouter(router).accrueInterest();
    }

    function _positionRequired() internal {
        if (ILPRouter(router).addressPositions(msg.sender) == address(0)) {
            createPosition();
        }
    }

    /**
     *
     *     _________    __________
     *    / ____/   |  / ____/ __ \
     *   / /   / /| | / __/ / /_/ /
     *  / /___/ ___ |/ /___/ _, _/
     *  \____/_/  |_/_____/_/ |_|
     */

    /**
     * @notice Creates a new Position contract for the caller if one does not already exist.
     * @dev Each user can have only one Position contract. The Position contract manages collateral and borrowed assets for the user.
     * @custom:throws PositionAlreadyCreated if the caller already has a Position contract.
     * @custom:emits CreatePosition when a new Position is created.
     */
    function createPosition() public {
        address position = ILPRouter(router).createPosition(msg.sender);
        emit CreatePosition(msg.sender, position);
    }

    /**
     * @notice Supply liquidity to the lending pool by depositing borrow tokens.
     * @dev Users receive shares proportional to their deposit. Shares represent ownership in the pool. Accrues interest before deposit.
     * @param _amount The amount of borrow tokens to supply as liquidity.
     * @custom:throws ZeroAmount if amount is 0.
     * @custom:emits SupplyLiquidity when liquidity is supplied.
     */
    function supplyLiquidity(uint256 _amount) public nonReentrant updateInterest {
        if (_amount == 0) revert ZeroAmount();
        uint256 shares = ILPRouter(router).supplyLiquidity(_amount, msg.sender);
        IERC20(ILPRouter(router).borrowToken()).safeTransferFrom(msg.sender, address(this), _amount);
        emit SupplyLiquidity(msg.sender, _amount, shares);
    }

    /**
     * @notice Withdraw supplied liquidity by redeeming shares for underlying tokens.
     * @dev Calculates the corresponding asset amount based on the proportion of total shares. Accrues interest before withdrawal.
     * @param _shares The number of supply shares to redeem for underlying tokens.
     * @custom:throws ZeroAmount if _shares is 0.
     * @custom:throws InsufficientShares if user does not have enough shares.
     * @custom:throws InsufficientLiquidity if protocol lacks liquidity after withdrawal.
     * @custom:emits WithdrawLiquidity when liquidity is withdrawn.
     */
    function withdrawLiquidity(uint256 _shares) public nonReentrant updateInterest {
        if (_shares == 0) revert ZeroAmount();
        if (_shares > ILPRouter(router).userSupplyShares(msg.sender)) revert InsufficientShares();
        uint256 amount = ILPRouter(router).withdrawLiquidity(_shares, msg.sender);
        IERC20(ILPRouter(router).borrowToken()).safeTransfer(msg.sender, amount);
        emit WithdrawLiquidity(msg.sender, amount, _shares);
    }

    /**
     * @notice Supply collateral tokens to the user's position in the lending pool.
     * @dev Transfers collateral tokens from user to their Position contract. Accrues interest before deposit.
     * @param _amount The amount of collateral tokens to supply.
     * @custom:throws ZeroAmount if amount is 0.
     * @custom:emits SupplyCollateral when collateral is supplied.
     */
    function supplyCollateral(uint256 _amount) public positionRequired nonReentrant updateInterest {
        if (_amount == 0) revert ZeroAmount();
        IERC20(ILPRouter(router).collateralToken()).safeTransferFrom(
            msg.sender, ILPRouter(router).addressPositions(msg.sender), _amount
        );
        emit SupplyCollateral(msg.sender, _amount);
    }

    /**
     * @notice Withdraw supplied collateral from the user's position.
     * @dev Transfers collateral tokens from Position contract back to user. Accrues interest before withdrawal.
     * @param _amount The amount of collateral tokens to withdraw.
     * @custom:throws ZeroAmount if amount is 0.
     * @custom:throws InsufficientCollateral if user has insufficient collateral balance.
     */
    function withdrawCollateral(uint256 _amount) public positionRequired nonReentrant updateInterest {
        if (_amount == 0) revert ZeroAmount();
        if (
            _amount
                > IERC20(ILPRouter(router).collateralToken()).balanceOf(ILPRouter(router).addressPositions(msg.sender))
        ) {
            revert InsufficientCollateral();
        }

        IPosition(ILPRouter(router).addressPositions(msg.sender)).withdrawCollateral(_amount, msg.sender);

        ILPRouter(router).withdrawCollateral(_amount, msg.sender);
    }

    /**
     * @notice Borrow assets using supplied collateral and optionally send them to a different network.
     * @dev Calculates shares, checks liquidity, and handles cross-chain or local transfers. Accrues interest before borrowing.
     * @param _amount The amount of tokens to borrow.
     * @param _chainId The chain id of the destination network.
     * @custom:throws InsufficientLiquidity if protocol lacks liquidity.
     * @custom:emits BorrowDebtCrosschain when borrow is successful.
     */
    function borrowDebt(uint256 _amount, uint256 _chainId) public payable nonReentrant updateInterest {
        if (_amount == 0) revert ZeroAmount();

        (uint256 protocolFee, uint256 userAmount, uint256 shares) = ILPRouter(router).borrowDebt(_amount, msg.sender);

        if (_chainId != block.chainid) {
            address helperTestnet = IFactory(factory).helper();
            (,, uint32 destinationDomain) = IHelperTestnet(helperTestnet).chains(_chainId);
            (, address interchainGasPaymaster,) = IHelperTestnet(helperTestnet).chains(block.chainid);

            address bridgeRouter = IFactory(factory).bridgeRouter();
            address bridgeTokenSenders =
                IBridgeRouter(bridgeRouter).getBridgeTokenSendersChainId(ILPRouter(router).borrowToken(), _chainId);

            uint256 gasAmount =
                IInterchainGasPaymaster(interchainGasPaymaster).quoteGasPayment(destinationDomain, userAmount); // TODO: BURN

            IERC20(ILPRouter(router).borrowToken()).approve(bridgeTokenSenders, userAmount);
            ICaerBridgeTokenSender(bridgeTokenSenders).bridge{value: gasAmount}(
                userAmount, msg.sender, ILPRouter(router).borrowToken()
            );
            IERC20(ILPRouter(router).borrowToken()).safeTransfer(protocol, protocolFee);
        } else {
            IERC20(ILPRouter(router).borrowToken()).safeTransfer(msg.sender, userAmount);
            IERC20(ILPRouter(router).borrowToken()).safeTransfer(protocol, protocolFee);
        }
        emit BorrowDebtCrosschain(msg.sender, _amount, userAmount, shares, _chainId);
    }

    /**
     * @notice Repay borrowed assets using a selected token from the user's position.
     * @dev Swaps selected token to borrow token if needed via position contract. Accrues interest before repayment.
     * @param _shares The number of borrow shares to repay.
     * @param _token The address of the token to use for repayment.
     * @param _fromPosition Whether to use tokens from the position contract (true) or from the user's wallet (false).
     * @custom:throws ZeroAmount if shares is 0.
     * @custom:throws amountSharesInvalid if shares exceed user's borrow shares.
     * @custom:emits RepayWithCollateralByPosition when repayment is successful.
     */
    function repayWithSelectedToken(uint256 _shares, address _token, bool _fromPosition)
        public
        positionRequired
        nonReentrant
        updateInterest
    {
        if (_shares == 0) revert ZeroAmount();
        if (_shares > ILPRouter(router).userBorrowShares(msg.sender)) revert amountSharesInvalid();

        uint256 borrowAmount = ILPRouter(router).repayWithSelectedToken(_shares, msg.sender);

        if (_token == ILPRouter(router).borrowToken() && !_fromPosition) {
            IERC20(ILPRouter(router).borrowToken()).safeTransferFrom(msg.sender, address(this), borrowAmount);
        } else {
            IPosition(ILPRouter(router).addressPositions(msg.sender)).repayWithSelectedToken(borrowAmount, _token);
        }

        emit RepayWithCollateralByPosition(msg.sender, borrowAmount, _shares);
    }

    /**
     * @notice Swap tokens within a user's position.
     * @dev Executes a token swap via the user's Position contract. Accrues interest before swap.
     * @param _tokenFrom The address of the token to swap from.
     * @param _tokenTo The address of the token to receive.
     * @param _amountIn The amount of _tokenFrom to swap.
     * @return amountOut The amount of _tokenTo received from the swap.
     * @custom:throws ZeroAmount if amountIn is 0.
     * @custom:throws TokenNotAvailable if _tokenFrom is not available in position.
     */
    function swapTokenByPosition(address _tokenFrom, address _tokenTo, uint256 _amountIn)
        public
        positionRequired
        updateInterest
        returns (uint256 amountOut)
    {
        if (_amountIn == 0) revert ZeroAmount();
        if (
            _tokenFrom != ILPRouter(router).collateralToken()
                && IPosition(ILPRouter(router).addressPositions(msg.sender)).tokenListsId(_tokenFrom) == 0
        ) {
            revert TokenNotAvailable();
        }
        amountOut = IPosition(ILPRouter(router).addressPositions(msg.sender)).swapTokenByPosition(
            _tokenFrom, _tokenTo, _amountIn
        );
    }
}
