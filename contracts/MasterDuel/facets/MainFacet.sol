// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {AppStorage, LibAppStorage, Modifiers} from "../libraries/LibAppStorage.sol";
import {LibAccessControl} from "../../shared/libraries/LibAccessControl.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {LibMain} from "../libraries/LibMain.sol";
import {MetaPackedData} from "../../shared/libraries/LibMetaTxDomain.sol";

contract MainFacet is Modifiers {
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

    function getAmountsOut(uint256 _amountIn) external view returns (uint256) {
        return LibMain.getAmountsOut(_amountIn);
    }

    function claim(
        MetaPackedData calldata _req,
        bytes calldata _signature
    ) external signatureVerified(this.claim.selector, _req, _signature) {
        LibMain.claim(_req.nonce, _req.data);
    }

    // receive() external payable {
    //     LibMain.receiveETH();
    // }
}
