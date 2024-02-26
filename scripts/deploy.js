
const hre = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const routerAbi = require("../artifacts/@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol/ISwapRouter.json");
const erc20Abi = require("../artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json");
const swapAddAbi = require("../artifacts/contracts/swapAdd.sol/SwapAddLiquidityV3.json")
const {parseUnits, Interface, AbiCoder} = require("ethers");

async function main() {
  
  const hugeNumber = 115792089237316195423570985008687907853n;

  // Impersonate address
  const address = "0xf89d7b9c864f589bbF53a82105107622B35EaA40";
  await helpers.impersonateAccount(address);
  const impersonatedSigner = await hre.ethers.getSigner(address);
  console.log("Impersonated signer:", await impersonatedSigner.getAddress());

  const amountIn = 100 * 1e6;

  const swapRouter = '0x1b81D678ffb9C0263b24A97847620C99d213eB14';
  const nonFungiblePositionManager = '0x46A15B0b27311cedF172AB29E4f4766fbE7F4364';

  const USDT = '0x55d398326f99059fF775485246999027B3197955';
  const USDC = '0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d';

  // Approve tokens
  const usdtContract = new hre.ethers.Contract(USDT, erc20Abi.abi, hre.ethers.provider);
  const usdccontract = new hre.ethers.Contract(USDC, erc20Abi.abi, hre.ethers.provider);

  // Deploy swap contract
  const swapadd = await hre.ethers.deployContract("SwapAddLiquidityV3", [swapRouter, nonFungiblePositionManager], {});
  await swapadd.waitForDeployment();
  const swapaddAddress = await swapadd.getAddress();
  console.log("SwapAddLiquidityV3 deployed to:", swapaddAddress);

  // Currently vulnerable to bots
  const params = {
      tokenIn: USDT,
      tokenOut: USDC,
      fee: 100,
      recipient: swapaddAddress,
      deadline: Math.floor(Date.now() / 1000 + (10 * 60)),
      amountIn,
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0,
  };

  await usdtContract.connect(impersonatedSigner).approve(swapaddAddress, hugeNumber);
  await usdccontract.connect(impersonatedSigner).approve(swapaddAddress, hugeNumber);

  console.log("Approval done");

  const abiCoder = new AbiCoder();

  const myData = abiCoder.encode(
    routerAbi.abi[1].inputs,
    [params]
  );

  const iface = new Interface(swapAddAbi.abi);
  const Data = iface.encodeFunctionData('swapAndAddLiquidity', [myData]);
  const tx = {
    to: swapaddAddress, // The contract address
    data: Data, // The encoded function call data
  };

  // Send the transaction
  const txResponse = await impersonatedSigner.sendTransaction(tx);

  // Wait for the transaction to be mined
  const receipt = await txResponse.wait();

  console.log('Transaction receipt:', receipt);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
