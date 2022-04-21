// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IERCxxxx.sol";
import "./Controllable.sol";

contract ERCxxxx is Controllable, IERCxxxx {
    using Address for address;

    uint256 private _nonce;
    uint256 private _hash;

    mapping(address => mapping(string => address)) actionApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;

    function commitAction(Action memory action)
        external
        payable
        virtual
        override
    {
        _commitAction(action);
    }

    function isValid(uint256 actionHash, uint256 nonce)
        external
        view
        returns (bool)
    {
        return actionHash == _hash && nonce == _nonce;
    }

    function handleAction(Action memory action, uint256 nonce)
        external
        payable
        virtual
        override
    {
        _handleAction(action, nonce);
    }

    modifier onlyValidCommitAction(Action memory action) {
        if (_isApprovedController(msg.sender, action.name)) {
            return;
        }
        require(bytes(action.name).length > 0, "ERCxxxx: empty action name");
        require(
            _isApprovedOrSelf(action.user, action.name),
            "ERCxxxx: unapproved sender"
        );
        _;
    }

    modifier onlyValidAction(Action calldata action, uint256 nonce) {
        if (_isApprovedController(msg.sender, action.name)) {
            return;
        }
        require(bytes(action.name).length > 0, "ERCxxxx: empty action name");
        if (action.to._address == address(this)) {
            require(
                action.from._address == address(0) ||
                    action.from._address == msg.sender,
                "ERCxxxx: invalid sender"
            );
            require(
                action.from._address != address(0) || action.user == msg.sender,
                "ERCxxxx: invalid sender"
            );
        } else if (action.state == address(this)) {
            require(action.state == address(this), "ERCxxxx: invalid state");
            require(
                action.to._address == address(0) ||
                    action.to._address == msg.sender,
                "ERCxxxx: invalid sender"
            );
            require(
                action.from._address == address(0) ||
                    action.to._address == msg.sender,
                "ERCxxxx: invalid sender"
            );

            // State contracts must validate the action with the `from` contract in
            // the case of a 3-contract chain (`from`, `to` and `state`) all set to
            // valid contract addresses.
            if (
                action.to._address.isContract() &&
                action.from._address.isContract()
            ) {
                uint256 actionHash = uint256(
                    keccak256(
                        abi.encodePacked(
                            action.name,
                            action.user,
                            action.from._address,
                            action.from._tokenId,
                            action.to._address,
                            action.to._tokenId,
                            action.state,
                            action.data,
                            nonce
                        )
                    )
                );
                try
                    IERCxxxx(action.from._address).isValid(actionHash, nonce)
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

    function approveForAction(
        address _account,
        string memory _action,
        address _approved
    ) public virtual override returns (bool) {
        require(_approved != _account, "ERCxxxx: approve to caller");

        require(
            msg.sender == _account ||
                isApprovedForAllActions(_account, msg.sender),
            "ERCxxxx: approve caller is not account nor approved for all"
        );

        actionApprovals[_account][_action] = _approved;
        emit ApprovalForAction(_account, _action, _approved);

        return true;
    }

    function setApprovalForAllActions(address _operator, bool _approved)
        public
        virtual
        override
    {
        require(msg.sender != _operator, "ERCxxxx: approve to caller");

        operatorApprovals[msg.sender][_operator] = _approved;

        emit ApprovalForAllActions(msg.sender, _operator, _approved);
    }

    function getApprovedForAction(address _account, string memory _action)
        public
        view
        returns (address)
    {
        return actionApprovals[_account][_action];
    }

    function isApprovedForAllActions(address _account, address _operator)
        public
        view
        returns (bool)
    {
        return operatorApprovals[_account][_operator];
    }

    function _commitAction(Action memory action) internal {
        if (_isApprovedController(msg.sender, action.name)) {
            return;
        }
        action.from._address = address(this);
        bool toIsContract = action.to._address.isContract();
        bool stateIsContract = action.state.isContract();
        address next;
        if (toIsContract) {
            next = action.to._address;
        } else if (stateIsContract) {
            next = action.state;
        }
        uint256 nonce;
        if (toIsContract && stateIsContract) {
            _validate(action);
            nonce = _nonce;
        }
        if (next.isContract()) {
            try
                IERCxxxx(next).handleAction{value: msg.value}(action, nonce)
            {} catch Error(string memory err) {
                revert(err);
            } catch (bytes memory returnData) {
                if (returnData.length > 0) {
                    revert(string(returnData));
                }
            }
        }
        emit CommitAction(
            action.name,
            action.user,
            action.from._address,
            action.from._tokenId,
            action.to._address,
            action.to._tokenId,
            action.state,
            action.data
        );
    }

    function _validate(Action memory action) internal {
        ++_nonce;
        _hash = uint256(
            keccak256(
                abi.encodePacked(
                    action.name,
                    action.user,
                    action.from._address,
                    action.from._tokenId,
                    action.to._address,
                    action.to._tokenId,
                    action.state,
                    action.data,
                    _nonce
                )
            )
        );
    }

    function _handleAction(Action memory action, uint256 nonce)
        internal
        virtual
    {
        if (_isApprovedController(msg.sender, action.name)) {
            return;
        }
        if (action.to._address == address(this)) {
            if (action.state != address(0)) {
                require(action.state.isContract(), "ERCxxxx: invalid state");
                try
                    IERCxxxx(action.state).handleAction{value: msg.value}(
                        action,
                        nonce
                    )
                {} catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert("ERCxxxx: call to non ERCxxxx implementer");
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            }
        } else {
            // Handle as state contract
            if (action.from._address.isContract()) {}
        }
        emit CommitAction(
            action.name,
            action.user,
            action.from._address,
            action.from._tokenId,
            action.to._address,
            action.to._tokenId,
            action.state,
            action.data
        );
    }

    function _isApprovedOrSelf(address account, string memory action)
        internal
        view
        returns (bool)
    {
        return (msg.sender == account ||
            isApprovedForAllActions(account, msg.sender) ||
            getApprovedForAction(account, action) == msg.sender);
    }
}
