// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.14;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

/*
This is were we test the retry mechanism.


What I won't test:
- Callback 
    Callbacks are a bad design for E2E, mainly in web3.

- Permission's calls 
    Permissioned vs permisionless calls. There's no point of testing both in a PoC, the end result is the same.            

- recovery
    No need to test it.
*/

contract Target is Ownable {
	error NotAllowed();

	mapping(address => bool) public isAllowed;

	uint256 public uselessValue;

	function changeUselessValue(uint256 _value) external {
		uselessValue = _value;
	}

	function updateUselessValue(address _from, uint256 _uselessValue)
		external
	{
		if (!isAllowed[_from]) revert NotAllowed();
		uselessValue = _uselessValue;
	}

	function allowUserToXCall(address _user, bool _status) external {
		isAllowed[_user] = _status;
	}
}
