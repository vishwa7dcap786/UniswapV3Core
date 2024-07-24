//SPDX-Lisence-Identifier:MIT

import {BytesLib} from "./BytesLib.sol";

pragma solidity 0.8.24;



library Path{
    using BytesLib for bytes;

    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant FEE_SIZE = 3;
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    uint256 private constant MULTIPLE_POOLS_MIN_LENGHT = POP_OFFSET + NEXT_OFFSET;



    function numPools(bytes memory path) internal pure returns(uint256){

        return (path.length - ADDR_SIZE)/ NEXT_OFFSET;

    } 


    function hasMultiplePools(bytes memory path) internal pure returns(bool){
        return (path.length >= MULTIPLE_POOLS_MIN_LENGHT);
    }

    function getFirstPool(bytes memory path) internal pure returns(bytes memory){
        return path.slice(0,POP_OFFSET);
    }

    function skipToken(bytes memory path) internal pure returns(bytes memory){
        return path.slice(NEXT_OFFSET,path.length - NEXT_OFFSET);
    }

    function decodeFirstPool(bytes memory path) internal pure returns(address tokenIn, address tokenOut, uint24 fee){
        tokenIn = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenOut  = path.toAddress(NEXT_OFFSET);
    }

    function encodePools(address token1,address token2, address token3, address token4, uint24 ticks1, uint24 ticks2, uint24 ticks3) internal pure returns (bytes memory path){
         path= abi.encodePacked(
                    token1,
                    ticks1,
                    token2,
                    ticks2,
                    token3,
                    ticks3,
                    token4
         );   
    
    }


    

}
/*0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 # weth address
  60                                   # 60
  0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db # usdc address
  10                                   # 10
  0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB # usdt address
  60                                   # 60
  0x617F2E2fD72FD9D5503197092aC168c91465E7f2 # wbtc address
  
  0xab8483f64d9c6d1ecf9b849ae677dd3315835cb200003c4b20993bc481177ec7e8f571cecae8a9e22c02db00000a78731d3ca6b7e34ac0f824c42a7cc18a495cabab00003c617f2e2fd72fd9d5503197092ac168c91465e7f2*/