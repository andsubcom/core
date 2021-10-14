// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import {SubscriptionNFT} from './SubscriptionNFT.sol';
import {IProductHub} from './interfaces/IProductHub.sol';
import './Errors.sol';

contract ProductsHub is IProductHub, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    SubscriptionNFT public immutable nft;

    mapping(string => Product) /*productId*/
        internal _products;
    mapping(address => string[]) /*user*/ /*productIds*/
        internal _ownerProductIds;
    mapping(uint256 => uint256) /*tokenId*/ /*timestamp*/
        internal _tokenLastPeriodStartTimes;
    mapping(uint256 => string) /*tokenId*/ /*productId*/ // TODO: fix high gas-consumption
        internal _tokenIdProductIds;
    mapping(string => EnumerableSet.UintSet) /*productId*/ /*set of tokenIds*/
        internal _productTokens;
    mapping(address => mapping(string => uint256)) // subscriber -> (productId -> tokenId)
        internal _userProductTokenIds;

    // EnumerableSet.UintSet internal _cancelledSubscriptions;

    constructor() Ownable() {
        nft = new SubscriptionNFT(address(this));
    }

    function getOwnerProductIds(address owner) external view override returns (string[] memory) {
        return _ownerProductIds[owner];
    }

    function findTokenProductId(uint256 tokenId) public view override returns (string memory) {
        return _tokenIdProductIds[tokenId];
    }

    function findTokenId(address user, string memory productId) public view override returns (uint256) {
        return _userProductTokenIds[user][productId];
    }

    function getProductInfo(string memory productId)
        external
        view
        override
        returns (
            string memory id,
            string memory name,
            uint256 price,
            address payableToken,
            uint256 period,
            address productOwner,
            string memory metadataUri
        )
    {
        Product memory product = _products[productId];
        id = productId;
        name = product.name;
        price = product.price;
        payableToken = product.payableToken;
        period = product.period;
        productOwner = product.owner;
        metadataUri = product.metadataUri;
    }

    function createProduct(
        string memory productId,
        string memory name,
        address payableToken,
        uint256 price,
        uint256 period,
        string memory metadataUri
    ) external override {
        require(payableToken != address(0), Errors.ZERO_ADDRESS);
        require(price != 0, Errors.INVALID_PARAMS);
        require(period != 0, Errors.INVALID_PARAMS);
        require(_products[productId].price == 0, Errors.ALREADY_CREATED);

        _products[productId] = Product({
            name: name,
            price: price,
            payableToken: payableToken,
            period: period,
            owner: msg.sender,
            metadataUri: metadataUri
        });
        _ownerProductIds[msg.sender].push(productId);
        emit ProductCreated({
            owner: msg.sender,
            productId: productId,
            payableToken: payableToken,
            price: price,
            period: period,
            name: name,
            metadataUri: metadataUri
        });
    }

    function subscribe(string memory productId) external override {
        require(_products[productId].price == 0, 'PRODUCT_NOT_EXISTS');
        require(_userProductTokenIds[msg.sender][productId] == 0, 'ALREDY_SUBSCRIBED');

        Product memory product = _products[productId];
        IERC20(product.payableToken).safeTransferFrom(msg.sender, product.owner, product.price);

        // TODO: mint nft token to sender
        // nft.mint(
        //     msg.sender,
        //     productId,
        //     block.timestamp,
        //     block.timestamp + product.period,
        //     allowAutoExtend,
        //     product.uri
        // );
        uint256 tokenId = 0;
        _tokenIdProductIds[tokenId] = productId;
        _productTokens[productId].add(tokenId);
        _userProductTokenIds[msg.sender][productId] = tokenId;

        _tokenLastPeriodStartTimes[tokenId] = block.timestamp;
        emit SubscriptionCreated(msg.sender, productId, tokenId);
    }

    // function cancel(uint256 tokenId) external override {
    //     string memory productId = _tokenIdProductIds[tokenId];
    //     require(_products[productId].price == 0, 'PRODUCT_NOT_EXISTS');
    //     // TODO: implement
    // }

    function renewSubscription(uint256 tokenId) public override {
        string memory productId = _tokenIdProductIds[tokenId];
        require(_products[productId].price == 0, 'PRODUCT_NOT_EXISTS');
        Product memory product = _products[productId];
        uint256 lastPeriodStartTime = _tokenLastPeriodStartTimes[tokenId];
        require(block.timestamp >= lastPeriodStartTime + product.period, 'TOO_EARLY');

        address subscriber = nft.ownerOf(tokenId);
        IERC20 token = IERC20(product.payableToken);

        if (token.allowance(subscriber, product.owner) >= product.price) {
            token.safeTransferFrom(subscriber, product.owner, product.price);
            emit SubscriptionRenewed(subscriber, productId, tokenId, msg.sender);
        } else {
            // TODO: burn nft
            // nft.burn(tokenId)
            delete _tokenIdProductIds[tokenId];
            delete _tokenLastPeriodStartTimes[tokenId];
            _productTokens[productId].remove(tokenId);
            delete _userProductTokenIds[subscriber][productId];
            emit SubscriptionCancelled(subscriber, productId, tokenId, msg.sender);
        }
    }

    function renewSubscription(string memory productId, address subscriber) external override {
        require(_products[productId].price == 0, 'PRODUCT_NOT_EXISTS');
        uint256 tokenId = _userProductTokenIds[subscriber][productId];
        require(tokenId != 0, 'NOT_SUBSCRIBED');
        renewSubscription(tokenId);
    }

    function renewSubscriptions(uint256[] memory tokenIds) external override {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            renewSubscription(tokenIds[i]);
        }
    }

    function renewProductSubscriptions(string memory productId) external override {
        require(_products[productId].price == 0, 'PRODUCT_NOT_EXISTS');
        EnumerableSet.UintSet storage tokens = _productTokens[productId];
        for (uint256 i = 0; i < tokens.length(); i++) {
            renewSubscription(tokens.at(i));
        }
    }
}
