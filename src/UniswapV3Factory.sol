//SPDX-Lisence-Identifier:MIT

import {UniswapV3Deployer} from "./UniswapV3Deployer.sol";
import {Test, console} from "forge-std/Test.sol";

pragma solidity 0.8.24;

contract UniswapV3Factory is UniswapV3Deployer{


    error UnsupportedFee();
    mapping(uint24 => uint24) public fees;
    mapping(address => mapping(address => mapping(uint24 => address))) public pools;

    event poolCreated(address pool, address token0, address token1, uint24 fee);
   

    constructor(){
        fees[500] = 10;
        fees[3000] = 60;
    }


    function createPool(address token0, address token1, uint24 fee) external returns(address pool){

        require(token0 != token1);

        (token0,token1) = (token0<token1)
            ?   (token0,token1)
            :   (token1,token0);
        console.log(token0,token1);    
        require(token0 != address(0));    
        if(fees[fee]==0) revert UnsupportedFee();
        require(pools[token0][token1][fee]==address(0));
        pool = deploy(address(this),token0,token1,fees[fee],fee);

        pools[token0][token1][fee] = pool;
        pools[token1][token0][fee] = pool;

        emit poolCreated(pool,token0,token0,fee);


    }
}