// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Metaverse Protocol: [tbd]
/**********************************************************/

interface IControllable {
    function approveController(address sender, string memory action)
        external
        returns (bool);

    function revokeController(address sender, string memory action)
        external
        returns (bool);

    function isApprovedController(address sender, string memory action)
        external
        view
        returns (bool);
}
