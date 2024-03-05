// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {IVault as IEVCVault} from "ethereum-vault-connector/interfaces/IVault.sol";

// Full interface of EVault and all it's modules

interface IInitialize {
    /// @notice Initialization of the newly deployed proxy contract
    /// @param creator Account which created the proxy or should be the initial governor
    function initialize(address creator) external;
}

interface IERC20 {
    /// @notice Vault share token (eToken) name, ie "Euler Vault: DAI"
    function name() external view returns (string memory);

    /// @notice Vault share token (eToken) symbol, ie "eDAI"
    function symbol() external view returns (string memory);

    /// @notice Decimals, always normalised to 18
    function decimals() external view returns (uint8);

    /// @notice Sum of all eToken balances
    function totalSupply() external view returns (uint256);

    /// @notice Balance of a particular account, in eTokens
    function balanceOf(address account) external view returns (uint256);

    /// @notice Retrieve the current allowance
    /// @param holder The account holding the eTokens
    /// @param spender Trusted address
    function allowance(address holder, address spender) external view returns (uint256);

    /// @notice Transfer eTokens to another address
    /// @param to Recipient account
    /// @param amount In shares.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Transfer eTokens from one address to another
    /// @param from This address must've approved the to address
    /// @param to Recipient account
    /// @param amount In shares
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Allow spender to access an amount of your eTokens
    /// @param spender Trusted address
    /// @param amount Use max uint for "infinite" allowance
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC2612 {
    /// @notice Retrieve domain separator for ERC2612 permit
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Retrieve current account nonce for ERC2612 permit
    function nonces(address owner) external view returns (uint256);

    /// @notice Apply signed ERC2612 permit to set allowance for a spender account
    /// @param owner Account owner and signer
    /// @param spender Account for which allowance will be set
    /// @param value Amount of allowance
    /// @param deadline Permit expiration timestamp
    /// @param v Secp256k1 signature v byte
    /// @param r Secp256k1 signature r value
    /// @param s Secp256k1 signature s value
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IToken is IERC20, IERC2612 {
    /// @notice Transfer the full eToken balance of an address to another
    /// @param from This address must've approved the to address
    /// @param to Recipient account
    function transferFromMax(address from, address to) external returns (bool);
}

interface IERC4626 {
    /// @notice Vault underlying asset
    function asset() external view returns (address);

    /// @notice Total amount of managed assets
    function totalAssets() external view returns (uint256);

    /// @notice Calculate amount of assets corresponding to the requested shares amount
    function convertToAssets(uint256 shares) external view returns (uint256);

    /// @notice Calculate amount of shares corresponding to the requested assets amount
    function convertToShares(uint256 assets) external view returns (uint256);

    /// @notice Fetch the maximum amount of assets a user can deposit
    function maxDeposit(address) external view returns (uint256);

    /// @notice Calculate an amount of shares that would be created by depositing assets
    /// @param assets Amount of assets deposited
    /// @return Amount of shares received
    function previewDeposit(uint256 assets) external view returns (uint256);

    /// @notice Fetch the maximum amount of shares a user can mint
    function maxMint(address) external view returns (uint256);

    /// @notice Calculate an amount of assets that would be required to mint requested amount of shares
    /// @param shares Amount of shares to be minted
    /// @return Required amount of assets
    function previewMint(uint256 shares) external view returns (uint256);

    /// @notice Fetch the maximum amount of assets a user is allowed to withdraw
    /// @param owner Account holding the shares
    /// @return The maximum amount of assets the owner is allowed to withdraw
    function maxWithdraw(address owner) external view returns (uint256);

    /// @notice Calculate the amount of shares that will be burned when withdrawing requested amount of assets
    /// @param assets Amount of assets withdrawn
    /// @return Amount of shares burned
    function previewWithdraw(uint256 assets) external view returns (uint256);

    /// @notice Fetch the maximum amount of shares a user is allowed to redeem for assets
    /// @param owner Account holding the shares
    /// @return The maximum amount of shares the owner is allowed to redeem
    function maxRedeem(address owner) external view returns (uint256);

    /// @notice Calculate the amount of assets that will be transferred when redeeming requested amount of shares
    /// @param shares Amount of shares redeemed
    /// @return Amount of assets transferred
    function previewRedeem(uint256 shares) external view returns (uint256);

    /// @notice Transfer requested amount of underlying tokens from sender to the vault pool in return for shares
    /// @param assets In underlying units (use max uint for full underlying token balance)
    /// @param receiver An account to receive the shares
    /// @return Amount of shares minted
    /// @dev Deposit will round down the amount of assets that are converted to shares. To prevent losses consider using mint instead.
    function deposit(uint256 assets, address receiver) external returns (uint256);

    /// @notice Transfer underlying tokens from sender to the vault pool in return for requested amount of shares
    /// @param shares Amount of share to be minted
    /// @param receiver An account to receive the shares
    /// @return Amount of assets deposited
    function mint(uint256 shares, address receiver) external returns (uint256);

    /// @notice Transfer requested amount of underlying tokens from the vault and decrease account's shares balance
    /// @param assets In underlying units
    /// @param receiver Account to receive the withdrawn assets
    /// @param owner Account holding the shares to burn
    /// @return Amount of shares burned
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);

    /// @notice Burn requested shares and transfer corresponding underlying tokens from the vault to the receiver
    /// @param shares Amount of shares to burn (use max to burn full owner balance)
    /// @param receiver Account to receive the withdrawn assets
    /// @param owner Account holding the shares to burn.
    /// @return Amount of assets transferred
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);
}

interface IVault is IERC4626 {
    /// @notice Balance of the fees accumulator, in eTokens
    function feesBalance() external view returns (uint256);

    /// @notice Balance of the fees accumulator, in underlying units
    function feesBalanceAssets() external view returns (uint256);

    /// @notice Allows protocol admin to rescue funds transferred to the vault directly (instead of deposit/mint)
    function skimAssets() external;
}

interface IBorrowing {
    /// @notice Sum of all outstanding debts, in underlying units (increases as interest is accrued)
    function totalBorrows() external view returns (uint256);

    /// @notice Sum of all outstanding debts, in underlying units scaled up by INTERNAL_DEBT_PRECISION bits
    function totalBorrowsExact() external view returns (uint256);

    /// @notice Balance of vault assets as tracked by deposits/withdrawals and borrows/repays
    function cash() external view returns (uint256);

    /// @notice Debt owed by a particular account, in underlying units
    function debtOf(address account) external view returns (uint256);

    /// @notice Debt owed by a particular account, in underlying units scaled up by INTERNAL_DEBT_PRECISION bits
    function debtOfExact(address account) external view returns (uint256);

    /// @notice Retrieves the current interest rate for an asset
    /// @return The interest rate in yield-per-second, scaled by 10**27
    function interestRate() external view returns (uint256);

    /// @notice Retrieves the current interest rate accumulator for an asset
    /// @return An opaque accumulator that increases as interest is accrued
    function interestAccumulator() external view returns (uint256);

    /// @notice Retrieves amount of the collateral that is being actively used to support the debt of the account.
    function collateralUsed(address collateral, address account)
        external
        view
        returns (uint256);

    /// @notice Address of the sidecar DToken
    function dToken() external view returns (address);

    /// @notice Address of EthereumVaultConnector contract
    function EVC() external view returns (address);

    /// @notice Transfer underlying tokens from the vault to the sender, and increase sender's debt
    /// @param assets In underlying units (use max uint for all available tokens)
    /// @param receiver Account receiving the borrowed tokens (use zero address for authenticated account)
    function borrow(uint256 assets, address receiver) external;

    /// @notice Transfer underlying tokens from the sender to the vault, and decrease receiver's debt
    /// @param assets In underlying units (use max uint256 for full debt)
    /// @param receiver Account holding the debt to be repaid (use zero address for authenticated acount).
    function repay(uint256 assets, address receiver) external;

    /// @notice Mint shares and a corresponding amount of debt ("self-borrow")
    /// @param assets In underlying units
    /// @param sharesReceiver Account to receive the created shares (use zero address for authenticated acount).
    /// @return Amount of shares created
    function loop(uint256 assets, address sharesReceiver) external returns (uint256);

    /// @notice Pay off liability with shares ("self-repay")
    /// @param assets In underlying units (use max uint to repay the debt in full or up to the available underlying balance)
    /// @param debtFrom Account to remove debt from by burning sender's shares (use zero address for authenticated acount).
    /// @return Amount of shares burned
    function deloop(uint256 assets, address debtFrom) external returns (uint256);

    /// @notice Take over debt from another account
    /// @param assets Amount of debt in underlying units (use max for all the account's debt)
    /// @param from Account to pull the debt from
    function pullDebt(uint256 assets, address from) external;

    /// @notice Request a flash-loan. A onFlashLoan() callback in msg.sender will be invoked, which must repay the loan to the main Euler address prior to returning.
    /// @param assets In underlying units
    /// @param data Passed through to the onFlashLoan() callback, so contracts don't need to store transient data in storage
    function flashLoan(uint256 assets, bytes calldata data) external;

    /// @notice Updates interest accumulator and totalBorrows, credits reserves, re-targets interest rate, and logs market status
    function touch() external;
}

interface ILiquidation {
    /// @notice Checks to see if a liquidation would be profitable, without actually doing anything
    /// @param liquidator Address that will initiate the liquidation
    /// @param violator Address that may be in collateral violation
    /// @param collateral Collateral which is to be seized
    /// @return maxRepay Max amount of debt that can be repaid, in asset units
    /// @return maxYield Yield in collateral corresponding to max allowed amount of debt to be repaid, in collateral balance (shares for vaults)
    function checkLiquidation(address liquidator, address violator, address collateral)
        external
        view
        returns (uint256 maxRepay, uint256 maxYield);

    /// @notice Attempts to perform a liquidation
    /// @param violator Address that may be in collateral violation
    /// @param collateral Collateral which is to be seized
    /// @param repayAssets The amount of underlying debt to be transferred from violator to sender, in asset units (use max to repay the maximum possible amount).
    /// @param minYieldBalance The minimum acceptable amount of collateral to be transferred from violator to sender, in collateral balance units (shares for vaults)
    function liquidate(address violator, address collateral, uint256 repayAssets, uint256 minYieldBalance)
        external;
}

interface IRiskManager is IEVCVault {
    /// @notice Retrieve account's total liquidity
    /// @param account Account holding debt in this vault
    /// @param liquidation Flag to indicate if the calculation should be performed in liquidation vs account status check mode, where different LTV values might apply.
    /// @return collateralValue Total risk adjusted value of all collaterals in unit of account
    /// @return liabilityValue Value of debt in unit of account
    function accountLiquidity(address account, bool liquidation) external view returns (uint256 collateralValue, uint256 liabilityValue);

    /// @notice Retrieve account's liquidity per collateral
    /// @param account Account holding debt in this vault
    /// @param liquidation Flag to indicate if the calculation should be performed in liquidation vs account status check mode, where different LTV values might apply.
    /// @return collaterals Array of collaterals enabled
    /// @return collateralValues Array of risk adjusted collateral values corresponding to items in collaterals array. In unit of account
    /// @return liabilityValue Value of debt in unit of account
    function accountLiquidityFull(address account, bool liquidation) external view returns (address[] memory collaterals, uint256[] memory collateralValues, uint256 liabilityValue);

    /// @notice Release control of the account on EVC if no outstanding debt is present
    function disableController() external;

    /// @notice Checks the status of an account and reverts if account is not healthy
    /// @param account The address of the account to be checked
    /// @return magicValue Must return the bytes4 magic value 0xb168c58f (which is a selector of this function) when account status is valid, or revert otherwise.
    /// @dev Only callable by EVC during status checks
    function checkAccountStatus(address account, address[] calldata collaterals) external returns (bytes4);

    /// @notice Checks the status of the vault and reverts if caps are exceeded
    /// @return magicValue Must return the bytes4 magic value 0x4b3d1223 (which is a selector of this function) when account status is valid, or revert otherwise.
    /// @dev Only callable by EVC during status checks
    function checkVaultStatus() external returns (bytes4);
}

interface IBalanceForwarder {
    /// @notice Retrieve the address of rewards contract, tracking changes in account's balances
    function balanceTrackerAddress() external view returns (address);

    /// @notice Retrieves boolean indicating if the account opted in to forward balance changes to the rewards contract
    function balanceForwarderEnabled(address account) external view returns (bool);

    /// @notice Enables balance forwarding for the authenticated account
    /// @dev Only the authenticated account can enable balance forwarding for itself
    /// @dev Should call the IBalanceTracker hook with the current account's balance
    function enableBalanceForwarder() external;

    /// @notice Disables balance forwarding for the authenticated account
    /// @dev Only the authenticated account can disable balance forwarding for itself
    /// @dev Should call the IBalanceTracker hook with the account's balance of 0
    function disableBalanceForwarder() external;
}

interface IGovernance {
    /// @notice Retrieves the address of the governor
    function governorAdmin() external view returns (address);

    /// @notice Retrieves the address of the pause guardian - an account which can disable or enable operations
    function pauseGuardian() external view returns (address);

    /// @notice Retrieves the interest fee in effect for the vault
    /// @return Amount of interest that is redirected as a fee, as a fraction scaled by CONFIG_SCALE (60_000)
    function interestFee() external view returns (uint16);

    /// @notice Retrieves the protocol fee share
    /// @return A percentage share of fees accrued belonging to the protocol. In wad scale (1e18)
    function protocolFeeShare() external view returns (uint256);

    /// @notice Retrieves the address which will receive protocol's fees
    function protocolFeeReceiver() external view returns (address);

    /// @notice Retrieves regular LTV set for the collateral, which is used to determine the health of the account
    function LTV(address collateral) external view returns (uint16);

    /// @notice Retrieves current ramped value of LTV, which is used to determine liquidation penalty
    function LTVLiquidation(address collateral) external view returns (uint16);

    /// @notice Retrieves LTV detailed config for a collateral
    /// @param collateral Collateral asset
    /// @return targetTimestamp the timestamp when the ramp ends
    /// @return targetLTV current regular LTV or target LTV that the ramped LTV will reach after ramp is over
    /// @return rampDuration ramp duration in seconds
    /// @return originalLTV previous LTV value, where the ramp starts
    function LTVFull(address collateral) external view returns (uint40 targetTimestamp, uint16 targetLTV, uint24 rampDuration, uint16 originalLTV);

    /// @notice Retrieves a list of collaterals with configured LTVs
    /// @return List of asset collaterals
    /// @dev The list can have duplicates. Returned assets could have the ltv disabled (set to zero)
    function LTVList() external view returns (address[] memory);

    /// @notice Looks up an asset's currently configured interest rate model
    /// @return Address of the interest rate contract or address zero to indicate 0% interest
    function interestRateModel() external view returns (address);

    /// @notice Retrieves a bitmask indicating which operations are disabled.
    function disabledOps() external view returns (uint32);

    /// @notice Retrieves supply and borrow caps in AmountCap format
    function caps() external view returns (uint16 supplyCap, uint16 borrowCap);

    /// @notice Retrieves address of the governance fee receiver
    function feeReceiver() external view returns (address);

    /// @notice Indicates if debt socialization is activated
    function debtSocialization() external view returns (bool);

    /// @notice Retrieves a reference asset used for liquidity calculations
    function unitOfAccount() external view returns (address);

    /// @notice Retrieves the address of the oracle contract
    function oracle() external view returns (address);


    /// @notice Splits accrued fees balance according to protocol fee share and transfers shares to the governor fee receiver and protocol fee receiver
    function convertFees() external;

    /// @notice Set a new eToken name
    function setName(string calldata newName) external;

    /// @notice Set a new eToken symbol
    function setSymbol(string calldata newSymbol) external;

    /// @notice Set a new governor address
    function setGovernorAdmin(address newGovernorAdmin) external;

    /// @notice Set a new pause guardian address
    function setPauseGuardian(address newPauseGuardian) external;

    /// @notice Set a new governor fee receiver address
    function setFeeReceiver(address newFeeReceiver) external;

    /// @notice Set a new LTV config
    /// @param collateral Address of collateral to set LTV for
    /// @param ltv New LTV in CONFIG_SCALE (60 000)
    /// @param rampDuration Ramp duration in seconds
    function setLTV(address collateral, uint16 ltv, uint24 rampDuration) external;

    /// @notice Completely clears LTV configuratrion, signalling the collateral is not considered safe to liquidate anymore
    /// @param collateral Address of collateral
    function clearLTV(address collateral) external;

    /// @notice Set a new interest rate model contract
    /// @param newModel Address of the contract
    /// @param resetParams Data to use in the `reset` function called on the IRM contract after setting it
    function setIRM(address newModel, bytes calldata resetParams) external;

    /// @notice Set new bitmap indicating which operations should be disabled. Operations are defined in Constants contract
    function setDisabledOps(uint32 newDisabledOps) external;

    /// @notice Set new supply and borrow caps in AmountCap format
    function setCaps(uint16 supplyCap, uint16 borrowCap) external;

    /// @notice Set a new interest fee
    function setInterestFee(uint16 newFee) external;

    /// @notice Enable or disable debt socialization during liquidations
    function setDebtSocialization(bool newValue) external;
}

interface IEVault is IInitialize, IToken, IVault, IBorrowing, ILiquidation, IRiskManager, IBalanceForwarder, IGovernance {}
