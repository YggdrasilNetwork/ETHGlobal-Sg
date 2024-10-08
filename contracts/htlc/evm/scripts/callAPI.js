const axios = require("axios");
require("dotenv").config();

async function callAPI(btcRecipient, btcAmount) {
  try {
    // Load API key from environment variables
    const apiUrl = "https://127.0.0.1:5000/transfer_tokens"; // New API URL as per your request

    // Construct the query parameters for the API call
    const queryParams = `?recipient=${btcRecipient}&amount=${btcAmount}`;

    // Send a GET request to the API with query parameters
    const response = await axios.get(apiUrl + queryParams);

    console.log(`API call successful: ${response.data}`);
  } catch (error) {
    console.error(`API call failed: ${error.message}`);
  }
}

module.exports = callAPI;
