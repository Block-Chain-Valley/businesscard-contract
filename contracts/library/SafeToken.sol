// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../IERC20.sol";

library SafeToken {
    function safeTransfer(address token, address to, uint256 value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeToken: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeToken: TRANSFER_FROM_FAILED");
    }

    function safeApprove(address token, address spender, uint256 value) internal {
        require((value == 0) || (IERC20(token).allowance(msg.sender, spender) == 0), "SafeToken: APPROVE_NONZERO");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeToken: APPROVE_FAILED");
    }

    function safeTransferETH(address payable to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "SafeToken: ETH_TRANSFER_FAILED");
    }
}
