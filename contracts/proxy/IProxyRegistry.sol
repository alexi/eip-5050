// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

interface IProxyRegistry {
    function register(address _contract, address _proxy) external;

    function deregister(address _contract) external;

    function getManager(address _contract) external view returns (address);

    function reverseProxy(address _proxy) external view returns (address);
}
