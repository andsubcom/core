// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

import {SubscriptionTicketNFT} from './SubscriptionTicketNFT.sol';
import "./Errors.sol";


contract SubscriptionsHub is Ownable {
    using SafeERC20 for IERC20;

    uint256 internal _nextOrganizationId;
    uint256 internal _nextSubscriptionId;
    SubscriptionTicketNFT public nft;

    event OrganizationCreated(
        uint256 indexed organizationId,
        address indexed owner,
        string name
    );

    event SubscriptionCreated(
        uint256 indexed organizationId,
        uint256 indexed subscriptionId,
        address indexed payableToken,
        uint256 amount,
        uint256 period,
        string name
    );

    struct Organization {
        string name;
        address owner;
        uint256[] subscriptionIds;
    }

    struct Subscription {
        string name;
        uint256 amount;
        address payableToken;
        uint256 period;
        uint256 organizationId;
    }

    mapping (uint256 /*organizationId*/ => Organization) internal _organizations;
    mapping (uint256 /*subscriptionId*/ => Subscription) internal _subscriptions;
    mapping (address /*user*/ => uint256[] /*organizationIds*/) internal _ownerOrganizationIds;

    constructor() Ownable() {
        nft = new SubscriptionTicketNFT(address(this));
    }

    function createOrganization(string memory name) external {
        uint256 organizationId = _nextOrganizationId++;
        _organizations[organizationId].owner = msg.sender;
        _organizations[organizationId].name = name;
        _ownerOrganizationIds[msg.sender].push(organizationId);
        emit OrganizationCreated({
            organizationId: organizationId,
            owner: msg.sender,
            name: name
        });
    }

    function getOwnerOrganizationIds(address owner) external view returns(uint256[] memory) {
        return _ownerOrganizationIds[owner];
    }

    function createSubscription(uint256 organizationId, string memory name, address payableToken, uint256 amount, uint256 period) external {
        require(payableToken != address(0), Errors.ZERO_ADDRESS);
        require(amount != 0, Errors.INVALID_PARAMS);
        require(period != 0, Errors.INVALID_PARAMS);
        
        require(msg.sender == _organizations[organizationId].owner, Errors.NOT_OWNER);

        uint256 subscriptionId = _nextSubscriptionId++;
        _subscriptions[subscriptionId] = Subscription({
            name: name,
            amount: amount,
            payableToken: payableToken,
            period: period,
            organizationId: organizationId
        });
        _organizations[organizationId].subscriptionIds.push(subscriptionId);
        emit SubscriptionCreated({
            organizationId: organizationId,
            subscriptionId: subscriptionId,
            payableToken: payableToken,
            amount: amount,
            period: period,
            name: name
        });
    }
    
    function buySubscription(uint256 subscriptionId, bool allowAutoExtend) external {
        Subscription memory subscription = _subscriptions[subscriptionId];
        address organizationOwner = _organizations[subscription.organizationId].owner;
        IERC20(subscription.payableToken).safeTransferFrom(msg.sender, organizationOwner, subscription.amount);
        nft.mint(msg.sender, subscriptionId, block.timestamp, block.timestamp+subscription.period, allowAutoExtend);
    }

    /**
     * @dev Extend any existant subscription.
     * @dev May be called by the owner or by the token holder.
     * @dev Owner can extend subscription not early than 1 days before the endTimestamp.
     */
    function extendSubscription(uint256 tokenId) external {
        (uint256 subscriptionId, /*startTimestamp*/, uint256 endTimestamp, bool allowAutoExtend) = nft.getTokenInfo(tokenId);
        address holder = nft.ownerOf(tokenId);
        if (holder != msg.sender) {
            require(msg.sender == owner(), Errors.NOT_OWNER);
            require(allowAutoExtend, Errors.OWNER_DISALLOW_AUTO_EXTEND);
            require(block.timestamp >= endTimestamp - 1 days, Errors.AUTO_BY_ADMIN_EXTEND_TOO_EARLY);
        }
        
        Subscription memory subscription = _subscriptions[subscriptionId];
        address organizationOwner = _organizations[subscription.organizationId].owner;
        IERC20(subscription.payableToken).safeTransferFrom(holder, organizationOwner, subscription.amount);
        uint256 newEndTimestamp = block.timestamp + subscription.period;
        if (newEndTimestamp < endTimestamp + subscription.period) {  // take max
            newEndTimestamp = endTimestamp + subscription.period;
        }
        nft.extend(tokenId, newEndTimestamp);   
    }
    
    function checkUserHasActiveSubscription(address user, uint256 subscriptionId) external view returns(bool) {
        return nft.checkUserHasActiveSubscription(user, subscriptionId);
    }
    
    function getAllsubscriptionsForOrganization(uint256 organizationId) external view returns(uint256[] memory) {
        // uint256[] result =  new uint256[];
        // return result;
        return _organizations[organizationId].subscriptionIds;
    }
    
    function getOrganizationInfo(uint256 organizationId) view external returns(
        address owner,
        string memory name
    ) {
        Organization memory organization = _organizations[organizationId];
        owner = organization.owner;
        name = organization.name;
    }

    function getSubscriptionInfo(uint256 subscriptionId) view external returns(
        uint256 amount,
        address payableToken,
        uint256 period,
        uint256 organizationId
    ) {
        Subscription memory subscription = _subscriptions[subscriptionId];
        return (subscription.amount, subscription.payableToken, subscription.period, subscription.organizationId);
    }
}
