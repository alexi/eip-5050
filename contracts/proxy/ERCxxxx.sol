// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import "./ERCxxxxSender.sol";
import "./ERCxxxxReceiver.sol";

contract ERCxxxx is ERCxxxxSender, ERCxxxxReceiver {
    function setProxyRegistry(address registry)
        external
        virtual
        override(ERCxxxxSender, ERCxxxxReceiver)
        onlyOwner
    {
        _setProxyRegistry(registry);
    }

    function _registerAction(bytes4 action) internal {
        _registerReceivable(action);
        _registerSendable(action);
    }
}
