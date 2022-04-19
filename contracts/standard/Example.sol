pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERCxxxx.sol";
import "./State.sol";

interface IStateExample {
    function getStrength(address _contract, uint256 tokenId)
        external
        view
        returns (uint256);
}

contract Sender is ERCxxxx {
    uint256 public numSuccessfulSends;

    function commitAction(Action memory action)
        external
        payable
        override
        onlyCommitableAction(action)
    {
        require(
            keccak256(action.name) == keccak256("ATTACK"),
            "invalid action"
        );
        require(
            IStateExample(action.state).getStrength(
                address(this),
                action.tokenId
            ) > 2,
            "not strong enough to commit"
        );
        _commitAction(action);
        ++numSuccessfulSends;
    }
}

contract Receiver is ERCxxxx {
    uint256 public numSuccessfulReceives;

    function handleAction(Action memory action)
        external
        payable
        override
        onlyValidAction(action)
    {
        require(
            keccak256(action.name) == keccak256("ATTACK"),
            "invalid action"
        );
        require(
            IStateExample(action.state).getStrength(
                address(this),
                action.toTokenId
            ) >
                IStateExample(action.state).getStrength(
                    address(action.fromContract),
                    action.tokenId
                ),
            "sender weaker than receiver"
        );
        numSuccessfulReceives++;
        _handleAction(action);
    }
}

contract State is ERCxxxxState {
    mapping(address => mapping(uint256 => uint256)) tokenStrengths;

    constructor() {}

    function getStrength(address _contract, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return tokenStrengths[_contract][tokenId];
    }

    function handleAction(Action memory action)
        external
        payable
        override
        onlyValidAction(action)
    {
        require(
            keccak256(action.name) == keccak256("ATTACK"),
            "invalid action"
        );
        require(
            tokenStrengths[action.fromContract][action.tokenId] >
                tokenStrengths[action.to][action.toTokenId] + 2,
            "sender weaker than receiver + 2"
        );
        tokenStrengths[action.to][action.toTokenId]--;
        _handleAction(action);
    }
}
