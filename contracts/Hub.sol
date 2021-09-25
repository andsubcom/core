pragma solidity ^0.8.6;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SubscriptionTicketNFT} from './SubscriptionTicketNFT.sol';


contract Hub {
    using EnumerableSet for EnumerableSet.UintSet;

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

    struct Organisation {
        address owner;
        EnumerableSet.UintSet subscriptionIds;
    }

    struct Subscription {
        uint256 amount;
        address payableToken;
        uint40 period;
    }

    mapping

    constructor() {
        // todo deploy nft
    }

    function createOrganization() external;    
    function createSubscription() external;
    function buySubscription() external;
    function extendSubscription() external;
    function extendSubscription() external;
    function checkUserHasActiveSubscription external;
    function getAllsubscriptionsForOrganisation external;
    function getSubscriptionInfo external;
}
