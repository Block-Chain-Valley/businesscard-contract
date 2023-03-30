// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBCCoin {
    function mint(address _to, uint256 _amount) external;

    function balanceOf(address account) external view returns (uint256);
}
