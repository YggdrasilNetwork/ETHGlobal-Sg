
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.starknet.common.storage import Storage
from starkware.starknet.common.syscalls import deploy_contract

@contract_interface
namespace IERC20 {
    func transfer(recipient: felt, amount: felt) -> (success: felt):
    end

    func transferFrom(sender: felt, recipient: felt, amount: felt) -> (success: felt):
    end
}

@storage_var
func sender() -> felt:
end

@storage_var
func recipient() -> felt:
end

@storage_var
func btc_recipient() -> felt:
end

@storage_var
func rootstock_recipient() -> felt:
end

@storage_var
func flow_recipient() -> felt:
end

@storage_var
func usdc_token() -> felt:
end

@storage_var
func amount() -> felt:
end

@storage_var
func hashlock() -> felt:
end

@storage_var
func timelock() -> felt:
end

@storage_var
func btc_amount() -> felt:
end

@storage_var
func rootstock_amount() -> felt:
end

@storage_var
func flow_amount() -> felt:
end

@storage_var
func api_key() -> felt:
end

@event
func LockFunds(sender: felt, amount: felt, hashlock: felt, timelock: felt):
end

@event
func ReleaseFunds(recipient: felt, amount: felt, preimage: felt, btc_recipient: felt, rootstock_recipient: felt, flow_recipient: felt):
end

@event
func Refund(sender: felt, amount: felt):
end

@event
func APICallTriggered(api_key: felt, amount: felt, btc_recipient: felt, rootstock_recipient: felt, flow_recipient: felt):
end

# Constructor function to initialize the contract and lock USDC
@constructor
func constructor(
    _recipient: felt,
    _btc_recipient: felt,
    _rootstock_recipient: felt,
    _flow_recipient: felt,
    _usdc_token: felt,
    _amount: felt,
    _hashlock: felt,
    _timelock: felt,
    _btc_amount: felt,
    _rootstock_amount: felt,
    _flow_amount: felt,
    _api_key: felt
) {
    sender.write(get_caller_address());
    recipient.write(_recipient);
    btc_recipient.write(_btc_recipient);
    rootstock_recipient.write(_rootstock_recipient);
    flow_recipient.write(_flow_recipient);
    usdc_token.write(_usdc_token);
    amount.write(_amount);
    hashlock.write(_hashlock);
    timelock.write(block_timestamp() + _timelock);
    btc_amount.write(_btc_amount);
    rootstock_amount.write(_rootstock_amount);
    flow_amount.write(_flow_amount);
    api_key.write(_api_key);

    # Lock the USDC by calling transferFrom
    let (success) = IERC20.transferFrom(get_caller_address(), address(), _amount).success;
    assert success = 1;

    emit LockFunds(sender.read(), _amount, _hashlock, timelock.read());
    return ();
}

# Release function - called when the correct preimage is provided
@external
func release(preimage: felt) -> (success: felt) {
    # Ensure the preimage hash matches the hashlock
    let (preimage_hash) = HashBuiltin().hash(preimage);
    assert preimage_hash = hashlock.read();

    # Ensure that the timelock has not expired
    assert is_le_felt(block_timestamp(), timelock.read()) = 1;

    # Transfer USDC to the recipient
    let (success) = IERC20.transfer(recipient.read(), amount.read()).success;
    assert success = 1;

    # Emit event for API call
    emit ReleaseFunds(
        recipient.read(),
        amount.read(),
        preimage,
        btc_recipient.read(),
        rootstock_recipient.read(),
        flow_recipient.read()
    );

    emit APICallTriggered(
        api_key.read(),
        amount.read(),
        btc_recipient.read(),
        rootstock_recipient.read(),
        flow_recipient.read()
    );
    return (1);
}

# Refund function - allows the sender to reclaim the funds after the timelock expires
@external
func refund() -> (success: felt) {
    # Ensure the timelock has expired
    assert is_le_felt(timelock.read(), block_timestamp()) = 1;

    # Transfer USDC back to the sender
    let (success) = IERC20.transfer(sender.read(), amount.read()).success;
    assert success = 1;

    emit Refund(sender.read(), amount.read());
    return (1);
}
