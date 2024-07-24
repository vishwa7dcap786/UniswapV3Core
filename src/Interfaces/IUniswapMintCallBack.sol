// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IUniswapMintCallBack {
    function uniswapMintCallBack(uint256 amount0, uint256 amount1, bytes calldata data) external;
}