// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-4964 Metaverse Protocol: [tbd]
/**********************************************************/

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

interface IERC4964Receiver {
    function handleAction(Action memory action) external payable;
}

interface IERC4964 {
    function commitAction(Action memory action) external payable;

    function handleAction(Action memory action) external payable;

    function validateAction(uint256 _hash) external returns (bool);

    event ActionTx(
        string indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        bytes _ext,
        address state
    );
}

interface IERC4964Definable is IERC4964 {
    function definition(uint256 tokenId, uint256 namespace)
        external
        view
        returns (bytes32);
}
