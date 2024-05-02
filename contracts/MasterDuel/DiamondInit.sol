// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { AppStorage } from "./libraries/LibAppStorage.sol";
import { LibMetaTransaction } from "./libraries/LibMetaTransaction.sol";
import {LibDiamond} from "../shared/libraries/LibDiamond.sol";
import {LibMeta} from "../shared/libraries/LibMeta.sol";
import { LibAccessControl } from "../shared/libraries/LibAccessControl.sol";
import { LibAppStorage } from "./libraries/LibAppStorage.sol";
import {IDiamondLoupe} from "../shared/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../shared/interfaces/IDiamondCut.sol";
import {IERC173} from "../shared/interfaces/IERC173.sol";
import {IERC165} from "../shared/interfaces/IERC165.sol";
import {IERC721} from "../shared/interfaces/IERC721.sol";

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract DiamondInit {
    AppStorage internal s;

    struct Args {
        address[] accounts;
    }

    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(Args memory args) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Receiver).interfaceId] = true;

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface

        LibMetaTransaction.initEIP721DomainData("MasterDuelMetaTx", "1.0");

        LibAccessControl.grantRole(LibAppStorage.accessControlStorage(), LibAccessControl.DEFAULT_ADMIN_ROLE, msg.sender);
        LibAccessControl.grantRole(LibAppStorage.accessControlStorage(), LibAccessControl.BLUEPRINT_ROLE, args.accounts[1]);
        LibAccessControl.grantRole(LibAppStorage.accessControlStorage(), LibAccessControl.MINTER_ROLE, args.accounts[2]);
        LibAccessControl.grantRole(LibAppStorage.accessControlStorage(), LibAccessControl.OP_ROLE, args.accounts[3]);
        LibAccessControl.grantRole(LibAppStorage.accessControlStorage(), LibAccessControl.FINANCIAL_ROLE, args.accounts[4]);
        LibAccessControl.grantRole(LibAppStorage.accessControlStorage(), LibAccessControl.SIGNER_ROLE, args.accounts[5]);
    }
}
