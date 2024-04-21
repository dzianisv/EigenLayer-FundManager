// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library AddressLibrary {
    // Converts an address to a hex string using OpenZeppelin's Strings library
    function toHexString(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(addr)), 20);
    }

    function toAddress(string memory str) public pure returns (address addr) {
        bytes memory strBytes = bytes(str);
        require(
            strBytes.length == 42,
            "Invalid input, should be 42 characters long including '0x'."
        );
        require(
            strBytes[0] == "0" && strBytes[1] == "x",
            "Address string should start with '0x'."
        );

        uint160 total = 0;

        // Start from the end of the string and ignore the '0x' prefix
        for (uint256 i = 2; i < strBytes.length; i++) {
            uint8 b = uint8(strBytes[i]);
            uint8 hexValue;

            if (b >= 48 && b <= 57) {
                // '0'-'9'
                hexValue = b - 48;
            } else if (b >= 97 && b <= 102) {
                // 'a'-'f'
                hexValue = b - 87;
            } else if (b >= 65 && b <= 70) {
                // 'A'-'F'
                hexValue = b - 55;
            } else {
                revert("Invalid hex character");
            }

            total = total * 16 + uint160(hexValue);
        }

        return address(total);
    }
}
