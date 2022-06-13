// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

interface IControllable {
    event ControllerApproval(
        address indexed _controller,
        bytes4 indexed _action
    );
    
    event ControllerApprovalForAll(
        address indexed _controller,
        bool _approved
    );
    
    function approveController(address _controller, bytes4 _action)
        external;

    function setControllerApprovalForAll(address _controller, bool _approved)
        external;

    function isApprovedController(address _controller, bytes4 _action)
        external
        view
        returns (bool);
}
