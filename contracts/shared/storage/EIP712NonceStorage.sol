// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

struct EIP712NonceStorage {
  mapping(uint256 => bool) used;
}