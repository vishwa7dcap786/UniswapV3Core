//SPDX-Lisence-Identifier:MIT

pragma solidity 0.8.24;

import {TickMath} from "../src/lib/TickMath.sol";
import {ABDKMath64x64} from "./ABDKMath64x64.sol";
import {Test,console} from "forge-std/Test.sol";

import {UniswapV3Pool} from "../src/UniswapV3Pool.sol";
contract TestUtils{

    uint8 internal constant RESOLUTION = 96;
    function nearestUsableTick(int24 tick_, uint24 tickSpacing)
        internal
        pure
        returns (int24 result)
    {
        result =
            int24(divRound(int128(tick_), int128(int24(tickSpacing)))) *
            int24(tickSpacing);

        if (result < TickMath.MIN_TICK) {
            result += int24(tickSpacing);
        } else if (result > TickMath.MAX_TICK) {
            result -= int24(tickSpacing);
        }
    }

    function tick(uint256 price) internal pure returns (int24 tick_) {
        tick_ = TickMath.getTickAtSqrtRatio(
            uint160(
                int160(
                    ABDKMath64x64.sqrt(int128(int256(price << 64))) <<
                        (96 - 64)
                    )
                )   
            );
    }

    function divRound(int128 x, int128 y)
        internal
        pure
        returns (int128 result)
    {
        int128 quot = ABDKMath64x64.div(x, y);
        result = quot >> 64;

        // Check if remainder is greater than 0.5
        if (quot % 2**64 >= 0x8000000000000000) {
            result += 1;
        }
    }

    function computePoolAddress(address factory, address token0, address token1, uint24 fee) internal view returns(address pool){
        require(token0 < token1);
        //.log("poolAddresssol",token0,token1);
        console.log("poolAddresssol",token0,token1);
        console.log(factory,uint256(fee));

        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encodePacked(token0, token1, fee)
                            ),
                            keccak256(type(UniswapV3Pool).creationCode)
                        )
                    )
                )
            )
        );

       
    }
    

    function sqrtP(uint256 price) internal pure returns (uint160) {
        return
            uint160(
                int160(
                    ABDKMath64x64.sqrt(int128(int256(price << 64))) <<
                        (RESOLUTION - 64)
                )
            );
    }



}
