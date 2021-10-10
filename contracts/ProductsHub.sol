// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {SubscriptionNFT} from './SubscriptionNFT.sol';
import "./Errors.sol";


contract ProductsHub is Ownable {
    using SafeERC20 for IERC20;

    SubscriptionNFT immutable public nft;
    IUniswapV2Router02 immutable public router;

    event ProductCreated(
        address indexed owner,
        string indexed productId,
        address indexed payableToken,
        uint256 amount,
        uint256 period,
        string name,
        string uri
    );

    struct Product {
        string name;
        uint256 amount;
        address payableToken;
        uint256 period;
        address owner;
        string uri;
    }

    mapping (string /*productId*/ => Product) internal _products;
    mapping (address /*user*/ => string[] /*productIds*/) internal _ownerProductIds;

    constructor() Ownable() {
        nft = new SubscriptionNFT(address(this));
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function getOwnerProductIds(address owner) external view returns(string[] memory) {
        return _ownerProductIds[owner];
    }

    function createProduct(string memory productId, string memory name, address payableToken, uint256 amount, uint256 period, string memory uri) external {
        require(payableToken != address(0), Errors.ZERO_ADDRESS);
        require(amount != 0, Errors.INVALID_PARAMS);
        require(period != 0, Errors.INVALID_PARAMS);
        require(_products[productId].amount == 0, Errors.ALREADY_CREATED);

        _products[productId] = Product({
            name: name,
            amount: amount,
            payableToken: payableToken,
            period: period,
            owner: msg.sender,
            uri: uri
        });
        _ownerProductIds[msg.sender].push(productId);
        emit ProductCreated({
            owner: msg.sender,
            productId: productId,
            payableToken: payableToken,
            amount: amount,
            period: period,
            name: name,
            uri: uri
        });
    }
    
    function subscribe(string memory productId, bool allowAutoExtend) external {
        Product memory product = _products[productId];
        IERC20(product.payableToken).safeTransferFrom(msg.sender, product.owner, product.amount);
        nft.mint(msg.sender, productId, block.timestamp, block.timestamp+product.period, allowAutoExtend, product.uri);
    }

    function subscribeByAnyToken(
        string memory productId,
        bool allowAutoExtend,
        address token,
        uint256 amountInMax,
        uint256 deadline
    ) external {
        Product memory product = _products[productId];
        _swapTo(token, product.payableToken, product.amount, deadline, msg.sender, product.owner, amountInMax);
        nft.mint(msg.sender, productId, block.timestamp, block.timestamp+product.period, allowAutoExtend, product.uri);
    }

    /**
     * @dev Extend any existant product.
     * @dev May be called by the owner or by the token holder.
     * @dev Owner can extend product not early than 1 days before the endTimestamp.
     */
    function extendSubscription(uint256 tokenId) external {
        (string memory productId, /*startTimestamp*/, uint256 endTimestamp, bool allowAutoExtend, /*uri*/) = nft.getTokenInfo(tokenId);
        address holder = nft.ownerOf(tokenId);
        if (holder != msg.sender) {
            require(msg.sender == owner(), Errors.NOT_OWNER);
            require(allowAutoExtend, Errors.OWNER_DISALLOW_AUTO_EXTEND);
            require(block.timestamp >= endTimestamp - 1 days, Errors.AUTO_BY_ADMIN_EXTEND_TOO_EARLY);
        }
        
        Product memory product = _products[productId];
        IERC20(product.payableToken).safeTransferFrom(holder, product.owner, product.amount);
        uint256 newEndTimestamp = block.timestamp + product.period;
        if (newEndTimestamp < endTimestamp + product.period) {  // take max
            newEndTimestamp = endTimestamp + product.period;
        }
        nft.extend(tokenId, newEndTimestamp);   
    }

    function withdraw(string memory productId) external {
        Product memory product = _products[productId];
        require(product.owner != address(0), Errors.NOT_EXISTS);
//        uint256 amount;
//        address payableToken;
//        uint256 period;
//        address owner;
    }

    function _swapTo(address fromToken, address toToken, uint256 amount, uint256 deadline, address from, address to, uint256 amountInMax) internal {
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;
        uint256[] memory swapAmounts = router.getAmountsIn(amount, path);
        uint256 swapAmount = swapAmounts[0];
        IERC20(fromToken).safeTransferFrom(from, address(this), swapAmount);
        IERC20(fromToken).approve(address(router), swapAmount);
        uint256[] memory amounts = router.swapTokensForExactTokens(
          amount,
          amountInMax,
          path,
          to,
          deadline
        );
        require(amounts[0] == swapAmount, Errors.DEX_FAIL);
    }

    function extendSubscriptionByAnyToken(
        uint256 tokenId,
        address token,
        uint256 amountInMax,
        uint256 deadline
    ) external {
        (string memory productId, /*startTimestamp*/, uint256 endTimestamp, bool allowAutoExtend, /*uri*/) = nft.getTokenInfo(tokenId);
        address holder = nft.ownerOf(tokenId);
        if (holder != msg.sender) {
            require(msg.sender == owner(), Errors.NOT_OWNER);
            require(allowAutoExtend, Errors.OWNER_DISALLOW_AUTO_EXTEND);
            require(block.timestamp >= endTimestamp - 1 days, Errors.AUTO_BY_ADMIN_EXTEND_TOO_EARLY);
        }

        Product memory product = _products[productId];
        _swapTo(token, product.payableToken, product.amount, deadline, holder, product.owner, amountInMax);

        uint256 newEndTimestamp = block.timestamp + product.period;
        if (newEndTimestamp < endTimestamp + product.period) {  // take max
            newEndTimestamp = endTimestamp + product.period;
        }
        nft.extend(tokenId, newEndTimestamp);
    }


    function checkUserHasActiveSubscription(address user, string memory productId) external view returns(bool) {
        return nft.checkUserHasActiveSubscription(user, productId);
    }
    
    function getProductInfo(string memory productId) view external returns(
        string memory id,
        string memory name,
        uint256 amount,
        address payableToken,
        uint256 period,
        address owner__,  // dirty naming hack to not misused Ownable attributes
        string memory uri
    ) {
        Product memory product = _products[productId];
        id = productId;
        name = product.name;
        amount = product.amount;
        payableToken = product.payableToken;
        period = product.period;
        owner__ = product.owner;
        uri = product.uri;
    }
}
