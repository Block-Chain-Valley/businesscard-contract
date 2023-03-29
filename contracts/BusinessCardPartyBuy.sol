//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./BusinessCardBase.sol";

// Errors
error BusinessCardPartyBuy__NotStaked();
error BusinessCardPartyBuy__ExceededPeople();
error BusinessCardBase__InvalidArrayCount();

contract BusinessCardPartyBuy is BusinessCardBase {
    // State Variables
    uint256 internal immutable i_stakePrice;
    uint32 constant MAX_PEOPLE = 10;
    uint32 constant MAX_DECIMALS = 10 ^ 18;
    uint256 constant STAKE_TIME = 180 days;
    mapping(address => uint256) internal i_stakedTime;
    mapping(address => bool) internal i_successfullyStaked;

    constructor(uint256 _stakePrice) {
        i_stakePrice = _stakePrice;
    }

    // Events
    event Stake(address indexed staker, uint256 amount);
    event PartyMint(address indexed staker, uint32 employeeCount);

    // Functions
    modifier onlyStaked() {
        if (i_successfullyStaked[msg.sender] == false) {
            revert BusinessCardPartyBuy__NotStaked();
        }

        _;
    }

    function stake() public payable returns (bool success) {
        if (msg.value != i_stakePrice) {
            revert BusinessCardPartyBuy__NotStaked();
        }

        i_successfullyStaked[msg.sender] = true;

        emit Stake(msg.sender, msg.value);

        return true;
    }

    function partyMint(
        uint32 _employeeCount,
        string[] memory _name,
        string[] memory _email,
        string[] memory _phone,
        string memory _company,
        uint32[] memory _valueDesired
    ) external payable onlyStaked returns (bool success) {
        if (_employeeCount > MAX_PEOPLE) {
            revert BusinessCardPartyBuy__ExceededPeople();
        }
        if (msg.value != i_mintPrice * _employeeCount) {
            revert BusinessCardBase__InvalidETHAmountSent();
        }
        if (
            _name.length != _employeeCount ||
            _email.length != _employeeCount ||
            _phone.length != _employeeCount ||
            _valueDesired.length != _employeeCount
        ) {
            revert BusinessCardBase__InvalidArrayCount();
        }
        for (uint32 i = 0; i < _employeeCount; i++) {
            mintCard(_name[i], _email[i], _phone[i], _company, _valueDesired[i] * MAX_DECIMALS);
        }

        emit PartyMint(msg.sender, _employeeCount);

        return true;
    }
}
