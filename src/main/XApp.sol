// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.14;

import { IXApp } from "./IXApp.sol";

import { IExecutor } from "./vendor/connext/IExecutor.sol";
import { IConnextHandler } from "./vendor/connext/IConnextHandler.sol";
import { CallParams, XCallArgs, ExecuteArgs } from "./vendor/connext/LibConnextStorage.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/*
	XApp is mainly trying a catch-fail system. This will allow the user to try again the call if it fails for some reason.
	For POC purposes, we are doing permissionless call only and it's not optimized.
 */
contract XApp is IXApp, Ownable {
	IConnextHandler public immutable connext;
	uint32 public immutable domain;

	//Chain Domain -> XApp
	mapping(uint32 => address) public xCallApps;
	mapping(uint32 => uint256) public nonces;
	mapping(uint32 => mapping(uint256 => FailedCall)) public failedXCalls;

	uint256[] public failedNonce; //this is for test purposes.

	constructor(address _connext, uint32 _domain) {
		connext = IConnextHandler(_connext);
		domain = _domain;
	}

	function sendXCall(
		address _to,
		address _token,
		uint256 _tokenAmount,
		uint32 _destinationDomain,
		bool _permissionless,
		bytes calldata _payloadWithSignature
	) external {
		address xAppDestination = xCallApps[_destinationDomain];

		if (xAppDestination == address(0)) {
			revert XAppNotRegistered(_destinationDomain);
		}

		bytes memory callData = abi.encodeWithSignature(
			"xCallReceived(address,uint32,bytes)",
			_to,
			domain,
			_payloadWithSignature
		);

		CallParams memory callParams = CallParams({
			to: xAppDestination,
			callData: callData,
			originDomain: domain,
			destinationDomain: _destinationDomain,
			recovery: xAppDestination,
			callback: address(this),
			callbackFee: 0,
			forceSlow: !_permissionless,
			receiveLocal: false
		});

		XCallArgs memory xcallArgs = XCallArgs({
			params: callParams,
			transactingAssetId: _token,
			amount: _tokenAmount,
			relayerFee: 0
		});

		connext.xcall(xcallArgs);
		emit XCallSent(_destinationDomain, _to, _payloadWithSignature);
	}

	function xCallReceived(
		address _to,
		uint32 _domain,
		bytes calldata _payloadWithSignature
	) external {
		uint256 nonce = nonces[_domain];
		nonces[_domain]++;

		(bool success, ) = _to.call(_payloadWithSignature);

		if (success) {
			emit XCallExecuted(_domain, nonce, _to, _payloadWithSignature);
			return;
		}

		failedXCalls[_domain][nonce] = FailedCall(_to, _payloadWithSignature);

		failedNonce.push(nonce);
		emit FailedCallSaved(_domain, nonce, _to, _payloadWithSignature);
	}

	function retryFailedCall(uint32 _chainDomain, uint256 _nonce) external {
		FailedCall memory failedCallData = failedXCalls[_chainDomain][_nonce];

		if (failedCallData.to == address(0)) revert UnknownNonce();

		(bool success, ) = failedCallData.to.call(
			failedCallData.payloadWithSignature
		);

		if (!success) revert RetryFailed();

		delete failedXCalls[_chainDomain][_nonce];
	}

	function deleteFailedCall(uint32 _chainDomain, uint256 _nonce)
		external
		onlyOwner
	{
		delete failedXCalls[_chainDomain][_nonce];
	}

	function registerNewXApp(uint32 _chainDomain, address _xAppAddress)
		external
		onlyOwner
	{
		xCallApps[_chainDomain] = _xAppAddress;

		emit XAppRegistered(_chainDomain, _xAppAddress);
	}

	function getXAppAddressOf(uint32 _chainDomain)
		external
		view
		returns (address)
	{
		return xCallApps[_chainDomain];
	}

	function getFailedCallDataOf(uint32 _chainDomain, uint256 _nonce)
		external
		view
		returns (FailedCall memory)
	{
		return failedXCalls[_chainDomain][_nonce];
	}

	function getLastFailedNonce() external view returns (uint256) {
		return failedNonce[failedNonce.length - 1];
	}
}
