// SPDX-License-Identifier: UNLICENSED
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
    
    event SetTokenInfo(
        uint256 indexed tokenId,
        uint256 indexed subscriptionId,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool allowAutoExtend  // it allows owner to call extend
    );

    struct TokenInfo {
        uint256 subscriptionId;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool allowAutoExtend;
    }
    mapping (uint256/*tokenId*/ => TokenInfo) internal _tokenInfo;
    
    function getTokenInfo(uint256 tokenId) external view returns(
        uint256 subscriptionId,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool allowAutoExtend
    ) {
        TokenInfo memory info = _tokenInfo[tokenId];
        subscriptionId = info.subscriptionId;
        startTimestamp = info.startTimestamp;
        endTimestamp = info.endTimestamp;
        allowAutoExtend = info.allowAutoExtend;
    }

    mapping (address /*user*/ => mapping(uint256 /*subscriptionId*/ => uint256[])) private _userSubscriptionTokens;

    address public hub;

    constructor(address _hub) ERC721("SubscriptionTicketNFT", "SubNFT") {
        require(_hub != address(0), Errors.ZERO_ADDRESS);
        hub = _hub;
    }

    modifier onlyHub() {
        require(msg.sender == hub, Errors.NOT_HUB);
        _;
    }

    function getUserTokenIds(address user) external view returns(uint256[] memory) {
        uint256 userBalance = balanceOf(user);
        uint256[] memory result = new uint256[](userBalance);
        for (uint256 i=0; i<userBalance; i++){
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            result[i] = tokenId;
        }
        return result;
    }

    /**
     * @dev get all tokens for specific user and subscription (including past, current and future)
     */
    function getUserSubscriptionTokenIds(address user, uint256 subscriptionId) external view returns(uint256[] memory) {
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

    function mint(address user, uint256 subscriptionId, uint256 startTimestamp, uint256 endTimestamp, bool allowAutoExtend) onlyHub external returns (uint256) {
        require(user != address(0), Errors.ZERO_ADDRESS);
        uint256 tokenId = _nextTokenId++;
        _mint(user, tokenId);
        TokenInfo memory tokenInfo = TokenInfo({
            subscriptionId: subscriptionId,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            allowAutoExtend: allowAutoExtend
        });
        _tokenInfo[tokenId] = tokenInfo;
        _userSubscriptionTokens[user][subscriptionId].push(tokenId);
        emit SetTokenInfo({
            tokenId: tokenId,
            subscriptionId: subscriptionId,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            allowAutoExtend: allowAutoExtend
        });
        return tokenId;
    }

    function extend(uint256 tokenId, uint256 newEndTimestamp) onlyHub external {
        TokenInfo storage tokenInfo = _tokenInfo[tokenId];
        tokenInfo.endTimestamp = newEndTimestamp;
        emit SetTokenInfo({
            tokenId: tokenId,
            subscriptionId: tokenInfo.subscriptionId,
            startTimestamp: tokenInfo.startTimestamp,
            endTimestamp: newEndTimestamp,
            allowAutoExtend: tokenInfo.allowAutoExtend
        });
    }

    function setAllowAutoExtend(uint256 tokenId, bool allowAutoExtend) external {
        require(msg.sender == ownerOf(tokenId), Errors.NOT_OWNER);
        TokenInfo storage tokenInfo = _tokenInfo[tokenId];
        tokenInfo.allowAutoExtend = allowAutoExtend;
        emit SetTokenInfo({
            tokenId: tokenId,
            subscriptionId: tokenInfo.subscriptionId,
            startTimestamp: tokenInfo.startTimestamp,
            endTimestamp: tokenInfo.endTimestamp,
            allowAutoExtend: allowAutoExtend
        });
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
        uint256 subscriptionId = _tokenInfo[tokenId].subscriptionId;
        uint256[] storage fromTokens = _userSubscriptionTokens[from][subscriptionId];
        uint256 length = fromTokens.length;
        for(uint256 i=0; i<length; i++) {
            if (fromTokens[i] == tokenId) {
                // remove
                if(i != length-1) {
                    // set last to current to free up the last element
                    fromTokens[i] = fromTokens[length-1];
                }
                fromTokens.pop();
                break;
            }
        }  // if not found will fail in transfer itself
        _userSubscriptionTokens[to][subscriptionId].push(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
