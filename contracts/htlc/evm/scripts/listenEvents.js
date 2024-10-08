const { ethers } = require("ethers");
const callAPI = require("./call_api");
require("dotenv").config();

async function listenForEvents() {
  // Initialize provider and wallet
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.PROVIDER_URL
  );
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  // Load contract ABI and address
  const abi = JSON.parse(
    require("fs").readFileSync("./abi/HTLCERC20.json", "utf8")
  );
  const contractAddress = process.env.CONTRACT_ADDRESS;

  // Connect to the contract
  const contract = new ethers.Contract(contractAddress, abi, wallet);

  console.log("Listening for APICallTriggered event...");

  // Listen for APICallTriggered event
  contract.on("APICallTriggered", async (btcRecipient, btcAmount) => {
    console.log(
      `APICallTriggered event detected. BTC Recipient: ${btcRecipient}, BTC Amount: ${btcAmount}`
    );

    // Call the API to release BTC
    await callAPI(btcRecipient, btcAmount);
  });

  // Keep the script running
  process.stdin.resume();
}

listenForEvents().catch((error) => {
  console.error("Error listening for events:", error);
});
