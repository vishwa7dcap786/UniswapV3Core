// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.24;


import {Test, console} from "forge-std/Test.sol";

import "./PRBMath.sol";



library Math{
    uint8 constant RESOLUTION = 96; //FixedPoint96
    uint256 constant fix = 2**96;

    function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x4) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
    }

    function sqrt (int128 x) internal pure returns (int128) {
        unchecked {
            require (x >= 0);
            return int128 (sqrtu (uint256 (int256 (x)) << 64));
            //console.log((x) << 64);
            
        }
    }

    // function sqrt(uint y) public pure returns (uint z) {
    //     if (y > 3) {
    //         z = y;
    //         uint x = y / 2 + 1;
    //         while (x < z) {
    //         z = x;
    //         x = (y / x + x) / 2;
    //     }
    //         } else if (y != 0) {
    //             z = 1;
    //         }
    //     z = z * 100;    
    // }
    // function sqrtx96(uint256 value) external view returns (uint256 ) {
    //     return sqrt(value)*(2**96);
    // }
    

    function liquidityAmount1(uint256 amount1, uint256 sqrtPriceCX96,
        uint256 sqrtPriceAX96 ) internal pure returns (uint128 liquidity){
            if (sqrtPriceAX96 > sqrtPriceCX96) 
            (sqrtPriceCX96,sqrtPriceAX96) = (sqrtPriceAX96,sqrtPriceCX96);
            //console.log(sqrtPriceCX96,sqrtPriceAX96);
            uint256 delP = sqrtPriceCX96-sqrtPriceAX96;
            //console.log(delP);
            liquidity = uint128(mulDiv(amount1,fix,delP));
            // amount * q96 / (pb - pa)
            

     }

    function liquidityAmount0(uint256 amount0, uint256 sqrtPriceCX96,
        uint256 sqrtPriceBX96 ) internal pure returns (uint128 liquidity){
            if (sqrtPriceCX96 > sqrtPriceBX96) 
            (sqrtPriceBX96,sqrtPriceCX96) = (sqrtPriceCX96,sqrtPriceBX96);
            // uint160 delP = (sqrtPriceBX96 - sqrtPriceCX96);
            // console.log(delP);
            
            // uint256 delp = uint256(sqrtPriceBX96) * uint256(sqrtPriceCX96);
            // uint256 delp1 = delp / 2**96;
            // console.log("i",delp);
             uint256 intermediate = mulDiv(
            sqrtPriceCX96,
            sqrtPriceBX96,
            2**96
        );
        liquidity = uint128(
            mulDiv(amount0, intermediate, sqrtPriceBX96 - sqrtPriceCX96)
        );
            //(amount * (pa * pb) / q96) / (pb - pa)
    }

    function minLiquidity(uint256 amount1, uint256 amount0, uint256 sqrtPriceAX96, uint256 sqrtPriceCX96,
        uint256 sqrtPriceBX96) internal pure returns(uint128 liquidity){
            
           

            if(sqrtPriceCX96 <= sqrtPriceAX96){
                 liquidity = uint128(liquidityAmount0(amount0,sqrtPriceAX96,sqrtPriceBX96));
            }else if(sqrtPriceCX96 <= sqrtPriceBX96){
            uint256 liquidity1 = liquidityAmount1(amount1,sqrtPriceCX96,sqrtPriceAX96);
            uint256 liquidity0 = liquidityAmount0(amount0,sqrtPriceCX96,sqrtPriceBX96);
            liquidity =uint128( (liquidity0 > liquidity1 ) ? liquidity1 : liquidity0);
             
            }else{
                 liquidity = uint128(liquidityAmount1(amount1,sqrtPriceBX96,sqrtPriceAX96));
            }
            
        }
    function calcAmount0Delta(
        uint256 sqrtPriceAX96,
        uint256 sqrtPriceBX96,
        uint256 liquidity,
        bool round
    ) internal pure returns (uint256 amount0) {

        if  (sqrtPriceAX96 > sqrtPriceBX96)
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

        require(sqrtPriceAX96 > 0);
        if(round){
            amount0 = divRoundingUp(
                mulDivRoundingUp(
                    (uint256(liquidity) << RESOLUTION),
                    (sqrtPriceBX96 - sqrtPriceAX96),
                    sqrtPriceBX96
                ),
                sqrtPriceAX96
            );
        }else{
            amount0 = divRoundingUp(
                mulDiv(
                    (uint256(liquidity) << RESOLUTION),
                    (sqrtPriceBX96 - sqrtPriceAX96),
                    sqrtPriceBX96
                ),
                sqrtPriceAX96
            );
        }

    }
    function calcAmount1Delta(
        uint256 sqrtPriceAX96,
        uint256 sqrtPriceBX96,
        uint256 liquidity,
        bool round
    ) internal pure returns (uint256 amount1) {
        if (sqrtPriceAX96 > sqrtPriceBX96) 
        (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
        // console.log("minus",sqrtPriceBX96 - sqrtPriceAX96);
        // console.log("mul",liquidity*(sqrtPriceBX96 - sqrtPriceAX96));
        // console.log("div",(396140812571321687967591596612949673937060310210756/fix ));
        // console.log("check",79228162514264337593543950336==2**96, 2**96);
        if(round){
            amount1 = mulDivRoundingUp(
                liquidity,
                (sqrtPriceBX96 - sqrtPriceAX96),
                fix
            );
        }else{
            amount1 = mulDiv(
                liquidity,
                (sqrtPriceBX96 - sqrtPriceAX96),
                fix
            );
        }
    }

    function calcAmount0Delta(
        uint256 sqrtPriceAX96,
        uint256 sqrtPriceBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {

        if  (sqrtPriceAX96 > sqrtPriceBX96)
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

        require(sqrtPriceAX96 > 0);

        amount0 = int256(divRoundingUp(
            mulDiv(
                (uint256(uint128(liquidity)) * 2**96),
                (sqrtPriceBX96 - sqrtPriceAX96),
                sqrtPriceBX96
            ),
            sqrtPriceAX96
        ));

    }
    function calcAmount1Delta(
        uint256 sqrtPriceAX96,
        uint256 sqrtPriceBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        if (sqrtPriceAX96 > sqrtPriceBX96) 
        (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
        // console.log("minus",sqrtPriceBX96 - sqrtPriceAX96);
       
        // console.log("div",(396140812571321687967591596612949673937060310210756/fix ));
        // console.log("check",79228162514264337593543950336==2**96, 2**96);

        amount1 = int256(mulDivRoundingUp(
            uint256(uint128(liquidity)),
            (sqrtPriceBX96 - sqrtPriceAX96),
            fix
        ));
    }


    function getNextSqrtPriceFromInput(
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint256 amount,
        bool zeroForOne
    ) internal pure returns(uint160 sqrtPriceNextX96){

        sqrtPriceNextX96 = zeroForOne
            ? getNextSqrtPriceFromAmount0RoundingUp(
                sqrtPriceX96,
                liquidity,
                amount
            ) 
            : getNextSqrtPriceFromAmount1RoundingDown(
                sqrtPriceX96,
                liquidity,
                amount
            );

    }

    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPriceX96,
        uint128 liquidity, 
        uint256 amount
    ) internal pure returns(uint160){

        uint256 numerator = uint256(liquidity) << 96;
        uint256 product = amount * sqrtPriceX96;
        if(product / amount == sqrtPriceX96){
            uint256 denominator = numerator + product;
            if(denominator >= numerator){
                // console.log("a01",mulDivRoundingUp(numerator, sqrtPriceX96, denominator),sqrtPriceX96, uint256(liquidity));
                // console.log("a00", numerator,denominator,product);
                return 
                    uint160(
                        mulDivRoundingUp(numerator, sqrtPriceX96, denominator)
                    );
                    
            }
        }

       //console.log("a02", divRoundingUp(numerator, amount + (numerator / sqrtPriceX96)));
        return 
            uint160(
                divRoundingUp(numerator, amount + (numerator / sqrtPriceX96))

            );
            

    }

    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPriceX96, 
        uint128 liquidity, 
        uint256 amount
    ) internal pure returns(uint160){
        return 
            sqrtPriceX96 + 
            uint160(divRoundingUp(amount * 2**96,liquidity));

    }


    function addLiquidity(uint128 x, int128 y)
        internal
        pure
        returns (uint128 z)
    {
        if (y < 0) {
            z = x - uint128(-y);
        } else {
            z = x + uint128(y);
        }
    } 

// minus 260940132338909448795026516466
// mul 396140812571321687967591596612949673937060310210756

    // function calcAmount1DeltaEG( uint160 sqrtPriceAX96,
    //     uint160 sqrtPriceBX96,
    //     uint256 liquidity) public view returns (uint256 amount1){
    //     if (sqrtPriceAX96 > sqrtPriceBX96)
    //         (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
    //         (sqrtPriceBX96 - sqrtPriceAX96);
    //         console.log(sqrtPriceBX96 - sqrtPriceAX96);
    //         uint256 delp =(uint256(liquidity) * (sqrtPriceBX96 - sqrtPriceAX96));
    //         amount1 = delp / fix;
    //     }
// 5602277097478614198912276234240-n = 2192253463713690532467206957
    
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(a, b, denominator);
        // console.log("muldiv before",result);

        if (mulmod(a, b, denominator) > 0) {
            // console.log(mulmod(a, b, denominator) > 0);
            // console.log(mulmod(a, b, denominator));
            require(result < type(uint256).max);
            result++;
        }
        //console.log("muldiv after",result);
    }

    function divRoundingUp(uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uint256 result)
    {
        assembly {
            result := add(
                div(numerator, denominator),
                gt(mod(numerator, denominator), 0)
            )
        }
    }


    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }
}



// 115792089237316195423570985008687907853269984665640564039457584007913129639936


// 60793103552880169587415260903235842800387072023646425701398935220727802804710400
















