// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {IExecutor} from "./IExecutor.sol";
import { CallParams, XCallArgs, ExecuteArgs } from "./LibConnextStorage.sol";

interface IConnextHandler {
  // BridgeFacet
  function relayerFees(bytes32 _transferId) external view returns (uint256);

  function routedTransfers(bytes32 _transferId) external view returns (address[] memory);

  function domain() external view returns (uint256);

  function executor() external view returns (IExecutor);

  function nonce() external view returns (uint256);

  function xcall(XCallArgs calldata _args) external payable returns (bytes32);

  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external;

  function execute(ExecuteArgs calldata _args) external returns (bytes32 transferId);
}
