# EIP-xxxx: Action Protocol

This is a work-in-progress reference implementation of the upcoming Action Protocol EIP.

The Action Protocol enables users, ERC-721s, and other tokens to interact with each other, and with shared `State` contracts via `Actions`.

**Actions** are arbitrary strings, and structured to allow any combination of sender (`fromContract`), receiver (`to`), and `state` contract.

```solidity
struct Action {
    string name;
    address from;
    address fromContract;
    uint256 tokenId;
    address to;
    uint256 toTokenId;
    bytes ext;
    address state;
    uint256 _hash;
}

interface IERCxxxx {
    // Commit actions via the `fromContract`
    function commitAction(Action memory action) external payable;

    // `to` and `state` contracts handle actions sent either by 
    // the `fromContract` or, if no `fromContract` is set, the 
    // `from` address is expected to be the msg.sender.
    function handleAction(Action memory action) external payable;

    // `state` contracts validate actions with the `fromContract`.
    function validateAction(uint256 _hash) external returns (bool);
}
```

## Request for Comment

The Action Protocol is just beginning the EIP process. Everything is open for feedback, and all feedback is appreciated! Please dm me [@0xalxi](https://twitter.com/0xalxi) or find me on discord.

A few questions that are currently being discussed:

### Action Strings

Should actions be strings? Solidity does not have good strings support, and essentially every contract will need an if/switch statement to route action handlers.

### Bridging

Gas costs on mainnet are game-breakingly expensive, and most Metaverse games are being built on L2s and alternative L1s. While bridging is probably out of scope for this EIP, we should make sure that bridging can be done without additional callbacks or multiple transactions.

We should support: 

1. L1-action, L2-storage: Actions committed on layer 1 assets are saved to layer 2 state contracts.
2. Cross-chain token interactions: L1 asset acting on L2 asset.

### commitAction vs. handleAction

Separate functions generally helps move gas cost from action transmission to contract deployment, as we do not need as many checks. If commitAction was merged into handleAction, how do we know what step of the process we are on when a contract is both the sender and receiver? We would need to track the action step in a separate variable.

Currently, handleAction is used by both the receiving contract and the state contract. This means that state contracts need to be separate from action receiver contracts. This seems ok to me, but is an asymmetric design which makes me think there is a better alternative.
