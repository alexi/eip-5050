// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Metaverse Protocol: [tbd]
/**********************************************************/

import {Action} from "../interfaces/IERCxxxx.sol";

library ERCxxxxStorage {
    bytes32 constant ERC_xxxx_STORAGE_POSITION =
        keccak256("ercxxxx.interaction.location");

    struct Layout {
        mapping(uint256 => bool) verified;
        uint256 nonce;
        mapping(address => mapping(address => mapping(string => bool))) approvals;
        mapping(address => mapping(string => bool)) controllers;
    }

    function layout() internal pure returns (Layout storage es) {
        bytes32 position = ERC_xxxx_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

    function receipt(Layout storage l, Action memory action)
        internal
        returns (uint256 _hash)
    {
        _hash = uint256(
            keccak256(
                abi.encodePacked(
                    action.name,
                    action.from,
                    action.fromContract,
                    action.tokenId,
                    action.to,
                    action.toTokenId,
                    action.ext,
                    action.state,
                    l.nonce
                )
            )
        );
        ++l.nonce;
        l.verified[_hash] = true;
    }
}
