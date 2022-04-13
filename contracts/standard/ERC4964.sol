pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IERC4964.sol";
import "./Controllable.sol";
import "./Approvable.sol";

contract ERC4964 is Approvable, Controllable, IERC4964 {
    using Address for address;
    mapping(uint256 => bool) private _verified;
    uint256 private _nonce;

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
            ++_nonce;
            uint256 _hash = uint256(
                keccak256(
                    abi.encodePacked(
                        action.name,
                        action.from,
                        action.fromContract,
                        action.tokenId,
                        action.to,
                        action.toTokenId,
                        action.ext,
                        action.state,
                        _nonce
                    )
                )
            );
            _verified[_hash] = true;
            action._hash = _hash;
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
            delete _verified[action._hash];
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

    modifier onlyCommitableAction(Action memory action) {
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

    function validateAction(uint256 _hash)
        external
        view
        override
        returns (bool)
    {
        return _verified[_hash];
    }

    function handleAction(Action memory action)
        external
        payable
        virtual
        override
    {
        _handleAction(action);
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
}
