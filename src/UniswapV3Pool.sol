//SPDX-Lisence_identifier:MIT

pragma solidity 0.8.24;
import { console} from "forge-std/Test.sol";
import {Tick} from "./lib/Tick.sol";
import {Position} from "./lib/Position.sol";
import {console} from "forge-std/Test.sol";
import {IERC20} from "./Interfaces/IERC20.sol";
import {IUniswapMintCallBack} from "./Interfaces/IUniswapMintCallBack.sol";
import {IUniswapSwapCallBack} from "./Interfaces/IUniswapSwapCallBack.sol";
import {IUniswapFlashCallBack} from "./Interfaces/IUniswapFlashCallBack.sol";
import {IUniswapV3Deployer} from "./interfaces/IUniswapV3Deployer.sol";
import {TickBitMap} from "./lib/TickBitMap.sol";
import {TickMath} from "./lib/TickMath.sol";
import {Math} from "./lib/Math.sol";
import {SwapMath} from "./lib/SwapMath.sol";
//import {UniswapMintCallBack} from "./UniswapMintCallBack.sol";
contract UniswapV3Pool{
    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;
    using TickBitMap for  mapping(int16 => uint256) ;

    error InvalidTickRange();
    error InvalidPriceLimit();
    error ZeroLiquidity();
    error InsufficientInputAmount();
    error NotEnoughLiquidity();
    error FlashLoanNotPaid();
    error AlreadyInitialized();
    //test
    event Infos(uint256 bit, int16 word, uint8 bitPos, uint256 mask);

    event Mint(address sender,address owner,int24 lowerTick,int24 upperTick,uint128 amount,uint256 amount0,uint256 amount1);
    event Swap(address indexed sender,address indexed recipient,int256 amount0,int256 amount1,uint160 sqrtPriceX96,uint128 liquidity,int24 tick, uint128 liquidityDelta);
    event Burn(address sender,int24 lowerTick,int24 upperTick,uint256 amount0,uint256 amount1,uint128 amount);
    event Collect(address recipient,int24 lowerTick, int24 upperTick, uint128 amount0, uint128 amount1);
    event Flash(address sender, uint256 amount0, uint256 amount1);
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -(MIN_TICK);

    address public immutable factory;
    address public immutable token0;
    address public immutable token1;
    uint24 public immutable tickSpacing;
    uint24 public immutable fee;
    uint128 public liquidity;
    uint256 public feeGrouthGlobal0X120;
    uint256 public feeGrouthGlobal1X120;
    

    struct Slot0{
        uint160 sqrtPriceX96;
        int24 tick;
    } 

    struct Extra{
        address token0;
        address token1;
        address payer;
    }

    Slot0 public slot0;

    mapping(int24 => Tick.Info) public ticks;
    mapping(bytes32 => Position.Info) public positions;
    mapping(int16 => uint256) public tickBitmap;

    constructor(){
        (factory,token0,token1,tickSpacing,fee) = IUniswapV3Deployer(msg.sender).parameters();
        

       
    }
    

    function mint(address owner, int24 lowerTick, int24 upperTick, uint128 amount, bytes calldata data) public returns(uint256 amount0, uint256 amount1){
       
        if(lowerTick>=upperTick||
            lowerTick<MIN_TICK ||
            upperTick>MAX_TICK)
            revert InvalidTickRange();
    
        if(amount <= 0) revert ZeroLiquidity();

     
        (int256 amount0Int, int256 amount1Int,) = _modifyPosition(ModifyPositionParams({lowerTick:lowerTick,upperTick:upperTick,liquidityDelta:int128(amount),owner:owner}));
        
        (amount0, amount1) = (uint256(amount0Int),uint256(amount1Int));
         console.log("M",amount0,amount1);
       
        uint256 balance0Before;
        uint256 balance1Before;

        if(amount0 > 0) balance0Before = balance0();
        if(amount1 > 0) balance1Before = balance1();

        IUniswapMintCallBack(msg.sender).uniswapMintCallBack(amount0,amount1,data);
       
        

        if(amount0 > 0 && balance0Before + amount0 > balance0())
            revert InsufficientInputAmount();
        if(amount1 > 0 && balance1Before + amount1 > balance1())
            revert InsufficientInputAmount();

        emit Mint(msg.sender, owner, lowerTick, upperTick, amount, amount0, amount1);
      
        


    }


    struct ModifyPositionParams{
        int24 lowerTick; 
        int24 upperTick; 
        int128 liquidityDelta;
        address owner;
    }



    function _modifyPosition(ModifyPositionParams memory params) internal returns(int256 amount0, int256 amount1, Position.Info storage position){
       

        uint256 feeGrouthGlobal0X120_ = feeGrouthGlobal0X120;
        uint256 feeGrouthGlobal1X120_ = feeGrouthGlobal1X120;
        Slot0 memory _slot0 = slot0; 
     

        bool flippedLower = ticks.update(
            params.lowerTick,
            _slot0.tick, 
            feeGrouthGlobal0X120_, 
            feeGrouthGlobal1X120_, 
            params.liquidityDelta, 
            false
            );
            
        bool flippedupper = ticks.update(
            params.upperTick, 
            _slot0.tick,
            feeGrouthGlobal0X120_, 
            feeGrouthGlobal1X120_, 
            params.liquidityDelta, 
            true
            );

        
        
        
       
        if(flippedLower){
             tickBitmap.flipTick(params.lowerTick,int24(tickSpacing));                   
        }

        if(flippedupper){
            tickBitmap.flipTick(params.upperTick,int24(tickSpacing));          
        }
        

        (uint256 feeGrouthInside0X120, uint256 feeGrouthInside1X120) = ticks.getFeeGrowthInside(
            params.upperTick,
            params.lowerTick,
            _slot0.tick,
            feeGrouthGlobal0X120_,
            feeGrouthGlobal1X120_
            );


        

        //console.log(bitl,bitu);

      
        
        position = positions.get(params.owner,params.lowerTick,params.upperTick);
        //console.log(position.liquidity);
        //uint128 liquiditys= positions[keccak256(abi.encodePacked(owner,lowerTick,upperTick))]);
         //  console.log(getter(owner,lowerTick,upperTick));
         
        position.update(params.liquidityDelta,feeGrouthInside0X120,feeGrouthInside1X120);
         //    console.log();
     
        if(_slot0.tick < params.lowerTick){

            amount0 = Math.calcAmount0Delta( 
                TickMath.getSqrtRatioAtTick(params.lowerTick),
                TickMath.getSqrtRatioAtTick(params.upperTick),
                params.liquidityDelta
            );

        }else if(_slot0.tick < params.upperTick){
            uint128 liquidityBefore = liquidity;

            amount0 = Math.calcAmount0Delta(
                TickMath.getSqrtRatioAtTick(params.upperTick), 
                slot0.sqrtPriceX96, 
                params.liquidityDelta
            );

            amount1 = Math.calcAmount1Delta( 
                TickMath.getSqrtRatioAtTick(params.lowerTick), 
                slot0.sqrtPriceX96, 
                params.liquidityDelta
            );

            liquidity = Math.addLiquidity(liquidityBefore, params.liquidityDelta);
            console.log("mint add liquidity ----->",liquidity);

        }else{

            amount1 = Math.calcAmount1Delta(
                TickMath.getSqrtRatioAtTick(params.lowerTick),
                TickMath.getSqrtRatioAtTick(params.upperTick),
                params.liquidityDelta
            );

        }

        if(params.liquidityDelta < 0){

            (amount0,amount1) = (-amount0,-amount1);
        }

        if(params.liquidityDelta < 0){
            if(flippedLower)
                ticks.clear(params.lowerTick);
            if(flippedupper) 
                ticks.clear(params.upperTick);

        }
        

    }



    function burn(int24 lowerTick, int24 upperTick, uint128 amount) external returns(uint256 amount0, uint256 amount1){

        (int256 amount0Int, int256 amount1Int, Position.Info storage position) = 
            _modifyPosition(
                ModifyPositionParams({
                    lowerTick:lowerTick,
                    upperTick:upperTick,
                    liquidityDelta:-int128(amount),
                    owner:msg.sender
                })
            );


        (amount0,amount1) = (uint256(-amount0Int),uint256(-amount1Int));


        if(amount0 > 0 || amount1 > 0 ){
            position.tokenOwned0 =
                position.tokenOwned0 + uint128(amount0);
            position.tokenOwned1 = 
                position.tokenOwned1 + uint128(amount1); 
        }


        emit Burn(msg.sender,lowerTick,upperTick,amount0,amount1,amount);

    }


    function collect(address recipient, int24 lowerTick, int24 upperTick, uint128 amount0Requested, uint128 amount1Requested) external returns(uint128 amount0, uint128 amount1){

        Position.Info storage position = positions.get(recipient,lowerTick,upperTick);

        amount0 = (amount0Requested > position.tokenOwned0) ? position.tokenOwned0 : amount0Requested;
        amount1 = (amount1Requested > position.tokenOwned1) ? position.tokenOwned1 : amount1Requested;

        if(amount0 > 0){
            position.tokenOwned0 -= amount0;
            IERC20(token0).transfer(recipient,amount0);
        }

        if(amount1 > 0){
            position.tokenOwned1 -= amount1;
            IERC20(token1).transfer(recipient,amount1);
        }

        emit Collect(recipient,lowerTick,upperTick,amount0,amount1);
    }

    struct swapState{
        uint256 amountSpecifiedRemaining;
        uint256 amountCalculated;
        uint160 sqrtPriceX96;
        uint256 feeGrouthGlobalX120;
        int24 tick;
        uint128 liquidity;
    }

    struct stepState{
        uint160 sqrtPriceStartX96;
        int24 nextTick;
        uint160 sqrtPriceNextX96;
        uint256 amountIn;
        uint256 amountOut;
        bool initialized;
        uint256 feeAmount;

    }

    // zeroForOne is the flag that controls swap direction: when true, token0 is traded in for token1; 
    // when false, it’s the opposite
    function swap(address recipient, bool zeroForOne, uint256 specifiedAmount, uint160 sqrtPriceLimitX96, bytes calldata data) public returns(int256 amount0, int256 amount1){
        Slot0 memory slot0_ = slot0;
        uint128 liquidity_ = liquidity;
       
        if(
            zeroForOne
            ?   (slot0_.sqrtPriceX96 < sqrtPriceLimitX96 || 
                    sqrtPriceLimitX96 < TickMath.MIN_SQRT_RATIO)
            :   (slot0_.sqrtPriceX96 > sqrtPriceLimitX96 || 
                    sqrtPriceLimitX96 > TickMath.MAX_SQRT_RATIO)
        ) revert InvalidPriceLimit();

        swapState memory state = swapState({
            amountSpecifiedRemaining:specifiedAmount,
            amountCalculated:0,
            sqrtPriceX96:slot0_.sqrtPriceX96,
            feeGrouthGlobalX120:zeroForOne?feeGrouthGlobal0X120:feeGrouthGlobal1X120,
            tick:slot0_.tick,
            liquidity:liquidity_
        });



        while(state.amountSpecifiedRemaining > 0 && state.sqrtPriceX96 != sqrtPriceLimitX96){

            stepState memory step;
            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.nextTick, step.initialized) = tickBitmap.nextInitializedTickWithinOneWord(state.tick,int24(tickSpacing),zeroForOne);


            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.nextTick);

            (state.sqrtPriceX96 , step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                step.sqrtPriceStartX96,
                (
                    zeroForOne 
                        ? step.sqrtPriceNextX96 < sqrtPriceLimitX96
                        : step.sqrtPriceNextX96 > sqrtPriceLimitX96
                )   ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                fee
                );

                

           
            
            state.feeGrouthGlobalX120 += Math.mulDiv(step.feeAmount,Position.Q128,state.liquidity);

            state.amountSpecifiedRemaining -= step.amountIn + step.feeAmount;
            state.amountCalculated += step.amountOut;

            
//7,127,668,559,040,850,058,098
            if(state.sqrtPriceX96 == step.sqrtPriceNextX96){
                if(step.initialized){
                  
                    int128 liquidityDelta = ticks.cross(
                        step.nextTick,
                        zeroForOne?state.feeGrouthGlobalX120:feeGrouthGlobal1X120,
                        zeroForOne?feeGrouthGlobal0X120:state.feeGrouthGlobalX120
                        
                        );

                    if(zeroForOne) liquidityDelta = -liquidityDelta;

                    state.liquidity = Math.addLiquidity(
                        state.liquidity,
                        liquidityDelta
                    );

                    

                    if(state.liquidity == 0) revert NotEnoughLiquidity();

                }
                state.tick = zeroForOne ? step.nextTick -1 : step.nextTick;
            
            }else if( state.sqrtPriceX96 != step.sqrtPriceStartX96){
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }    
        }
       

       
        if(slot0.tick != state.tick){
            (slot0.tick, slot0.sqrtPriceX96) = (state.tick, state.sqrtPriceX96);
        }

        if (liquidity_ != state.liquidity) liquidity = state.liquidity;

        if(zeroForOne){
            feeGrouthGlobal0X120 = state.feeGrouthGlobalX120;
        }else
            feeGrouthGlobal1X120 = state.feeGrouthGlobalX120;


      
        (amount0, amount1) = zeroForOne 
            ? (int256(specifiedAmount - state.amountSpecifiedRemaining), 
                -int256(state.amountCalculated)
            )
            : (-int256(state.amountCalculated),
                int256(specifiedAmount - state.amountSpecifiedRemaining)
            );

        if(zeroForOne){
            IERC20(token1).transfer(recipient, uint256(-amount1));
            uint256 balance0Before = balance0();
           
            IUniswapSwapCallBack(msg.sender).uniswapSwapCallBack(
                amount0,
                amount1,
                data
            );
            
            if (balance0Before + uint256(amount0) > balance0())
                revert InsufficientInputAmount();
       
        
        }else{
            IERC20(token0).transfer(recipient, uint256(-amount0));
            uint256 balance1Before = balance1();
            IUniswapSwapCallBack(msg.sender).uniswapSwapCallBack(
                amount0,
                amount1,
                data
            );
        
       
            if (balance1Before + uint256(amount1) > balance1())
                revert InsufficientInputAmount();

        }    
        

        emit Swap(
            msg.sender,
            recipient,
            amount0,
            amount1,
            slot0.sqrtPriceX96,
            liquidity,
            slot0.tick,
            state.liquidity
        


            
            
        );


    }


    function initialize(uint160 sqrtPriceX96) public {
        if(slot0.sqrtPriceX96 != 0) revert AlreadyInitialized();

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        slot0 = Slot0({
            sqrtPriceX96:sqrtPriceX96,
            tick:tick
            });

    }




    function flash(uint256 amount0, uint256 amount1, bytes calldata data) public {
        
        uint256 feeAmount0 = Math.mulDiv(amount0,fee,1e6);
        uint256 feeAmount1 = Math.mulDiv(amount1,fee,1e6);

        uint256 balance0Before = IERC20(token0).balanceOf(address(this));
        uint256 balance1Before = IERC20(token1).balanceOf(address(this));

        if(amount0 > 0) IERC20(token0).transfer(msg.sender,amount0);
        if(amount1 > 0) IERC20(token1).transfer(msg.sender,amount1);

        IUniswapFlashCallBack(msg.sender).uniswapFlashCallBack(
            feeAmount0,
            feeAmount1,
            data
        );

        if(IERC20(token0).balanceOf(address(this)) < balance0Before + feeAmount0)
            revert FlashLoanNotPaid();
        if(IERC20(token1).balanceOf(address(this)) < balance1Before + feeAmount1)
            revert FlashLoanNotPaid();

        emit Flash(msg.sender,amount0,amount1);    

    }


    function balance0() internal view returns(uint256 balance){
        balance = IERC20(token0).balanceOf(address(this));
    } 

    function balance1() internal view returns (uint256 balance){
        balance = IERC20(token1).balanceOf(address(this));
    }


}