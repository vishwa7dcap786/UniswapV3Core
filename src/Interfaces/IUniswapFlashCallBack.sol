// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IUniswapFlashCallBack {
    function uniswapFlashCallBack(uint256 amount0, uint256 amount1, bytes calldata data) external;
}