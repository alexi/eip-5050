// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../standard/ERCxxxx.sol";

contract Wizards is ERCxxxx, ERC721, Ownable {
    bytes4 constant CAST_SELECTOR = bytes4(keccak256("cast"));
    bytes4 constant ATTUNE_SELECTOR = bytes4(keccak256("attune"));

    address spells;
    mapping(uint256 => uint256) lastEnchanter;
    mapping(uint256 => uint256) lastEnchantedBlock;

    constructor(address _spells) ERC721("Willies", unicode"🏆") {
        spells = _spells;
        _registerReceivable(CAST_SELECTOR);
        _registerSendable(ATTUNE_SELECTOR);
    }

    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
        require(action.from._address == spells, "Wizards: invalid action.from");

        lastEnchantedBlock[action.to._tokenId] = block.number;
        lastEnchanter[action.to._tokenId] = action.from._tokenId;

        _onActionReceived(action, _nonce);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // wizard bg changes based on which kind of spell enchanted it
        string memory background = "white";
        if (block.number - lastEnchantedBlock[tokenId] < 5000) {
            uint256 spellType = _spellType(lastEnchanter[tokenId]);
            if (spellType == 0) {
                background = "black";
            } else if (spellType == 1) {
                background = "magenta";
            } else if (spellType == 2) {
                background = "yellow";
            } else if (spellType == 3) {
                background = "blue";
            } else if (spellType == 4) {
                background = "green";
            } else if (spellType == 5) {
                background = "red";
            }
        }
        string
            memory img = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 350"><style>.willy{ fill: white; font-family: serif; font-size: 60px; }</style><rect width="100%" height="100%" fill="';
        img = string.concat(img, background);
        img = string.concat(
            img,
            unicode'"/><text x="14" y="24" class="base">🧙</text></svg>'
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Gate #',
                        Strings.toString(tokenId),
                        '", "description": "Enchanted wizards ready to party.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(img)),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _spellType(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = _random(Strings.toString(tokenId));
        return rand % 6;
    }

    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
}
