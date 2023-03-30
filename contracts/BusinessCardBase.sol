// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721EnumerableUpgradeable.sol";
import "./access/Ownable.sol";
import "./security/ReentrancyGuard.sol";
import "./library/SafeToken.sol";
import "./IBCCoin.sol";

// Errors
error BusinessCardBase__NotFirstMint();
error BusinessCardBase__InvalidString();
error BusinessCardBase__InvalidETHAmountSent();
error BusinessCardBase__NotMintable();
error BusinessCardBase__NotStaked();
error BusinessCardBase__ExceededPeople();
error BusinessCardBase__InvalidArrayCount();
error BusinessCardBase__StakeNotExpired();
error BusinessCardBase__WithdrawFailed();

contract BusinessCardBase is ERC721EnumerableUpgradeable, ReentrancyGuard {
    enum CardType {
        Personal,
        Business
    }
    // State Variables
    Card[] private cards;
    uint32 internal constant MAX_CARDS = 1000;
    uint32 internal constant MAX_FIRST_MINT = 10;
    uint32 constant MAX_EMPLOYEES = 10;
    uint256 constant MAX_DECIMALS = 10 ** 18;
    uint256 internal stakePrice;
    uint256 internal firstMintPrice;
    uint256 internal mintPrice;
    uint256 constant STAKE_TIME = 180 days;
    IBCCoin internal bcCoin;
    uint256 constant BC_COIN_PER_MINT = 10;

    // Mappings
    mapping(address => bool) internal firstMinted;
    mapping(address => mapping(address => uint256)) internal mintableCountOf;
    mapping(address => uint256) internal stakedTime;
    mapping(address => bool) internal successfullyStaked;
    mapping(address => string) internal companyNameOf;

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
        CardType cardType,
        uint256 valueDesired,
        address owner
    );
    event CardTransfer(uint256 indexed id, address indexed from, address indexed to);
    event Stake(address indexed staker, uint256 amount, string companyName);
    event PartyMint(address indexed company, address[] employeeAddresses, uint32 employeeCount);
    event bcCoinMinted(address indexed to, uint256 amount);
    event CompanyBCProceedsRedeemed(address indexed company, uint256 amount);

    // Functions
    modifier onlyStaked() {
        if (successfullyStaked[msg.sender] == false) {
            revert BusinessCardBase__NotStaked();
        }

        _;
    }

    function __BusinessCardBase__init(
        uint256 _firstMintPrice,
        uint256 _mintPrice,
        uint256 _stakePrice,
        address bcCoinAddress
    ) external {
        // __ERC721_init("BusinessCardBase", "BC");
        firstMintPrice = _firstMintPrice;
        mintPrice = _mintPrice;
        stakePrice = _stakePrice;
        bcCoin = IBCCoin(bcCoinAddress);
    }

    function BCMint() public payable returns (bool success) {
        uint mintableAmount;
        uint bcAmount;
        if (firstMinted[msg.sender]) {
            if (msg.value != mintPrice) {
                revert BusinessCardBase__InvalidETHAmountSent();
            }
            mintableAmount = 1;
            bcAmount = BC_COIN_PER_MINT;
        } else {
            if (msg.value != firstMintPrice) {
                revert BusinessCardBase__InvalidETHAmountSent();
            }
            firstMinted[msg.sender] = true;

            mintableAmount = MAX_FIRST_MINT;
            bcAmount = BC_COIN_PER_MINT * 10;
        }
        mintableCountOf[msg.sender][msg.sender] += MAX_FIRST_MINT;
        bcCoinFactory(msg.sender, bcAmount);
        emit bcCoinMinted(msg.sender, bcAmount);

        // ADD REFUND LOGIC WHEN MORE THAN ENOUGH ETH IS SENT

        return true;
    }

    function _BCmint(
        string memory _name,
        string memory _email,
        string memory _phone,
        address _company,
        uint256 valueDesired
    ) public virtual {
        if (mintableCountOf[msg.sender][_company] <= 0 && mintableCountOf[msg.sender][msg.sender] <= 0) {
            revert BusinessCardBase__NotMintable();
        }
        if (
            bytes(_name).length * bytes(_email).length * bytes(_phone).length * valueDesired == 0 || _company == address(0)
        ) {
            revert BusinessCardBase__InvalidString();
        }

        CardType cardType;
        string memory company = companyNameOf[_company];
        if (bytes(company).length == 0 || (msg.sender == _company)) {
            cardType = CardType.Personal;
        } else {
            cardType = CardType.Business;
        }

        Card memory card = Card({
            name: _name,
            email: _email,
            phone: _phone,
            company: bytes(company).length == 0 ? "N/A" : company,
            cardType: cardType,
            valueDesired: valueDesired,
            owner: msg.sender
        });

        cards.push(card);
        uint256 _id = cards.length - 1;
        mintableCountOf[msg.sender][msg.sender] -= 1;
        _safeMint(msg.sender, _id);
        if (cardType == CardType.Business) approve(_company, _id);
        emit CardCreated(_id, _name, _email, _phone, company, cardType, valueDesired, msg.sender);
    }

    function stake(string memory _company) public payable returns (bool success) {
        if (msg.value != stakePrice) {
            revert BusinessCardBase__InvalidETHAmountSent();
        }

        successfullyStaked[msg.sender] = true;
        companyNameOf[msg.sender] = _company;
        stakedTime[msg.sender] = block.timestamp;
        emit Stake(msg.sender, msg.value, _company);

        return true;
    }

    function withdraw() external onlyStaked nonReentrant {
        if (block.timestamp - stakedTime[msg.sender] < STAKE_TIME) {
            revert BusinessCardBase__StakeNotExpired();
        }
        (bool success, ) = payable(msg.sender).call{value: stakePrice}("");
        successfullyStaked[msg.sender] = false;
        companyNameOf[msg.sender] = "";
        stakedTime[msg.sender] = 0;
        if (!success) {
            revert BusinessCardBase__WithdrawFailed();
        }
    }

    function partyBCMint(
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
            mintableCountOf[employeeAddresses[i]][companyAddress] += 1;
        }

        emit PartyMint(msg.sender, employeeAddresses, uint32(_employeeCount));

        return true;
    }

    function redeemCompanyBCProceeds() external onlyStaked {
        uint256 timeSinceStake = block.timestamp - stakedTime[msg.sender];
        uint256 proceeds = timeSinceStake / 86400;
        if (proceeds > 0) {
            bcCoinFactory(msg.sender, proceeds);
            stakedTime[msg.sender] += proceeds * 86400;
        }
        emit CompanyBCProceedsRedeemed(msg.sender, proceeds);
    }

    function bcCoinFactory(address _to, uint256 _amount) private {
        bcCoin.mint(_to, _amount);
        emit bcCoinMinted(_to, _amount);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal virtual override {
        super._transfer(_from, _to, _tokenId);
        emit CardTransfer(_tokenId, _from, _to);
    }

    function getFirstMintPrice() external view returns (uint256) {
        return firstMintPrice;
    }

    function getFirstMinted(address minter) external view returns (bool) {
        return firstMinted[minter];
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
        return companyNameOf[companyAddress];
    }

    function getMintableAuthorities(address _owner, address _company) external view returns (uint256) {
        return mintableCountOf[_owner][_company];
    }
}
// modifier 1번 사용시 굳이 함수로 빼지 않아도 될 것 같습니다.
// mintable count of (mapping name convention)
// erc20 logic

// permit
// erc20 -> marketplace
// marketplace auction

// BC코인 -> mintable++
