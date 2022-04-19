pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IERCxxxx.sol";
import "./Controllable.sol";
import "./Approvable.sol";

abstract contract ERCxxxxState is
    Controllable,
    Approvable,
    IERCxxxxReceiver,
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
        require(tx.origin == action.from, "ERCxxxx: origin is invalid");
        if (action.fromContract != address(0)) {
            require(action._hash != 0, "EERCxxxx: zero hash");
            require(
                IERCxxxx(action.fromContract).validateAction(action._hash),
                "sender does not validate action"
            );
        }
        // }
        // if bridge and it is not the sender (i.e. an approved controller)
        // if (action.bridge != address(0) && msg.sender != action.bridge) {
        //     IERCxxxxReceiver(action.bridge).handleAction(action);
        // }
    }
}
