// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title MockUSD
 * Mock ERC-20 token to represent a USD stablecoin with 8 decimals precision.
 * This is useful for simulating financial environments in testing.
 */
contract MockUSD is ERC20, Ownable, ERC20Permit {
    /**
     * @dev Initializes the contract with 8 decimals precision, setting the initial owner and permitting future transactions.
     * @param initialOwner The address that will be set as the initial owner of the contract.
     */
    constructor(address initialOwner)
        ERC20("MockUSD", "mUSD")
        Ownable(initialOwner)
        ERC20Permit("MockUSD")
    {
        _mint(initialOwner, 1000 * 10 ** decimals());
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * @dev Allows the owner to mint new tokens to a specified address.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint, expressed in the smallest unit.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}