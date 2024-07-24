//SPDX-Lisence-Identifier:MIT

pragma solidity 0.8.24;
import {Test,console,stdError} from "forge-std/Test.sol";
import {UniswapV3Pool} from "../src/UniswapV3Pool.sol";
import {UniswapV3Factory} from "../src/UniswapV3Factory.sol";
import {UniswapV3Manager} from "../src/UniswapV3Manager.sol";
import {ERC20Mintable} from "./ERC20.sol";
import {IERC20} from "../src/Interfaces/IERC20.sol";
import {Math} from "../src/lib/Math.sol";
import {TickMath} from "../src/lib/TickMath.sol";
import {ABDKMath64x64} from "./ABDKMath64x64.sol";
import {TestUtils} from "./TestUtils.sol";
import {IUniswapV3Manager} from "../src/Interfaces/IUniswapV3Manager.sol";
import {UniswapV3Deployer} from "../src/UniswapV3Deployer.sol";
import {AssertionTest} from "./Assertion.sol";
 
contract UniswapV3ManagerTest is Test,TestUtils,AssertionTest,UniswapV3Deployer{
    
    UniswapV3Pool pool;
    UniswapV3Factory factory;
    UniswapV3Manager manager;
    ERC20Mintable token0;
    ERC20Mintable token1;
    ERC20Mintable uni;


    function setUp() public {
        
        //token0 = new ERC20Mintable("ETH","ETH",18);
        token1 = new ERC20Mintable("USDC","USDC",18);
        token0 = new ERC20Mintable("ETH","ETH",18);
        uni = new ERC20Mintable("Uniswap Coin", "UNI", 18);
        factory = new UniswapV3Factory();
        pool =  UniswapV3Pool(factory.createPool(address(token0),address(token1),3000));
        pool.initialize(TickMath.getSqrtRatioAtTick(85176));
        manager = new UniswapV3Manager(address(factory));


    }


    function testPoolAddress() public {
     
        assertEq(computePoolAddress(address(factory), address(token0), address(token1), 3000),0xC0AAC1540a371419860Dcd93e46Fb18784F5fEe9);
        assertEq(computePoolAddress(address(factory), address(token0), address(uni), 3000),0x8CD6ABC944d4ED15B6A00376F21d1CBD4e8F8D41);
    
    }

    function testMintInRange() public {

        
        console.log("pool tokens",pool.token0(),pool.token1());
        console.log("test tokens",address(token0), address(token1));
        (uint256 poolBalance0,
            uint256 poolBalance1,
            ,IUniswapV3Manager.MintParams[] memory mints) = setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:1 ether,
                balanceAmount1:5000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(4545,5500,1 ether,5000 ether)),
                mint:true,
                deploy:false

            }));


            assertMany(ExpectAssertMany({
                
                positions:ExpectedPosition({
                pool:pool,
                ticks:[mints[0].lowerTick,mints[0].upperTick],
                owner:address(this),
                liquidity:1546633283020210920055,
                feeGrowth: [uint256(0), 0],
                tokensOwed: [uint128(0), 0]
                }),

                poolState:ExpectedPoolState({
                    pool:pool,
                    liquidity:1546633283020210920055,
                    tick:85176,
                    sqrtPriceX96:TickMath.getSqrtRatioAtTick(85176),
                    fees:[uint256(0),0]
                }),

                tick:ExpectedTick({
                    pool:pool,
                    ticks:[mints[0].lowerTick,mints[0].upperTick],
                    initialized:true,
                    liquidityGross:[uint128(1546633283020210920055),1546633283020210920055],
                    liquidityNet:[int128(1546633283020210920055),-1546633283020210920055],
                    feeGrouthOutside0X120:0,
                    feeGrouthOutside1X120:0
                }),

                balance:ExpectedBalance({
                    pool:pool,
                    token:[token0,token1],
                    poolBalance0:poolBalance0,
                    poolBalance1:poolBalance1,
                    userBalance0:1 ether-poolBalance0,
                    userBalance1:5000 ether-poolBalance1

                }),

                testPosition:true,
                testPoolState:true,
                testTick:true,
                testBalance:true
            }));

    }


    function testMintRangeBelow() public {
        (uint256 poolBalance0,
            uint256 poolBalance1,,
            IUniswapV3Manager.MintParams[] memory mints) = setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:1 ether,
                balanceAmount1:5000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(4000,4996,1 ether,5000 ether)),
                mint:true,
                deploy:false

            }));


             assertMany(ExpectAssertMany({
                
                positions:ExpectedPosition({
                pool:pool,
                ticks:[mints[0].lowerTick,mints[0].upperTick],
                owner:address(this),
                liquidity:674293217439940683703,
                feeGrowth: [uint256(0), 0],
                tokensOwed: [uint128(0), 0]
                }),

                poolState:ExpectedPoolState({
                    pool:pool,
                    liquidity:0,
                    tick:85176,
                    sqrtPriceX96:TickMath.getSqrtRatioAtTick(85176),
                    fees:[uint256(0),0]
                }),

                tick:ExpectedTick({
                    pool:pool,
                    ticks:[mints[0].lowerTick,mints[0].upperTick],
                    initialized:true,
                    liquidityGross:[uint128(674293217439940683703),674293217439940683703],
                    liquidityNet:[int128(674293217439940683703),-674293217439940683703],
                    feeGrouthOutside0X120:0,
                    feeGrouthOutside1X120:0
                }),

                balance:ExpectedBalance({
                    pool:pool,
                    token:[token0,token1],
                    poolBalance0:poolBalance0,
                    poolBalance1:poolBalance1,
                    userBalance0:1 ether-poolBalance0,
                    userBalance1:5000 ether-poolBalance1

                }),

                testPosition:true,
                testPoolState:true,
                testTick:true,
                testBalance:true
            }));


            //lowerTick: 82920 [8.292e4], upperTick: 85140 [8.514e4], amount: 674293217439940683703 [6.742e20], amount0: 0, amount1: 4999999999999999999993 [4.999e21]
    }



    function testMintRangeAbove() public {
        (uint256 poolBalance0,
            uint256 poolBalance1,
            ,
            IUniswapV3Manager.MintParams[] memory mints) = setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:1 ether,
                balanceAmount1:5000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(5027,6250,1 ether,5000 ether)),
                mint:true,
                deploy:false

            }));


            assertMany(ExpectAssertMany({
                
                positions:ExpectedPosition({
                pool:pool,
                ticks:[mints[0].lowerTick,mints[0].upperTick],
                owner:address(this),
                liquidity:693653329148876535895,
                feeGrowth: [uint256(0), 0],
                tokensOwed: [uint128(0), 0]
                }),

                poolState:ExpectedPoolState({
                    pool:pool,
                    liquidity:0,
                    tick:85176,
                    sqrtPriceX96:TickMath.getSqrtRatioAtTick(85176),
                    fees:[uint256(0),0]
                }),

                tick:ExpectedTick({
                    pool:pool,
                    ticks:[mints[0].lowerTick,mints[0].upperTick],
                    initialized:true,
                    liquidityGross:[uint128(693653329148876535895),693653329148876535895],
                    liquidityNet:[int128(693653329148876535895),-693653329148876535895],
                    feeGrouthOutside0X120:0,
                    feeGrouthOutside1X120:0
                }),

                balance:ExpectedBalance({
                    pool:pool,
                    token:[token0,token1],
                    poolBalance0:poolBalance0,
                    poolBalance1:poolBalance1,
                    userBalance0:1 ether-poolBalance0,
                    userBalance1:5000 ether-poolBalance1

                }),

                testPosition:true,
                testPoolState:true,
                testTick:true,
                testBalance:true
            }));


            //lowerTick: 85260 [8.526e4], upperTick: 87420 [8.742e4], amount: 693653329148876535895 [6.936e20], amount0: 1000000000000000000 [1e18], amount1: 0)
    }



    function testMintOverlappingRanges() public {
        (uint256 _poolBalance0,
            uint256 _poolBalance1,
            ,
            IUniswapV3Manager.MintParams[] memory mints) = setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:2 ether,
                balanceAmount1:10000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(4545,5500,1 ether,5000 ether),
                            mintParams(4545,5500,1 ether,5000 ether)),
                mint:true,
                deploy:false

            }));

        uint256 poolBalance0 = 2 ether-_poolBalance0;
        uint256 poolBalance1 = 10000 ether-_poolBalance1;


        for(uint i = 0; i<mints.length; i++){

        assertMany(ExpectAssertMany({
                
                positions:ExpectedPosition({
                pool:pool,
                ticks:[mints[i].lowerTick,mints[i].upperTick],
                owner:address(this),
                liquidity:3093266566040421840110,
                feeGrowth: [uint256(0), 0],
                tokensOwed: [uint128(0), 0]
                }),

                poolState:ExpectedPoolState({
                    pool:pool,
                    liquidity:3093266566040421840110,
                    tick:85176,
                    sqrtPriceX96:TickMath.getSqrtRatioAtTick(85176),
                    fees:[uint256(0),0]
                }),

                tick:ExpectedTick({
                    pool:pool,
                    ticks:[mints[i].lowerTick,mints[i].upperTick],
                    initialized:true,
                    liquidityGross:[uint128(3093266566040421840110),3093266566040421840110],
                    liquidityNet:[int128(3093266566040421840110),-3093266566040421840110],
                    feeGrouthOutside0X120:0,
                    feeGrouthOutside1X120:0
                }),

                balance:ExpectedBalance({
                    pool:pool,
                    token:[token0,token1],
                    poolBalance0:_poolBalance0,
                    poolBalance1:_poolBalance1,
                    userBalance0:poolBalance0,
                    userBalance1:poolBalance1

                }),

                testPosition:true,
                testPoolState:true,
                testTick:true,
                testBalance:true
            }));
        }



        // lowerTick: 84240 [8.424e4], upperTick: 86100 [8.61e4], 3093266566040421840110 amount: 1546633283020210920055 [1.546e21], amount0: 987492179736600509 [9.874e17], amount1: 4999999999999999999998 [4.999e21])
    }


    function testMintPartiallyOverlappingRanges() public {

        (uint256 _poolBalance0,
            uint256 _poolBalance1,
            ,
            IUniswapV3Manager.MintParams[] memory mints) = setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:3 ether,
                balanceAmount1:15000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(4545,5500,1 ether,5000 ether),
                            mintParams(4000,4996,1 ether,5000 ether),
                            mintParams(5027,6250,1 ether,5000 ether)),
                mint:true,
                deploy:false

            }));

        uint256 poolBalance0 = 3 ether-_poolBalance0;
        uint256 poolBalance1 = 15000 ether-_poolBalance1;
        uint128[3] memory liquidityGross = [uint128(1546633283020210920055),674293217439940683703, 693653329148876535895];
        
        for(uint i = 0; i<mints.length; i++){

        assertMany(ExpectAssertMany({
                
                positions:ExpectedPosition({
                pool:pool,
                ticks:[mints[i].lowerTick,mints[i].upperTick],
                owner:address(this),
                liquidity:liquidityGross[i],
                feeGrowth: [uint256(0), 0],
                tokensOwed: [uint128(0), 0]
                }),

                poolState:ExpectedPoolState({
                    pool:pool,
                    liquidity:1546633283020210920055,
                    tick:85176,
                    sqrtPriceX96:TickMath.getSqrtRatioAtTick(85176),
                    fees:[uint256(0),0]
                }),

                tick:ExpectedTick({
                    pool:pool,
                    ticks:[mints[i].lowerTick,mints[i].upperTick],
                    initialized:true,
                    liquidityGross:[uint128(liquidityGross[i]),liquidityGross[i]],
                    liquidityNet:[int128(liquidityGross[i]),-int128(liquidityGross[i])],
                    feeGrouthOutside0X120:0,
                    feeGrouthOutside1X120:0
                }),

                balance:ExpectedBalance({
                    pool:pool,
                    token:[token0,token1],
                    poolBalance0:_poolBalance0,
                    poolBalance1:_poolBalance1,
                    userBalance0:poolBalance0,
                    userBalance1:poolBalance1

                }),

                testPosition:true,
                testPoolState:true,
                testTick:true,
                testBalance:true
            }));
        }
            //   lowerTick: 84240 [8.424e4], upperTick: 86100 [8.61e4], amount: 1546633283020210920055 [1.546e21], amount0: 987492179736600509 [9.874e17], amount1: 4999999999999999999998 [4.999e21])
            // lowerTick: 82920 [8.292e4], upperTick: 85140 [8.514e4], amount: 1546633283020210920055 [6.742e20], amount0: 0, amount1: 4999999999999999999993 [4.999e21])
            //  lowerTick: 85260 [8.526e4], upperTick: 87420 [8.742e4], amount: 1546633283020210920055 [6.936e20], amount0: 1000000000000000000 [1e18], amount1: 0)
    }


    function testMintInvalidTickRangeLower() public {

        vm.expectRevert(bytes("T"));
        int24 lowerTick = -887273;
        int24 upperTick = 1;
        uint256 amount0D = 1;
        uint256 amount1D = 1;
        manager.mint(IUniswapV3Manager.MintParams({
            token0:address(token0),
            token1:address(token1),
            fee:3000,
            upperTick:upperTick,
            lowerTick:lowerTick,
            amount0Desired:amount0D,
            amount1Desired:amount1D,
            amount0Min:0,
            amount1Min:0
        }));
        
        
    }

    
    function testMintInvalidTickRangeUpper() public {

        vm.expectRevert(bytes("T"));
        int24 lowerTick = 1;
        int24 upperTick = 887273;
        uint256 amount0D = 1;
        uint256 amount1D = 1;
        manager.mint(IUniswapV3Manager.MintParams({
            token0:address(token0),
            token1:address(token1),
            fee:3000,
            upperTick:upperTick,
            lowerTick:lowerTick,
            amount0Desired:amount0D,
            amount1Desired:amount1D,
            amount0Min:0,
            amount1Min:0
        }));
        
        
    }


    function testMintZeroLiquidity() public {
        
    

        (,,
            ,
            IUniswapV3Manager.MintParams[] memory mints) = setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:1 ether,
                balanceAmount1:5000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(5027,6250,0,0)),
                mint:false,
                deploy:false

            }));

        vm.expectRevert(abi.encodeWithSignature("ZeroLiquidity()"));
        manager.mint(mints[0]);    

    }


    function testMintInsufficientTokenBalance() public {



        (,
            ,
            ,IUniswapV3Manager.MintParams[] memory mints) = setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:0,
                balanceAmount1:0,
                currentPrice:5000,
                mints:mintParams(mintParams(5027,6250,1 ether,5000 ether)),
                mint:false,
                deploy:false

            }));

        vm.expectRevert(stdError.arithmeticError);
        manager.mint(mints[0]);    
        


        
    }


    

    function testSwapBuyUSDC() public {

        (uint256 poolBalance0,
            uint256 poolBalance1,
            ,
            IUniswapV3Manager.MintParams[] memory mints) = setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:1 ether,
                balanceAmount1:5000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(4545,5500,1 ether,5000 ether)),
                mint:true,
                deploy:false

            }));
            assertEq(ERC20Mintable(token0).balanceOf(address(this)),12507820263399491);

            ERC20Mintable(token0).approve(address(manager),0.008396874645169943 ether);

            manager.swapSingle(IUniswapV3Manager.SwapSingleParams({
                tokenIn:address(token0),
                tokenOut:address(token1),
                fee:3000,
                amountIn:0.008396874645169943 ether,
                sqrtPriceLimitX96:0
            }));



            assertMany(ExpectAssertMany({
                
                positions:ExpectedPosition({
                pool:pool,
                ticks:[mints[0].lowerTick,mints[0].upperTick],
                owner:address(this),
                liquidity:1546633283020210920055,
                feeGrowth: [uint256(0), 0],
                tokensOwed: [uint128(0), 0]
                }),

                poolState:ExpectedPoolState({
                    pool:pool,
                    liquidity:1546633283020210920055,
                    tick:85168,
                    sqrtPriceX96:5600080368524410198304530243981,
                    fees:[uint256(5542312603186474605673842350446),0]
                }),

                tick:ExpectedTick({
                    pool:pool,
                    ticks:[mints[0].lowerTick,mints[0].upperTick],
                    initialized:true,
                    liquidityGross:[uint128(1546633283020210920055),1546633283020210920055],
                    liquidityNet:[int128(1546633283020210920055),-1546633283020210920055],
                    feeGrouthOutside0X120:0,
                    feeGrouthOutside1X120:0
                }),

                balance:ExpectedBalance({
                    pool:pool,
                    token:[token0,token1],
                    poolBalance0:poolBalance0 + 0.008396874645169943 ether,
                    poolBalance1:poolBalance1 - 41841608453698538982 ,
                    userBalance0:1 ether-poolBalance0 - 0.008396874645169943 ether,
                    userBalance1:5000 ether-poolBalance1 + 41841608453698538982 

                }),

                testPosition:true,
                testPoolState:true,
                testTick:true,
                testBalance:true
            }));

    }


    function testSwapBuyEth() public {

        (uint256 poolBalance0,
            uint256 poolBalance1,
            ,
            IUniswapV3Manager.MintParams[] memory mints) = setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:1 ether,
                balanceAmount1:5000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(4545,5500,1 ether,5000 ether)),
                mint:true,
                deploy:false

            }));
            assertEq(ERC20Mintable(token0).balanceOf(address(this)),12507820263399491);
            ERC20Mintable(token1).mint(address(this),42 ether);
            ERC20Mintable(token1).approve(address(manager),42 ether);

             manager.swapSingle(IUniswapV3Manager.SwapSingleParams({
                tokenIn:address(token1),
                tokenOut:address(token0),
                fee:3000,
                amountIn:42 ether,
                sqrtPriceLimitX96:0
            }));

            assertMany(ExpectAssertMany({
                
                positions:ExpectedPosition({
                pool:pool,
                ticks:[mints[0].lowerTick,mints[0].upperTick],
                owner:address(this),
                liquidity:1546633283020210920055,
                feeGrowth: [uint256(0), 0],
                tokensOwed: [uint128(0), 0]
                }),

                poolState:ExpectedPoolState({
                    pool:pool,
                    liquidity:1546633283020210920055,
                    tick:85183,
                    sqrtPriceX96:5604368801926411075902760472622,
                    fees:[uint256(0),27721877385382738726755016209929146]
                }),

                tick:ExpectedTick({
                    pool:pool,
                    ticks:[mints[0].lowerTick,mints[0].upperTick],
                    initialized:true,
                    liquidityGross:[uint128(1546633283020210920055),1546633283020210920055],
                    liquidityNet:[int128(1546633283020210920055),-1546633283020210920055],
                    feeGrouthOutside0X120:0,
                    feeGrouthOutside1X120:0
                }),

                balance:ExpectedBalance({
                    pool:pool,
                    token:[token0,token1],
                    poolBalance0:poolBalance0 -8371754005882865,
                    poolBalance1:poolBalance1 + 42000000000000000000 ,
                    userBalance0:(1 ether-poolBalance0) + 8371754005882865,
                    userBalance1:(5000 ether-poolBalance1)  

                }),

                testPosition:true,
                testPoolState:true,
                testTick:true,
                testBalance:true
            }));


            // amount0: -8371754005882865 [-8.371e15], amount1: 42000000000000000000 [4.2e19], sqrtPriceX96: 5604368801926411075902760472622 [5.604e30], liquidity: 1546633283020210920055 [1.546e21], tick: 85183 [8.518e4], liquidityDelta: 1546633283020210920055 [1.546e21])
    }



    function testSwapBuyMultipool() public{
        (uint256 pool0Balance0,
            uint256 pool0Balance1,
            ,
            IUniswapV3Manager.MintParams[] memory mints) = setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:1 ether,
                balanceAmount1:5000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(4545,5500,1 ether,5000 ether)),
                mint:true,
                deploy:false

        }));

        (uint256 pool1Balance0,
            uint256 pool1Balance1,
            UniswapV3Pool pool1,
            IUniswapV3Manager.MintParams[] memory mints1) = setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(uni),
                balanceAmount0:10 ether,
                balanceAmount1:100 ether,
                currentPrice:10,
                mints:mintParams(mintParams(address(token0),address(uni),7, 13,10 ether,100 ether)),
                mint:true,
                deploy:true

        }));

        ERC20Mintable(token1).mint(address(this),42 ether);
        ERC20Mintable(token1).approve(address(manager),42 ether);

        bytes memory path = abi.encodePacked(
            bytes20(address(token1)),
            bytes3(uint24(3000)),
            bytes20(address(token0)),
            bytes3(uint24(3000)),
            bytes20(address(uni))
            );

        // bytes memory path = bytes.concat(
        //     bytes20(address(uni)),
        //     bytes3(uint24(3000)),
        //     bytes20(address(token0)),
        //     bytes3(uint24(3000)),
        //     bytes20(address(token1))
        // );

        manager.swap(IUniswapV3Manager.SwapParams({
            recipient:address(this),
            path:path,
            amountIn:42 ether,
            minAmountOut:0
        }));


        assertMany(ExpectAssertMany({
                
                positions:ExpectedPosition({
                pool:pool,
                ticks:[mints[0].lowerTick,mints[0].upperTick],
                owner:address(this),
                liquidity:1546633283020210920055,
                feeGrowth: [uint256(0), 0],
                tokensOwed: [uint128(0), 0]
                }),

                poolState:ExpectedPoolState({
                    pool:pool,
                    liquidity:1546633283020210920055,
                    tick:85183,
                    sqrtPriceX96:5604368801926411075902760472622,
                    fees:[uint256(0),27721877385382738726755016209929146]
                }),

                tick:ExpectedTick({
                    pool:pool,
                    ticks:[mints[0].lowerTick,mints[0].upperTick],
                    initialized:true,
                    liquidityGross:[uint128(1546633283020210920055),1546633283020210920055],
                    liquidityNet:[int128(1546633283020210920055),-1546633283020210920055],
                    feeGrouthOutside0X120:0,
                    feeGrouthOutside1X120:0
                }),

                balance:ExpectedBalance({
                    pool:pool,
                    token:[token0,token1],
                    poolBalance0:pool0Balance0 -8371754005882865,
                    poolBalance1:pool0Balance1 + 42000000000000000000 ,
                    userBalance0:(1 ether-pool0Balance0) + (10 ether-pool1Balance0) ,
                    userBalance1:(5000 ether-pool0Balance1)  

                }),

                testPosition:true,
                testPoolState:true,
                testTick:true,
                testBalance:true
            }));


            assertMany(ExpectAssertMany({
                
                positions:ExpectedPosition({
                pool:pool1,
                ticks:[mints1[0].lowerTick,mints1[0].upperTick],
                owner:address(this),
                liquidity:192611247052046431504,
                feeGrowth: [uint256(0), 0],
                tokensOwed: [uint128(0), 0]
                }),

                poolState:ExpectedPoolState({
                    pool:pool1,
                    liquidity:192611247052046431504,
                    tick:23024,
                    sqrtPriceX96:250507120252781734798817413778,
                    fees:[uint256(44370621840664443437862666733184),0]
                }),

                tick:ExpectedTick({
                    pool:pool1,
                    ticks:[mints1[0].lowerTick,mints1[0].upperTick],
                    initialized:true,
                    liquidityGross:[uint128(192611247052046431504),192611247052046431504],
                    liquidityNet:[int128(192611247052046431504),-192611247052046431504],
                    feeGrouthOutside0X120:0,
                    feeGrouthOutside1X120:0
                }),

                balance:ExpectedBalance({
                    pool:pool1,
                    token:[token0,uni],
                    poolBalance0:pool1Balance0 + 8371754005882865,
                    poolBalance1:pool1Balance1 - 83454951229706714 ,
                    userBalance0:(1 ether-pool0Balance0) + (10 ether-pool1Balance0) ,
                    userBalance1:(100 ether-pool1Balance1) + 83454951229706714

                }),

                testPosition:true,
                testPoolState:true,
                testTick:true,
                testBalance:true
            }));




    }


    function testSwapBuyEthNotEnoughLiquidity() public{

        
             setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:1 ether,
                balanceAmount1:5000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(4545,5500,1 ether,5000 ether)),
                mint:true,
                deploy:false

            }));
            assertEq(ERC20Mintable(token0).balanceOf(address(this)),12507820263399491);
            ERC20Mintable(token1).mint(address(this),5300 ether);
            ERC20Mintable(token1).approve(address(manager),5300 ether);

            vm.expectRevert(abi.encodeWithSignature("NotEnoughLiquidity()"));
            manager.swapSingle(IUniswapV3Manager.SwapSingleParams({
                tokenIn:address(token1),
                tokenOut:address(token0),
                fee:3000,
                amountIn:5300 ether,
                sqrtPriceLimitX96:0
            }));
    }



    function testSwapBuyUSDCNotEnoughLiquidity() public {

         setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:1 ether,
                balanceAmount1:5000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(4545,5500,1 ether,5000 ether)),
                mint:true,
                deploy:false

            }));
            assertEq(ERC20Mintable(token0).balanceOf(address(this)),12507820263399491);
            ERC20Mintable(token0).mint(address(this),1.5 ether);
            ERC20Mintable(token0).approve(address(manager),1.5 ether);

            vm.expectRevert(abi.encodeWithSignature("NotEnoughLiquidity()"));
            manager.swapSingle(IUniswapV3Manager.SwapSingleParams({
                tokenIn:address(token0),
                tokenOut:address(token1),
                fee:3000,
                amountIn:1.5 ether,
                sqrtPriceLimitX96:0
            }));

    }


    function testSwapInsufficientInputAmount() public {

         setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:1 ether,
                balanceAmount1:5000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(4545,5500,1 ether,5000 ether)),

                mint:true,
                deploy:false

            }));
            assertEq(ERC20Mintable(token0).balanceOf(address(this)),12507820263399491);
            
            vm.expectRevert(stdError.arithmeticError);
            manager.swapSingle(IUniswapV3Manager.SwapSingleParams({
                tokenIn:address(token1),
                tokenOut:address(token0),
                fee:3000,
                amountIn:42 ether,
                sqrtPriceLimitX96:0
            }));

            // amount0: -8371754005882865 [-8.371e15], amount1: 42000000000000000000 [4.2e19], sqrtPriceX96: 5604368801926411075902760472622 [5.604e30], liquidity: 1546633283020210920055 [1.546e21], tick: 85183 [8.518e4], liquidityDelta: 1546633283020210920055 [1.546e21])
    }


    function testGetPosition() public {


        setUpTest(SetUpParams({
                token0:address(token0),
                token1:address(token1),
                balanceAmount0:1 ether,
                balanceAmount1:5000 ether,
                currentPrice:5000,
                mints:mintParams(mintParams(4545,5500,1 ether,5000 ether)),

                mint:true,
                deploy:false

            }));


            (uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1)  = manager.getPosition(IUniswapV3Manager.GetPositionParams({
                tokenA:address(token0),
                tokenB:address(token1),
                fee:3000,
                owner:address(this),
                lowerTick:84240,
                upperTick:86100
            }));

            assertEq(liquidity,1546633283020210920055);
            assertEq(feeGrowthInside0LastX128,0);
            assertEq(feeGrowthInside1LastX128,0);
            assertEq(tokensOwed0,0);
            assertEq(tokensOwed1,0);
    }





    


    

        


        struct SetUpParams{
            address token0;
            address token1;
            uint256 balanceAmount0;
            uint256 balanceAmount1;
            uint256 currentPrice;
            IUniswapV3Manager.MintParams[] mints;
            bool mint;
            bool deploy;
        }


        function setUpTest(SetUpParams memory params) internal returns(uint256 poolBalance0,
            uint256 poolBalance1,
            UniswapV3Pool pool1,
            IUniswapV3Manager.MintParams[] memory mints) {
            
            if(params.deploy){
                pool1 = UniswapV3Pool(factory.createPool(params.token0,params.token1,3000)); 
                pool1.initialize(sqrtP(10));
            }
            

            if(params.mint){
                ERC20Mintable(params.token0).mint(address(this),params.balanceAmount0);
                ERC20Mintable(params.token1).mint(address(this),params.balanceAmount1);
                ERC20Mintable(params.token0).approve(address(manager),params.balanceAmount0);
                ERC20Mintable(params.token1).approve(address(manager),params.balanceAmount1);
                console.log(params.mints.length);
                for(uint256 i = 0; i<params.mints.length; i++){
                    (uint256 amount0, uint256 amount1) = manager.mint(params.mints[i]);
                    poolBalance0 += amount0;
                    poolBalance1 += amount1;
                }
            }

            mints = params.mints;

        }

       

        function mintParams(
            uint256 lowerPrice, 
            uint256 upperPrice, 
            uint256 amount0, 
            uint256 amount1
            ) 
            internal 
            view 
            returns(IUniswapV3Manager.MintParams memory params) {

            params = mintParams(
                address(token0), 
                address(token1), 
                lowerPrice, 
                upperPrice, 
                amount0, 
                amount1);

        }

        function mintParams(
            address tokenA, 
            address tokenB, 
            uint256 lowerPrice, 
            uint256 upperPrice, 
            uint256 amount0, 
            uint256 amount1
            ) 
            internal 
            pure 
            returns(IUniswapV3Manager.MintParams memory params){
             
            params = IUniswapV3Manager.MintParams({
                token0:tokenA,
                token1:tokenB,
                fee:3000,
                upperTick:nearestUsableTick(tick(upperPrice),60),
                lowerTick:nearestUsableTick(tick(lowerPrice),60),
                amount0Desired:amount0,
                amount1Desired:amount1,
                amount0Min:0,
                amount1Min:0
            });
        }

        function mintParams(
            address tokenA, 
            address tokenB, 
            uint256 lowerPrice, 
            uint256 upperPrice, 
            uint256 amount0, 
            uint256 amount1,
            uint256 amount0Min,
            uint256 amount1Min
            ) 
            internal 
            pure 
            returns(IUniswapV3Manager.MintParams memory params){
             
            params = IUniswapV3Manager.MintParams({
                token0:tokenA,
                token1:tokenB,
                fee:3000,
                upperTick:nearestUsableTick(tick(upperPrice),60),
                lowerTick:nearestUsableTick(tick(lowerPrice),60),
                amount0Desired:amount0,
                amount1Desired:amount1,
                amount0Min:amount0Min,
                amount1Min:amount1Min
            });
        }


        


        function mintParams(IUniswapV3Manager.MintParams memory params) internal pure returns(IUniswapV3Manager.MintParams[] memory mints) {

            mints = new IUniswapV3Manager.MintParams[](1);
            mints[0] = params;

        }


        

        function mintParams(
            IUniswapV3Manager.MintParams memory params0, 
            IUniswapV3Manager.MintParams memory params1    
        ) internal pure returns(IUniswapV3Manager.MintParams[] memory mints){

            mints = new IUniswapV3Manager.MintParams[](2);
            mints[0] = params0;
            mints[1] = params1;

        }

        function mintParams(
            IUniswapV3Manager.MintParams memory params0, 
            IUniswapV3Manager.MintParams memory params1, 
            IUniswapV3Manager.MintParams memory params2
        ) internal pure returns(IUniswapV3Manager.MintParams[] memory mints){

            mints = new IUniswapV3Manager.MintParams[](3);
            mints[0] = params0;
            mints[1] = params1;
            mints[2] = params2;

        }
        

        

}