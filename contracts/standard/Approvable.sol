pragma solidity ^0.8.0;

import "../interfaces/IApprovable.sol";

contract Approvable is IApprovable {
    mapping(address => mapping(address => mapping(string => bool)))
        private _approvals;

    function approve(
        address from,
        address sender,
        string memory action
    ) external virtual override returns (bool) {
        _approvals[from][sender][action] = true;
        return true;
    }

    function revoke(
        address from,
        address sender,
        string memory action
    ) external virtual override returns (bool) {
        delete _approvals[from][sender][action];
        return true;
    }

    // TODO: should approve for specific `from`
    function isApproved(
        address from,
        address sender,
        string memory action
    ) external view returns (bool) {
        return _isApproved(from, sender, action);
    }

    function _isApproved(
        address from,
        address sender,
        string memory action
    ) internal view returns (bool) {
        if (_approvals[from][sender][action]) {
            return true;
        }
        if (_approvals[from][sender][""]) {
            return true;
        }
        return false;
    }
}
