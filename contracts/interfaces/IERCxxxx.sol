// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alexi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Metaverse Protocol: [tbd]
/**********************************************************/

/// @dev This emits when an action is sent (`commitAction()`)
/// @param name The name of the action
/// @param from The address of the sender
/// @param fromContract The address of the sender
/// @param tokenId Optional ID of the sending token
/// @param to The address of the receiving wallet or contract
/// @param toTokenId Optional ID of the receiving token
/// @param state The state contract
/// @param data Additional data with no specified format
struct Action {
    string name;
    address from;
    address fromContract;
    uint256 tokenId;
    address to;
    uint256 toTokenId;
    address state;
    bytes data;
}

contract Test {
    Action currentAction;

    function getAction() external view returns (Action memory) {
        return currentAction;
    }

    function commitAction(Action calldata action) external payable {
        // MUST be initiated by user
        require(action.from == msg.sender);
        currentAction = action;
        // action.next.handleAction()
        delete currentAction;
    }

    function handleAction(Action calldata action) external payable {
        // MUST be initiated by user
        require(action.from == msg.sender);
        require(action.fromContract == address(0));
        if (action.to == address(this)) {
            currentAction = action;
        } else {
            require(action.state == address(this));
        }
        // do handling
        // action.next.handleAction(address(this))
        delete currentAction;
    }

    function handleAction(address origin) external payable {
        Action memory action = IERCxxxx(origin).getAction();
        if (action.fromContract != address(0)) {
            // origin must be fromContract (always first in the chain when used)
            require(action.fromContract == origin);
        } else {
            // if no fromContract, origin must be `to`. Otherwise there is
            // no `fromContract` and either no `to` or `to` is a wallet,
            // then handleAction(Action) should be called directly on the
            // `state` contract.
            require(action.to == origin);
            require(action.state == address(this));
        }
        //
    }
}

interface IERCxxxx {
    function getAction() external returns (Action memory);

    /// @notice Send an action to the target address
    /// @dev The action's `fromContract` is automatically set to `address(this)`,
    /// and the `from` parameter is set to `msg.sender`.
    /// @param action The action to send
    function commitAction(Action calldata action) external payable;

    /// @notice Handle an action
    /// @dev Both the `to` contract and `state` contract are called via
    /// `handleAction()`. This means that `state` and `to` must be different.
    /// @param action The action to handle
    function handleAction(Action calldata action) external payable;

    /// @notice Handle an action
    /// @dev Both the `to` contract and `state` contract are called via
    /// `handleAction()`. This means that `state` and `to` must be different.
    function handleAction(uint256 nonce) external payable;

    /// @notice Handle an action
    /// @dev Both the `to` contract and `state` contract are called via
    /// `handleAction()`. This means that `state` and `to` must be different.
    /// @param action The action to handle
    function handleAction(Action calldata action, uint256 nonce)
        external
        payable;

    /// @notice Check if an action is valid
    /// @dev State contracts need to validate the `fromContract`
    /// when called by the `to` contract (`msg.sender == action.to`). When
    /// both `to` and `state` are set to contract addresses, the sending contract
    /// (`fromContract`) sets a nonce, which is then sending `fromContract`
    /// sets a nonce in `storage`, and includes it in `action._nonce`. The
    /// state contract calls `validateAction(action._nonce)`.
    /// @param _nonce The nonce to validate
    function isValid(uint256 _nonce) external returns (bool);

    /// @dev This emits when an action is sent (`commitAction()`)
    event CommitAction(
        string indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );

    /// @dev This emits when an action is received (`handleAction()`)
    event HandleAction(
        string indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );
}

interface IERCxxxxReceiver {
    function handleAction(Action memory action) external payable;
}
