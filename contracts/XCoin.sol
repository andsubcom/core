// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract XCoin is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("USDX Coin", "USDX") {}

    function name() public view virtual override returns (string memory) {
        return "USDX Coin";
    }
}