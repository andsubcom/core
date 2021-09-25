pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Errors.sol";


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] 
 * Non-Fungible Token Standard, including required information about subscription ticket.
 */
contract SubscriptionTicketNFT is ERC721, ERC721Enumerable, Ownable {
    uint256 internal _nextTokenId;
    
    emit SetTokenInfo(
        uint256 indexed tokenId,
        uint40 indexed subscriptionId,
        uint40 startTimestamp,
        uint40 endTimestamp
    );

    struct TokenInfo {
        uint40 subscriptionId;
        uint40 startTimestamp;
        uint40 endTimestamp;
    }
    mapping (uint256/*tokenId*/ => TokenInfo) internal _tokenInfo;
    
    mapping (address /*user*/ => mapping(uint256 /*subscriptionId*/ => uint256[])) private _userSubscriptionTokens;

    Hub public hub;

    constructor(address _hub) ERC721("SubscriptionTicketNFT", "SubNFT") {
        require(_hub != address(0), Errors.ZERO_ADDRESS);
        hub = _hub;
    }

    modifier onlyHub() {
        require(msg.sender == hub, Erros.NOT_HUB);
        _;
    }

    function getUserTokenIds(address user) external view returns(uint256[]) {
        uint256 balance = _balances[user];
        uint256[] result = new uint256[balance];
        for (uint256 i=0; i<balance; i++){
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            result[i] = tokenId;
        }
        return result;
    }

    /**
     * @dev get all tokens for specific user and subscription (including past, current and future)
     */
    function getUserSubscriptionTokenIds(address user, uint256 subscriptionId) external view returns(uint256[]) {
        return _userSubscriptionTokens[user][subscriptionId];
    }

    function checkUserHasActiveSubscription(address user, uint256 subscriptionId) external view returns(bool) {
        uint256[] storage tokens = _userSubscriptionTokens[user][subscriptionId];
        uint length = tokens.length;  // gas optimisation
        for (uint256 i; i<length; i++) {
            TokenInfo storage tokenInfo = _tokenInfo[tokens[i]];
            if ((tokenInfo.startTimestamp <= block.timestamp) && (block.timestamp <= tokenInfo.endTimestamp)){
                return true;
            }
        }
        return false;
    }

    function mint(address user, uint40 subscriptionId, uint40 startTimestamp, uint40 endTimestamp) onlyHub external returns (uint256) {
        require(user != address(0), Errors.ZERO_ADDRESS);
        uint256 tokenId = nextTokenId++;
        _mint(to, tokenId);
        TokenInfo tokenInfo = TokenInfo({
            subscriptionId: subscriptionId,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp
        });
        _tokenInfo[tokenId] = tokenInfo;
        _userSubscriptionTokens[user][subscriptionId] = tokenId;
        emit SetTokenInfo({
            tokenId: tokenId,
            subscriptionId: subscriptionId,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp
        });
        return tokenId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
        uint40 subscriptionId = _tokenInfo[tokenId].subscriptionId;
        uint256[] storage fromTokens = _userSubscriptionTokens[from][subscriptionId];
        uint256 length = fromTokens.length;
        for(uint256 i; i<length; i++) {
            if (fromTokens[i] == tokenId) {
                // remove
                if(i != length-1) {
                    // set last to current to free up the last element
                    fromTokens[i] = fromTokens[length-1];
                }
                fromTokens.length--;
            }
        }  // if not found will fail in transfer itself
        _userSubscriptionTokens[to][subscriptionId] = tokenId;
    }
}
