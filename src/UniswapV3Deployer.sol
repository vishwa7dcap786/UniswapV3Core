//SPDX-Lisence-Identifier:MIT


import {UniswapV3Pool} from "./UniswapV3Pool.sol";
import {IUniswapV3Deployer} from "./interfaces/IUniswapV3Deployer.sol";

pragma solidity 0.8.24;

contract UniswapV3Deployer is IUniswapV3Deployer{

    struct Parameters{
        address factory;
        address token0;
        address token1;
        uint24 tickSpacing;
        uint24 fee;
    }

    
    Parameters public override parameters;



    function deploy(address factory, address token0, address token1, uint24 tickSpacing, uint24 fee) internal returns(address pool){
        parameters = Parameters({
            factory:factory, token0:token0, token1:token1, tickSpacing:tickSpacing, fee:fee
        });

        pool = address(new UniswapV3Pool{salt:keccak256(abi.encodePacked(token0,token1,fee))}());
        delete parameters; 
    }

}