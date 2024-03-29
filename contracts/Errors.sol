// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

library Errors {
string public constant INVALID_PARAMS = 'INVALID_PARAMS';
 string public constant NOT_HUB = 'NOT_HUB';
 string public constant ZERO_ADDRESS = 'ZERO_ADDRESS';
 string public constant NOT_OWNER = 'NOT_OWNER';
 string public constant DEX_FAIL = 'DEX_FAIL';
 string public constant OWNER_DISALLOW_AUTO_EXTEND = 'OWNER_DISALLOW_AUTO_EXTEND';
 string public constant AUTO_BY_ADMIN_EXTEND_TOO_EARLY = 'AUTO_BY_ADMIN_EXTEND_TOO_EARLY';
 string public constant ALREADY_CREATED = 'ALREADY_CREATED';
 string public constant NOT_EXISTS = 'NOT_EXISTS';
}
