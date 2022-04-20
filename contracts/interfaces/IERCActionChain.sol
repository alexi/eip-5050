// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alexi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Metaverse Protocol: [tbd]
/**********************************************************/

struct Node {
    address _address;
    uint256 _tokenId;
}

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
    Node[] chain;
    address state;
    bytes data;
}

contract ChainTest {
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
        require(action.chain[0]._address == address(0));

        // require(action.chain.last() == msg.sender)
        // if (action.chain.next().isContract()){
        //      pass to next
        // } else if (action.state.isContract()) {
        //     pass to state
        // }

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

interface IERCActionChain {
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

    /// @notice Get the initiating contract's stored hash value
    /// @dev State contracts need to validate the `fromContract`
    /// when called by the `to` contract (`msg.sender == action.to`). When
    /// both `to` and `state` are set to contract addresses, the sending contract
    /// (`fromContract`) sets a nonce, which is then sending `fromContract`
    /// sets a nonce in `storage`, and includes it in `action._nonce`. The
    /// state contract calls `validateAction(action._nonce)`.
    function getHash() external returns (uint256);

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
