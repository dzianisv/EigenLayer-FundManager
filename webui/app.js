const networks = {
    31337: {name: "localnet", contract: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"},
    17000: {name: "Holesky", contract: "0x1A75E43149A18CFfacA68b86e45df3E47A300149", explorer: "https://holesky.etherscan.io/address"},
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
    "function getOperatorsWeights() public view returns (address[] memory, uint256[] memory)"
];

const operators = {
    17000: {
        "0xbE4B4Fa92b6767FDa2C8D1db53A286834dB19638": {
            "metadata": "https://raw.githubusercontent.com/Layr-Labs/eigendata/master/operators/coinbasecloud/metadata.json"
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
    const assetSymbol = await vaultContract.asset();
    const assetTokenContract = new ethers.Contract(assetSymbol, ERC20_ABI, signer);
    const holdingsManagerContract = new ethers.Contract(await vaultContract.holdingsManager(), HodlingsManager_ABI, signer);

    holdingsManagerContract.get

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
        const symbol = await assetTokenContract.symbol();
        updateInvestedAssets(balance, symbol);
    }

    async function fetchBalance() {
        const balance = await assetTokenContract.balanceOf(walletAddress);
        const symbol = await assetTokenContract.symbol();
        updateWalletAssets(balance, symbol);
    }

    async function fetchAll() {
        await fetchAssets();
        await fetchShares();
        await fetchBalance();
        // await updateHoldingsTable();
    }

    await fetchAll();
    setInterval(() => {
        fetchAll();
    }, 3000);

    // Deposit
    document.getElementById('depositBtn').addEventListener('click', async () => {
        const amount = ethers.utils.parseEther(document.getElementById('amountInput').value);
        try {
            
            {
                console.log("Approve", amount);
                let tx = await assetTokenContract.approve(contractAddress, amount);
                console.log("Watingin for the transactoin", tx);
                console.log("Approved", await tx.wait());
            }

            {
                console.log("Deposit", amount, assetSymbol);
                const tx = await vaultContract.deposit(amount, await signer.getAddress());
                console.log("Watingin for the transactoin", tx);
                console.log("Deposited", await tx.wait());
            }

            fetchAll();
        } catch (error) {
            console.error("Deposit failed", error);
            alert(JSON.stringify(error));
        }
    });

    // Withdraw
    document.getElementById('withdrawBtn').addEventListener('click', async () => {
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
        const operatorStakeBps = Math.floor(parseFloat(document.getElementById("operatorStake").value));

        try {
            const tx = await holdingPercentage.setOperator(operatorAddress, operatorStakeBps, txOptions);
            await tx.wait();
            fetchAll();
        } catch (error) {
            console.error("setOperator failed:", error);
            alert("setOperator failed: " + JSON.stringify(error));
        }
    });


    async function updateHoldingsTable() {
        return;
        console.log('updateHoldingsTable')
        // Fetch the vaults
        const vaultAddresses = await vaultContract.asset();
        const totalAssets = await vaultContract.totalAssets();
        let items = [];

        for (let address of vaultAddresses) {
            // Create ERC4626 contract instance
            const vault = new ethers.Contract(address, ERC4626_ABI, signer); // Ensure you have the ABI for ERC4626

            const perfomanceIndex = await vaultContract.getPerfomanceIndex(address);

            // Fetch the necessary data
            const name = await vault.name();
            const symbol = await vault.symbol();
            const vaultTotalShares = await vault.totalSupply();
            const vaultTotalAssets = await vault.totalAssets();
            const vaultSharePrice = vaultTotalAssets / vaultTotalShares;

            const vaultOurShares = await vault.balanceOf(contractAddress);
            const vaultOurAssets = vaultSharePrice * vaultOurShares;

            let holdingPercentage = 0;
            if (totalAssets > 0) {
                holdingPercentage = (vaultOurAssets / totalAssets) * 100;
            }

            items.push({
                name, symbol, vaultTotalShares, vaultTotalAssets, vaultSharePrice, vaultOurShares, vaultOurAssets,  holdingPercentage, perfomanceIndex
            });
        }
        updateVaults(items);
    }

});
