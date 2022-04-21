// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import {IStateExample} from "./SlapState.sol";
import {StringCompare} from "./StringCompare.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../ERCxxxx.sol";

contract Willies is ERCxxxx, ERC721 {
    using StringCompare for string;

    string constant SLAP_ACTION = "SLAP";

    uint256 public numSuccessfulSends;
    uint256 public numSuccessfulReceives;

    constructor() ERC721("Willies", unicode"🏆") {}

    function commitAction(Action memory action)
        external
        payable
        override
        onlyValidCommitAction(action)
    {
        require(action.name.cmp(SLAP_ACTION), "invalid action");
        require(
            IStateExample(action.state).getStrength(
                address(this),
                action.from._tokenId
            ) > 2,
            "not strong enough to commit"
        );
        _commitAction(action);
        ++numSuccessfulSends;
    }

    function handleAction(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyValidAction(action, _nonce)
    {
        require(action.name.cmp(SLAP_ACTION), "invalid action");
        require(
            IStateExample(action.state).getStrength(
                address(this),
                action.to._tokenId
            ) >
                IStateExample(action.state).getStrength(
                    address(action.from._address),
                    action.from._tokenId
                ),
            "sender weaker than receiver"
        );
        _handleAction(action, _nonce);
        numSuccessfulReceives++;
    }
}
