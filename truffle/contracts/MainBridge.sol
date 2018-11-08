pragma solidity ^0.4.17;


import "./Helpers.sol";
import "./Message.sol";


contract MainBridge {
    /// Number of authorities signatures required to withdraw the money.
    ///
    /// Must be lesser than number of authorities.
    uint256 public requiredSignatures;

    /// The gas cost of calling `MainBridge.withdraw`.
    ///
    /// Is subtracted from `value` on withdraw.
    /// recipient pays the relaying authority for withdraw.
    /// this shuts down attacks that exhaust authorities funds on main chain.
    uint256 public estimatedGasCostOfWithdraw;

    /// reject deposits that would increase `this.balance` beyond this value.
    /// security feature:
    /// limits the total amount of mainnet ether that can be lost
    /// if the bridge is faulty or compromised in any way!
    /// set to 0 to disable.
    uint256 public maxTotalMainContractBalance;

    /// reject deposits whose `msg.value` is higher than this value.
    /// security feature.
    /// set to 0 to disable.
    uint256 public maxSingleDepositValue;

    /// Contract authorities.
    address[] public authorities;

    /// Used side transaction hashes.
    mapping (bytes32 => bool) public withdraws;

    /// Event created on money deposit.
    event Deposit (address recipient, uint256 value);

    /// Event created on money withdraw.
    event Withdraw (address recipient, uint256 value, bytes32 transactionHash);

    /// Constructor.
    function MainBridge(
        uint256 requiredSignaturesParam,
        address[] authoritiesParam,
        uint256 estimatedGasCostOfWithdrawParam,
        uint256 maxTotalMainContractBalanceParam,
        uint256 maxSingleDepositValueParam
    ) public
    {
        require(requiredSignaturesParam != 0);
        require(requiredSignaturesParam <= authoritiesParam.length);
        requiredSignatures = requiredSignaturesParam;
        authorities = authoritiesParam;
        estimatedGasCostOfWithdraw = estimatedGasCostOfWithdrawParam;
        maxTotalMainContractBalance = maxTotalMainContractBalanceParam;
        maxSingleDepositValue = maxSingleDepositValueParam;
    }

    /// Should be used to deposit money.
    function () public payable {
        require(maxSingleDepositValue == 0 || msg.value <= maxSingleDepositValue);
        // the value of `this.balance` in payable methods is increased
        // by `msg.value` before the body of the payable method executes
        require(maxTotalMainContractBalance == 0 || this.balance <= maxTotalMainContractBalance);
        Deposit(msg.sender, msg.value);
    }

    /// Called by the bridge node processes on startup
    /// to determine early whether the address pointing to the main
    /// bridge contract is misconfigured.
    /// so we can provide a helpful error message instead of the very
    /// unhelpful errors encountered otherwise.
    function isMainBridgeContract() public pure returns (bool) {
        return true;
    }

    /// final step of a withdraw.
    /// checks that `requiredSignatures` `authorities` have signed of on the `message`.
    /// then transfers `value` to `recipient` (both extracted from `message`).
    /// see message library above for a breakdown of the `message` contents.
    /// `vs`, `rs`, `ss` are the components of the signatures.

    /// anyone can call this, provided they have the message and required signatures!
    /// only the `authorities` can create these signatures.
    /// `requiredSignatures` authorities can sign arbitrary `message`s
    /// transfering any ether `value` out of this contract to `recipient`.
    /// bridge users must trust a majority of `requiredSignatures` of the `authorities`.
    function withdraw(uint8[] vs, bytes32[] rs, bytes32[] ss, bytes message) public {
        require(message.length == 116);

        // check that at least `requiredSignatures` `authorities` have signed `message`
        require(Helpers.hasEnoughValidSignatures(message, vs, rs, ss, authorities, requiredSignatures));

        address recipient = Message.getRecipient(message);
        uint256 value = Message.getValue(message);
        bytes32 hash = Message.getTransactionHash(message);
        uint256 mainGasPrice = Message.getMainGasPrice(message);

        // if the recipient calls `withdraw` they can choose the gas price freely.
        // if anyone else calls `withdraw` they have to use the gas price
        // `mainGasPrice` specified by the user initiating the withdraw.
        // this is a security mechanism designed to shut down
        // malicious senders setting extremely high gas prices
        // and effectively burning recipients withdrawn value.
        // see https://github.com/paritytech/parity-bridge/issues/112
        // for further explanation.
        require((recipient == msg.sender) || (tx.gasprice == mainGasPrice));

        // The following two statements guard against reentry into this function.
        // Duplicated withdraw or reentry.
        require(!withdraws[hash]);
        // Order of operations below is critical to avoid TheDAO-like re-entry bug
        withdraws[hash] = true;

        uint256 estimatedWeiCostOfWithdraw = estimatedGasCostOfWithdraw * mainGasPrice;

        // charge recipient for relay cost
        uint256 valueRemainingAfterSubtractingCost = value - estimatedWeiCostOfWithdraw;

        // pay out recipient
        recipient.transfer(valueRemainingAfterSubtractingCost);

        // refund relay cost to relaying authority
        msg.sender.transfer(estimatedWeiCostOfWithdraw);

        Withdraw(recipient, valueRemainingAfterSubtractingCost, hash);
    }
}
