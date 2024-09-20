const { createPublicClient, http, watchContractEvent } = require('viem');
const ethers = require('ethers');
const callAPI = require('./callAPI');
const HTLC_ABI = require('../abi/HTLCUSDC.json');

require('dotenv').config();

const provider = new ethers.providers.JsonRpcProvider(process.env.RSK_PROVIDER);
const client = createPublicClient({
  transport: http(provider),
});

const contractAddress = process.env.CONTRACT_ADDRESS;

watchContractEvent({
  client,
  abi: HTLC_ABI.abi,
  address: contractAddress,
  eventName: 'APICallTriggered',
  onLogs: (logs) => {
    logs.forEach(log => {
      const { apiKey, preImage } = log.args;
      console.log('Event Detected: APICallTriggered', apiKey, preImage);
      
      // Trigger the API call function
      callAPI(apiKey, preImage);
    });
  }
});

console.log('Listening for APICallTriggered events...');

