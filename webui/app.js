const networks = {
    31337: {name: "localnet", contract: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"},
    17000: {name: "Holesky", contract: "0xe3fd89803f4b31bc9949e6c3ed4be83a90c9941d", explorer: "https://holesky.etherscan.io/"},
};

const txOptions = {
    gasLimit: 5 * 10 ** 6
};

const ERC4626_ABI = [
    "function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets)",
    "function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares)",
    "function deposit(uint256 assets, address receiver) external returns (uint256 shares)",
    "function totalAssets() external view returns (uint256 totalManagedAssets)",
    "function asset() external view returns (address assetTokenAddress)",
    "function totalSupply() external view returns (uint256)",
    "function balanceOf(address account) external view returns (uint256)",
    "function name() external view returns (string memory)",
    "function symbol() external view returns (string memory)",
    "function convertToAssets(uint256 shares) external view returns (uint256 assets)",
    "function holdingsManager() public view returns (address)",
    {
        "type": "function",
        "name": "getPortfolio",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "tuple[]",
                "internalType": "struct OperatorAllocation[]",
                "components": [
                    {
                        "name": "staker",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "operator",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "deposited",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "rewards",
                        "type": "uint256",
                        "internalType": "uint256"
                    }
                ]
            }
        ],
        "stateMutability": "view"
    },
];

const ERC20_ABI = [
    "function totalSupply() external view returns (uint256)",
    "function balanceOf(address account) external view returns (uint256)",
    "function name() external view returns (string memory)",
    "function symbol() external view returns (string memory)",
    "function approve(address spender, uint256 amount) external returns (bool)"
];

const HoldingsManager_ABI = [
    "function setOperator(address operator, uint256 stake_bps) public",
    "function removeOperator(address operator) public",
    "function getOperatorWeight(address operator) public view returns (uint256)",
    "function existsOperator(address operator) public view returns (bool)",
    "function numberOfOperators() public view returns (uint256)",
    "function getOperatorsWeights() public view returns (address[] memory, uint256[] memory)",
    {
        "inputs": [],
        "name": "getOperatorsInfo",
        "outputs": [
            {
                "components": [
                    {
                        "internalType": "address",
                        "name": "operator",
                        "type": "address"
                    },
                    {
                        "internalType": "uint256",
                        "name": "weight",
                        "type": "uint256"
                    }
                ],
                "internalType": "struct OperatorInfo[]",
                "name": "",
                "type": "tuple[]"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
];

// Metadata files are located there https://github.com/Layr-Labs/eigendata/tree/master/operators
const operatorsMetadata = {
    17000: {
        "0xbE4B4Fa92b6767FDa2C8D1db53A286834dB19638": {
            metadataUrl: "https://raw.githubusercontent.com/Layr-Labs/eigendata/master/operators/coinbasecloud/metadata.json"
        },
        "0x5e29b3107937b4675FdDF113EDC5530498B3Fb70": {
            metadataUrl: "https://raw.githubusercontent.com/Layr-Labs/eigendata/master/operators/Ankr/metadata.json"
        },
        "0x4E59E88207Ac04e6615D79Ae565E877DD80BCF8e": {
            metadataUrl: "https://raw.githubusercontent.com/Layr-Labs/eigendata/master/operators/GoogleCloudWeb3/metadata.json"
        }

    }
}

// returns provider
async function connectWallet() {
    if (window.ethereum) {
        try {
            // Request account access
            const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
            console.log("Connected to the wallet", accounts);
            const provider = new ethers.providers.Web3Provider(window.ethereum, "any");

            const signer = provider.getSigner();
            const walletAddress = await signer.getAddress();
            const walletNetwork = await provider.getNetwork();
            const chainId = walletNetwork.chainId;

            const network = networks[chainId];
            let networkName = walletNetwork.name;
            let contractAddress = '';

            if (network) {
                networkName = network.name;
                contractAddress = `${network.explorer}/${network.contract}`;
            }

            updateWallet(walletAddress, chainId, networkName, contractAddress);
            return provider;
        } catch (error) {
            console.error("User denied account access");
        }
    } else {
        alert('Please install MetaMask, Rubby Wallet, Coinbase Walletd or another web3 provider.');
    }
}

async function disconnectWallet() {
    updateWallet(null, null, null);
}

document.addEventListener('DOMContentLoaded', async () => {
    const provider = await connectWallet();


    provider.on("network", (newNetwork, oldNetwork) => {
        console.log("Switching from ", oldNetwork, "to", newNetwork);
        if (oldNetwork) {
            window.location.reload();
        }
    });

 
    const signer = provider.getSigner();
    const walletAddress = await signer.getAddress();
    const chainId = (await provider.getNetwork()).chainId;

    const network = networks[chainId];
    if (!network) {
        alert(`${chainId} network is not supported`);
        return;
    }

    const contractAddress = network.contract;

    const vaultContract = new ethers.Contract(contractAddress, ERC4626_ABI, signer);
    const assetAddress = await vaultContract.asset();
    const assetContract = new ethers.Contract(assetAddress, ERC20_ABI, signer);
    const assetSymbol = await assetContract.symbol();

    async function waitForTransaction(txFn, description) {
        setAppBusy(true, `Please sign "${description}" transaction`);
        const tx = await txFn();
        setAppBusy(true, `Waiting for the "${description}" <a href="${network.explorer}/tx/${tx.hash}">transaction</a>`);
        const status = await tx.wait();
        console.log(description, status);
        setAppBusy(false);
        return status;
    }

    // Fetch balance and display
    async function fetchShares() {
        const balance = await vaultContract.balanceOf(walletAddress);
        const total = await vaultContract.totalSupply();
        const symbol = await vaultContract.symbol();
        updateShares(balance, total, symbol);
    }

    // Fetch balance and display
    async function fetchAssets() {
        const balance = await vaultContract.totalAssets();
        const symbol = await assetContract.symbol();
        updateInvestedAssets(balance, symbol);
    }

    async function fetchBalance() {
        const balance = await assetContract.balanceOf(walletAddress);
        const symbol = await assetContract.symbol();
        updateWalletAssets(balance, symbol);
    }

    async function fetchAll() {
        await fetchAssets();
        await fetchShares();
        await fetchBalance();
        await updateHoldingsTable();
    }

    await fetchAll();
    setInterval(() => {
        fetchAll();
    }, 3000);

    // Deposit
    document.getElementById('depositBtn').addEventListener('click', async () => {
        const amount = ethers.utils.parseEther(document.getElementById('amountInput').value);
        try {
            await waitForTransaction(async () => await assetContract.approve(contractAddress, amount), assetSymbol + " approve");
            await waitForTransaction(async () => await vaultContract.deposit(amount, walletAddress), "deposit");
            fetchAll();
        } catch (error) {
            console.error("Deposit failed", error);
            alert(JSON.stringify(error));
        }
        setAppBusy(false);
    });

    // Withdraw
    document.getElementById('withdrawBtn').addEventListener('click', async () => {
        alert("not implemented!");

        const amount = ethers.utils.parseEther(document.getElementById('amountInput').value);
        try {
            const tx = await vaultContract.withdraw(amount, await signer.getAddress(), await signer.getAddress(), txOptions);
            await tx.wait();
            fetchAll();
        } catch (error) {
            console.error("Withdraw failed:", error);
            alert(JSON.stringify(error));
        }
    });

    document.getElementById('setOperator').addEventListener('click', async () => {
        const operatorAddress = ethers.utils.parseEther(document.getElementById('operatorAddress').value);
        const operatorWeight = Math.floor(parseFloat(document.getElementById("operatorWeight").value));

        try {
            console.log('setOperator', operatorAddress, operatorWeight);
            await waitForTransaction(async () => await holdingPercentage.setOperator(operatorAddress, operatorWeight, txOptions), "set operator weight");
            fetchAll();
        } catch (error) {
            console.error("setOperator failed:", error);
            alert("setOperator failed: " + JSON.stringify(error));
        }
    });


    async function listOperators() {
        const holdingsManagerContract = new ethers.Contract(await vaultContract.holdingsManager(), HoldingsManager_ABI, signer);

        const operators = await holdingsManagerContract.getOperatorsInfo();
        for (let operatorWeightr of operators) {
            console.log(operatorWeightr);

            const address = operatorWeightr.operator;
            
            let metadata = {name: "", logo: "", description: "", website: ""};
            const operatorRecord = operatorsMetadata[chainId][address];
            if (operatorRecord) {
                // use cached
                if (operatorRecord.metadata) {
                    metadata = operatorRecord.metadata;
                } else {
                    try { 
                        metadata = await (await fetch(operatorRecord.metadataUrl)).json();
                        //cache json metadata
                        operatorRecord.metadata = metadata;
                        console.log(address, metadata);
                    } catch(err) {
                        console.error(`failed to retrieve oeprator ${address} on chainId=${chainId} metadata`, err);
                    }
                }
            }

            const info = {...metadata, ...operatorWeightr};
        }
    }

    async function updateHoldingsTable() {
        console.log('updateHoldingsTable');

        let items = [];
        
        const portfolioPositions = await vaultContract.getPortfolio();
        for (let portfolioPosition of portfolioPositions) {
            console.log(portfolioPosition);

            const address = portfolioPosition.operator;
            
       
            let metadata = {name: "", logo: "", description: "", website: ""};
            const operatorRecord = operatorsMetadata[chainId][address];
            if (operatorRecord) {
                // use cached
                if (operatorRecord.metadata) {
                    metadata = operatorRecord.metadata;
                } else {
                    try { 
                        metadata = await (await fetch(operatorRecord.metadataUrl)).json();
                        //cache json metadata
                        operatorRecord.metadata = metadata;
                        console.log(address, metadata);
                    } catch(err) {
                        console.error(`failed to retrieve oeprator ${address} on chainId=${chainId} metadata`, err);
                    }
                }
            }
            
            const vaultTotalShares = await vaultContract.totalSupply();
            const vaultTotalAssets = await vaultContract.totalAssets();
            const vaultSharePrice = vaultTotalAssets / vaultTotalShares;

            const vaultOurShares = await vaultContract.balanceOf(walletAddress);
            const vaultOurAssets = vaultOurShares * vaultSharePrice;
            const rewards = portfolioPosition.rewards;
            const deposited = portfolioPosition.deposited;

            items.push({
                ...metadata, 
                address, 
                vaultTotalShares, 
                vaultTotalAssets,
                vaultSharePrice, 
                vaultOurShares, 
                vaultOurAssets,  
                deposited, 
                rewards,
                assetSymbol,
            });
        }
        updateHoldings(items);
    }

});
