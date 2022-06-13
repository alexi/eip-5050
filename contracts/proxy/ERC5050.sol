// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import "./ERC5050Sender.sol";
import "./ERC5050Receiver.sol";

contract ERC5050 is ERC5050Sender, ERC5050Receiver {
    function setProxyRegistry(address registry)
        external
        virtual
        override(ERC5050Sender, ERC5050Receiver)
        onlyOwner
    {
        _setProxyRegistry(registry);
    }

    function _registerAction(string memory action) internal {
        _registerReceivable(action);
        _registerSendable(action);
    }
}
