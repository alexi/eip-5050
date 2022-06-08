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

contract ERC5050TempProxyRegistry {
    mapping(address => address) _lookup;
    mapping(address => address) _reverseLookup;

    function register(address _contract, address _proxy) external {
        delete _reverseLookup[_proxy];
        _lookup[_contract] = _proxy;
        _reverseLookup[_proxy] = _contract;
    }

    function deregister(address _contract) external {
        address _proxy = _lookup[_contract];
        delete _reverseLookup[_proxy];
        delete _lookup[_contract];
    }

    function proxy(address _contract) external view returns (address) {
        return _lookup[_contract];
    }

    function reverseProxy(address _proxy) external view returns (address) {
        return _reverseLookup[_proxy];
    }
}
