// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Errors.sol";


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] 
 * Non-Fungible Token Standard, including required information about product ticket.
 */
contract SubscriptionNFT is ERC721, ERC721Enumerable, Ownable, ERC721URIStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    uint256 internal _nextTokenId;
    
    event SetTokenInfo(
        uint256 indexed tokenId,
        string indexed productId,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool allowAutoExtend  // it allows owner to call extend
    );

    struct TokenInfo {
        string productId;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool allowAutoExtend;
    }
    mapping (uint256/*tokenId*/ => TokenInfo) internal _tokenInfo;

    function getTokenInfo(uint256 tokenId) external view returns(
        string memory productId,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool allowAutoExtend,
        string memory uri
    ) {
        TokenInfo memory info = _tokenInfo[tokenId];
        productId = info.productId;
        startTimestamp = info.startTimestamp;
        endTimestamp = info.endTimestamp;
        allowAutoExtend = info.allowAutoExtend;
        uri = tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        _userProductTokens[ownerOf(tokenId)][_tokenInfo[tokenId].productId].remove(tokenId);
        _productTokens[_tokenInfo[tokenId].productId].remove(tokenId);
        super._burn(tokenId);  // take care about multiple inheritance
        delete _tokenInfo[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    mapping (address /*user*/ => mapping(string /*productId*/ => EnumerableSet.UintSet /*tokenIds set*/)) private _userProductTokens;
    mapping(string /*productId*/ => EnumerableSet.UintSet /*tokenIds set*/) private _productTokens;

    address public hub;

    constructor(address _hub) ERC721("SubscriptionNFT", "SubNFT") {
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
     * @dev get all tokens for specific user and product (including past, current and future)
     */
    function getUserProductSubscriptionIds(address user, string memory productId) external view returns(uint256[] memory) {
        EnumerableSet.UintSet storage set = _userProductTokens[user][productId];
        uint256 length = set.length();
        uint256[] memory result = new uint256[](length);
        for (uint256 i=0; i<length; i++){
            result[i] = set.at(i);
        }
        return result;
    }

    function checkUserHasActiveSubscription(address user, string memory productId) external view returns(bool) {
        EnumerableSet.UintSet storage set = _userProductTokens[user][productId];
        uint256 length = set.length();  // gas optimisation
        for (uint256 i=0; i<length; i++){
            uint256 tokenId = set.at(i);
            TokenInfo storage tokenInfo = _tokenInfo[tokenId];
            if ((tokenInfo.startTimestamp <= block.timestamp) && (block.timestamp <= tokenInfo.endTimestamp)){
                return true;
            }
        }
        return false;
    }

    function getProductTokens(string memory productId) external view returns(uint256[] memory) {
        uint256 length = _productTokens[productId].length();
        uint256[] memory result = new uint256[](length);
        for (uint256 i=0; i<length; i++){
            result[i] = _productTokens[productId].at(i);
        }
        return result;
    }

    function mint(address user, string memory productId, uint256 startTimestamp, uint256 endTimestamp, bool allowAutoExtend, string memory uri) onlyHub external returns (uint256) {
        require(user != address(0), Errors.ZERO_ADDRESS);
        uint256 tokenId = _nextTokenId++;
        _mint(user, tokenId);
        TokenInfo memory tokenInfo = TokenInfo({
            productId: productId,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            allowAutoExtend: allowAutoExtend
        });
        _tokenInfo[tokenId] = tokenInfo;
        _userProductTokens[user][productId].add(tokenId);
        _productTokens[productId].add(tokenId);
        _setTokenURI(tokenId, uri);
        emit SetTokenInfo({
            tokenId: tokenId,
            productId: productId,
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
            productId: tokenInfo.productId,
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
            productId: tokenInfo.productId,
            startTimestamp: tokenInfo.startTimestamp,
            endTimestamp: tokenInfo.endTimestamp,
            allowAutoExtend: allowAutoExtend
        });
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
        string memory productId = _tokenInfo[tokenId].productId;
        _userProductTokens[from][productId].remove(tokenId);
        _userProductTokens[to][productId].add(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
