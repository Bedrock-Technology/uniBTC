// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FBTC is ERC20, Ownable {
    constructor()
        ERC20("FBTC", "FBTC")
        Ownable()
    {
        setMintable(msg.sender, true);
    }

    // @dev mintable group
    mapping(address => bool) public mintableGroup;
    modifier onlyMintableGroup() {
        require(mintableGroup[msg.sender], "FBTC: not in mintable group");
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * @dev set or remove address to mintable group
     */
    function setMintable(address account, bool allow) public onlyOwner {
        require(mintableGroup[account] != allow, "already set");
        mintableGroup[account] = allow;
    }

    function mint(address to, uint256 amount) public onlyMintableGroup {
        _mint(to, amount);
    }
}
