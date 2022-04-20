// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Metaverse Protocol: [tbd]
*
* Implementation of a metaverse protocol.
/**********************************************************/

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ERCxxxxStorage} from "./ERCxxxxStorage.sol";
import {IERCxxxx, IERCxxxxReceiver, Action} from "../interfaces/IERCxxxx.sol";
import {IApprovable} from "../interfaces/IApprovable.sol";
import {IControllable} from "../interfaces/IControllable.sol";

contract ERCxxxx is IERCxxxx, IApprovable, IControllable {
    using ERCxxxxStorage for ERCxxxxStorage.Layout;
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
            action._hash = ERCxxxxStorage.layout().receipt(action);
        }
        if (next.isContract()) {
            try
                IERCxxxxReceiver(next).handleAction{value: msg.value}(action)
            {} catch Error(string memory err) {
                revert(err);
            } catch (bytes memory returnData) {
                if (returnData.length > 0) {
                    revert(string(returnData));
                }
            }
            delete ERCxxxxStorage.layout().verified[action._hash];
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
        return ERCxxxxStorage.layout().verified[_hash];
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
        require(bytes(action.name).length > 0, "ERCxxxx: empty action name");
        if (msg.sender != action.from) {
            require(
                _isApproved(action.from, msg.sender, action.name),
                "ERCxxxx: unapproved sender"
            );
        }
        _;
    }

    modifier onlyValidAction(Action memory action) {
        if (_isApprovedController(msg.sender, action.name)) {
            return;
        }
        require(bytes(action.name).length > 0, "ERCxxxx: empty action name");
        if (action.to == address(this)) {
            require(
                action.fromContract == address(0) ||
                    action.fromContract == msg.sender,
                "ERCxxxx: invalid sender"
            );
            require(
                action.fromContract != address(0) || action.from == msg.sender,
                "ERCxxxx: invalid sender"
            );
        } else if (action.state == address(this)) {
            require(action.state == address(this), "ERCxxxx: invalid state");
            require(
                action.to == address(0) || action.to == msg.sender,
                "ERCxxxx: invalid sender"
            );
            require(
                action.fromContract == address(0) || action.to == msg.sender,
                "ERCxxxx: invalid sender"
            );
            if (action.to.isContract() && action.fromContract.isContract()) {
                try
                    IERCxxxx(action.fromContract).validateAction(action._hash)
                returns (bool ok) {
                    require(ok, "ERCxxxx: action not validated");
                } catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert("ERCxxxx: call to non ERCxxxx implementer");
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
                require(action.state.isContract(), "ERCxxxx: invalid state");
                try
                    IERCxxxxReceiver(action.state).handleAction{
                        value: msg.value
                    }(action)
                {} catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert(
                            "ERCxxxx: call to non ERCxxxxReceiver implementer"
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
        emit CommitAction(
            action.name,
            action.from,
            action.fromContract,
            action.tokenId,
            action.to,
            action.toTokenId,
            action.state,
            action.data
        );
    }

    function approve(
        address from,
        address sender,
        string memory action
    ) external virtual override returns (bool) {
        ERCxxxxStorage.layout().approvals[from][sender][action] = true;
        return true;
    }

    function revoke(
        address from,
        address sender,
        string memory action
    ) external virtual override returns (bool) {
        delete ERCxxxxStorage.layout().approvals[from][sender][action];
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
        ERCxxxxStorage.Layout storage es = ERCxxxxStorage.layout();
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
        ERCxxxxStorage.layout().controllers[sender][action] = true;
        return true;
    }

    function revokeController(address sender, string memory action)
        external
        virtual
        returns (bool)
    {
        delete ERCxxxxStorage.layout().controllers[sender][action];
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
        ERCxxxxStorage.Layout storage es = ERCxxxxStorage.layout();
        if (es.controllers[sender][action]) {
            return true;
        }
        if (es.controllers[sender][""]) {
            return true;
        }
        return false;
    }
}
