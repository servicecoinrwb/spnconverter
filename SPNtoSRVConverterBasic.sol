/**
 *Submitted for verification at Arbiscan.io on 2025-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract SPNtoSRVConverterBasic {
    address public dao;
    IERC20 public immutable spn;
    IERC20 public immutable srv;

    uint256 public conversionRate; // e.g. 0.5268 * 1e18 = 526800000000000000

    event Converted(address indexed user, uint256 spnBurned, uint256 srvReceived);
    event ConversionRateUpdated(uint256 newRate);

    modifier onlyDAO() {
        require(msg.sender == dao, "Not authorized");
        _;
    }

    constructor(address _spn, address _srv, address _dao, uint256 _rate) {
        spn = IERC20(_spn);
        srv = IERC20(_srv);
        dao = _dao;
        conversionRate = _rate;
    }

    function updateConversionRate(uint256 newRate) external onlyDAO {
        conversionRate = newRate;
        emit ConversionRateUpdated(newRate);
    }

    function burnAndConvert(uint256 spnAmount) external {
        require(spnAmount > 0, "Amount must be > 0");
        require(spn.allowance(msg.sender, address(this)) >= spnAmount, "Approve SPN first");

        // Pull and burn SPN from user
        require(spn.transferFrom(msg.sender, address(this), spnAmount), "SPN transfer failed");
        spn.burn(spnAmount);

        uint256 srvAmount = (spnAmount * conversionRate) / 1e18;
        require(srv.balanceOf(address(this)) >= srvAmount, "Insufficient SRV in converter");

        require(srv.transfer(msg.sender, srvAmount), "SRV transfer failed");
        emit Converted(msg.sender, spnAmount, srvAmount);
    }

    function withdrawSRV(address to, uint256 amount) external onlyDAO {
        require(srv.transfer(to, amount), "Withdraw failed");
    }

    function setDAO(address newDao) external onlyDAO {
        dao = newDao;
    }
}