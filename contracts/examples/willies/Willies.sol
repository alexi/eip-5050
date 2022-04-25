// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import {IStateExample} from "./SlapState.sol";
import {Base64} from "../common/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../standard/ERCxxxx.sol";

contract Willies is ERCxxxx, ERC721, Ownable {
    bytes4 constant SLAP_SELECTOR = bytes4(keccak256("slap"));

    string constant deadFace = unicode"💀";
    string constant slappedFace = unicode"😵‍💫";
    string constant defaultFace = unicode"😀";
    string constant winningFace = unicode"🏆";

    mapping(uint256 => string) faces;

    // Restrict actions to single state controller.
    address slapStateController;

    constructor(address _slapStateController) ERC721("Willies", unicode"🏆") {
        _registerAction(SLAP_SELECTOR);
        slapStateController = _slapStateController;
    }

    function sendAction(Action memory action)
        external
        payable
        override
        onlySendableAction(action)
    {
        require(
            action.state == slapStateController,
            "invalid state controller"
        );
        uint256 strengthStart = IStateExample(action.state).getStrength(
            address(this),
            action.from._tokenId
        );
        require(strengthStart > 0, "not strong enough to commit");
        _sendAction(action);

        _updateFace(
            action.from._tokenId,
            strengthStart,
            IStateExample(action.state).getStrength(
                address(this),
                action.from._tokenId
            )
        );
    }

    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
        require(
            action.state == slapStateController,
            "invalid state controller"
        );
        uint256 strengthStart = IStateExample(action.state).getStrength(
            address(this),
            action.to._tokenId
        );
        require(
            strengthStart >
                IStateExample(action.state).getStrength(
                    address(action.from._address),
                    action.from._tokenId
                ),
            "sender weaker than receiver"
        );

        // Pass action to state receiver
        _onActionReceived(action, _nonce);

        // Update appearance based on fight outcome.
        _updateFace(
            action.to._tokenId,
            strengthStart,
            IStateExample(action.state).getStrength(
                address(this),
                action.to._tokenId
            )
        );
    }

    function _updateFace(
        uint256 tokenId,
        uint256 strengthStart,
        uint256 strengthEnd
    ) private {
        if (strengthEnd == 0) {
            faces[tokenId] = deadFace;
        } else if (strengthEnd > strengthStart) {
            faces[tokenId] = winningFace;
        } else if (strengthEnd < strengthStart) {
            faces[tokenId] = slappedFace;
        } else {
            faces[tokenId] = defaultFace;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string
            memory img = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 350"><style>.willy{ fill: white; font-family: serif; font-size: 60px; }</style><rect width="100%" height="100%" fill="#000000" /><text x="14" y="24" class="base">';
        string memory _face = faces[tokenId];
        if (bytes(_face).length == 0) {
            _face = defaultFace;
        }
        img = string.concat(img, _face);
        img = string.concat(img, "</text></svg>");
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Gate #',
                        Strings.toString(tokenId),
                        '", "description": "Willies like to slap and be slapped.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(img)),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
