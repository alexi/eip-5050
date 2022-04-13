pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../diamond/interfaces/IERC4964.sol";
import "./Controllable.sol";
import "./Approvable.sol";

abstract contract ERC4964State is
    Controllable,
    Approvable,
    IERC4964Receiver,
    Ownable
{
    function _handleAction(Action memory action) internal {
        if (_isApprovedController(msg.sender, action.name)) {
            return;
        }
        require(address(this) == action.state, "invalid state");
        // if (!_isApprovedController(msg.sender, action.name)) {
        if (action.to != address(0)) {
            require(msg.sender == action.to, "invalid address");
        }
        require(tx.origin == action.from, "ERC4964: origin is invalid");
        if (action.fromContract != address(0)) {
            require(action._hash != 0, "EERC4964: zero hash");
            require(
                IERC4964(action.fromContract).validateAction(action._hash),
                "sender does not validate action"
            );
        }
        // }
        // if bridge and it is not the sender (i.e. an approved controller)
        // if (action.bridge != address(0) && msg.sender != action.bridge) {
        //     IERC4964Receiver(action.bridge).handleAction(action);
        // }
    }
}
