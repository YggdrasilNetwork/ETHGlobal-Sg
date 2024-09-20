
import os
from starknet_py.net import AccountClient, KeyPair
from starknet_py.contract import Contract
from starknet_py.net.networks import TESTNET
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# StarkNet provider settings
PRIVATE_KEY = os.getenv("PRIVATE_KEY")
CONTRACT_ABI_PATH = './abi/HTLCUSDC.json'
USDC_TOKEN_ADDRESS = os.getenv("USDC_TOKEN")
AMOUNT = int(os.getenv("AMOUNT"))
HASH_LOCK = int(os.getenv("HASH_LOCK"), 16)  # Convert to felt
TIME_LOCK = int(os.getenv("TIME_LOCK"))
BTC_AMOUNT = int(os.getenv("BTC_AMOUNT"))
API_KEY = os.getenv("API_KEY")

async def deploy_contract():
    key_pair = KeyPair.from_private_key(int(PRIVATE_KEY, 16))
    client = await AccountClient.create(TESTNET, key_pair)

    # Load the contract ABI and bytecode
    with open(CONTRACT_ABI_PATH, 'r') as f:
        contract_abi = f.read()

    # Deploy the HTLC contract
    deployment_result = await Contract.deploy(
        client=client,
        compiled_contract=contract_abi,
        constructor_calldata=[
            os.getenv("RECIPIENT"),
            os.getenv("BTC_RECIPIENT"),
            os.getenv("ROOTSTOCK_RECIPIENT"),
            os.getenv("FLOW_RECIPIENT"),
            USDC_TOKEN_ADDRESS,
            AMOUNT,
            HASH_LOCK,
            TIME_LOCK,
            BTC_AMOUNT,
            API_KEY
        ]
    )
    
    # Await transaction receipt
    await deployment_result.wait_for_acceptance()

    print(f"HTLC contract deployed at: {deployment_result.deployed_contract_address}")

# Run the deployment function
if __name__ == "__main__":
    import asyncio
    asyncio.run(deploy_contract())
