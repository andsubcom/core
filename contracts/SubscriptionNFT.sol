// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import {IProductHub} from './interfaces/IProductHub.sol';

import './Errors.sol';

contract SubscriptionNFT is ERC721, ERC721Enumerable, Ownable, ERC721URIStorage {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 internal _nextTokenId;
    address public hub;

    modifier onlyHub() {
        require(msg.sender == hub, Errors.NOT_HUB);
        _;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    constructor(address _hub) ERC721('SubscriptionNFT', 'SubNFT') {
        require(_hub != address(0), Errors.ZERO_ADDRESS);
        hub = _hub;
    }

    function mint(address user, string memory uri) external onlyHub returns (uint256) {
        require(user != address(0), Errors.ZERO_ADDRESS);
        uint256 tokenId = _nextTokenId++;
        _mint(user, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId); // takes care about multiple inheritance
    }

    function burn(uint256 tokenId) external onlyHub {
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);

        // for prototype simplicity a user can't hold two subscriptions of the same product
        if (to != address(0)) {
            string memory productId = IProductHub(hub).findTokenProductId(tokenId);
            require(IProductHub(hub).findTokenId(to, productId) == 0, 'CANT_OWN_TWO_SUBSCRIPTIONS');
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
