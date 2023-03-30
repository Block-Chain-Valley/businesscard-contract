//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";

contract BCCoin is ERC20 {
    constructor() ERC20("BusinessCardCoin", "BCC") {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
