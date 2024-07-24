// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {UniswapV3Pool} from "../src/UniswapV3Pool.sol";
import {UniswapV3Factory} from "../src/UniswapV3Factory.sol";
import {ERC20Mintable} from "./ERC20.sol";
import {IERC20} from "../src/Interfaces/IERC20.sol";
import {Math} from "../src/lib/Math.sol";
import {TickMath} from "../src/lib/TickMath.sol";
import {ABDKMath64x64} from "./ABDKMath64x64.sol";




contract UniswapV3PoolTest is Test {
   // Counter public counter;
    UniswapV3Factory factory;
    UniswapV3Pool pool;
    ERC20Mintable token0;
    ERC20Mintable token1;

    address public USER = makeAddr("user");


    struct MintParams{
      uint256 amount0;
      uint256 amount1;
      uint256 allowenceAmount0;
      uint256 allowenceAmount1;
      int24 currentTick;
      int24 upperTick;
      int24 lowerTick;

    }

    struct SwapParams{
      uint256 amount0;
      uint256 amount1;
      bool zeroForOne;
      uint160 sqrtPriceLimitX96;
    }


    struct FlashParams{
        uint256 amount0;
        uint256 amount1;
    }

    function setUp() public {
        //vm.prank(USER);
        token1 = new ERC20Mintable("USDC","USDC",18);
        token0 = new ERC20Mintable("ETH","ETH",18);
        
        factory = new UniswapV3Factory();
        pool = UniswapV3Pool(factory.createPool(address(token0),address(token1),3000));
        pool.initialize(TickMath.getSqrtRatioAtTick(85176));   
    }


    function testTokenOrder() public {
 
        assertEq(address(token0)==address(pool.token0()),true);
        assertEq(address(token1)==address(pool.token1()),true);
        assertEq(token0<token1,true);
    }

/*
One price range
5500    5000    4545
 |--------|--------|
          C
*/          
    


    function testSwapWithInOnePriceRange() public {

        token0.mint(address(this),1 ether);
        token1.mint(address(this),6000 ether); 

        MintParams memory mintParams = MintParams({
            amount0:1 ether,
            amount1:5000 ether,
            allowenceAmount0:1 ether,
            allowenceAmount1:5000 ether,
            currentTick:nearestUsableTick(tick(5000),60),
            upperTick:nearestUsableTick(tick(5500),60),
            lowerTick:nearestUsableTick(tick(4545),60)
        });

        SwapParams memory swapParams = SwapParams({
            amount0:0,
            amount1:42 ether,
            zeroForOne:false,
            sqrtPriceLimitX96:0
        });

        InputUniswapMintCallBack(mintParams);

        (int256 amount0,int256 amount1) = InputUniswapSwapCallBack(swapParams);

          assertEq(amount0,-8371669858540599);
          assertEq(amount1,42 ether);




    }

//   //  998976618347425408
// /*
// Two equal price ranges
// 5500--------|-------4545
//           5000
// 5500--------|-------4545
// */
    function testSwapWithInTwoEqualPriceRange() public {
        token0.mint(address(this),2 ether);
        token1.mint(address(this),10042 ether); 
        MintParams memory mintParams = MintParams({
            amount0:1 ether,
            amount1:5000 ether,
            allowenceAmount0:1 ether,
            allowenceAmount1:5000 ether,
            currentTick:nearestUsableTick(tick(5000),60),
            upperTick:nearestUsableTick(tick(5500),60),
            lowerTick:nearestUsableTick(tick(4545),60)
        });

        

        SwapParams memory swapParams = SwapParams({
            amount0:0,
            amount1:42 ether,
            zeroForOne:false,
            sqrtPriceLimitX96:0
        });

        
        InputUniswapMintCallBack(mintParams);

        InputUniswapMintCallBack(mintParams);

        (int256 amount0,int256 amount1) = InputUniswapSwapCallBack(swapParams);

          assertEq(amount0,-8373314347699432);
          assertEq(amount1,42 ether);

    }

/*
Consecutive price ranges
6250---------------5500      5000
                  5500--------|--------4545
                              C
*/
    function testSwapWithInConsecutivePriceRange() public {
        token0.mint(address(this),2 ether);
        token1.mint(address(this),15000 ether); 
        MintParams memory mintParams1 = MintParams({
            amount0:1 ether,
            amount1:5000 ether,
            allowenceAmount0:1 ether,
            allowenceAmount1:5000 ether,
            currentTick:nearestUsableTick(tick(5000),60),
            upperTick:nearestUsableTick(tick(5500),60),
            lowerTick:nearestUsableTick(tick(4545),60)
        });

        MintParams memory mintParams2 = MintParams({
            amount0:1 ether,
            amount1:5000 ether,
            allowenceAmount0:1 ether,
            allowenceAmount1:0 ether,
            currentTick:nearestUsableTick(tick(5000),60),
            upperTick:nearestUsableTick(tick(6250),60),
            lowerTick:nearestUsableTick(tick(5500),60)
        });

        

        SwapParams memory swapParams = SwapParams({
            amount0:0,
            amount1:10000 ether,
            zeroForOne:false,
            sqrtPriceLimitX96:0
        });

        
        InputUniswapMintCallBack(mintParams1);

        InputUniswapMintCallBack(mintParams2);

        (int256 amount0,int256 amount1) = InputUniswapSwapCallBack(swapParams);

          assertEq(amount0,-1812651997729774544);
          assertEq(amount1,10000 ether);
          assertEq(TickMath.getTickAtSqrtRatio(5875617940067453351001625213169),86129);


          // 1.829600026831158011
          // 1.558152222098388769
          // net -1518129116516325614066
          // net -320361671560818942450
          // -1518129116516325614066 + +1197767444955506671616 = 320361671560818942450

          // 381739656365887395592   76078838896153765    5622145994867546797787171334839
          // 1387719884058050968291  272080895930590471   5694568356906635577050546247497
          // 1405595967664531951712  268620626439733268   5767923636470119667816132517957
          // 1423702324230834940966  265204363952412292   5842223851049321075399999157648
          // 639880280561059518542   117010854912691805   5875617940067453351001625213169

    }

/* Partially Overlapping Price Ranges
6250-----------5001
    5500----------|----------4545
                5000
*/    


     function testSwapWithInPartiallyOverlappingPriceRange() public {
        token0.mint(address(this),2 ether);
        token1.mint(address(this),15000 ether); 
        MintParams memory mintParams1 = MintParams({
            amount0:1 ether,
            amount1:5000 ether,
            allowenceAmount0:1 ether,           
            allowenceAmount1:5000 ether,
            currentTick:nearestUsableTick(tick(5000),60),
            upperTick:nearestUsableTick(tick(5500),60),
            lowerTick:nearestUsableTick(tick(4545),60)
        });

        MintParams memory mintParams2 = MintParams({
            amount0:1 ether,
            amount1:5000 ether,
            allowenceAmount0:1 ether,
            allowenceAmount1:0 ether,
            currentTick:nearestUsableTick(tick(5000),60),
            upperTick:nearestUsableTick(tick(6250),60),
            lowerTick:nearestUsableTick(tick(5001),60)
        });

        

        SwapParams memory swapParams = SwapParams({
            amount0:0,
            amount1:10000 ether,
            zeroForOne:false,
            sqrtPriceLimitX96:0
        });

        
        InputUniswapMintCallBack(mintParams1);

        InputUniswapMintCallBack(mintParams2);

        (int256 amount0,int256 amount1) = InputUniswapSwapCallBack(swapParams);

          assertEq(amount0,-1853995322431115763);
          assertEq(amount1,10000 ether);
          assertEq(pool.feeGrouthGlobal1X120(),7580090987929391967937100848442586409);

          // 1.829600026831158011
          // 1.558152222098388769
          // net -1518129116516325614066
          // net -320021147472383814130
          // -1518129116516325614066 + +1198107969043941799936 = -320021147472383814130

    }

/*
Consecutive price ranges with sqrtPriceLimitX96
6250---------------5500      5000
                  5500--------|--------4545
                              C
*/

    function testSwapInConsecutivePriceRangeWithPriceLimit() external {
        token0.mint(address(this),2 ether);
        token1.mint(address(this),15000 ether); 
        MintParams memory mintParams1 = MintParams({
            amount0:1 ether,
            amount1:5000 ether,
            allowenceAmount0:1 ether,           
            allowenceAmount1:5000 ether,
            currentTick:nearestUsableTick(tick(5000),60),
            upperTick:nearestUsableTick(tick(5500),60),
            lowerTick:nearestUsableTick(tick(4545),60)
        });

        MintParams memory mintParams2 = MintParams({
            amount0:1 ether,
            amount1:5000 ether,
            allowenceAmount0:1 ether,           
            allowenceAmount1:0 ether,
            currentTick:nearestUsableTick(tick(5000),60),
            upperTick:nearestUsableTick(tick(6250),60),
            lowerTick:nearestUsableTick(tick(5500),60)
        });

        

        SwapParams memory swapParams = SwapParams({
            amount0:0,
            amount1:10000 ether,
            zeroForOne:false,
            sqrtPriceLimitX96:5767923636470119667816132517957
        });

        InputUniswapMintCallBack(mintParams1);

        InputUniswapMintCallBack(mintParams2);

        (int256 amount0,int256 amount1) = InputUniswapSwapCallBack(swapParams);
           
          assertEq(amount0,-612281549808915909);
          assertEq(amount1,3161380715555614955214);
          assertEq(TickMath.getTickAtSqrtRatio(5875617940067453351001625213169),86129);


          // 1.829600026831158011
          // 1.558152222098388769
          // net -1518129116516325614066
          // net -320361671560818942450
          // -1518129116516325614066 + +1197767444955506671616 = 320361671560818942450

          // 381739656365887395592   76078838896153765    5622145994867546797787171334839
          // 1387719884058050968291  272080895930590471   5694568356906635577050546247497
          // 1405595967664531951712  268620626439733268   5767923636470119667816132517957
          // 1423702324230834940966  265204363952412292   5842223851049321075399999157648
          // 639880280561059518542   117010854912691805   5875617940067453351001625213169

    }


    function testFlashLoan() public {

        token0.mint(address(this),1 ether);
        token1.mint(address(this),6000 ether);

        FlashParams memory flashParams = FlashParams({
            amount0:0.5 ether,
            amount1:2500 ether
        });

        MintParams memory mintParams = MintParams({
            amount0:1 ether,
            amount1:5000 ether,
            allowenceAmount0:1 ether,
            allowenceAmount1:5000 ether,
            currentTick:nearestUsableTick(tick(5000),60),
            upperTick:nearestUsableTick(tick(5500),60),
            lowerTick:nearestUsableTick(tick(4545),60)
        });

        InputUniswapMintCallBack(mintParams);

        InputUniswapFlashCallBack(flashParams);
    }

    
    function InputUniswapSwapCallBack(SwapParams memory SP) public returns (int256 amount0,int256 amount1) {

        uint256 balance = token0.balanceOf(address(this));
        console.log(balance);
        

        //vm.startBroadcast(USER);
        console.log("before",msg.sender);
       
        SP.zeroForOne ? (token0.approve(address(this),SP.amount0)): (token1.approve(address(this),SP.amount1));
        UniswapV3Pool.Extra memory extra = UniswapV3Pool.Extra({token0:address(token0), token1:address(token1), payer:address(this)});
      //  bytes32 data = abi.encode(extra);
        (amount0, amount1) = pool.swap(address(this),SP.zeroForOne,SP.zeroForOne?SP.amount0:SP.amount1,(SP.sqrtPriceLimitX96==0)?(SP.zeroForOne?TickMath.MIN_SQRT_RATIO+1:TickMath.MAX_SQRT_RATIO-1):SP.sqrtPriceLimitX96,abi.encode(extra));

//8396874645169943
    }



    

    function InputUniswapMintCallBack(MintParams memory MP) public {

        uint256 balance = token0.balanceOf(address(this));
        console.log(balance);
        //85,176.190439785021062545146298293
        uint128 value = Math.minLiquidity(MP.amount1,MP.amount0,
        //5341294542274603406682713227264 ,5602277097478614198912276234240 ,5875717789736564987741329162240
                                        TickMath.getSqrtRatioAtTick(MP.lowerTick),
                                        TickMath.getSqrtRatioAtTick(MP.currentTick),
                                        TickMath.getSqrtRatioAtTick(MP.upperTick)/*5314786713428871004159001755648*/
                                        );
      
        console.log(uint256(value));
        console.log("sqrtattick",TickMath.getSqrtRatioAtTick(84222),
                                        TickMath.getSqrtRatioAtTick(85176),
                                        TickMath.getSqrtRatioAtTick(86129));
        console.log( TickMath.getSqrtRatioAtTick(85176));     
        console.log(TickMath.getTickAtSqrtRatio(5602223755577321903022134995689) == 85176)    ;           
        //vm.startBroadcast(USER);

        token0.approve(address(this),MP.allowenceAmount0);
        token1.approve(address(this),MP.allowenceAmount1);
        UniswapV3Pool.Extra memory extra = UniswapV3Pool.Extra({token0:address(token0), token1:address(token1), payer:address(this)});
      //  bytes32 data = abi.encode(extra);
      //  84222 85176 86129
        pool.mint(address(this),MP.lowerTick,MP.upperTick,uint128(value),abi.encode(extra));
        //  console.log((1 << (85184 % 256) ) - 1 + (1 << (85184 % 256)));
        //  console.log(1<<182);


        //1,517.8823437515104179547127202962  l
        //0.02767012882974527750883612494171   d p

        //  998976618347425274 5000000000000000000000
       
    }


    function InputUniswapFlashCallBack(FlashParams memory FP) public{

        //UniswapV3Pool.Extra memory extra = UniswapV3Pool.Extra({token0:address(token0),token1:address(token1),payer:address(this)});
        token0.approve(address(this),FP.amount0);
        token1.approve(address(this),FP.amount1);
        pool.flash(FP.amount0, FP.amount1, abi.encode(uint256(FP.amount0),uint256(FP.amount1)));
    }

    


    function uniswapSwapCallBack(int256 amount0, int256 amount1, bytes calldata data) public {
        console.log("after",msg.sender);
        UniswapV3Pool.Extra memory extra = abi.decode(data,(UniswapV3Pool.Extra));
       // IERC20(extra.token0).transferFrom(extra.payer,msg.sender,uint256(amount0));
        console.log(uint256(amount0),uint256(amount1));
        if(amount1>0){
          console.log("amount1",uint256(amount1));
          console.log("balance",token1.balanceOf(address(this)));
          console.log("allowence",token1.allowance(address(this),address(this)));
          IERC20(extra.token1).transferFrom(
            extra.payer,
            msg.sender,
            uint256(amount1)
            );
        }

        if(amount0>0){
          console.log("amount0",uint256(amount0));
          console.log("balance of amo0 this add", token0.balanceOf(address(this)));
          IERC20(extra.token0).transferFrom(
            extra.payer,
            msg.sender,
            uint256(amount0)
            );
        }



    }




    function uniswapMintCallBack(uint256 amount0, uint256 amount1, bytes calldata data) public {
        
        UniswapV3Pool.Extra memory extra = abi.decode(data,(UniswapV3Pool.Extra));
        if(amount0 > 0) IERC20(extra.token0).transferFrom(extra.payer,msg.sender,amount0);
        if(amount0 > 0) IERC20(extra.token1).transferFrom(extra.payer,msg.sender,amount1);
        console.log(amount0,amount1);



    }


    function uniswapFlashCallBack(uint256 fee0, uint256 fee1, bytes calldata data) public {
        (uint256 amount0, uint256 amount1) = abi.decode(data,(uint256,uint256));
        if(amount0 > 0) 
            console.log("amount1",uint256(amount0));
            console.log("balance",token0.balanceOf(address(this)));
           console.log("allowence",token0.allowance(address(this),address(this)));
            token0.transfer(msg.sender,amount0 + fee0);
        if(amount1 > 0) 
            console.log("amount1",uint256(amount1));
            console.log("balance",token1.balanceOf(address(this)));
            console.log("allowence",token1.allowance(address(this),address(this)));
            token1.transfer(msg.sender,amount1 + fee1);
        console.log(amount0,amount1);

    }  



    
    //sqrtu(price*2^128) = (sqrt of price * 2^64) => multiplying 2^32 gives sqrt of price * 2^96 = sqrtPriceX96
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


    function testsqrt() public {

        assertEq(ABDKMath64x64.sqrt(5000 ), 92233720368547758080000);
        assertEq(int128(int256(5000 << 64)),92233720368547758080000);
        //assertEq(int128(int256(5000 << 64)));
        assertEq(ABDKMath64x64.sqrtu(5000),70);
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

    function testdiv() public {
        assertEq(ABDKMath64x64.div(85176, 60),0);
        assertEq(int128(85176),0);
        assertEq(divRound(int128(85176), int128(int24(60))),0);
        assertEq(ABDKMath64x64.div(int128(85176), int128(60)),0);
        console.log(2**128);
    }

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


    function testtick() public {
        assertEq(nearestUsableTick(85176,60),85200);
    }
}
