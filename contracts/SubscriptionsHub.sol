// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {SubscriptionTicketNFT} from './SubscriptionTicketNFT.sol';
import "./Errors.sol";


contract SubscriptionsHub {
    using SafeERC20 for IERC20;

    uint256 internal _nextOrganizationId;
    uint256 internal _nextSubscriptionId;
    SubscriptionTicketNFT public nft;
    address public treasury;

    event OrganizationCreated(
        uint256 indexed organizationId,
        address indexed owner
    );

    event SubscriptionCreated(
        uint256 indexed organizationId,
        uint256 indexed subscriptionId,
        address indexed payableToken,
        uint256 amount,
        uint256 period
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
    }

    mapping (uint256 /*organizationId*/ => Organization) internal _organizations;
    mapping (uint256 /*subscriptionId*/ => Subscription) internal _subscriptions;

    constructor(address _treasury) {
        nft = new SubscriptionTicketNFT(address(this));
        require(_treasury != address(0), Errors.ZERO_ADDRESS);
        treasury = _treasury;
    }

    function createOrganization(string memory name) external {
        uint256 organizationId = _nextOrganizationId++;
        _organizations[organizationId].owner = msg.sender;
        _organizations[organizationId].name = name;
        emit OrganizationCreated({
            organizationId: organizationId,
            owner: msg.sender
        });
    }

    function createSubscription(uint256 organizationId, string memory name, address payableToken, uint256 amount, uint256 period) external {
        require(payableToken != address(0), Errors.ZERO_ADDRESS);
        require(amount != 0, Errors.INVALID_PARAMS);
        require(period != 0, Errors.INVALID_PARAMS);
        
        uint256 subscriptionId = _nextSubscriptionId++;
        _subscriptions[subscriptionId] = Subscription({
            name: name,
            amount: amount,
            payableToken: payableToken,
            period: period
        });
        _organizations[organizationId].subscriptionIds.push(subscriptionId);
        emit SubscriptionCreated({
            organizationId: organizationId,
            subscriptionId: subscriptionId,
            payableToken: payableToken,
            amount: amount,
            period: period
        });
    }
    
    function buySubscription(uint256 subscriptionId) external {
        Subscription memory subscription = _subscriptions[subscriptionId];
        IERC20(subscription.payableToken).safeTransferFrom(msg.sender, treasury, subscription.amount);
        nft.mint(msg.sender, subscriptionId, block.timestamp, block.timestamp+subscription.period);
    }
    
    /**
     * @dev extend any existant subscription
     * @dev anyone can extend any subscription even if he is not the holder.
     */
    function extendSubscription(uint256 tokenId) external {
        (uint256 subscriptionId, /*startTimestamp*/, uint256 endTimestamp) = nft.getTokenInfo(tokenId);
        Subscription memory subscription = _subscriptions[subscriptionId];
        IERC20(subscription.payableToken).safeTransferFrom(msg.sender, treasury, subscription.amount);
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
        uint256 period
    ) {
        Subscription memory subscription = _subscriptions[subscriptionId];
        return (subscription.amount, subscription.payableToken, subscription.period);
    }
}
