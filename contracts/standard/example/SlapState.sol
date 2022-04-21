// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {StringCompare} from "./StringCompare.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IERCxxxx.sol";
import "../ERCxxxx.sol";
import "../Controllable.sol";

interface IStateExample {
    function registerToken(address _contract, uint256 tokenId) external;

    function getStrength(address _contract, uint256 tokenId)
        external
        view
        returns (uint256);
}

contract SlapState is ERCxxxx, Ownable {
    using Address for address;
    using StringCompare for string;

    mapping(address => mapping(uint256 => uint256)) tokenStrengths;

    string constant SLAP_ACTION = "SLAP";

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

    function handleAction(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyValidAction(action, _nonce)
    {
        require(action.name.cmp(SLAP_ACTION), "State: invalid action");
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
        require(
            fromStrength > toStrength,
            "State: cannot SLAP stronger target"
        );
        tokenStrengths[action.from._address][action.from._tokenId]++;
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
