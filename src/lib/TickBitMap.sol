//SPDX-Lisence_identifier:MIT

pragma solidity 0.8.24;
import { console} from "forge-std/Test.sol";
import {BitMath} from "./BitMath.sol";
import {Test, console} from "forge-std/Test.sol";

library TickBitMap{

    



    function position(int24 tick) internal  pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick % 256));
    }

    function flipTick(
    mapping(int16 => uint256) storage  self,
    int24 tick,
    int24 tickSpacing
    ) internal  {
        
        console.log("insidefliptickreqzrero",tick % tickSpacing == 0);
        console.log("tick tickspacing",uint256(int256(tick)),uint256(int256(tickSpacing)));
        require(tick % tickSpacing == 0); // ensure that the tick is spaced
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        uint256 mask = (1 << bitPos);

        self[wordPos] ^= mask;
        
       
    }



    function nextInitializedTickWithinOneWord( 
     mapping(int16 => uint256) storage  self,  
    int24 tick,
    int24 tickSpacing,
    bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                : (compressed - int24(uint24(bitPos))) * tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                : (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
        }
    }


    // function NextInitializedTick(int24 compressed) public view returns (uint256 bit, uint256 mask, uint256 masked ,int24 next, bool initialized){
    //       (int16 wordPos, uint8 bitPos) = position(compressed);
    //         // all the 1s at or to the right of the current bitPos
    //          mask = (1 << bitPos) - 1 ;
    //          masked = self[wordPos] & mask;
    //         bit = self[wordPos];
    //         initialized = masked != 0;

    //        //  next =  compressed - int24(bitPos-mostSignificantBit(masked));
    //        next 
    //        =initialized?(compressed - int24(uint24(bitPos - mostSignificantBit(masked)))):
    //        (compressed - int24(uint24(bitPos))) ;

            
    // }
    // function NextInitializedTickr(int24 tick, int24 tickSpacing) public view returns (uint256 bit, uint256 mask, uint256 masked ,int24 next, bool initialized){
    //         int24 compressed = tick / tickSpacing;
    //         if (tick < 0 && tick % tickSpacing != 0) compressed--;
    //         (int16 wordPos, uint8 bitPos) = position(compressed);
    //         // all the 1s at or to the right of the current bitPos
    //          mask = (1 << bitPos) - 1 ;
    //          masked = self[wordPos] & mask;
    //         bit = self[wordPos];
    //         // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
    //         initialized = masked != 0;
    //         // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
    //         next = initialized
    //             ? (compressed - int24(uint24(bitPos - mostSignificantBit(masked)))) * tickSpacing
    //             : (compressed - int24(uint24(bitPos))) * tickSpacing;
    // }

    // function NextInitializedTickl(int24 compressed) public view  returns(uint256 bit, uint256 mask, uint256 masked ,int24 next, bool initialized){
    //      (int16 wordPos, uint8 bitPos) = position(compressed+1);
    //         // all the 1s at or to the left of the bitPos
    //         mask = ~((1 << bitPos) - 1);
    //         masked = self[wordPos] & mask;
    //         bit = self[wordPos];
    //         // if there are no initialized ticks to the left of the current tick, return leftmost in the word
    //         initialized = masked != 0;
    //         // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
    //         next = initialized
    //             ? (compressed + 1+int24(uint24(leastSignificantBit(masked) - bitPos))) 
    //             : (compressed + 1+int24(uint24(type(uint8).max - bitPos))) ;
    // }


    

   
        

}