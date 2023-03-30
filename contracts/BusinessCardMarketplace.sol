// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";

// Errors
error BusinessCardMarketplace__OnlyOwner();
error BusinessCardMarketplace__AlreadyListed();
error BusinessCardMarketplace__NotListed();
error BusinessCardMarketplace__InvalidPrice();
error BusinessCardMarketplace__NotApproved();
error BusinessCardMarketplace__ApproveNotCleared();

contract BusinessCardMarketplace {
    // State Variables
    struct Listing {
        uint256 listId;
        uint256 price;
        address seller;
    }

    // Mappings
    mapping(address => mapping(uint256 => Listing)) internal listings;

    // Events
    event ListingListed(uint256 indexed cardId, uint256 price, address indexed seller);
    event ListingRemoved(uint256 indexed cardId, address indexed seller);
    event ListingBought(uint256 indexed cardId, address indexed buyer, address indexed seller, uint256 price);

    // Functions
    modifier onlyOwner(address _nftAddress, uint256 _cardId) {
        if (IERC721(_nftAddress).ownerOf(_cardId) != msg.sender) {
            revert BusinessCardMarketplace__OnlyOwner();
        }
        _;
    }

    modifier notListed(address _nftAddress, uint256 _cardId) {
        if (listings[_nftAddress][_cardId].seller != address(0) || listings[_nftAddress][_cardId].price != 0) {
            revert BusinessCardMarketplace__AlreadyListed();
        }
        _;
    }

    modifier Listed(address _nftAddress, uint256 _cardId) {
        if (listings[_nftAddress][_cardId].seller == address(0) || listings[_nftAddress][_cardId].price == 0) {
            revert BusinessCardMarketplace__NotListed();
        }
        _;
    }

    function createListing(
        address _nftAddress,
        uint256 _price,
        uint256 _cardId
    ) external onlyOwner(_nftAddress, _cardId) notListed(_nftAddress, _cardId) {
        if (_price <= 0) {
            revert BusinessCardMarketplace__InvalidPrice();
        }
        IERC721(_nftAddress).approve(address(this), _cardId);
        if (IERC721(_nftAddress).getApproved(_cardId) != address(this)) {
            revert BusinessCardMarketplace__NotApproved();
        }

        Listing memory listing = Listing(_cardId, _price, msg.sender);
        listings[msg.sender][_cardId] = listing;
        emit ListingListed(_cardId, _price, msg.sender);
    }

    function removeListing(
        address _nftAddress,
        uint256 _cardId
    ) external onlyOwner(_nftAddress, _cardId) Listed(_nftAddress, _cardId) {
        IERC721(_nftAddress).approve(address(0), _cardId);
        if (IERC721(_nftAddress).getApproved(_cardId) != address(0)) {
            revert BusinessCardMarketplace__ApproveNotCleared();
        }

        delete listings[msg.sender][_cardId];
        emit ListingRemoved(_cardId, msg.sender);
    }

    function buyCard(address _nftAddress, uint256 _cardId) external payable Listed(_nftAddress, _cardId) {
        Listing memory listing = listings[_nftAddress][_cardId];
        if (msg.value < listing.price) {
            revert BusinessCardMarketplace__InvalidPrice();
        }
        payable(listing.seller).transfer(msg.value);
        IERC721(_nftAddress).safeTransferFrom(listing.seller, msg.sender, _cardId);
        delete listings[_nftAddress][_cardId];
        emit ListingBought(_cardId, msg.sender, listing.seller, listing.price);
    }

    function updateListing(
        address _nftAddress,
        uint256 _cardId,
        uint256 _price
    ) external onlyOwner(_nftAddress, _cardId) Listed(_nftAddress, _cardId) {
        if (_price <= 0) {
            revert BusinessCardMarketplace__InvalidPrice();
        }
        listings[_nftAddress][_cardId].price = _price;
        emit ListingListed(_cardId, _price, msg.sender);
    }
}
