import * as dotenv from 'dotenv';

import { HardhatUserConfig } from 'hardhat/config';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-gas-reporter';
import 'solidity-coverage';

dotenv.config();

const config: HardhatUserConfig = {
    defaultNetwork: 'hardhat',
    solidity: '0.8.10',
    networks: {
        hardhat: {
            chainId: 1337
        },
        ropsten: {
            url: process.env.ROPSTEN_URL || '',
            accounts:
                process.env.PRIVATE_KEY !== undefined
                    ? [process.env.PRIVATE_KEY]
                    : []
        },
        fuji: {
            url: process.env.ROPSTEN_URL || '',
            gasPrice: 225000000000,
            chainId: 43113,
            accounts:
                process.env.PRIVATE_KEY !== undefined
                    ? [process.env.PRIVATE_KEY]
                    : []
        }
    },
    etherscan: {
        apiKey: process.env.API_KEY
    }
};

export default config;
