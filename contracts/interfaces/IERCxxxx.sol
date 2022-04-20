// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alexi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Metaverse Protocol: [tbd]
/**********************************************************/

/// @param name The name of the action
/// @param from The address of the sender
/// @param fromContract The address of the sender
/// @param tokenId Optional ID of the sending token
/// @param to The address of the receiving wallet or contract
/// @param toTokenId Optional ID of the receiving token
/// @param state The state contract
/// @param nonce A nonce used by the `state` contract for validation
/// @param data Additional data with no specified format
struct Action {
    string name;
    address from;
    address fromContract;
    uint256 tokenId;
    address to;
    uint256 toTokenId;
    address state;
    uint256 nonce;
    bytes data;
}

contract Test {
    Action currentAction;
    uint256 nonce;

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

    function handleAction(
        Action calldata action,
        uint256 _hash,
        uint256 _nonce
    ) external payable {
        // action.sender.isValid(_hash)
        require(
            _hash ==
                uint256(
                    keccak256(
                        abi.encodePacked(
                            action.name,
                            action.from,
                            action.fromContract,
                            action.tokenId,
                            action.to,
                            action.toTokenId,
                            action.state,
                            action.data,
                            _nonce
                        )
                    )
                ),
            "hash is invlaid"
        );
    }
}

interface IERCxxxx {
    /// @notice Send an action to the target address
    /// @dev The action's `fromContract` is automatically set to `address(this)`,
    /// and the `from` parameter is set to `msg.sender`.
    /// @param action The action to send
    function commitAction(Action calldata action) external payable;

    /// @notice Handle an action
    /// @dev Both the `to` contract and `state` contract are called via
    /// `handleAction()`. This means that `state` and `to` must be different.
    /// @param action The action to handle
    /// @param _nonce Action nonce created by sender
    function handleAction(Action calldata action, uint256 _nonce)
        external
        payable;

    /// @notice Handle an action
    /// @dev Both the `to` contract and `state` contract are called via
    /// `handleAction()`. This means that `state` and `to` must be different.
    /// @param action The action to handle
    function handleAction(Action calldata action) external payable;

    /// @notice Check if an action is valid based on its hash and nonce
    /// @dev When an action passes through all three possible contracts
    /// (`fromContract`, `to`, and `state`) the `state` contract validates the
    /// action with the initating `fromContract` using a nonced action hash.
    /// This hash is calculated and saved to storage on the `fromContract` before
    /// action handling is initiated. The `state` contract calculates the hash
    /// and verifies it and nonce with the `fromContract`.
    /// @param _hash The hash to validate
    /// @param _nonce The nonce to validate
    function isValid(uint256 _hash, uint256 _nonce) external returns (bool);

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
