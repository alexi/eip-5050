// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import "../interfaces/IControllable.sol";

contract Controllable is IControllable {
    mapping(address => mapping(string => bool)) private _approvedControllers;

    function approveController(address sender, string memory action)
        external
        virtual
        returns (bool)
    {
        _approvedControllers[sender][action] = true;
        return true;
    }

    function revokeController(address sender, string memory action)
        external
        virtual
        returns (bool)
    {
        delete _approvedControllers[sender][action];
        return true;
    }

    function isApprovedController(address sender, string memory action)
        external
        view
        returns (bool)
    {
        return _isApprovedController(sender, action);
    }

    function _isApprovedController(address sender, string memory action)
        internal
        view
        returns (bool)
    {
        if (_approvedControllers[sender][action]) {
            return true;
        }
        if (_approvedControllers[sender][""]) {
            return true;
        }
        return false;
    }
}
