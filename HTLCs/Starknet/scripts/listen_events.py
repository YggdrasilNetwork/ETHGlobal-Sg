
import os
from starknet_py.net import AccountClient, KeyPair
from starknet_py.contract import Contract
from starknet_py.net.networks import TESTNET
from dotenv import load_dotenv
import requests

# Load environment variables
load_dotenv()

# StarkNet settings
PRIVATE_KEY = os.getenv("PRIVATE_KEY")
CONTRACT_ADDRESS = os.getenv("CONTRACT_ADDRESS")
API_URL = os.getenv("API_URL")
API_KEY = os.getenv("API_KEY")

async def listen_for_events():
    key_pair = KeyPair.from_private_key(int(PRIVATE_KEY, 16))
    client = await AccountClient.create(TESTNET, key_pair)

    # Load the contract ABI and address
    with open('./abi/HTLCUSDC.json', 'r') as f:
        contract_abi = f.read()

    # Create a contract instance
    htlc_contract = Contract(contract_abi, CONTRACT_ADDRESS, client)

    # Listen for the `APICallTriggered` event
    async for event in htlc_contract.events("APICallTriggered").subscribe():
        amount, btc_recipient, rootstock_recipient, flow_recipient = event.data

        # Call the external API
        response = requests.post(
            API_URL,
            json={
                "apiKey": API_KEY,
                "usdcAmount": amount,
                "btcRecipient": btc_recipient,
                "rootstockRecipient": rootstock_recipient,
                "flowRecipient": flow_recipient
            }
        )
        print(f"API call result: {response.status_code}, {response.json()}")

# Run the event listener
if __name__ == "__main__":
    import asyncio
    asyncio.run(listen_for_events())
