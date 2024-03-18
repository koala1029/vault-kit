// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {EVault} from "../EVault/EVault.sol";
import {IGovernance, IInitialize} from "../EVault/IEVault.sol";
import {InitializeModule} from "../EVault/modules/Initialize.sol";
import {VaultModule} from "../EVault/modules/Vault.sol";
import {GovernanceModule} from "../EVault/modules/Governance.sol";
import {IERC20} from "../EVault/IEVault.sol";
import {ProxyUtils} from "../EVault/shared/lib/ProxyUtils.sol";
import {Operations} from "../EVault/shared/types/Types.sol";
import "../EVault/shared/Constants.sol";
import "../EVault/shared/types/Types.sol";

contract ESVault is EVault {
    using TypesLib for uint16;
    constructor(Integrations memory integrations, DeployedModules memory modules) EVault(integrations, modules) {}

    uint32 public constant SYNTH_VAULT_DISABLED_OPS = OP_MINT | OP_REDEEM | OP_SKIM | OP_LOOP | OP_DELOOP;
    uint32 public constant INTEREST_FEE = 1e4;

    error E_Disabled();

    // ----------------- Initialize ----------------

    /// @inheritdoc IInitialize
    function initialize(address proxyCreator) public override virtual reentrantOK {
        InitializeModule.initialize(proxyCreator);

        // disable not supported operations
        marketStorage.disabledOps = Operations.wrap(SYNTH_VAULT_DISABLED_OPS | Operations.unwrap(marketStorage.disabledOps));
        // set default interst fee to 100%
        marketStorage.interestFee = uint16(INTEREST_FEE).toConfigAmount();
        emit GovSetDisabledOps(SYNTH_VAULT_DISABLED_OPS);
    }

    // ----------------- Governance ----------------

    /// @inheritdoc IGovernance
    function setDisabledOps(uint32 newDisabledOps) public override reentrantOK {
        // Enforce that ops that are not supported by the synth vault are not enabled.
        uint32 filteredOps = newDisabledOps | SYNTH_VAULT_DISABLED_OPS;
        GovernanceModule.setDisabledOps(filteredOps);
    }

    /// @notice Disabled for synthetic asset vaults
    function setInterestFee(uint16 newInterestFee) public override virtual reentrantOK {
        revert E_Disabled();
    }

    // ----------------- Vault ----------------
    
    /// @dev This function can only be called by the synth contract to deposit assets into the vault.
    /// @param amount The amount of assets to deposit.
    /// @param receiver The address to receive the assets.
    function deposit(uint256 amount, address receiver) public override virtual reentrantOK callThroughEVC returns (uint256) {
        // only the synth contract can call this function.
        address account = EVCAuthenticate();
        (IERC20 synth,,) = ProxyUtils.metadata();

        if (account != address(synth)) revert E_Unauthorized();

        VaultModule.deposit(amount, receiver);
    }

}
