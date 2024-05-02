// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {AppStorage, Modifiers} from "../libraries/LibAppStorage.sol";
import {LibBlueprint} from "../libraries/LibBlueprint.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {MainStorage} from "../../shared/storage/MainStorage.sol";

import {LibAccessControl} from "../../shared/libraries/LibAccessControl.sol";

contract BlueprintFacet is Modifiers {
    function setBeneficiary(
        address _beneficiary
    ) external onlyRole(LibAccessControl.BLUEPRINT_ROLE) {
        MainStorage storage ms = LibAppStorage.mainStorage();
        ms.beneficiary = _beneficiary;
    }

    function setDexRouter(
        address _dexRouter
    ) external onlyRole(LibAccessControl.BLUEPRINT_ROLE) {
        MainStorage storage ms = LibAppStorage.mainStorage();
        ms.dexRouter = _dexRouter;
    }

    function setTokenOut(
        address _tokenOut
    ) external onlyRole(LibAccessControl.BLUEPRINT_ROLE) {
        MainStorage storage ms = LibAppStorage.mainStorage();
        ms.tokenOut = _tokenOut;
    }

    function setSlippage(
        uint256 _slip
    ) external onlyRole(LibAccessControl.BLUEPRINT_ROLE) {
        MainStorage storage ms = LibAppStorage.mainStorage();
        ms.slip = _slip;
    }
}
