import { ethers } from 'hardhat';

async function main() {
    const RaffleContract = await ethers.getContractFactory('RaffleContract');
    const UsdcContract = await ethers.getContractFactory('UsdcContract');
    const usdccontract = await UsdcContract.deploy();
    await usdccontract.deployed();

    const usdcAddress = usdccontract.address;
    const nftAddress = '0xEFAA837e146F9c22edF559B05eddf4FF56772A78';
    const raffleContract = await RaffleContract.deploy(usdcAddress, nftAddress);

    await raffleContract.deployed();

    console.log('usdc deployed to:', usdccontract.address);
    console.log('RaffleContract deployed to:', raffleContract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
