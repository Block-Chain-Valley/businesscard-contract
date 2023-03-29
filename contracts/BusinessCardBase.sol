// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721EnumerableUpgradeable.sol";
import "./access/Ownable.sol";

// Errors
error BusinessCardBase__NotFirstMint();
error BusinessCardBase__InvalidString();
error BusinessCardBase__InvalidETHAmountSent();

contract BusinessCardBase is ERC721EnumerableUpgradeable {
    enum CardType {
        Personal,
        Business
    }
    // State Variables
    Card[] private cards;
    uint32 internal constant MAX_CARDS = 1000;
    uint32 internal constant MAX_FIRST_MINT = 10;
    uint256 internal firstMintPrice;
    uint256 internal mintPrice;

    // Mappings
    mapping(address => bool) internal firstMinted;
    mapping(address => uint256) internal addressToCardCount;
    mapping(uint256 => address) internal cardToAddress;
    mapping(address => uint256) internal addressToMintableAmount;

    struct Card {
        string name;
        string email;
        string phone;
        string company;
        CardType cardType;
        uint256 valueDesired;
    }

    // Events
    event CardCreated(uint256 indexed id, string name, string email, string phone, string company, uint256 valueDesired);
    event CardTransfer(uint256 indexed id, address indexed from, address indexed to);

    // Functions

    function __BusinessCardBase__init(uint256 _firstMintPrice, uint256 _mintPrice) internal {
        __ERC721_init("BusinessCardBase", "BC");
        firstMintPrice = _firstMintPrice;
        mintPrice = _mintPrice;
    }

    function mint(
        string memory _name,
        string memory _email,
        string memory _phone,
        string memory _company,
        uint256 valueDesired
    ) public payable returns (bool success) {
        if (
            bytes(_name).length == 0 || bytes(_email).length == 0 || bytes(_phone).length == 0 || bytes(_company).length == 0 || 
        ) {
            revert BusinessCardBase__InvalidString();
        }

        uint256 _id;

        if (firstMinted[msg.sender]) {
            if (msg.value != mintPrice) {
                revert BusinessCardBase__InvalidETHAmountSent();
            }

            // _id = cards.length;
            // cards.push(Card(_name, _email, _phone, _company, CardType.Personal, valueDesired));
            // _safeMint(msg.sender, _id);
            // cardToAddress[_id] = msg.sender;
            // addressToCardCount[msg.sender]++;
            // emit CardCreated(_id, _name, _email, _phone, _company, valueDesired);
            addressToMintableAmount[msg.sender] += 1;
        } else {
            if (msg.value != firstMintPrice) {
                revert BusinessCardBase__InvalidETHAmountSent();
            }
            firstMinted[msg.sender] = true;

            // for (uint256 i = 0; i < MAX_FIRST_MINT; i++) {
            //     _id = cards.length;
            //     cards.push(Card(_name, _email, _phone, _company, CardType.Personal, valueDesired));
            //     _safeMint(msg.sender, _id);
            //     icardToAddress[_id] = msg.sender;
            //     iaddressToCardCount[msg.sender]++;
            //     emit CardCreated(_id, _name, _email, _phone, _company, valueDesired);
            // }
            addressToMintableAmount[msg.sender] = 10;
        }

        return true;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal virtual override {
        super._transfer(_from, _to, _tokenId);
        emit CardTransfer(_tokenId, _from, _to);
    }

    function getFirstMintPrice() public view returns (uint256) {
        return firstMintPrice;
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function getCards() public view returns (Card[] memory) {
        return cards;
    }

    function getCard(uint256 _id) public view returns (Card memory) {
        return cards[_id];
    }

    function getCardCount() public view returns (uint256) {
        return cards.length;
    }

    function getCardCountByOwner(address _owner) public view returns (uint256) {
        return balanceOf(_owner);
    }

    function getCardByOwner(address _owner, uint256 _index) public view returns (Card memory) {
        return cards[tokenOfOwnerByIndex(_owner, _index)];
    }
}

// enumeratorupgradeable
// mint > 0?
// internal i 제거
// mintable

// 권한 함수 분리
// company명은 스테이킹 때 기입
// event -> address
// mintCard -> mint
// opcode x and +
// keccak when comparing strings
// uint32 == uint256 when single
// Mint, transfer => convention
// permit
