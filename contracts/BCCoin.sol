//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";

contract BCCoin is ERC20 {
    constructor() ERC20("BusinessCardCoin", "BCC") {
        _mint(msg.sender, 1000000000000000000000000);
    }
}
