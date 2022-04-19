// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Metaverse Protocol: [tbd]
/**********************************************************/

interface IApprovable {
    function approve(
        address from,
        address sender,
        string memory action
    ) external returns (bool);

    function revoke(
        address from,
        address sender,
        string memory action
    ) external returns (bool);

    function isApproved(
        address from,
        address sender,
        string memory action
    ) external view returns (bool);
}
