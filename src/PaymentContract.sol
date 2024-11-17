// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaymentContract is Ownable {
    /// @notice The USDC token contract
    IERC20 public immutable usdcToken;

    /// @notice The FoodiversePoints token contract
    IERC20 public immutable fpToken;

    /// @notice Conversion rate from USDC to FP (1 USDC = 1 FP by default)
    uint256 public constant CONVERSION_RATE = 1;

    /// @notice Event emitted when a payment is made
    event PaymentProcessed(
        address indexed user,
        uint256 usdcAmount,
        uint256 fpAmount
    );

    /// @notice Thrown when payment amount is zero
    error ZeroAmount();
    /// @notice Thrown when transfer fails
    error TransferFailed();

    constructor(address _usdcToken, address _fpToken) Ownable(msg.sender) {
        if (_usdcToken == address(0) || _fpToken == address(0))
            revert("Invalid token address");
        usdcToken = IERC20(_usdcToken);
        fpToken = IERC20(_fpToken);
    }

    /// @notice Pay USDC to receive FoodiversePoints
    /// @param amount The amount of USDC to pay
    function pay(uint256 amount) external {
        // Check amount
        if (amount == 0) revert ZeroAmount();

        // Calculate FP amount (1:1 ratio with USDC for now)
        uint256 fpAmount = amount * CONVERSION_RATE;

        // Transfer USDC from user to contract
        bool success = usdcToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) revert TransferFailed();

        // Transfer FP tokens to user
        success = fpToken.transfer(msg.sender, fpAmount);
        if (!success) revert TransferFailed();

        emit PaymentProcessed(msg.sender, amount, fpAmount);
    }

    /// @notice Withdraw USDC from the contract (only owner)
    /// @param amount Amount of USDC to withdraw
    function withdrawUSDC(uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmount();
        bool success = usdcToken.transfer(owner(), amount);
        if (!success) revert TransferFailed();
    }

    /// @notice Withdraw FP tokens from the contract (only owner)
    /// @param amount Amount of FP tokens to withdraw
    function withdrawFP(uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmount();
        bool success = fpToken.transfer(owner(), amount);
        if (!success) revert TransferFailed();
    }
}
