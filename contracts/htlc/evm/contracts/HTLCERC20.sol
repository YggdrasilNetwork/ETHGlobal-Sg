// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract HTLCERC20 {
    address public sender;
    address public recipient; // Ethereum/RSK recipient for ERC20 tokens
    string public btcRecipient; // Bitcoin recipient address (keep as string)
    address public erc20Token;  // Address of the ERC20 token
    uint256 public amount;
    uint256 public timeLock;

    event LockFunds(address indexed sender, uint256 amount, uint256 timeLock);
    event ReleaseFunds(address indexed recipient, uint256 amount, string btcRecipient, uint256 btcAmount);
    event Refund(address indexed sender, uint256 amount);
    event APICallTriggered(string btcRecipient, uint256 btcAmount);

    modifier onlySender() {
        require(msg.sender == sender, "Only sender can call this function");
        _;
    }

    modifier onlyRecipient() {
        require(msg.sender == recipient, "Only recipient can call this function");
        _;
    }

    constructor(
        address _recipient,  // Ethereum/RSK recipient (address type)
        string memory _btcRecipient, // BTC recipient address (string type)
        address _erc20Token,  // Address of any ERC20 token
        uint256 _amount,
        uint256 _timeLock
    ) {
        sender = msg.sender;
        recipient = _recipient;
        btcRecipient = _btcRecipient;  // Store BTC recipient address as string
        erc20Token = _erc20Token;
        amount = _amount;
        timeLock = block.timestamp + _timeLock;
    }

    function lockFunds() onlySender payable public {
        // Lock ERC20 tokens
        require(IERC20(erc20Token).transferFrom(sender, address(this), amount), "Transfer failed");
    
        // Emit event with the amount and timeLock
        emit LockFunds(sender, amount, timeLock);
    
        // Trigger API call event for the off-chain service to lock BTC
        emit APICallTriggered("", 0);
     }

    // Function to release funds when the timelock has passed
    function releaseFunds(uint256 btcAmount) external onlyRecipient {
        require(block.timestamp >= timeLock, "Timelock not expired");

        // Transfer ERC20 tokens to the recipient
        require(IERC20(erc20Token).transfer(recipient, amount), "Transfer failed");

        // Emit event with all necessary data for the API call (including the BTC recipient address and dynamic BTC amount)
        emit ReleaseFunds(recipient, amount, btcRecipient, btcAmount);

        // Trigger API call event for the off-chain service to release BTC
        emit APICallTriggered(btcRecipient, btcAmount);
    }

    // Refund function in case the timelock expires and the funds are not claimed
    function refund() external onlySender {
        require(block.timestamp >= timeLock, "Timelock not expired");

        // Refund the locked ERC20 tokens back to the sender
        require(IERC20(erc20Token).transfer(sender, amount), "Refund failed");

        emit Refund(sender, amount);
    }
}