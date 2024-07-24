//SPDX-Lisence-Identifier:MIT

pragma solidity 0.8.24;

interface IUniswapV3Deployer{

    


    function parameters() external view returns(
        address factory,
        address token0,
        address token1,
        uint24 tickSpacing,
        uint24 fee 
    );
    
}