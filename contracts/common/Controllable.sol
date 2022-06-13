// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import "../interfaces/IControllable.sol";

contract Controllable is IControllable {
    mapping(address => mapping(bytes4 => bool)) private _actionControllers;
    mapping(address => bool) private _universalControllers;

    function approveController(address _controller, bytes4 _action)
        external
        virtual
    {
        _actionControllers[_controller][_action] = true;
        emit ControllerApproval(
            _controller,
            _action
        );
    }
    
    function setControllerApprovalForAll(address _controller, bool _approved)
        external
        virtual
    {
        _universalControllers[_controller] = _approved;
        emit ControllerApprovalForAll(
            _controller,
            _approved
        );
    }

    function isApprovedController(address _controller, bytes4 _action)
        external
        view
        returns (bool)
    {
        return _isApprovedController(_controller, _action);
    }

    function _isApprovedController(address _controller, bytes4 _action)
        internal
        view
        returns (bool)
    {
        if (_universalControllers[_controller]) {
            return true;
        }
        return _actionControllers[_controller][_action];
    }
}
