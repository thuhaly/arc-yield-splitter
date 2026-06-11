// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract YieldSplitter {
    IERC20 public immutable usdc;
    address public owner;
    address[] public beneficiaries;
    uint256[] public shares; // basis points (total must = 10000)
    uint256 public totalDistributed;

    event Distributed(uint256 amount, uint256 timestamp);
    event BeneficiariesUpdated(uint256 count);

    constructor(address _usdc) {
        require(_usdc != address(0), "BAD_USDC");
        usdc = IERC20(_usdc);
        owner = msg.sender;
    }

    modifier onlyOwner() { require(msg.sender == owner, "NOT_OWNER"); _; }

    function setBeneficiaries(address[] calldata _bens, uint256[] calldata _shares) external onlyOwner {
        require(_bens.length == _shares.length && _bens.length > 0, "BAD_INPUT");
        uint256 total;
        for (uint256 i; i < _shares.length; i++) total += _shares[i];
        require(total == 10000, "SHARES_NOT_10000");
        beneficiaries = _bens;
        shares = _shares;
        emit BeneficiariesUpdated(_bens.length);
    }

    function distribute() external {
        uint256 bal = usdc.balanceOf(address(this));
        require(bal > 0 && beneficiaries.length > 0, "NOTHING");
        for (uint256 i; i < beneficiaries.length; i++) {
            uint256 amt = (bal * shares[i]) / 10000;
            if (amt > 0) require(usdc.transfer(beneficiaries[i], amt), "TRANSFER_FAILED");
        }
        totalDistributed += bal;
        emit Distributed(bal, block.timestamp);
    }
}
