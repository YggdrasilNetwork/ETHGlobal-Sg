
import requests
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

API_URL = os.getenv("API_URL")
API_KEY = os.getenv("API_KEY")

def call_api(usdc_amount, btc_recipient, rootstock_recipient, flow_recipient):
    try:
        response = requests.post(
            API_URL,
            json={
                "apiKey": API_KEY,
                "usdcAmount": usdc_amount,
                "btcRecipient": btc_recipient,
                "rootstockRecipient": rootstock_recipient,
                "flowRecipient": flow_recipient
            }
        )
        print(f"API call result: {response.status_code}, {response.json()}")
    except Exception as e:
        print(f"Error in API call: {e}")

