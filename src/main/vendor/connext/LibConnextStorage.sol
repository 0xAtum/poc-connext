// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

// ============= Structs =============

/**
 * @notice These are the call parameters that will remain constant between the
 * two chains. They are supplied on `xcall` and should be asserted on `execute`
 * @property to - The account that receives funds, in the event of a crosschain call,
 * will receive funds if the call fails.
 * @param to - The address you are sending funds (and potentially data) to
 * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
 * @param originDomain - The originating domain (i.e. where `xcall` is called). Must match nomad domain schema
 * @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called). Must match nomad domain schema
 * @param recovery - The address to send funds to if your `Executor.execute call` fails
 * @param callback - The address on the origin domain of the callback contract
 * @param callbackFee - The relayer fee to execute the callback
 * @param forceSlow - If true, will take slow liquidity path even if it is not a permissioned call
 * @param receiveLocal - If true, will use the local nomad asset on the destination instead of adopted.
 */
struct CallParams {
  address to;
  bytes callData;
  uint32 originDomain;
  uint32 destinationDomain;
  address recovery;
  address callback;
  uint256 callbackFee;
  bool forceSlow;
  bool receiveLocal;
}

/**
 * @notice The arguments you supply to the `xcall` function called by user on origin domain
 * @param params - The CallParams. These are consistent across sending and receiving chains
 * @param transactingAssetId - The asset the caller sent with the transfer. Can be the adopted, canonical,
 * or the representational asset
 * @param amount - The amount of transferring asset the tx called xcall with
 * @param relayerFee - The amount of relayer fee the tx called xcall with
 */
struct XCallArgs {
  CallParams params;
  address transactingAssetId; // Could be adopted, local, or wrapped
  uint256 amount;
  uint256 relayerFee;
}

/**
 * @notice
 * @param params - The CallParams. These are consistent across sending and receiving chains
 * @param local - The local asset for the transfer, will be swapped to the adopted asset if
 * appropriate
 * @param routers - The routers who you are sending the funds on behalf of
 * @param amount - The amount of liquidity the router provided or the bridge forwarded, depending on
 * if fast liquidity was used
 * @param relayerFee - The relayer fee amount
 * @param nonce - The nonce used to generate transfer id
 * @param originSender - The msg.sender of the xcall on origin domain
 */
struct ExecuteArgs {
  CallParams params;
  address local; // local representation of canonical token
  address[] routers;
  bytes[] routerSignatures;
  uint256 relayerFee;
  uint256 amount;
  uint256 nonce;
  address originSender;
}

/**
 * @notice Contains RouterFacet related state
 * @param approvedRouters - Mapping of whitelisted router addresses
 * @param routerRecipients - Mapping of router withdraw recipient addresses.
 * If set, all liquidity is withdrawn only to this address. Must be set by routerOwner
 * (if configured) or the router itself
 * @param routerOwners - Mapping of router owners
 * If set, can update the routerRecipient
 * @param proposedRouterOwners - Mapping of proposed router owners
 * Must wait timeout to set the
 * @param proposedRouterTimestamp - Mapping of proposed router owners timestamps
 * When accepting a proposed owner, must wait for delay to elapse
 */
struct RouterPermissionsManagerInfo {
  mapping(address => bool) approvedRouters;
  mapping(address => bool) approvedForPortalRouters;
  mapping(address => address) routerRecipients;
  mapping(address => address) routerOwners;
  mapping(address => address) proposedRouterOwners;
  mapping(address => uint256) proposedRouterTimestamp;
}