// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProxyRegistry} from "./IProxyRegistry.sol";

contract ProxyClient {
    IProxyRegistry proxyRegistry;

    function _setProxyRegistry(address _proxyRegistry) internal {
        proxyRegistry = IProxyRegistry(_proxyRegistry);
    }

    function getManager(address _contract) internal view returns (address) {
        return proxyRegistry.getManager(_contract);
    }

    function reverseProxy(address _proxy) internal view returns (address) {
        return proxyRegistry.reverseProxy(_proxy);
    }
}
