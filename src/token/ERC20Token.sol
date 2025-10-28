// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Capped } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Token is ERC20, ERC20Burnable, ERC20Capped, Ownable {
    /// @dev The number of decimals for the token
    uint8 private _decimals;

    /// @notice Constructor for the ERC20Token contract
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param initialSupply The initial supply of the token
    /// @param maxSupply The maximum supply of the token
    /// @param tokenDecimals The number of decimals for the token
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 maxSupply,
        uint8 tokenDecimals,
        address newOwner
    )
        ERC20(name, symbol)
        ERC20Capped(maxSupply)
        Ownable(newOwner)
    {
        _mint(newOwner, initialSupply);
        _decimals = tokenDecimals;
    }

    /// @inheritdoc ERC20
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @notice Mints new tokens to a specified account
    /// @param account The account to mint tokens to
    /// @param amount The amount of tokens to mint
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /// @inheritdoc ERC20
    function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }
}
