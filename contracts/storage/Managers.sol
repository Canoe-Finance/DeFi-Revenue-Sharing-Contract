// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Managers {
    // financial administrator
    bytes32 public constant FINANCIAL_ADMINISTRATOR  = keccak256("FINANCIAL_ADMINISTRATOR ");
    // Project administrators
    bytes32 public constant PROJECT_ADMINISTRATORS = keccak256("PROJECT_ADMINISTRATORS");
}
