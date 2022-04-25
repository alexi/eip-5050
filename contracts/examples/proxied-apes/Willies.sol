// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import {SlapStateController} from "./SlapState.sol";
import {Base64} from "../common/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../proxy/ERCxxxx.sol";

contract Willies is ERCxxxx, ERC721, Ownable {
    bytes4 constant SLAP_SELECTOR = bytes4(keccak256("slap"));

    string constant deadFace = unicode"💀";
    string constant slappedFace = unicode"😵‍💫";
    string constant defaultFace = unicode"😀";
    string constant winningFace = unicode"🏆";

    /// Any state controller can be used for actions, but tokenURI
    /// reads need a single default.
    address defaultStateController;

    /// Allow token holders to set custom default state controller for
    /// tokenURI reads.
    mapping(uint256 => address) tokenStateController;

    constructor(address _defaultStateController)
        ERC721("Willies", unicode"🏆")
    {
        defaultStateController = _defaultStateController;
        _registerAction(SLAP_SELECTOR);
    }

    function getDefaultTokenStateController(uint256 tokenId)
        public
        view
        returns (address)
    {
        if (tokenStateController[tokenId] != address(0)) {
            return tokenStateController[tokenId];
        }
        return defaultStateController;
    }

    function setDefaultTokenStateController(
        uint256 tokenId,
        address stateController
    ) external {
        require(ownerOf(tokenId) == msg.sender, "not owner");
        tokenStateController[tokenId] = stateController;
    }

    function sendAction(Action memory action)
        external
        payable
        override
        onlySendableAction(action)
    {
        uint256 strengthStart = SlapStateController(action.state).getStrength(
            address(this),
            action.from._tokenId
        );
        require(strengthStart > 0, "not strong enough to commit");
        _sendAction(action);
    }

    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
        uint256 strengthStart = SlapStateController(action.state).getStrength(
            address(this),
            action.to._tokenId
        );
        require(
            strengthStart >
                SlapStateController(action.state).getStrength(
                    address(action.from._address),
                    action.from._tokenId
                ),
            "sender weaker than receiver"
        );

        // Pass action to state receiver
        _onActionReceived(action, _nonce);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        address stateController = getDefaultTokenStateController(tokenId);
        SlapStateController.TokenSlapState state = SlapStateController(
            stateController
        ).getState(address(this), tokenId);
        string memory face = defaultFace;
        if (state == SlapStateController.TokenSlapState.DEAD) {
            face = deadFace;
        } else if (state == SlapStateController.TokenSlapState.WINNER) {
            face = winningFace;
        } else if (state == SlapStateController.TokenSlapState.SLAPPED) {
            face = slappedFace;
        }
        string
            memory img = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 350"><style>.willy{ fill: white; font-family: serif; font-size: 60px; }</style><rect width="100%" height="100%" fill="#000000" /><text x="14" y="24" class="base">';

        img = string.concat(img, face);
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
