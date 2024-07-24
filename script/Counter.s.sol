//SPDX-Lisence-Identifer:MIT

pragma solidity 0.8.24;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import {UniswapV3ManagerTest} from "../test/UniswapV3Manager.t.sol";
import {ERC20Mintable} from "../test/ERC20.sol";
import {TickMath} from "../src/lib/TickMath.sol";
import {PoolAddress} from "../src/lib/PoolAddress.sol";
import {UniswapV3Manager} from "../src/UniswapV3Manager.sol";
import {IUniswapV3Manager} from "../src/Interfaces/IUniswapV3Manager.sol";
import {UniswapV3Factory} from "../src/UniswapV3Factory.sol";
import {UniswapV3Pool} from "../src/UniswapV3Pool.sol";


contract InteractScript is Script,UniswapV3ManagerTest{


           

    function run() external {
        // DEPLOYING STARGED

        //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast( );
        //ERC20Mintable token1 = new ERC20Mintable("USD Coin", "USDC", 18);
        ERC20Mintable token0 = new ERC20Mintable("Wrapped Ether", "WETH", 18);
        ERC20Mintable token1 = new ERC20Mintable("USD Coin", "USDC", 18);
        console.log(token0 < token1);

        

        UniswapV3Factory factory = new UniswapV3Factory();
         address poolAddress = PoolAddress.computePoolAddress(
            address(factory),
            address(token0),
            address(token1),
            3000
        );
        console.log("poolAddress",poolAddress,0xB9F9C716AA155B9255CBd4Ac495a6605Ab4E4802);
        UniswapV3Manager manager = new UniswapV3Manager(address(factory));


        UniswapV3Pool pool = UniswapV3Pool(factory.createPool(address(token0),address(token1),3000));
        console.log("up",pool.token0(),pool.token1());
        console.log("down",address(token0),address(token1));

        pool.initialize(TickMath.getSqrtRatioAtTick(85176));

        



        token1.mint(msg.sender, 5000 ether);
        token0.mint(msg.sender, 1 ether);

       
        token1.approve(address(manager), 5000 ether);
        token0.approve(address(manager), 1 ether);

        manager.mint(
            UniswapV3ManagerTest.mintParams(
                address(token0),
                address(token1),
                4545,
                5500,
                1 ether,
                5000 ether
            ));

        // UniswapV3Pool wethUsdc =  (
        //     factory,
        //     address(weth),
        //     address(usdc),
        //     3000,
        //     5000
        // );

        // UniswapV3Pool wethUni = deployPool(
        //     factory,
        //     address(weth),
        //     address(uni),
        //     3000,
        //     10
        // );

        // UniswapV3Pool wbtcUSDT = deployPool(
        //     factory,
        //     address(wbtc),
        //     address(usdt),
        //     3000,
        //     20_000
        // );

        // UniswapV3Pool usdtUSDC = deployPool(
        //     factory,
        //     address(usdt),
        //     address(usdc),
        //     500,
        //     1
        // );

     
        // usdc.mint(msg.sender, balances.usdc);
        // weth.mint(msg.sender, balances.weth);

       
        // usdc.approve(address(manager), 1_005_000 ether);
        // weth.approve(address(manager), 11 ether);

        // manager.mint(
        //     mintParams(
        //         address(weth),
        //         address(usdc),
        //         4545,
        //         5500,
        //         1 ether,
        //         5000 ether
        //     )
        // );
        // manager.mint(
        //     mintParams(address(weth), address(uni), 7, 13, 10 ether, 100 ether)
        // );

        // manager.mint(
        //     mintParams(
        //         address(wbtc),
        //         address(usdt),
        //         19400,
        //         20500,
        //         10 ether,
        //         200_000 ether
        //     )
        // );
        // manager.mint(
        //     mintParams(
        //         address(usdt),
        //         address(usdc),
        //         uint160(77222060634363714391462903808), //  0.95, int(math.sqrt(0.95) * 2**96)
        //         uint160(81286379615119694729911992320), // ~1.05, int(math.sqrt(1/0.95) * 2**96)
        //         1_000_000 ether,
        //         1_000_000 ether,
        //         500
        //     )
        // );

         vm.stopBroadcast();
        // // DEPLOYING DONE

        // console.log("WETH address", address(weth));
        // console.log("UNI address", address(uni));
        // console.log("USDC address", address(usdc));
        // console.log("USDT address", address(usdt));
        // console.log("WBTC address", address(wbtc));

        // console.log("Factory address", address(factory));
        // console.log("Manager address", address(manager));
        // console.log("Quoter address", address(quoter));

        // console.log("USDT/USDC address", address(usdtUSDC));
        // console.log("WBTC/USDT address", address(wbtcUSDT));
        // console.log("WETH/UNI address", address(wethUni));
        // console.log("WETH/USDC address", address(wethUsdc));
    }
}

//forge script script/Counter.s.sol --rpc-url https://eth-sepolia.g.alchemy.com/v2/s9ijM9GJ7CwHrk6kUNu6qGCbH_RDh724 --private-key c096607f604bec8ecb4b0702ea980d215a4e22c6e005c1439b5f5605434e7e3e --etherscan-api-key AK2G9NSYXP5V728MWKS9WAE95YNBWYQRZ9 \--verify -vvvv --ffi