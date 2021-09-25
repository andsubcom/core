//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

contract Subscriptions {
    string private greeting;

    constructor() {
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}
