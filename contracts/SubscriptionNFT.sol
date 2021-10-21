// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import {IProductHub} from './interfaces/IProductHub.sol';

import './Errors.sol';

interface ISubscriptionNFT {
    /// @notice Returns token id if user subscribed to a product or 0 otherwise.
    function findTokenId(string memory productId, address user) external returns (uint256);

    /// @notice Returns product id a token associated with.
    function findTokenProduct(uint256 tokenId) external returns (string memory);
}

contract SubscriptionNFT is ISubscriptionNFT, ERC721, ERC721Enumerable, Ownable, ERC721URIStorage {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 internal _nextTokenId;
    address public hub;

    mapping(uint256 => string) /// tokenId -> productId // TODO: fix high gas-consumption because of string id
        internal _tokenToProduct;
    mapping(address => mapping(string => uint256)) // user -> (productId -> tokenId)
        internal _userProductTokenIds;

    modifier onlyHub() {
        require(msg.sender == hub, Errors.NOT_HUB);
        _;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function findTokenId(string memory productId, address user) public view override returns (uint256) {
        return _userProductTokenIds[user][productId];
    }

    function findTokenProduct(uint256 tokenId) public view override returns (string memory) {
        return _tokenToProduct[tokenId];
    }

    constructor(address _hub) ERC721('SubscriptionNFT', 'SubNFT') {
        require(_hub != address(0), Errors.ZERO_ADDRESS);
        hub = _hub;
    }

    function mint(
        address user,
        string memory productId,
        string memory uri
    ) external onlyHub returns (uint256) {
        require(user != address(0), Errors.ZERO_ADDRESS);
        require(_userProductTokenIds[user][productId] == 0, 'ALREDY_SUBSCRIBED');

        uint256 tokenId = _nextTokenId++;
        _mint(user, tokenId);
        _setTokenURI(tokenId, uri);

        _tokenToProduct[tokenId] = productId;
        _userProductTokenIds[user][productId] = tokenId;

        return tokenId;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId); // takes care about multiple inheritance
    }

    function burn(uint256 tokenId) external onlyHub {
        _burn(tokenId);
        delete _tokenToProduct[tokenId];

        // TODO: pass susbcriber and productId from ProductHub to save gas
        address subscriber = ownerOf(tokenId);
        string memory productId = findTokenProduct(tokenId);
        delete _userProductTokenIds[subscriber][productId];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);

        // for prototype simplicity a user can't hold two subscriptions of the same product
        if (to != address(0)) {
            string memory productId = findTokenProduct(tokenId);
            require(findTokenId(productId, to) == 0, 'CANT_OWN_TWO_SUBSCRIPTIONS');
        }

        // update owner info on transfer
        if (from != address(0) && to != address(0)) {
            string memory productId = findTokenProduct(tokenId);
            delete _userProductTokenIds[from][productId];
            _userProductTokenIds[from][productId] = tokenId;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
