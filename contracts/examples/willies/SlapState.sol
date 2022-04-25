// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IERCxxxx.sol";
import "../../standard/ERCxxxxState.sol";

interface IStateExample {
    function registerToken(address _contract, uint256 tokenId) external;

    function getStrength(address _contract, uint256 tokenId)
        external
        view
        returns (uint256);
}

contract SlapState is ERCxxxxState, Ownable {
    using Address for address;

    mapping(address => mapping(uint256 => uint256)) tokenStrengths;

    bytes4 constant SLAP_SELECTOR = bytes4(keccak256("slap"));

    constructor() {
        _registerReceivable(SLAP_SELECTOR);
    }

    function registerToken(address _contract, uint256 tokenId) external {
        require(
            tokenStrengths[_contract][tokenId] == 0,
            "State: already registered"
        );
        tokenStrengths[_contract][tokenId] =
            (_random(_contract, tokenId) % 20) +
            4;
    }

    function getStrength(address _contract, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return tokenStrengths[_contract][tokenId];
    }

    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
        require(
            action.from._address.isContract() &&
                action.to._address.isContract(),
            "State: invalid to and from"
        );

        uint256 fromStrength = tokenStrengths[action.from._address][
            action.from._tokenId
        ];
        uint256 toStrength = tokenStrengths[action.to._address][
            action.to._tokenId
        ];
        require(fromStrength > 0 && toStrength > 0, "0 strength token");

        uint256 val = (_random(action.from._address, action.from._tokenId) %
            (fromStrength + toStrength)) + 1;

        // Relative strength determines likelihood of a win.
        if (val < fromStrength) {
            // sender wins!
            uint256 delta = fromStrength - val;
            fromStrength += delta;
            if (delta >= toStrength) {
                toStrength = 0;
            } else {
                toStrength -= delta;
            }
        } else {
            // receiver wins!
            uint256 delta = val - fromStrength;
            toStrength += delta;
            if (delta >= fromStrength) {
                fromStrength = 0;
            } else {
                fromStrength -= delta;
            }
        }
        tokenStrengths[action.from._address][
            action.from._tokenId
        ] = fromStrength;
        tokenStrengths[action.to._address][action.to._tokenId] = toStrength;
    }

    function _random(address _contract, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(abi.encodePacked(block.coinbase, _contract, tokenId))
            );
    }
}
