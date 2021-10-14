// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface IProductHub {
    event ProductCreated(
        address indexed owner,
        string indexed productId,
        address indexed payableToken,
        uint256 price,
        uint256 period,
        string name,
        string metadataUri
    );

    event SubscriptionCreated(
        address indexed subscriber,
        string indexed productId,
        uint256 indexed tokenId
    );

    event SubscriptionRenewed(
        address indexed subscriber,
        string indexed productId,
        uint256 indexed tokenId,
        address caller
    );

    event SubscriptionCancelled(
      address indexed subscriber,
      string indexed productId,
      uint256 indexed tokenId,
      address caller
    );

    struct Product {
        string name;
        uint256 price;
        address payableToken;
        uint256 period;
        address owner;
        string metadataUri;
    }

    function getOwnerProductIds(address owner) external view returns (string[] memory);

    function findTokenProductId(uint256 tokenId) external view returns (string memory);

    function findTokenId(address user, string memory productId) external view returns(uint256);

    function getProductInfo(string memory productId)
        external
        view
        returns (
            string memory id,
            string memory name,
            uint256 price,
            address payableToken,
            uint256 period,
            address productOwner,
            string memory uri
        );

    function createProduct(
        string memory productId,
        string memory name,
        address payableToken,
        uint256 price,
        uint256 period,
        string memory metadataUri
    ) external;

    /**
      * @notice Subscribes a sender to a product and charges for the first period.
      * @notice msg.sender must have an allowance to pay for the first period.
      */
    function subscribe(string memory productId) external;

    // /** 
    //  * @notice Cancels subscription to product.
    //  * @notice Subscription is active until end of paid period.
    //  */
    // function cancel(uint256 tokenId) external;

    /**
     * @notice Charges a subscription owner for the current period and renews a subscription.
     * @notice Must be called within a new period that wasn't paid yet.
     * @notice Cancels a subscription if subscription owner doesn't have token allowance or tokens for transferFrom.
     * @notice May be called by anyone.
     */
    function renewSubscription(uint256 tokenId) external;

    /**
     * @notice Renews a subscription by product id.
     */
    function renewSubscription(string memory productId, address subscriber) external;

    /**
     * @notice Renews multuple subscriptions.
     */
    function renewSubscriptions(uint256[] memory tokenIds) external;

    /**
     * @notice Renews all product's subscriptions.
     * @notice May run out of gas limit, only use for debugging on testnet.
     */
    function renewProductSubscriptions(string memory productId) external;
}
