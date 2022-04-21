// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import {Action} from "../interfaces/IERCxxxx.sol";

library ERCxxxxStorage {
    bytes32 constant ERC_xxxx_STORAGE_POSITION =
        keccak256("ercxxxx.interaction.location");

    struct Layout {
        uint256 hash;
        uint256 nonce;
        mapping(address => mapping(string => address)) actionApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(address => mapping(string => bool)) controllers;
    }

    function layout() internal pure returns (Layout storage es) {
        bytes32 position = ERC_xxxx_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

    function hashAndGetNonce(Layout storage l, Action memory action)
        internal
        returns (uint256)
    {
        ++l.nonce;
        l.hash = uint256(
            keccak256(
                abi.encodePacked(
                    action.name,
                    action.user,
                    action.from._address,
                    action.from._tokenId,
                    action.to._address,
                    action.to._tokenId,
                    action.state,
                    action.data,
                    l.nonce
                )
            )
        );
        return l.nonce;
    }

    function isValid(
        Layout storage l,
        uint256 _hash,
        uint256 _nonce
    ) internal view returns (bool) {
        return l.hash == _hash && l.nonce == _nonce;
    }
}
