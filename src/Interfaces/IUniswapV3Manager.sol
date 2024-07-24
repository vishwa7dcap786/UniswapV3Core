//SPDX-Lisence-Identifier:MIT

pragma solidity 0.8.24;

interface IUniswapV3Manager{

    struct MintParams{
        address token0;
        address token1;
        uint24 fee;
        int24 upperTick;
        int24 lowerTick;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;

    }

    struct SwapSingleParams{
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 amountIn;
        uint160 sqrtPriceLimitX96;
    }

    struct SwapParams{
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 minAmountOut;
    }

    struct SwapCallBackData{
        bytes path;
        address payer;
    }

    struct GetPositionParams {
        address tokenA;
        address tokenB;
        uint24 fee;
        address owner;
        int24 lowerTick;
        int24 upperTick;
    }
}