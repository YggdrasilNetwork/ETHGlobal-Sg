const { ethers } = require('ethers');
const fs = require('fs');
require('dotenv').config();

async function deployContract() {
    // Initialize provider, wallet, and contract ABI and bytecode
    const provider = new ethers.providers.JsonRpcProvider(process.env.PROVIDER_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    const abi = JSON.parse(fs.readFileSync('./abi/HTLCERC20.json', 'utf8'));
    const bytecode = fs.readFileSync('./bin/HTLCERC20.bin', 'utf8');

    // Create a contract factory
    const contractFactory = new ethers.ContractFactory(abi, bytecode, wallet);

    // Define constructor parameters
    const recipient = process.env.RECIPIENT; // Ethereum recipient address
    const btcRecipient = process.env.BTC_RECIPIENT; // Bitcoin recipient address
    const erc20Token = process.env.ERC20_TOKEN_ADDRESS; // ERC20 token contract address
    const amount = ethers.utils.parseUnits(process.env.AMOUNT, 18); // ERC20 amount with correct decimals
    const timelock = process.env.TIME_LOCK;  // Time lock in seconds
    const btcAmount = process.env.BTC_AMOUNT; // BTC amount to release
    const apiKey = process.env.API_KEY; // API key for authorization (optional)

    // Deploy the contract with constructor arguments
    const contract = await contractFactory.deploy(
        recipient,
        btcRecipient,
        erc20Token,
        amount,
        timelock,
        btcAmount,
        apiKey
    );

    console.log(`Contract deployed at address: ${contract.address}`);
}

deployContract().catch((error) => {
    console.error('Error deploying contract:', error);
});
