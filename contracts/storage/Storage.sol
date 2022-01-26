// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Storage {

    mapping(string => uint256) public projectFee;
    mapping(string => uint256) public projectTreasuryFee;

    mapping(string => mapping(address => uint256)) public projectFeeAddress;
    mapping(string => address[]) public projectAddress;

    mapping(address => uint256) public treasuryFeeAddress;
    address[] public treasuryAddress;

    address  public _ETH_ADDRESS_;

    uint256 public _precision;
    uint256 public treasuryFee;

}
