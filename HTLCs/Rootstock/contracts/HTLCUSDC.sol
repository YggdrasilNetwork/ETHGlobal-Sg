// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract HTLCUSDC {
    address public sender;
    address public recipient; // Ethereum/RSK recipient
    string public btcRecipient; // Bitcoin recipient address (keep as string)
    address public usdcToken;
    uint256 public amount;
    bytes32 public hashLock;
    uint256 public timeLock;
    uint256 public btcAmount; // Optional hardcoded BTC equivalent
    string public apiKey;

    event LockFunds(address indexed sender, uint256 amount, bytes32 hashLock, uint256 timeLock);
    event ReleaseFunds(address indexed recipient, uint256 amount, bytes32 preImage, string btcRecipient, uint256 btcAmount);
    event Refund(address indexed sender, uint256 amount);
    event APICallTriggered(string apiKey, uint256 usdcAmount, string btcRecipient, uint256 btcAmount);

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
        address _usdcToken,
        uint256 _amount,
        bytes32 _hashLock,
        uint256 _timeLock,
        uint256 _btcAmount, // Set the BTC equivalent of USDC (or fetch it off-chain)
        string memory _apiKey
    ) {
        sender = msg.sender;
        recipient = _recipient;
        btcRecipient = _btcRecipient;  // Store BTC recipient address as string
        usdcToken = _usdcToken;
        amount = _amount;
        hashLock = _hashLock;
        timeLock = block.timestamp + _timeLock;
        btcAmount = _btcAmount;  // Optional hardcoded BTC amount
        apiKey = _apiKey;

        // Lock USDC
        require(IERC20(usdcToken).transferFrom(sender, address(this), amount), "Transfer failed");

        emit LockFunds(sender, amount, hashLock, timeLock);
    }

    // Function to release funds when the correct pre-image is provided
    function releaseFunds(bytes32 _preImage) external onlyRecipient {
        require(sha256(abi.encodePacked(_preImage)) == hashLock, "Invalid pre-image");
        require(block.timestamp < timeLock, "Timelock expired");

        // Transfer USDC to the recipient (if applicable)
        require(IERC20(usdcToken).transfer(recipient, amount), "Transfer failed");

        // Emit event with all necessary data for the API call (including the BTC recipient address and amount)
        emit ReleaseFunds(recipient, amount, _preImage, btcRecipient, btcAmount);

        // Trigger API call to release BTC
        emit APICallTriggered(apiKey, amount, btcRecipient, btcAmount);
    }

    // Refund function in case the timelock expires and the funds are not claimed
    function refund() external onlySender {
        require(block.timestamp >= timeLock, "Timelock not expired");

        // Refund the locked USDC back to the sender
        require(IERC20(usdcToken).transfer(sender, amount), "Refund failed");

        emit Refund(sender, amount);
    }
}
