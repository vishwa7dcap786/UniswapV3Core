//SPDX-Lisence-Identifier:MIT

pragma solidity 0.8.24;

import {TickMath} from "../src/lib/TickMath.sol";
import {ABDKMath64x64} from "./ABDKMath64x64.sol";
import {Test,console} from "forge-std/Test.sol";
import {ERC20Mintable} from "./ERC20.sol";
import {UniswapV3Pool} from "../src/UniswapV3Pool.sol";
contract AssertionTest is Test{

   

    struct ExpectedTick {
        UniswapV3Pool pool;
        int24[2] ticks;
        bool initialized;
        uint128[2] liquidityGross;
        int128[2] liquidityNet;
        uint256 feeGrouthOutside0X120;
        uint256 feeGrouthOutside1X120;
    }


    struct ExpectedPoolState {
        UniswapV3Pool pool;
        uint128 liquidity;
        uint160 sqrtPriceX96;
        int24 tick;
        uint256[2] fees;
    }

    struct ExpectedPosition {
        UniswapV3Pool pool;
        address owner;
        int24[2] ticks;
        uint128 liquidity;
        uint256[2] feeGrowth;
        uint128[2] tokensOwed;
    }

    struct ExpectedBalance {
        UniswapV3Pool pool;
        ERC20Mintable[2] token;
        uint256 userBalance0;
        uint256 userBalance1;
        uint256 poolBalance0;
        uint256 poolBalance1;
    }
    

    struct ExpectAssertMany{
        ExpectedTick tick;
        ExpectedPosition positions;
        ExpectedPoolState poolState;
        ExpectedBalance balance;
        bool testPosition;
        bool testPoolState;
        bool testTick;
        bool testBalance;
    }


    function assertMany(ExpectAssertMany memory params) public {
        
        if(params.testPosition){
           
            bytes memory position = abi.encodePacked(params.positions.owner,params.positions.ticks[0],params.positions.ticks[1]);
            ( uint128 liquidity,
                uint256 feeGrowthInside0LastX128,
                uint256 feeGrowthInside1LastX128,
                uint128 tokensOwed0,
                uint128 tokensOwed1)=params.positions.pool.positions(keccak256(position));
            
            assertEq(liquidity,params.positions.liquidity);
            assertEq(feeGrowthInside0LastX128,params.positions.feeGrowth[0]);
            assertEq(feeGrowthInside1LastX128,params.positions.feeGrowth[1]);
            assertEq(tokensOwed0,params.positions.tokensOwed[0]);
            assertEq(tokensOwed1,params.positions.tokensOwed[1]);
        }

        if(params.testPoolState){
            

           
            ( uint128 liquidity,
            uint256[2] memory fees) = (
                params.poolState.pool.liquidity(),
                [params.poolState.pool.feeGrouthGlobal0X120(),params.poolState.pool.feeGrouthGlobal1X120()]
                );

            (uint160 sqrtPriceX96, int24 tick) = (
                params.poolState.pool.slot0()
               
                );

            assertEq(liquidity,params.poolState.liquidity);
            assertEq(sqrtPriceX96,params.poolState.sqrtPriceX96);
            assertEq(tick,params.poolState.tick);
            assertEq(fees[0],params.poolState.fees[0]);
            assertEq(fees[1],params.poolState.fees[1]);
        }

        if(params.testTick){

            
        for(uint256 i = 0; i < params.tick.ticks.length; i++ ){
            (uint128 liquidityGross,
        int128 liquidityNet,
        bool initialized,
        uint256 feeGrouthOutside0X120,
        uint256 feeGrouthOutside1X120)=params.tick.pool.ticks(params.tick.ticks[i]);

            assertEq(liquidityGross,params.tick.liquidityGross[i]);
            assertEq(liquidityNet,params.tick.liquidityNet[i]);
            assertEq(initialized,params.tick.initialized);
            assertEq(feeGrouthOutside0X120,params.tick.feeGrouthOutside0X120);
            assertEq(feeGrouthOutside1X120,params.tick.feeGrouthOutside1X120);
        }

        }

        if(params.testBalance){

            assertEq(
                params.balance.token[0].balanceOf(address(this)),
                params.balance.userBalance0,
                "incorrect token0 balance of user"
            );
            assertEq(
                params.balance.token[1].balanceOf(address(this)),
                params.balance.userBalance1,
                "incorrect token1 balance of user"
            );

            assertEq(
               params.balance.token[0].balanceOf(address(params.balance.pool)),
                params.balance.poolBalance0,
                "incorrect token0 balance of pool"
            );
            assertEq(
                params.balance.token[1].balanceOf(address(params.balance.pool)),
                params.balance.poolBalance1,
                "incorrect token1 balance of pool"
            );
        }

    }


}
