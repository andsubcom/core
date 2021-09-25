pragma solidity ^0.8.6;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {SubscriptionTicketNFT} from './SubscriptionTicketNFT.sol';


contract Hub {
    uint256 internal _nextOrganisationId;
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
        uint40 period
    );

    struct Organization {
        address owner;
        uint256[] subscriptionIds;
    }

    struct Subscription {
        uint256 amount;
        address payableToken;
        uint40 period;
    }

    mapping (uint256 /*organizationId*/ => Organization) internal _organizations;
    mapping (uint256 /*subscriptionId*/ => Subscription) internal _subscriptions;

    constructor(address _treasury) {
        nft = new SubscriptionTicketNFT(address(this));
        require(_treasury != address(0), Errors.ZERO_ADDRESS);
        treasury = _treasury;
    }

    function createOrganization() external {
        uint256 organizationId = _nextOrganisationId++;
        _organizations[organizationId].owner = msg.sender;
        emit OrganizationCreated({
            organizationId: organizationId,
            owner: msg.sender
        })
    }

    function createSubscription(uint256 organisationId, address payableToken, uint256 amount, uint40 period) external {
        require(payableToken != address(0), Errors.ZERO_ADDRESS);
        require(amount != 0, Errors.INVALID_PARAMS);
        require(period != 0, Errors.INVALID_PARAMS);
        
        uint256 subscriptionId = _nextSubscriptionId++;
        _subscrptions[subscriptionId] = Subscription({
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
        })
    }
    
    function buySubscription(uint256 subscriptionId) external {
        Subscription memory subscription = _subscrptions[subscriptionId];
        SafeERC20(subscription.payableToken).safeTransferFrom(msg.sender, treasury, subscription.amount);
        nft.mint(msg.sender, subscriptionId, subscription.startTimestamp, subscription.endTimestamp);
    }
    
    function extendSubscription(uint256 tokenId) external {
        (uint256 subscriptionId,,) = nft.getTokenInfo(tokenId);
        address owner = nft.ownerOf(tokenId);
        require(owner == msg.sender, Errors.NOT_OWNER);
    }
    
    function checkUserHasActiveSubscription(address user, uint256 subscriptionId) external view returns(bool) {
        return nft.checkUserHasActiveSubscription(user, subscriptionId);
    }
    
    function getAllsubscriptionsForOrganisation(uint256 organisationId) external view returns(uint256[]) {
        uint256[] result =  new uint256[];
        return result;
    }
    
    function getSubscriptionInfo(uint256 subscriptionId) view external returns(
        uint256 amount,
        address payableToken,
        uint40 period
    ) {
        Subscription storage subscription = _subscriptions[subscriptionId];
        return (subscriptionId.amount, subscriptionId.payableToken, subscriptionId.period);
    }
}
