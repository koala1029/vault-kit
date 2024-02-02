// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IRiskManager, IEVault} from "../IEVault.sol";
import {Base} from "../shared/Base.sol";
import {BorrowUtils} from "../shared/BorrowUtils.sol";
import {IRiskManager} from "../IEVault.sol";
import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";

import "../shared/types/Types.sol";

abstract contract RiskManagerModule is IRiskManager, Base, BorrowUtils {
    using TypesLib for uint256;
    using UserStorageLib for UserStorage;

    function computeAccountLiquidity(address account) external virtual view returns (uint256 collateralValue, uint256 liabilityValue) {
        address controller = getSupportedController(account);
        address[] memory collaterals = IEVC(evc).getCollaterals(account);

        return computeLiquidity(
            account,
            collaterals,
            Liability(controller, IEVault(controller).asset(), IEVault(controller).debtOf(account))
        );
    }

    struct MarketLiquidity {
        address market;
        uint256 collateralValue;
        uint256 liabilityValue;
    }

    function computeAccountLiquidityPerMarket(address account) external virtual view returns (MarketLiquidity[] memory) {
        Liability memory liability;
        liability.market = getSupportedController(account);
        liability.asset = IEVault(liability.market).asset();
        liability.owed = IEVault(liability.market).debtOf(account);

        address[] memory collaterals = IEVC(evc).getCollaterals(account);

        uint256 numMarkets = collaterals.length + 1;
        for (uint256 i; i < collaterals.length;) {
            if (collaterals[i] == liability.market) {
                numMarkets--;
                break;
            }
            unchecked {
                ++i;
            }
        }

        MarketLiquidity[] memory output = new MarketLiquidity[](numMarkets);
        address[] memory singleCollateral = new address[](1);

        // account also supplies collateral in liability market
        for (uint256 i; i < collaterals.length;) {
            output[i].market = collaterals[i];
            singleCollateral[0] = collaterals[i];

            (output[i].collateralValue, output[i].liabilityValue) =
                computeLiquidity(account, singleCollateral, liability);
            if (collaterals[i] != liability.market) output[i].liabilityValue = 0;

            unchecked {
                ++i;
            }
        }

        // liability market is not included in supplied collaterals
        if (numMarkets > collaterals.length) {
            singleCollateral[0] = liability.market;
            uint256 index = numMarkets - 1;

            output[index].market = liability.market;
            (output[index].collateralValue, output[index].liabilityValue) =
                computeLiquidity(account, singleCollateral, liability);
        }

        return output;
    }

    /// @inheritdoc IRiskManager
    function disableController() external virtual nonReentrant {
        address account = EVCAuthenticate();

        if (!marketStorage.users[account].getOwed().isZero()) revert E_OutstandingDebt();

        disableControllerInternal(account);
    }

    /// @inheritdoc IRiskManager
    /// @dev The function doesn't have a re-entrancy lock, because onlyEVCChecks provides equivalent behaviour. It ensures that the caller
    /// is the EVC, in 'checks in progress' state. In this state EVC will not accept any calls. Since all the functions which modify
    /// vault state use callThroughEVC modifier, they are effectively blocked while the function executes. There are non-view functions without
    /// callThroughEVC modifier (`flashLoan`, `disableCollateral`, `skimAssets`), but they don't change the vault's storage.
    function checkAccountStatus(address account, address[] calldata collaterals)
        external
        virtual
        reentrantOK
        onlyEVCChecks
        returns (bytes4 magicValue)
    {
        MarketCache memory marketCache = loadMarket();
        checkAccountStatusInternal(account, collaterals, getRMLiability(marketCache, account));
        magicValue = ACCOUNT_STATUS_CHECK_RETURN_VALUE;
    }

    function checkAccountStatusInternal(address account, address[] memory collaterals, Liability memory liability)
        private
        view
    {
        if (liability.market == address(0) || liability.owed == 0) return;
        (uint256 collateralValue, uint256 liabilityValue) = computeLiquidity(account, collaterals, liability);

        if (collateralValue < liabilityValue) revert RM_AccountLiquidity();
    }

    /// @inheritdoc IRiskManager
    /// @dev See comment about re-entrancy for `checkAccountStatus`
    function checkVaultStatus() external virtual reentrantOK onlyEVCChecks returns (bytes4 magicValue) {
        // Use the updating variant to make sure interest is accrued in storage before the interest rate update
        MarketCache memory marketCache = updateMarket();
        uint72 newInterestRate = updateInterestParams(marketCache);

        logMarketStatus(marketCache, newInterestRate);

        MarketSnapshot memory currentSnapshot = getMarketSnapshot(0, marketCache);
        MarketSnapshot memory oldSnapshot = marketStorage.marketSnapshot;
        delete marketStorage.marketSnapshot.performedOperations;

        if (oldSnapshot.performedOperations == 0) revert E_InvalidSnapshot();

        checkVaultStatusInternal(
            oldSnapshot.performedOperations,
            Snapshot({
                poolSize: oldSnapshot.poolSize.toUint(),
                totalBorrows: oldSnapshot.totalBorrows.toUint()
            }),
            Snapshot({
                poolSize: currentSnapshot.poolSize.toUint(),
                totalBorrows: currentSnapshot.totalBorrows.toUint()
            })
        );

        magicValue = VAULT_STATUS_CHECK_RETURN_VALUE;
    }

    function checkVaultStatusInternal(
        uint32 performedOperations,
        Snapshot memory oldSnapshot,
        Snapshot memory currentSnapshot
    ) private view {
        // TODO optimize reads
        uint256 pauseBitmask = marketConfig.pauseBitmask;
        uint256 supplyCap = marketConfig.supplyCap;
        uint256 borrowCap = marketConfig.borrowCap;
        uint256 assetDecimalsMultiplier = 10 ** marketConfig.assetDecimals;

        if (pauseBitmask & performedOperations != 0) revert RM_OperationPaused();

        if (supplyCap == 0 && borrowCap == 0) return;

        uint256 totalAssets = currentSnapshot.poolSize + currentSnapshot.totalBorrows;
        if (
            supplyCap != 0 && totalAssets > (oldSnapshot.poolSize + oldSnapshot.totalBorrows)
                && totalAssets >= supplyCap * assetDecimalsMultiplier
        ) revert RM_SupplyCapExceeded();

        if (
            borrowCap != 0 && currentSnapshot.totalBorrows > oldSnapshot.totalBorrows
                && currentSnapshot.totalBorrows >= borrowCap * assetDecimalsMultiplier
        ) revert RM_BorrowCapExceeded();
    }

    // getters

    function getSupportedController(address account) internal view returns (address controller) {
        address[] memory controllers = IEVC(evc).getControllers(account);

        if (controllers.length > 1) revert RM_TransientState();
        if (controllers.length == 0) revert RM_NoLiability();

        controller = controllers[0];

        if (controller != address(this)) revert RM_NotController();
    }
}

contract RiskManager is RiskManagerModule {
    constructor(address evc, address protocolAdmin, address balanceTracker) Base(evc, protocolAdmin, balanceTracker) {}
}
