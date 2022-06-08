// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

interface IControllable {
    function approveController(address sender, bytes4 action)
        external
        returns (bool);

    function revokeController(address sender, bytes4 action)
        external
        returns (bool);

    function isApprovedController(address sender, bytes4 action)
        external
        view
        returns (bool);
}
