// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";

library LibBlueprint {
    using EnumerableSet for EnumerableSet.UintSet;
}
