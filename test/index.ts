import { expect } from 'chai';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { RaffleContract, RaffleContract__factory } from '../typechain-types';

describe('RarestNft', async () => {
    let raffleContract: RaffleContract;
    let owner: SignerWithAddress;
    let addr1: SignerWithAddress;
    let addrs: SignerWithAddress[];
    beforeEach(async () => {
        [owner, addr1, ...addrs] = await ethers.getSigners();
        let [USDC]: string[] = await ethers.provider.listAccounts();
        const raffleContractFactory = (await ethers.getContractFactory(
            'RaffleContract',
            owner
        )) as RaffleContract__factory;
        raffleContract = await raffleContractFactory.deploy(USDC);
        await raffleContract.deployed();
    });
});
