// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { PausableStorage } from "../../shared/storage/PausableStorage.sol";
import { MainStorage } from "../../shared/storage/MainStorage.sol";
import { AccessControlStorage } from "../../shared/storage/AccessControlStorage.sol";
import { EIP712NonceStorage } from "../../shared/storage/EIP712NonceStorage.sol";
import { LibDiamond } from "../../shared/libraries/LibDiamond.sol";
import { LibMeta } from "../../shared/libraries/LibMeta.sol";
import { LibAccessControl } from "../../shared/libraries/LibAccessControl.sol";

import { EIP712DomainData } from "./LibMetaTransaction.sol";
import { LibMetaTransaction, MetaPackedData } from "./LibMetaTransaction.sol";

import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct AppStorage {
    uint256 version;
}

library LibAppStorage {
    bytes32 public constant EIP712Nonce_STORAGE_POSITION = keccak256("EIP712Nonce.storage.position");
    bytes32 public constant EIP712DomainData_STORAGE_POSITION = keccak256("EIP712DomainData.storage.position");
    bytes32 public constant PausableStorage_STORAGE_POSITION = keccak256("PausableStorage.storage.position");
    bytes32 public constant AccessControlStorage_STORAGE_POSITION = keccak256("AccessControlStorage.storage.position");
    bytes32 public constant MainStorage_STORAGE_POSITION = keccak256("MainStorage.storage.position");

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function eip712NonceStorage() internal pure returns (EIP712NonceStorage storage ds) {
        bytes32 position = EIP712Nonce_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function eip712DomainDataStorage() internal pure returns(EIP712DomainData storage ds) {
        bytes32 position = EIP712DomainData_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function pausableStorage() internal pure returns(PausableStorage storage ds) {
        bytes32 position = PausableStorage_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function accessControlStorage() internal pure returns(AccessControlStorage storage ds) {
        bytes32 position = AccessControlStorage_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function mainStorage() internal pure returns(MainStorage storage ds) {
        bytes32 position = MainStorage_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier signatureVerified(bytes4 selector, MetaPackedData calldata req, bytes calldata signature) {
        LibMetaTransaction.verify(selector, req, signature);
        LibAppStorage.eip712NonceStorage().used[req.nonce] = true;

        _;
    }

    modifier signatureVerifiedWithSender(
        bytes4 selector, MetaPackedData calldata req, bytes calldata signature, address sender
    ) {
        LibMetaTransaction.verify(selector, req, signature, sender);
        LibAppStorage.eip712NonceStorage().used[req.nonce] = true;

        _;
    }

    modifier onlyRole(bytes32 role) {
        LibAccessControl.checkRole(LibAppStorage.accessControlStorage(), role);
        _;
    }

    modifier onlyFromDiamond() {
        require(msg.sender == address(this), "internal call only!");
        _;
    }

    modifier whenNotPaused() {
        require(!LibAppStorage.pausableStorage().paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(LibAppStorage.pausableStorage().paused, "Pausable: not paused");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}
