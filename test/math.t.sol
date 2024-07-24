// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {Math} from "../src/lib/Math.sol";
import "../src/lib/PRBMath.sol";
import {TickMath} from "../src/lib/TickMath.sol";




contract MathTest is Test {
   //Counter public counter;
    

    struct sq160{
        uint160 sqrtPriceAX96;
        uint160 sqrtPriceCX96;
        uint160 sqrtPriceBX96;

    }
    struct sq164{
        uint256 sqrtPriceAX96;
        uint256 sqrtPriceCX96;
        uint256 sqrtPriceBX96;

    }
    sq160 public sqp;
    sq164 public sqpn;


    

    address public USER = makeAddr("user");
    

    function setUp() public {
        //vm.prank(USER);
        //mat = new Math();
        // sqp.sqrtPriceAX96 = 5341294542274603406682713227264;
        // sqp.sqrtPriceCX96 = 5602277097478614198912276234240;
        // sqp.sqrtPriceBX96 = 5875717789736564987741329162240;
        (sqp.sqrtPriceAX96,sqp.sqrtPriceCX96,sqp.sqrtPriceBX96 ) = (5341294542274603406682713227264,
                                                                    5602277097478614198912276234240,
                                                                    5875717789736564987741329162240
                                                                    );

                                                                    //5875617940067453351001625213169
        (sqpn.sqrtPriceAX96,sqpn.sqrtPriceCX96,sqpn.sqrtPriceBX96) = (89612052255362152668251723279865217024,
                                                                    93990612956251765795818223433511075840,
                                                                    98578186513452933897373631481999523840
                                                                    );
                                                                    // 22940685377372711083072441159645495558144 
                                                                    // 24061596916800452043729465198978835415040 
                                                                    // 25236015747443951077727649659391878103040
      
    }

    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) public pure returns (uint256 result) {
        result = PRBMath.mulDiv(a, b, denominator);
        // console.log("result",result);
        if (mulmod(a, b, denominator) > 0) {
            // console.log(mulmod(a, b, denominator) > 0);
            // console.log(mulmod(a, b, denominator));
            require(result < type(uint256).max);
            result++;
        }
    }

    
    
    function testMinLiquidity() public  {
        uint128 value = Math.minLiquidity(5000 ether,1 ether,
                                        TickMath.getSqrtRatioAtTick(84222),
                                        TickMath.getSqrtRatioAtTick(85176),
                                        TickMath.getSqrtRatioAtTick(86129)
                                        // sqp.sqrtPriceAX96,
                                        // sqp.sqrtPriceCX96,
                                        // sqp.sqrtPriceBX96/*5314786713428871004159001755648*/
                                        );
      
       
        assertEq(1518129116516325614066,value);
        

    }

    function testCalcAmount0Delta() public {
        uint128 value = Math.minLiquidity(5000 ether,1 ether,sqp.sqrtPriceAX96,
                                        sqp.sqrtPriceCX96,
                                        sqp.sqrtPriceBX96/*5314786713428871004159001755648*/);
        
        assertEq(1517882343751509783892,value);
        int256 liq = Math.calcAmount0Delta(sqp.sqrtPriceCX96,sqp.sqrtPriceBX96,int128(value));
       
        assertEq(998976618347425274,liq);
    }

    function testCalcAmount1Delta() public {
        
        uint128 value = Math.minLiquidity(6000 ether,1 ether,
                                        TickMath.getSqrtRatioAtTick(84222),
                                        TickMath.getSqrtRatioAtTick(85176),
                                        TickMath.getSqrtRatioAtTick(86129)
                                        // sqp.sqrtPriceAX96,
                                        // sqp.sqrtPriceCX96,
                                        // sqp.sqrtPriceBX96/*5314786713428871004159001755648*/
                                        );
        
        assertEq(1519655488682309199780,value);
        
        int256 liq = Math.calcAmount1Delta(TickMath.getSqrtRatioAtTick(84222),TickMath.getSqrtRatioAtTick(85176),int128(value)
                                            /*24061596916800452043729465198978835415040
                                            ,22940685377372711083072441159645495558144,value*/);
        
        assertEq(5005027148710137960969,liq);
                                           
    }

    function testmulmod() public {
        uint128 value = Math.minLiquidity(5000 ether,1 ether,sqp.sqrtPriceAX96,
                                        sqp.sqrtPriceCX96,
                                        sqp.sqrtPriceBX96/*5314786713428871004159001755648*/);
        
        //uint256 liq = Math.calcAmount1DeltaEG( sqp.sqrtPriceCX96,sqp.sqrtPriceAX96,value);
        //console.log(liq);
        uint256 amount = mulDivRoundingUp(
            uint256(value),
            ( sqp.sqrtPriceCX96 - sqp.sqrtPriceAX96),
            2**96
            );
        assertEq(value,1517882343751509783892);
        assertEq(amount,5000000000000000000000);   
    }



     function testMinLiquidity128() public  {
        uint128 value = Math.minLiquidity(5000 ether,1 ether,sqpn.sqrtPriceAX96,
                                        sqpn.sqrtPriceCX96,
                                        sqpn.sqrtPriceBX96/*5314786713428871004159001755648*/);
       
       
        assertEq(90472837910146,value);
        

    }
    
    
}


// 607218838701025028515336969249153439281925866210993260685180501638914246285721600 
// 115792089237316195423570985008687907853269984665640564039457584007913129639936