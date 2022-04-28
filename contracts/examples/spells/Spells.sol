// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERCxxxx, Action, Strings} from "../../standard/ERCxxxx.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Spells is ERCxxxx, ERC721, Ownable {
    using SafeMath for uint256;

    bytes4 constant CAST_SELECTOR = bytes4(keccak256("cast"));
    bytes4 constant ATTUNE_SELECTOR = bytes4(keccak256("attune"));

    mapping(uint256 => uint256) spellDust;
    mapping(address => string) attunementRegistry;
    mapping(uint256 => address) attunement;

    constructor() ERC721("Spells", unicode"🔮") {
        _registerSendable(CAST_SELECTOR);
        _registerReceivable(ATTUNE_SELECTOR);
    }

    /// @dev Set unicode character "attunement" value for the given contract.
    /// Only callable by the contract owner.
    function setAttunement(address _contract, bytes32 _attunement) external {
        (bool ok, bytes memory _data) = _contract.staticcall(
            abi.encodeWithSignature("owner()")
        );
        require(ok, "Spells: not ok");
        require(
            msg.sender == abi.decode(_data, (address)),
            "Spells: invalid sender"
        );
        string memory unicodeChar;
        assembly {
            // Get first 6 bytes (format: \uXXXX)
            unicodeChar := shr(208, _attunement)
        }
        attunementRegistry[_contract] = unicodeChar;
    }

    function sendAction(Action memory action)
        external
        payable
        override
        onlySendableAction(action)
    {
        require(
            msg.sender == ownerOf(action.from._tokenId),
            "Spells: sender not owner"
        );
        _sendAction(action);
    }

    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
        // Pass action to state receiver
        if (action.selector == ATTUNE_SELECTOR) {
            attunement[action.to._tokenId] = action.from._address;
        }
        _onActionReceived(action, _nonce);
    }

    string[12] private dust = [
        unicode"․",
        unicode"․",
        unicode"․",
        unicode"․",
        unicode"∴",
        unicode"∴",
        unicode"∴",
        unicode"`",
        unicode"`",
        unicode"ҹ",
        unicode"⁕",
        unicode"º"
    ];

    string[5] private spells = [
        "Conjuring",
        "Divining",
        "Transforming",
        "Hexing",
        "Banishing"
    ];

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[16] memory canvas = _dustCanvas(tokenId);
        string
            memory out = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 350"><style>.base { fill: lightyellow; font-family: serif; font-size: 14px; } .chant { font-style: italic;} .dust {font-family: monospace; font-size: 8px; letter-spacing:5px;}.sm{font-size: 10px;} .sigil{font-family: monospace, font-size:13}</style><rect width="100%" height="100%" fill="#171717" /><text x="14" y="24" class="base">';
        out = string.concat(
            out,
            string.concat(spells[_spellType(tokenId)], " Spell")
        );

        uint256 i;
        for (i = 0; i < 16; i++) {
            out = string(
                abi.encodePacked(
                    out,
                    '</text><text x="20" y="',
                    Strings.toString(i * 10 + 145),
                    '" class="base chant dust">',
                    canvas[i]
                )
            );
        }
        out = string.concat(out, "</text></svg>");
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Spell #',
                        Strings.toString(tokenId),
                        '", "description": "Cast spells, attune spells.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(out)),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _dustCanvas(uint256 tokenId)
        internal
        view
        returns (string[16] memory canvas)
    {
        uint256 n = spellDust[tokenId];
        uint256 rand = _random(Strings.toString(tokenId));
        uint256 i;
        uint256 j;
        uint256[256] memory _chars;
        for (i = 0; i < n; i++) {
            if (_chars[rand % 256] <= 0) {
                _chars[rand % 256] = (rand % dust.length) + 1;
            } else {
                i--;
            }
            rand = rand.div(i + 3);
        }
        uint256 charidx;
        for (i = 0; i < 16; i++) {
            for (j = 0; j < 16; j++) {
                charidx = _chars[i * 16 + j];
                if (charidx > 0) {
                    canvas[i] = string(
                        abi.encodePacked(canvas[i], dust[charidx - 1])
                    );
                    rand += (i * j + j + 1);
                } else {
                    canvas[i] = string(abi.encodePacked(canvas[i], "\u00A0"));
                }
            }
        }
        return canvas;
    }

    function _spellType(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = _random(Strings.toString(tokenId));
        return rand % 6;
    }

    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
}