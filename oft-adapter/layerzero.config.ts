import { EndpointId } from '@layerzerolabs/lz-definitions'

import type { OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

// const zksyncContract: OmniPointHardhat = {
//     eid: EndpointId.SEPOLIA_V2_TESTNET,
//     contractName: 'MyOFT',
// }

// const blastContract: OmniPointHardhat = {
//     eid: EndpointId.AVALANCHE_V2_TESTNET,
//     contractName: 'MyOFT',
// }

// const amoyContract: OmniPointHardhat = {
//     eid: EndpointId.AMOY_V2_TESTNET,
//     contractName: 'MyOFT',
// }

const blastContract: OmniPointHardhat = {
    eid: EndpointId.BLAST_V2_MAINNET,
    address: '0x39655DD658a1bB9CD090c793f83d2e355D97D94E',
}

const zksyncContract: OmniPointHardhat = {
    eid: EndpointId.ZKSYNC_V2_MAINNET,
    address: '0x7a77B4003DC499c82D4A7A7e8fF340cA8308f9eb',
}

const config: OAppOmniGraphHardhat = {
    contracts: [
        {
            contract: blastContract,
        },
        {
            contract: zksyncContract,
        },
    ],
    connections: [
        {
            from: blastContract,
            to: zksyncContract,
        },
        {
            from: zksyncContract,
            to: blastContract,
        },
    ],
}

export default config
