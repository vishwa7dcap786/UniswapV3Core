//SPDX-Lisence_identifier:MIT

pragma solidity 0.8.24;
import {Test, console} from "forge-std/Test.sol";
import {Math} from "./Math.sol";


library Tick{


    struct Info{
        uint128 liquidityGross;
        int128 liquidityNet;
        bool initialized;
        uint256 feeGrouthOutside0X120;
        uint256 feeGrouthOutside1X120;
    }

    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int24 currentTick,
        uint256 feeGrouthGlobal0X120,
        uint256 feeGrouthGlobal1X120,
        int128 liquidityDelta,
        bool upper
    ) internal returns (bool flipped){

        Info storage tickInfo = self[tick];
        uint128 liquidityBefore = tickInfo.liquidityGross;
        uint128 liquidityAfter = Math.addLiquidity(liquidityBefore , liquidityDelta);

        if (liquidityBefore == 0) {
            tickInfo.initialized = true; 

            if(tick <= currentTick){
                tickInfo.feeGrouthOutside0X120 = feeGrouthGlobal0X120;
                tickInfo.feeGrouthOutside1X120 = feeGrouthGlobal1X120;
            }
        }

        tickInfo.liquidityNet = upper
            ? int128(int256(tickInfo.liquidityNet) - liquidityDelta)
            : int128(int256(tickInfo.liquidityNet) + liquidityDelta);


        tickInfo.liquidityGross = liquidityAfter;
        flipped = (liquidityAfter == 0) != (liquidityBefore == 0);
    }

    function clear(mapping(int24 => Tick.Info) storage self,int24 tick) internal {
        delete self[tick];
    }


    function getFeeGrowthInside(
        mapping(int24 => Tick.Info) storage self, 
        int24 upperTick_, 
        int24 lowerTick_, 
        int24 currentTick, 
        uint256 feeGrouthGlobal0X120, 
        uint256 feeGrouthGlobal1X120  
    )
     internal 
     view 
     returns (uint256 feeGrouthInside0X120, uint256 feeGrouthInside1X120){

        Info storage lowerTick = self[lowerTick_];
        Info storage upperTick = self[upperTick_];

        uint256 feeGrouthBelow0X120;
        uint256 feeGrouthBelow1X120;
        if(lowerTick_ <= currentTick){
            feeGrouthBelow0X120 = lowerTick.feeGrouthOutside0X120;
            feeGrouthBelow1X120 = lowerTick.feeGrouthOutside1X120;
        }else{
             
             feeGrouthBelow0X120 = feeGrouthGlobal0X120 - lowerTick.feeGrouthOutside0X120;
             feeGrouthBelow1X120 = feeGrouthGlobal1X120 - lowerTick.feeGrouthOutside1X120;
        }

        uint256 feeGrouthAbove0X120;
        uint256 feeGrouthAbove1X120;
        if(upperTick_ <= currentTick){
            feeGrouthAbove0X120 = feeGrouthGlobal0X120 - upperTick.feeGrouthOutside0X120;
            feeGrouthAbove1X120 = feeGrouthGlobal1X120 - upperTick.feeGrouthOutside1X120;
        }else{
            feeGrouthAbove0X120 = upperTick.feeGrouthOutside0X120;
            feeGrouthAbove1X120 = upperTick.feeGrouthOutside1X120;
        }
        
        
        feeGrouthInside0X120 = feeGrouthGlobal0X120 - feeGrouthAbove0X120 - feeGrouthBelow0X120;
        feeGrouthInside1X120 = feeGrouthGlobal1X120 - feeGrouthAbove1X120 - feeGrouthBelow1X120;

     }



    function cross(mapping(int24 => Tick.Info) storage self, int24 tick, uint256 feeGrouthGlobal0X120, uint256 feeGrouthGlobal1X120) internal returns(int128 liquidityDelta ){

        Info storage tickInfo = self[tick];
        liquidityDelta = tickInfo.liquidityNet;

        tickInfo.feeGrouthOutside0X120 = feeGrouthGlobal0X120 - tickInfo.feeGrouthOutside0X120;
        tickInfo.feeGrouthOutside1X120 = feeGrouthGlobal1X120 - tickInfo.feeGrouthOutside1X120;

    } 
}