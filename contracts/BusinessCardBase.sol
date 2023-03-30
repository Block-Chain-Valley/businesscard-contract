// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721EnumerableUpgradeable.sol";
import "./access/Ownable.sol";

// Errors
error BusinessCardBase__NotFirstMint();
error BusinessCardBase__InvalidString();
error BusinessCardBase__InvalidETHAmountSent();
error BusinessCardBase__NotMintable();
error BusinessCardBase__NotStaked();
error BusinessCardBase__ExceededPeople();
error BusinessCardBase__InvalidArrayCount();

contract BusinessCardBase is ERC721EnumerableUpgradeable {
    enum CardType {
        Personal,
        Business
    }
    // State Variables
    Card[] private cards;
    uint32 internal constant MAX_CARDS = 1000;
    uint32 internal constant MAX_FIRST_MINT = 10;
    uint32 constant MAX_EMPLOYEES = 10;
    uint32 constant MAX_DECIMALS = 10 ^ 18;
    uint256 internal stakePrice;
    uint256 internal firstMintPrice;
    uint256 internal mintPrice;
    uint256 constant STAKE_TIME = 180 days;

    // Mappings
    mapping(address => bool) internal firstMinted;
    mapping(address => mapping(address => uint256)) internal addressToDivisionToMintable;
    mapping(address => uint256) internal stakedTime;
    mapping(address => bool) internal successfullyStaked;
    mapping(address => string) internal addressToCompanyName;

    struct Card {
        string name;
        string email;
        string phone;
        string company;
        CardType cardType;
        uint256 valueDesired;
        address owner;
    }

    // Events
    event CardCreated(
        uint256 indexed id,
        string name,
        string email,
        string phone,
        string company,
        uint256 valueDesired,
        address owner
    );
    event CardTransfer(uint256 indexed id, address indexed from, address indexed to);
    event Stake(address indexed staker, uint256 amount, string companyName);
    event PartyMint(address indexed company, address[] employeeAddresses, uint32 employeeCount);

    // Functions
    modifier isMintable() {
        if (addressToDivisionToMintable[msg.sender][msg.sender] <= 0) {
            revert BusinessCardBase__NotMintable();
        }
        _;
    }

    modifier onlyStaked() {
        if (successfullyStaked[msg.sender] == false) {
            revert BusinessCardBase__NotStaked();
        }

        _;
    }

    function __BusinessCardBase__init(uint256 _firstMintPrice, uint256 _mintPrice, uint256 _stakePrice) internal {
        __ERC721_init("BusinessCardBase", "BC");
        firstMintPrice = _firstMintPrice;
        mintPrice = _mintPrice;
        stakePrice = _stakePrice;
    }

    function mint() public payable returns (bool success) {
        if (firstMinted[msg.sender]) {
            if (msg.value != mintPrice) {
                revert BusinessCardBase__InvalidETHAmountSent();
            }
            addressToDivisionToMintable[msg.sender][msg.sender] += 1;
        } else {
            if (msg.value != firstMintPrice) {
                revert BusinessCardBase__InvalidETHAmountSent();
            }
            firstMinted[msg.sender] = true;
            addressToDivisionToMintable[msg.sender][msg.sender] = MAX_FIRST_MINT;
        }

        return true;
    }

    function _mint(
        string memory _name,
        string memory _email,
        string memory _phone,
        address _company,
        uint256 valueDesired
    ) public virtual isMintable {
        if (
            bytes(_name).length * bytes(_email).length * bytes(_phone).length * valueDesired == 0 || _company == address(0)
        ) {
            revert BusinessCardBase__InvalidString();
        }
        string memory companyName = addressToCompanyName[_company];
        Card memory card = Card({
            name: _name,
            email: _email,
            phone: _phone,
            company: companyName,
            cardType: CardType.Personal,
            valueDesired: valueDesired,
            owner: msg.sender
        });

        cards.push(card);
        uint256 _id = cards.length - 1;
        addressToDivisionToMintable[msg.sender][msg.sender] -= 1;
        _safeMint(msg.sender, _id);
        emit CardCreated(_id, _name, _email, _phone, companyName, valueDesired, msg.sender);
    }

    function stake(string memory _company) public payable returns (bool success) {
        if (msg.value != stakePrice) {
            revert BusinessCardBase__NotStaked();
        }

        successfullyStaked[msg.sender] = true;
        addressToCompanyName[msg.sender] = _company;

        emit Stake(msg.sender, msg.value, _company);

        return true;
    }

    function partyMint(
        uint256 _employeeCount,
        address[] memory employeeAddresses
    ) external payable onlyStaked returns (bool success) {
        if (_employeeCount > MAX_EMPLOYEES) {
            revert BusinessCardBase__ExceededPeople();
        }
        if (msg.value != mintPrice * _employeeCount) {
            revert BusinessCardBase__InvalidETHAmountSent();
        }
        if (_employeeCount != employeeAddresses.length) {
            revert BusinessCardBase__InvalidArrayCount();
        }

        address companyAddress = msg.sender;
        for (uint256 i = 0; i < _employeeCount; i++) {
            addressToDivisionToMintable[employeeAddresses[i]][companyAddress] += 1;
        }

        emit PartyMint(msg.sender, employeeAddresses, uint32(_employeeCount));

        return true;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal virtual override {
        super._transfer(_from, _to, _tokenId);
        emit CardTransfer(_tokenId, _from, _to);
    }

    function getFirstMintPrice() external view returns (uint256) {
        return firstMintPrice;
    }

    function getMintPrice() external view returns (uint256) {
        return mintPrice;
    }

    function getCards() external view returns (Card[] memory) {
        return cards;
    }

    function getCard(uint256 _id) external view returns (Card memory) {
        return cards[_id];
    }

    function getCardCount() external view returns (uint256) {
        return cards.length;
    }

    function getCardCountByOwner(address _owner) external view returns (uint256) {
        return balanceOf(_owner);
    }

    function getCardByOwner(address _owner, uint256 _index) external view returns (Card memory) {
        return cards[tokenOfOwnerByIndex(_owner, _index)];
    }

    function getCompanyName(address companyAddress) external view returns (string memory) {
        return addressToCompanyName[companyAddress];
    }
}

// enumeratorupgradeable
// mint > 0?
// internal i 제거
// mintable
// event -> address
// mintCard -> mint
// 권한 함수 분리
// Mint, transfer => convention
// uint32 == uint256 when single
// company명은 스테이킹 때 기입

// permit

// opcode x and +
// keccak when comparing strings
