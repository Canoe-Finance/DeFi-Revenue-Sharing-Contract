// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Events {

    /*
    Modify the project fee ratio

    */
    event setProjectFeeRatio(uint256 blockTimestamp, string projectID, uint256 proportion);

    /*
    Modify the project treasury fee ratio

    */
    event setProjectTreasuryFeeRatio(uint256 blockTimestamp, string projectID, uint256 proportion);

    /*
    Modify the treasury fee ratio

    */
    event setTreasuryFeeRatio(uint256 blockTimestamp, uint256 proportion);

}
