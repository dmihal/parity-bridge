pragma solidity ^0.4.17;

import '../contracts/MessageSigning.sol';


/// Library used only to test MessageSigning library via rpc calls
library MessageSigningTest {
    function recoverAddressFromSignedMessage(bytes signature, bytes message) public pure returns (address) {
        return MessageSigning.recoverAddressFromSignedMessage(signature, message);
    }
}
