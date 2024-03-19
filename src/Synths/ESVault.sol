// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import {EVault} from "../EVault/EVault.sol";
import {InitializeModule} from "../EVault/modules/Initialize.sol";
import {VaultModule} from "../EVault/modules/Vault.sol";
import {GovernanceModule} from "../EVault/modules/Governance.sol";
import {IERC20} from "../EVault/IEVault.sol";
import {ProxyUtils} from "../EVault/shared/lib/ProxyUtils.sol";
import {Operations} from "../EVault/shared/types/Types.sol";
import {RevertBytes} from "../EVault/shared/lib/RevertBytes.sol";

import "../EVault/shared/Constants.sol";
import "../EVault/shared/types/Types.sol";

contract ESVault is EVault {
    using TypesLib for uint16;

    constructor(Integrations memory integrations, DeployedModules memory modules) EVault(integrations, modules) {}

    uint32 public constant SYNTH_VAULT_DISABLED_OPS = OP_MINT | OP_REDEEM | OP_SKIM | OP_LOOP | OP_DELOOP;
    uint16 internal constant INTEREST_FEE = 1e4;

    // ----------------- Initialize ----------------

    /// @inheritdoc IInitialize
    function initialize(address) public override virtual reentrantOK {
        (bool success, bytes memory result) = MODULE_INITIALIZE.delegatecall(msg.data); // send the whole msg.data, including proxy metadata
        if (!success) RevertBytes.revertBytes(result);

        // disable not supported operations
        uint32 newDisabledOps = SYNTH_VAULT_DISABLED_OPS | Operations.unwrap(marketStorage.disabledOps);
        marketStorage.disabledOps = Operations.wrap(newDisabledOps);
        emit GovSetDisabledOps(newDisabledOps);

        // set default interest fee to 100%
        uint16 newInterestFee = INTEREST_FEE;
        marketStorage.interestFee = newInterestFee.toConfigAmount();
        emit GovSetInterestFee(newInterestFee);
    }

    // ----------------- Governance ----------------

    /// @inheritdoc IGovernance
    function setDisabledOps(uint32 newDisabledOps) public virtual override reentrantOK {
        // Enforce that ops that are not supported by the synth vault are not enabled.
        uint32 filteredOps = newDisabledOps | SYNTH_VAULT_DISABLED_OPS;
        GovernanceModule.setDisabledOps(filteredOps);
    }

    /// @notice Disabled for synthetic asset vaults
    function setInterestFee(uint16) public virtual override reentrantOK {
        revert E_OperationDisabled();
    }

    // ----------------- Vault ----------------

    /// @dev This function can only be called by the synth contract to deposit assets into the vault.
    /// @param amount The amount of assets to deposit.
    /// @param receiver The address to receive the assets.
    function deposit(uint256 amount, address receiver) public virtual override callThroughEVC returns (uint256) {
        // only the synth contract can call this function.
        address account = EVCAuthenticate();
        (IERC20 synth,,) = ProxyUtils.metadata();

        if (account != address(synth)) revert E_Unauthorized();

        return VaultModule.deposit(amount, receiver);
    }
}
