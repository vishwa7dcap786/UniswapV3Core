//SPDX-Lisence-Identifier:MIT

pragma solidity 0.8.24;



import {PoolAddress} from "./lib/PoolAddress.sol";
import {IUniswapV3Pool} from "./Interfaces/IUniswapV3Pool.sol";
import {TickMath} from "./lib/TickMath.sol";
import {Math} from "./lib/Math.sol";
import {Path} from "./lib/Path.sol";
import {IERC20} from "./Interfaces/IERC20.sol";
import {IUniswapV3Manager} from "./Interfaces/IUniswapV3Manager.sol";

contract UniswapV3Manager is IUniswapV3Manager{
    using Path for bytes;


    error SlippageCheckFailed();
    error TooLittleReceived();


    

    address public immutable factory;

    constructor(address _factory){
        factory = _factory;
    }


    function mint(MintParams calldata mintParams) public returns(uint256 amount0, uint256 amount1){
      
        address poolAddress = PoolAddress.computePoolAddress(
            factory,
            mintParams.token0,
            mintParams.token1,
            mintParams.fee
        );
       

        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        (uint160 sqrtPriceX96,) = pool.slot0();
       
        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(mintParams.lowerTick);
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(mintParams.upperTick);

        uint128 liquidity = Math.minLiquidity(            
            mintParams.amount1Desired,
            mintParams.amount0Desired,
            sqrtPriceLowerX96,
            sqrtPriceX96,
            sqrtPriceUpperX96
        );

        (amount0,amount1) = pool.mint(
            msg.sender,
            mintParams.lowerTick,
            mintParams.upperTick,
            liquidity,
            abi.encode(
                IUniswapV3Pool.CallbackData({
                    token0:pool.token0(),
                    token1:pool.token1(),
                    payer:msg.sender
                })
            )   
        );

        if(amount0<mintParams.amount0Min || amount1 < mintParams.amount1Min) 
            revert SlippageCheckFailed();        


    }


    function swapSingle(SwapSingleParams calldata swapSingleParams) public returns (uint256 amountOut){
        
        amountOut = _swap(
            swapSingleParams.amountIn,
            swapSingleParams.sqrtPriceLimitX96,
            msg.sender,
            SwapCallBackData({
                path:abi.encodePacked(
                    swapSingleParams.tokenIn,
                    swapSingleParams.fee,
                    swapSingleParams.tokenOut
                ),
                payer:msg.sender
            })
        );


    } 

    function swap(SwapParams memory swapParams) public returns(uint256 amountOut){
        address payer = msg.sender;
        bool hasMultiplePools;

        while(true){
            hasMultiplePools = swapParams.path.hasMultiplePools();
            swapParams.amountIn = _swap(
                swapParams.amountIn,
                0,
                hasMultiplePools? address(this) : swapParams.recipient,
                SwapCallBackData({
                    path:swapParams.path.getFirstPool(),
                    payer:payer
                })
            );

            if(hasMultiplePools){
                swapParams.path = swapParams.path.skipToken();
                payer = address(this);

            }else{
                amountOut = swapParams.amountIn;
                break;
            }
        }

        if(amountOut < swapParams.minAmountOut)
            revert TooLittleReceived();

    }


    function _swap(uint256 amountIn, uint160 sqrtPriceLimitX96, address recipient, SwapCallBackData memory data ) internal returns(uint256 amountOut){
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();
       
        bool zeroForOne = tokenIn < tokenOut;
        (int256 amount0, int256 amount1) = IUniswapV3Pool(getPool(tokenIn,tokenOut,fee)).swap(
            recipient,
            zeroForOne,
            amountIn,
            (sqrtPriceLimitX96 == 0)
                ? (
                    zeroForOne 
                        ? TickMath.MIN_SQRT_RATIO + 1
                        : TickMath.MAX_SQRT_RATIO - 1
                )
                : sqrtPriceLimitX96,
            abi.encode(data)    
            );

        amountOut = uint256(-(zeroForOne?amount1:amount0));    

    }


    function getPosition(GetPositionParams calldata params)
        public
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        IUniswapV3Pool pool = IUniswapV3Pool(getPool(params.tokenA, params.tokenB, params.fee));

        (
            liquidity,
            feeGrowthInside0LastX128,
            feeGrowthInside1LastX128,
            tokensOwed0,
            tokensOwed1
        ) = pool.positions(
            keccak256(
                abi.encodePacked(
                    params.owner,
                    params.lowerTick,
                    params.upperTick
                )
            )
        );
    }




    function getPool(address token0, address token1, uint24 tickSpacing) public view returns(address pool){

        (token0,token1) = (token0<token1)
        ?   (token0,token1)
        :   (token1,token0);
        pool = PoolAddress.computePoolAddress(factory,token0,token1,tickSpacing);
    }

    function uniswapMintCallBack(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        IUniswapV3Pool.CallbackData memory extra = abi.decode(
            data,
            (IUniswapV3Pool.CallbackData)
        );
      
        

        IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
        IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
    }


    function uniswapSwapCallBack(
        int256 amount0,
        int256 amount1,
        bytes calldata data_
    ) external {
        SwapCallBackData memory data = abi.decode(data_, (SwapCallBackData));
        (address tokenIn, address tokenOut, ) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        int256 amount = zeroForOne ? amount0 : amount1;

        if (data.payer == address(this)) {
            IERC20(tokenIn).transfer(msg.sender, uint256(amount));
        } else {
            IERC20(tokenIn).transferFrom(
                data.payer,
                msg.sender,
                uint256(amount)
            );
        }
    }
}