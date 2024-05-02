// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { LibAccessControl } from "../../shared/libraries/LibAccessControl.sol";
import { LibDiamond } from "../../shared/libraries/LibDiamond.sol";

import { AppStorage, Modifiers } from "../libraries/LibAppStorage.sol";
import { LibMeta } from "../../shared/libraries/LibMeta.sol";

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "hardhat/console.sol";

contract UtilitiesFacet is Modifiers {
    using EnumerableSet for EnumerableSet.UintSet;

    function multiCall(bytes[] calldata data) external whenNotPaused returns (bytes[] memory) {
        bytes[] memory results = new bytes[](data.length);

        for (uint i = 0; i <  data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success, "call failed");
            results[i] = result;
        }

        return results;
    }

     function getNFTsOfOwner(address _contractAddr, address _owner, uint256 _collectionSize) external view returns (uint256[] memory) {
        IERC721 _contract = IERC721(_contractAddr);
        uint256 size = _collectionSize;
        bool[] memory temp = new bool[](size);
        uint256 count = 0;

        unchecked {
            for (uint i = 1; i <= size; i++) {
                try _contract.ownerOf(i) returns (address owner) {
                    if (owner == _owner) {
                        count++;
                        temp[i - 1] = true;
                    }
                } catch {
                    continue;
                }
            }

            uint256[] memory tokenIds = new uint256[](count);
            count = 0;
            for (uint i = 1; i <= size; i++) {
                if (temp[i - 1]) {
                    tokenIds[count++] = i;
                }
            }
            return tokenIds;
        }
    }
}