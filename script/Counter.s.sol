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

        

         vm.stopBroadcast();
        
    }
}

