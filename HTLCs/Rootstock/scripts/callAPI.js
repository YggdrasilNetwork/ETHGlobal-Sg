const axios = require('axios');
require('dotenv').config();

// Function to call the external API and pass the required information
async function callAPI(apiKey, usdcAmount, btcRecipient, btcAmount) {
  try {
    const response = await axios.post(process.env.API_URL, {
      apiKey,
      usdcAmount,
      btcRecipient,
      btcAmount
    });
    console.log('API call successful:', response.data);
  } catch (error) {
    console.error('API call failed:', error);
  }
}

module.exports = callAPI;
