pragma solidity ^0.4.17;

import '../contracts/Message.sol';

/// Library used only to test Message library via rpc calls
library MessageTest {
    function getRecipient(bytes message) public pure returns (address) {
        return Message.getRecipient(message);
    }

    function getValue(bytes message) public pure returns (uint256) {
        return Message.getValue(message);
    }

    function getTransactionHash(bytes message) public pure returns (bytes32) {
        return Message.getTransactionHash(message);
    }

    function getMainGasPrice(bytes message) public pure returns (uint256) {
        return Message.getMainGasPrice(message);
    }
}
