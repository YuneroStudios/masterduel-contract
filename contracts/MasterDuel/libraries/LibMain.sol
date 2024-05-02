// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {MainStorage} from "../../shared/storage/MainStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";

library LibMain {
    event Deposit(
        address user,
        uint256 nativeAmount,
        address tokenAddress,
        uint256 tokenAmounts
    );

    event Claimed(
        uint256 nonce,
        address user,
        address token,
        uint256 amount,
        bytes32 claimId
    );

    function getAmountsOut(uint256 _amountIn) internal view returns (uint256) {
        MainStorage storage ms = LibAppStorage.mainStorage();
        IUniswapV2Router02 router = IUniswapV2Router02(ms.dexRouter);
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(ms.tokenOut);
        return router.getAmountsOut(_amountIn, path)[1];
    }

    function receiveETH() internal {
        MainStorage storage ms = LibAppStorage.mainStorage();
        require(msg.value > 0, "LibMain: No ETH sent");
        require(ms.beneficiary != address(0), "LibMain: Beneficiary not set");
        (bool success, ) = ms.beneficiary.call{value: msg.value}("");
        require(success, "LibMain: ETH transfer failed");
        emit Deposit(msg.sender, msg.value, address(0), 0);
    }

    function claim(uint256 _nonce, bytes memory _data) internal {
        (address token, uint256 claimAmount, bytes32 claimId) = abi.decode(
            _data,
            (address, uint256, bytes32)
        );
        bool success = IERC20(token).transfer(LibMeta.msgSender(), claimAmount);
        require(success, "LibMain: claim failed");
        emit Claimed(_nonce, LibMeta.msgSender(), token, claimAmount, claimId);
    }
}
