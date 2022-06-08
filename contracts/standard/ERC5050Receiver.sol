// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC5050Sender, IERC5050Receiver, Action} from "../interfaces/IERC5050.sol";
import "../common/Controllable.sol";
import "../common/EnumerableBytes4Set.sol";

contract ERC5050Receiver is Controllable, IERC5050Receiver {
    using Address for address;
    using EnumerableBytes4Set for EnumerableBytes4Set.Set;

    EnumerableBytes4Set.Set _receivableActions;

    modifier onlyReceivableAction(Action calldata action, uint256 nonce) {
        if (_isApprovedController(msg.sender, action.selector)) {
            return;
        }
        require(
            action.to._address == address(this),
            "ERC5050: invalid receiver"
        );
        require(
            _receivableActions.contains(action.selector),
            "ERC5050: invalid action"
        );
        require(
            action.from._address == address(0) ||
                action.from._address == msg.sender,
            "ERC5050: invalid sender"
        );
        require(
            (action.from._address != address(0) && action.user == tx.origin) ||
                action.user == msg.sender,
            "ERC5050: invalid sender"
        );
        _;
    }

    function receivableActions() external view returns (bytes4[] memory) {
        return _receivableActions.values();
    }

    function onActionReceived(Action calldata action, uint256 nonce)
        external
        payable
        virtual
        override
        onlyReceivableAction(action, nonce)
    {
        _onActionReceived(action, nonce);
    }

    function _onActionReceived(Action calldata action, uint256 nonce)
        internal
        virtual
    {
        if (!_isApprovedController(msg.sender, action.selector)) {
            if (action.state != address(0)) {
                require(action.state.isContract(), "ERC5050: invalid state");
                try
                    IERC5050Receiver(action.state).onActionReceived{
                        value: msg.value
                    }(action, nonce)
                {} catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert("ERC5050: call to non ERC5050Receiver");
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            }
        }
        emit ActionReceived(
            action.selector,
            action.user,
            action.from._address,
            action.from._tokenId,
            action.to._address,
            action.to._tokenId,
            action.state,
            action.data
        );
    }

    function _registerReceivable(bytes4 action) internal {
        _receivableActions.add(action);
    }
}
