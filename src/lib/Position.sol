//SPDX-Lisence-Identifier:MIT

pragma solidity 0.8.24;
import {Test, console} from "forge-std/Test.sol";
import {Math} from "./Math.sol";

library Position{

    uint256 internal constant Q128 = 1 << 128;
    
    struct Info{
        uint128 liquidity;
        uint256 feeGrouthInside0LastX120;
        uint256 feeGrouthInside1LastX120;
        uint128 tokenOwned0;
        uint128 tokenOwned1;
    }

    function update(Info storage self, int128 liquidityDelta, uint256 feeGrouthInside0X120, uint256 feeGrouthInside1X120) internal {
        
        uint128 tokenOwned0 = uint128(
            Math.mulDiv(
                feeGrouthInside0X120 - self.feeGrouthInside0LastX120,
                self.liquidity,
                Q128
                )
            );
        uint128 tokenOwned1 = uint128(
            Math.mulDiv(
                feeGrouthInside1X120 - self.feeGrouthInside1LastX120,
                self.liquidity,
                Q128
                )
            );

        uint128 liquidityBefore = self.liquidity;
        uint128 liquidityAfter = Math.addLiquidity(liquidityBefore,liquidityDelta);

        if(liquidityDelta != 0)self.liquidity = liquidityAfter;

        self.feeGrouthInside0LastX120 = feeGrouthInside0X120;
        self.feeGrouthInside1LastX120 = feeGrouthInside1X120;
        if(tokenOwned0 > 0 || tokenOwned1 > 0){
        self.tokenOwned0 += tokenOwned0;
        self.tokenOwned1 += tokenOwned1;
        }
    }
    function get(
        mapping(bytes32 => Position.Info) storage self,
        address owner, 
        int24 lowerTick, 
        int24 upperTick) internal view returns(Position.Info storage position){
            position = self[keccak256(abi.encodePacked(owner,lowerTick,upperTick))];
            console.log(position.liquidity);

        }
}