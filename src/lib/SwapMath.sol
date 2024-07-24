//SPDX-License-Identifier:MIT

pragma solidity 0.8.24;

import {Math} from "./Math.sol";

library SwapMath{

    function computeSwapStep(
        uint160 sqrtPriceCurrentX96,
        uint160 sqrtPriceTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint24 fee
    ) internal pure returns(uint160 sqrtPriceNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount){

        bool zeroForOne = sqrtPriceCurrentX96 >= sqrtPriceTargetX96;

        uint256 amountRemainingLessFee = Math.mulDiv(
            amountRemaining,
            1e6-fee,
            1e6
        );


        amountIn = zeroForOne 
                    ?   Math.calcAmount0Delta(
                        sqrtPriceCurrentX96,
                        sqrtPriceTargetX96,
                        liquidity,
                        true
                    )
                    :   Math.calcAmount1Delta(
                        sqrtPriceCurrentX96,
                        sqrtPriceTargetX96,
                        liquidity,
                        true
                    );
        if(amountIn <= amountRemainingLessFee){ 
            
            (sqrtPriceNextX96 = sqrtPriceTargetX96);
        }else{     
            sqrtPriceNextX96 = Math.getNextSqrtPriceFromInput(
                sqrtPriceCurrentX96,
                liquidity,
                amountRemainingLessFee,
                zeroForOne
            );
        }
        //384996189372327723  21383005677122550174 
        //8231998133505122102

        bool max = sqrtPriceNextX96 == sqrtPriceTargetX96;

            
        if(zeroForOne){

            amountIn = max
                ?amountIn
                :Math.calcAmount0Delta(
                    sqrtPriceCurrentX96,
                    sqrtPriceNextX96,
                    liquidity,
                    true
                );

            amountOut = Math.calcAmount1Delta(
                sqrtPriceCurrentX96,
                sqrtPriceNextX96,
                liquidity,
                true
            );
        }else{

            amountIn = max
                ?amountIn
                :Math.calcAmount1Delta(
                    sqrtPriceCurrentX96,
                    sqrtPriceNextX96,
                    liquidity,
                    true
                );

            amountOut =  Math.calcAmount0Delta(
                    sqrtPriceCurrentX96,
                    sqrtPriceNextX96,
                    liquidity,
                    true
                );   

        }
        
        // (amountIn,amountOut) = zeroForOne? (amountIn,amountOut) : (amountOut,amountIn);
        if (!max) {
            feeAmount = amountRemaining - amountIn;
        }else{
            feeAmount = Math.mulDivRoundingUp(amountIn,fee,1e6-fee);
        }
        

    }
    
}     
    
// 3.6286387936610615478092261485466
// 1,377,927,174,436,484,433,323
// 3.4513067523018770470295381975222
// 5,244.0442408507577349572675683997
// 906866750716306162
// 998976618347425408