pragma solidity ^0.4.17;

import '../contracts/Helpers.sol';

/// Library used only to test Helpers library via rpc calls
library HelpersTest {
    function addressArrayContains(address[] array, address value) public pure returns (bool) {
        return Helpers.addressArrayContains(array, value);
    }

    function uintToString(uint256 inputValue) public pure returns (string str) {
        return Helpers.uintToString(inputValue);
    }

    function hasEnoughValidSignatures(bytes message, uint8[] vs, bytes32[] rs, bytes32[] ss, address[] addresses, uint256 requiredSignatures) public pure returns (bool) {
        return Helpers.hasEnoughValidSignatures(message, vs, rs, ss, addresses, requiredSignatures);
    }
}
