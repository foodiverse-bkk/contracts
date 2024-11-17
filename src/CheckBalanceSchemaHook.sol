// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ISPHook} from "../lib/sign-protocol-evm/src/interfaces/ISPHook.sol";
import {ISP} from "../lib/sign-protocol-evm/src/interfaces/ISP.sol";
import {Attestation} from "../lib/sign-protocol-evm/src/models/Attestation.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title Check Balance Schema Hook
 * @notice A hook that verifies the contract's balance matches the expected value
 * @dev Implements ISPHook interface for both ETH and ERC20 balance verification
 */
contract CheckBalanceSchemaHook is ISPHook {
    ////////////////////////////////////////////////////////////////////////////////
    ///                              STATE VARIABLES                              ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice The ERC20 token contract to verify balances for
    IERC20 public immutable paymentToken;

    /// @notice The SIGN Protocol contract
    ISP public immutable sp;

    ////////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                   ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when balance doesn't match attestation value
    error BalanceMismatch();
    /// @notice Thrown when an invalid token is provided
    error InvalidToken();
    /// @notice Thrown when attestation lookup fails
    error AttestationLookupFailed();

    ////////////////////////////////////////////////////////////////////////////////
    ///                               CONSTRUCTOR                                 ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Sets the ERC20 token contract for balance verification
    /// @param _token The ERC20 token contract address
    /// @param _sp The SIGN Protocol contract address
    constructor(address _token, address _sp) {
        if (_token == address(0) || _sp == address(0)) revert InvalidToken();
        paymentToken = IERC20(_token);
        sp = ISP(_sp);
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                          PRIVATE FUNCTIONS                               ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Private function to get total value from attestation
    /// @param attestationId The ID of the attestation
    /// @return total The total value from the attestation
    function _getAttestationTotal(
        uint64 attestationId
    ) private view returns (uint256) {
        try sp.getAttestation(attestationId) returns (
            Attestation memory attestation
        ) {
            // Decode the total value from the attestation data
            uint256 total = abi.decode(attestation.data, (uint256));
            return total;
        } catch {
            revert AttestationLookupFailed();
        }
    }

    /// @notice Private function to verify native token (ETH) balance deposited to the contract
    /// is equal to the expected value
    /// @param attestationId The ID of the attestation to verify against
    function _verifyNativeBalance(uint64 attestationId) private view {
        uint256 expectedBalance = _getAttestationTotal(attestationId);

        // Check if the contract's ETH balance matches expected value
        if (address(this).balance != expectedBalance) {
            revert BalanceMismatch();
        }
    }

    /// @notice Private function to verify ERC20 token balance that was deposited to the contract
    /// is equal to the expected value
    /// @param attestationId The ID of the attestation to verify against
    function _verifyTokenBalance(uint64 attestationId) private view {
        uint256 expectedBalance = _getAttestationTotal(attestationId);

        // Get the current balance
        uint256 currentBalance;
        try paymentToken.balanceOf(address(this)) returns (uint256 balance) {
            currentBalance = balance;
        } catch {
            revert InvalidToken();
        }

        // Ensure the balance is not zero when we expect a value
        if (expectedBalance > 0 && currentBalance == 0) {
            revert BalanceMismatch();
        }

        // Check if the contract's token balance matches expected value
        if (currentBalance != expectedBalance) {
            revert BalanceMismatch();
        }

        // Optional: Verify the token has the expected decimals (if it's supposed to be USDC)
        try IERC20Metadata(address(paymentToken)).decimals() returns (
            uint8 decimals
        ) {
            if (decimals != 6) {
                // USDC uses 6 decimals
                revert InvalidToken();
            }
        } catch {
            // If decimals() is not supported, we continue
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///                          ISPHook Implementation                           ///
    ////////////////////////////////////////////////////////////////////////////////

    /// @inheritdoc ISPHook
    function didReceiveAttestation(
        address attester,
        uint64 schemaId,
        uint64 attestationId,
        bytes calldata extraData
    ) external payable override {
        _verifyNativeBalance(attestationId);
    }

    /// @inheritdoc ISPHook
    function didReceiveAttestation(
        address attester,
        uint64 schemaId,
        uint64 attestationId,
        IERC20 token,
        uint256,
        bytes calldata
    ) external view override {
        // Verify that the token matches our payment token
        if (token != paymentToken) revert InvalidToken();
        _verifyTokenBalance(attestationId);
    }

    /// @inheritdoc ISPHook
    function didReceiveRevocation(
        address attester,
        uint64 schemaId,
        uint64 attestationId,
        bytes calldata extraData
    ) external payable override {
        // Revocations always pass
        return;
    }

    /// @inheritdoc ISPHook
    function didReceiveRevocation(
        address attester,
        uint64 schemaId,
        uint64 attestationId,
        IERC20 token,
        uint256 amount,
        bytes calldata extraData
    ) external pure override {
        // Revocations always pass
        return;
    }
}
