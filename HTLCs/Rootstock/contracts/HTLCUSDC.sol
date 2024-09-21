// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract HTLCERC20 {
    address public sender;
    address public recipient; // Ethereum/RSK recipient for ERC20 tokens
    string public btcRecipient; // Bitcoin recipient address (keep as string)
    address public erc20Token;  // Address of the ERC20 token
    uint256 public amount;
    uint256 public timeLock;
    uint256 public btcAmount; // Optional hardcoded BTC equivalent
    string public apiKey;

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
        uint256 _timeLock,
        uint256 _btcAmount,  // Set the BTC equivalent of the ERC20 token amount (or fetch it off-chain)
        string memory _apiKey
    ) {
        sender = msg.sender;
        recipient = _recipient;
        btcRecipient = _btcRecipient;  // Store BTC recipient address as string
        erc20Token = _erc20Token;
        amount = _amount;
        timeLock = block.timestamp + _timeLock;
        btcAmount = _btcAmount;  // Optional hardcoded BTC amount
        apiKey = _apiKey;

        // Lock ERC20 tokens
        require(IERC20(erc20Token).transferFrom(sender, address(this), amount), "Transfer failed");

        emit LockFunds(sender, amount, timeLock);
    }

    // Function to release funds when the timelock has passed
    function releaseFunds() external onlyRecipient {
        require(block.timestamp >= timeLock, "Timelock not expired");

        // Transfer ERC20 tokens to the recipient
        require(IERC20(erc20Token).transfer(recipient, amount), "Transfer failed");

        // Emit event with all necessary data for the API call (including the BTC recipient address and amount)
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
