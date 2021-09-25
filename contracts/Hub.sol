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

    event OrganisationCreated(
        uint256 indexed organisationId,
        address indexed owner
    );

    event SubscriptionCreated(
        uint256 indexed organisationId,
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

    constructor(nftOwner) {
        nft = new SubscriptionTicketNFT(address(this));
    }

    function createOrganization() external {
        uint256 organizationId = _nextOrganisationId++;
    }

    function createSubscription(uint256 organisationId, address payableToken, uint256 amount, uint40 period) external {

    }
    
    function buySubscription(uint256 organisationId, uint256 subscriptionId) external {

    }
    
    function buySubscription(uint256 subscriptionId) external {

    }
    
    function extendSubscription(uint256 tokenId) external {

    }
    
    function checkUserHasActiveSubscription(address user, uint256 subscriptionId) external view returns(bool) {
        return nft.checkUserHasActiveSubscription(user, subscriptionId);
    }
    
    function getAllsubscriptionsForOrganisation(uint256 organisationId) external view returns(uint256[]) {
        uint256[] result =  new uint256[];
        return result;
    }
    
    function getSubscriptionInfo(uint256 subscriptionId) view external return(
        uint256 amount,
        address payableToken,
        uint40 period
    ) {
        Subscription storage subscription = _subscriptions[subscriptionId];
        return (subscriptionId.amount, subscriptionId.payableToken, subscriptionId.period);
    }
}
