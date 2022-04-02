// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-4964 Metaverse Protocol: [tbd]
*
* Implementation of a metaverse protocol.
/**********************************************************/

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ERC4964Storage} from "./ERC4964Storage.sol";
import {IERC4964, IERC4964Receiver, Action} from "../interfaces/IERC4964.sol";
import {IApprovable} from "../interfaces/IApprovable.sol";
import {IControllable} from "../interfaces/IControllable.sol";

contract ERC4964 is IERC4964, IApprovable, IControllable {
    using ERC4964Storage for ERC4964Storage.Layout;
    using Address for address;

    event Log(string message);

    function commitAction(Action memory action)
        external
        payable
        virtual
        override
    {
        _commitAction(action);
    }

    function _commitAction(Action memory action) internal {
        if (_isApprovedController(msg.sender, action.name)) {
            return;
        }
        action.fromContract = address(this);
        bool toIsContract = action.to.isContract();
        bool stateIsContract = action.state.isContract();
        address next;
        if (toIsContract) {
            next = action.to;
        } else if (stateIsContract) {
            next = action.state;
        }
        if (toIsContract && stateIsContract) {
            action._hash = ERC4964Storage.layout().receipt(action);
        }
        if (next.isContract()) {
            try
                IERC4964Receiver(next).handleAction{value: msg.value}(action)
            {} catch Error(string memory err) {
                revert(err);
            } catch (bytes memory returnData) {
                if (returnData.length > 0) {
                    revert(string(returnData));
                }
            }
            delete ERC4964Storage.layout().verified[action._hash];
        }
        emit ActionTx(
            action.name,
            action.from,
            action.fromContract,
            action.tokenId,
            action.to,
            action.toTokenId,
            action.ext,
            action.state
        );
    }

    function validateAction(uint256 _hash)
        external
        view
        override
        returns (bool)
    {
        return ERC4964Storage.layout().verified[_hash];
    }

    function handleAction(Action memory action)
        external
        payable
        virtual
        override
    {
        _handleAction(action);
    }

    modifier onlyValidCommitAction(Action memory action) {
        if (_isApprovedController(msg.sender, action.name)) {
            return;
        }
        require(bytes(action.name).length > 0, "ERC4964: empty action name");
        if (msg.sender != action.from) {
            require(
                _isApproved(action.from, msg.sender, action.name),
                "ERC4964: unapproved sender"
            );
        }
        _;
    }

    modifier onlyValidAction(Action memory action) {
        if (_isApprovedController(msg.sender, action.name)) {
            return;
        }
        require(bytes(action.name).length > 0, "ERC4964: empty action name");
        if (action.to == address(this)) {
            require(
                action.fromContract == address(0) ||
                    action.fromContract == msg.sender,
                "ERC4964: invalid sender"
            );
            require(
                action.fromContract != address(0) || action.from == msg.sender,
                "ERC4964: invalid sender"
            );
        } else if (action.state == address(this)) {
            require(action.state == address(this), "ERC4964: invalid state");
            require(
                action.to == address(0) || action.to == msg.sender,
                "ERC4964: invalid sender"
            );
            require(
                action.fromContract == address(0) || action.to == msg.sender,
                "ERC4964: invalid sender"
            );
            if (action.to.isContract() && action.fromContract.isContract()) {
                try
                    IERC4964(action.fromContract).validateAction(action._hash)
                returns (bool ok) {
                    require(ok, "ERC4964: action not validated");
                } catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert("ERC4964: call to non ERC4964 implementer");
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            }
        }
        _;
    }

    function _handleAction(Action memory action) internal virtual {
        if (_isApprovedController(msg.sender, action.name)) {
            return;
        }
        if (action.to == address(this)) {
            if (action.state != address(0)) {
                require(action.state.isContract(), "ERC4964: invalid state");
                try
                    IERC4964Receiver(action.state).handleAction{
                        value: msg.value
                    }(action)
                {} catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert(
                            "ERC4964: call to non ERC4964Receiver implementer"
                        );
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            }
        } else {
            // Handle as state contract
            if (action.fromContract.isContract()) {}
        }
        emit ActionTx(
            action.name,
            action.from,
            action.fromContract,
            action.tokenId,
            action.to,
            action.toTokenId,
            action.ext,
            action.state
        );
    }

    function approve(
        address from,
        address sender,
        string memory action
    ) external virtual override returns (bool) {
        ERC4964Storage.layout().approvals[from][sender][action] = true;
        return true;
    }

    function revoke(
        address from,
        address sender,
        string memory action
    ) external virtual override returns (bool) {
        delete ERC4964Storage.layout().approvals[from][sender][action];
        return true;
    }

    function isApproved(
        address from,
        address sender,
        string memory action
    ) external view returns (bool) {
        return _isApproved(from, sender, action);
    }

    function _isApproved(
        address from,
        address sender,
        string memory action
    ) internal view returns (bool) {
        ERC4964Storage.Layout storage es = ERC4964Storage.layout();
        if (es.approvals[from][sender][action]) {
            return true;
        }
        if (es.approvals[from][sender][""]) {
            return true;
        }
        return false;
    }

    function approveController(address sender, string memory action)
        external
        virtual
        returns (bool)
    {
        ERC4964Storage.layout().controllers[sender][action] = true;
        return true;
    }

    function revokeController(address sender, string memory action)
        external
        virtual
        returns (bool)
    {
        delete ERC4964Storage.layout().controllers[sender][action];
        return true;
    }

    function isApprovedController(address sender, string memory action)
        external
        view
        returns (bool)
    {
        return _isApprovedController(sender, action);
    }

    function _isApprovedController(address sender, string memory action)
        internal
        view
        returns (bool)
    {
        ERC4964Storage.Layout storage es = ERC4964Storage.layout();
        if (es.controllers[sender][action]) {
            return true;
        }
        if (es.controllers[sender][""]) {
            return true;
        }
        return false;
    }
}
