// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./storage/Storage.sol";
import "./storage/Events.sol";
import "./storage/Managers.sol";


contract MetaDexSwap is AccessControlEnumerableUpgradeable, Storage, Events, Managers {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    

    /*
    * @notice Initialization method 0xaFd190a14847a16B7Bbed3A655E42133d439c037
    * @dev Initialization method, can only be used once,
    *      And set project default administrator
    */
    function initialize(
    ) public initializer {
        _ETH_ADDRESS_ = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        _precision = 100;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }

    receive() external payable {}

    /*
    * @notice Users use DODO API to trade
    * @dev Compatible with ETH=>ERC20, ERC20=>ETH
    * @param fromToken     Contract address of a token to sell ETH(BNB or Matic) 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    * @param toToken       Contract address of a token to buy ETH(BNB or Matic) 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    * @param fromAmount    Amount of a token to sell NOTE：calculated with decimals，For example 1ETH = 10**18
    * @param newFromAmount New amount of a token to sell NOTE：calculated with decimals，For example 1ETH = 10**18
    * @param projectId     The id of the project that has been cooperated with
    * @param dodoApprove   User need give sell Token's authority to this contract  before swaping. if sell Token equals to ETH (BNB or HT). the param will be empty.
    * @param dodoProxy     DODOV2Proxy or DODORouteProxy's address
    * @param dodoApiData   ABI Data,Use directly
    */
    function useDodoApiData(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 newFromAmount,
        string calldata projectId,
        address dodoApprove,
        address dodoProxy,
        bytes memory dodoApiData
    ) external payable {
        require(fromToken != address(0) && toToken != address(0), "MS:f1");
        uint256 newFromAmount_ = _getHandlingFee(fromAmount, projectId, fromToken);
        require(newFromAmount == newFromAmount_, "MS:f2");

        if (fromToken != _ETH_ADDRESS_) {
            IERC20(fromToken).transferFrom(_msgSender(), address(this), fromAmount);
            _generalApproveMax(fromToken, dodoApprove, newFromAmount_);
        } else {
            require(fromAmount == msg.value);
        }

        (bool success,) = dodoProxy.call{value : fromToken == _ETH_ADDRESS_ ? newFromAmount : 0}(dodoApiData);
        require(success, "MS:f3");

        uint256 returnAmount = _generalBalanceOf(toToken, address(this));

        _generalTransfer(toToken, _msgSender(), returnAmount);
    }

    /*
    * @dev Max Approve of user's sold tokens
    * @param token  Approve token address
    * @param to     Approve address
    * @param amount Number of transactions
    */
    function _generalApproveMax(
        address token,
        address to,
        uint256 amount
    ) internal {
        uint256 allowance = IERC20(token).allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                IERC20(token).safeApprove(to, 0);
            }
            IERC20(token).safeApprove(to, ~uint256(0));
        }
    }

    /*
    * @dev Send the tokens exchanged by the user to the user
    * @param token  Send token address
    * @param to     Payment address
    * @param amount Amount of tokens sent
    */
    function _generalTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (token == _ETH_ADDRESS_) {
                payable(to).transfer(amount);
            } else {
                IERC20(token).safeTransfer(to, amount);
            }
        }
    }

    /*
    * @dev Query the token balance in an address
    * @param token Query token address
    * @param who   The queried address
    */
    function _generalBalanceOf(
        address token,
        address who
    ) internal view returns (uint256) {
        if (token == _ETH_ADDRESS_) {
            return who.balance;
        } else {
            return IERC20(token).balanceOf(who);
        }
    }

    /*
    * @dev Calculate the fee ratio
    * @param  fromAmount     Amount of a token to sell NOTE：calculated with decimals，For example 1ETH = 10**18
    * @param  projectId      The id of the project that has been cooperated with
    * @return newFromAmount_ From amount after handling fee
    */
    function _getHandlingFee(
        uint256 fromAmount,
        string calldata projectId,
        address fromToken
    ) internal returns (uint256 newFromAmount_){

        (, uint256 treasuryBounty_) = (fromAmount.mul(treasuryFee)).tryDiv(_precision);
        (, uint256 projectBounty_) = ((fromAmount.sub(treasuryBounty_)).mul(projectFee[projectId])).tryDiv(_precision);
        (, uint256 projectTreasuryBounty_) = (projectBounty_.mul(projectTreasuryFee[projectId])).tryDiv(_precision);
        newFromAmount_ = fromAmount.sub(projectBounty_);

        if (projectFeeAddress[projectId][fromToken] == 0) projectAddress[projectId].push(fromToken);
        projectFeeAddress[projectId][fromToken] += projectBounty_.sub(projectTreasuryBounty_);

        if (treasuryFeeAddress[fromToken] == 0) treasuryAddress.push(fromToken);
        treasuryFeeAddress[fromToken] += treasuryBounty_.add(projectTreasuryBounty_);

        return newFromAmount_;
    }

    //==========================================================

    /*
    * @notice Upload a new collaborative project ID
    * @dev PROJECT_ADMINISTRATORS use
    * @param projectId       New project id
    * @param project         The percentage of fees charged by the project
    * @param projectTreasury The proportion of the fee charged by the treasury for the project
    */
    function uploadProjectParty(
        string calldata projectId,
        uint256 project,
        uint256 projectTreasury
    ) external onlyRole(PROJECT_ADMINISTRATORS) {
        projectFee[projectId] = project;
        projectTreasuryFee[projectId] = projectTreasury;
    }

    //==========================================================
    /*
    * @notice Modify the fee ratio
    * @dev PROJECT_ADMINISTRATORS use
    * @param projectId                  The id of the project that has been cooperated with
    * @param projectProportion          Proportion of fees charged by the project party
    * @param projectTreasuryProportion  Proportion of the fee charged by the treasury to the project party
    */
    function setProjectFee(
        string calldata projectId,
        uint256 projectProportion,
        uint256 projectTreasuryProportion
    ) external onlyRole(PROJECT_ADMINISTRATORS) {
        projectFee[projectId] = projectProportion;
        emit setProjectFeeRatio(block.timestamp, projectId, projectProportion);
        projectTreasuryFee[projectId] = projectTreasuryProportion;
        emit setProjectTreasuryFeeRatio(block.timestamp, projectId, projectTreasuryProportion);
    }

    /*
    * @notice Revised treasury fee
    * @dev PROJECT_ADMINISTRATORS use
    * @param proportion The percentage of the fee that the treasury must charge
    */
    function setTreasuryFee(
        uint256 proportion
    ) external onlyRole(PROJECT_ADMINISTRATORS) {
        treasuryFee = proportion;
        emit setTreasuryFeeRatio(block.timestamp, proportion);
    }

    /*
    * @notice Treasurer takes tokens
    * @dev FINANCIAL_ADMINISTRATOR use
    * @param token  Send token address
    * @param to     Payment address
    * @param amount Withdrawal amount
    */
    function withdrawMoney(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(FINANCIAL_ADMINISTRATOR) {
        if (amount > 0) {
            if (token == _ETH_ADDRESS_) {
                payable(to).transfer(amount);
            } else {
                IERC20(token).safeTransfer(to, amount);
            }
        }
    }
}
