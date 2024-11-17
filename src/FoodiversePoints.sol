// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FoodiversePoints is ERC20, Ownable {
    constructor() ERC20("Foodiverse Points", "FP") Ownable(msg.sender) {
        // Mint 1 million USDC to deployer
        _mint(msg.sender, 1_000_000 * 10 ether);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
