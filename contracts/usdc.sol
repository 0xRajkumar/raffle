//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract UsdcContract is ERC20 {
    address public admin;

    constructor() ERC20('USDC Contract', 'USDC') {
        _mint(msg.sender, 10000000 * 10**6);
        admin = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, 'Only Admin allowed');
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
