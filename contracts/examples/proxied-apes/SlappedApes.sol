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
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../proxy/ERCxxxx.sol";

// Bored
contract ApesProxy is ERCxxxx, Ownable {
    bytes4 constant SLAP_SELECTOR = bytes4(keccak256("slap"));

    // Suppose other actions are also supported
    bytes4 constant CAST_SELECTOR = bytes4(keccak256("cast"));
    bytes4 constant HONOR_SELECTOR = bytes4(keccak256("honor"));

    address bayc;

    /// Any state controller can be used for actions, but tokenURI
    /// reads need a single default.
    address defaultSlapStateController;

    /// Allow token holders to set custom default state controller for
    /// tokenURI reads.
    mapping(uint256 => address) tokenSlapStateController;

    /// Off-chain BAYC service listens for `StateControllerUpdate` events
    /// and updates render to match the user-defined state controller.
    event StateControllerUpdate(
        uint256 tokenId,
        string controllerType,
        address controller
    );

    constructor(address _bayc) {
        _registerAction(SLAP_SELECTOR);
        bayc = _bayc;
    }

    function sendAction(Action memory action)
        external
        payable
        override
        onlySendableAction(action)
    {
        if (action.selector == SLAP_SELECTOR) {
            _sendSlap(action);
        }
    }

    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
        if (action.selector == SLAP_SELECTOR) {
            _onSlapReceived(action, _nonce);
        }
    }

    /// Off-chain BAYC service listens for `ActionReceived` events and updates
    /// the render based on the `TokenSlapState` of the token's default `SlapStateController`.
    function getDefaultTokenSlapStateController(uint256 tokenId)
        public
        view
        returns (address)
    {
        if (tokenSlapStateController[tokenId] != address(0)) {
            return tokenSlapStateController[tokenId];
        }
        return defaultSlapStateController;
    }

    function setDefaultTokenSlapStateController(
        uint256 tokenId,
        address stateController
    ) external {
        require(IERC721(bayc).ownerOf(tokenId) == msg.sender, "not owner");
        tokenSlapStateController[tokenId] = stateController;
        emit StateControllerUpdate(tokenId, "slap", stateController);
    }

    function _sendSlap(Action memory action) private {
        uint256 strengthStart = SlapStateController(action.state).getStrength(
            bayc,
            action.to._tokenId
        );
        require(strengthStart > 0, "dead ape");

        _sendAction(action);
    }

    function _onSlapReceived(Action calldata action, uint256 _nonce) private {
        _onActionReceived(action, _nonce);
    }
}
