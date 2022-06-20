// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.14;

interface IXApp {
	error NoOwner();
	error UnknownNonce();
	error RetryFailed();
	error XAppNotRegistered(uint32);

	event XAppRegistered(uint32 indexed chainDomain, address xAppContract);
	event XCallSent(
		uint32 indexed destinationDomain,
		address indexed destinationContract,
		bytes payloadWithSignature
	);
	event XCallExecuted(
		uint32 indexed originDomain,
		uint256 nonce,
		address destination,
		bytes payloadWithSignature
	);
	event FailedCallSaved(
		uint32 indexed originDomain,
		uint256 nonce,
		address destination,
		bytes payloadWithSignature
	);

	struct FailedCall {
		address to;
		bytes payloadWithSignature;
	}
}
