# uniBTC


### 1. Compile Contracts
You need to update the submodules that this repository depends on to the required commits before building contracts with the following steps:

- (1) Clone all submodules before checking out any tags or commits. From the `uniBTC/` directory, run `git submodule update --init --recursive`. <br>
- (2) Checkout the celer-network commit. From the `uniBTC/contracts/lib/celer-network/sgn-v2-contracts-main/`, run `git checkout 0b4c531c52fd4f23cbb4397440da1cc42f837a12`. <br>
- (3) Checkout openzeppelin-contracts. From the `uniBTC/contracts/lib/OpenZeppelin/openzeppelin-contracts@4.8.3/`, run `git checkout v4.8.3`. <br>
- (4) Checkout openzeppelin-contracts-upgradeable. From the `uniBTC/contracts/lib/OpenZeppelin/openzeppelin-contracts-upgradeable@4.8.3/`, run `git checkout v4.8.3`. <br>

After all submodules updated as required, you can run the following command from the `uniBTC/contracts/` to build contracts: `brownie compile`

### 2. Deployed Contracts
**Ethereum Mainnet Deployment**

- [ProxyAdmin](https://etherscan.io/address/0x029E4FbDAa31DE075dD74B2238222A08233978f6): 0x029E4FbDAa31DE075dD74B2238222A08233978f6
- [uniBTC](https://etherscan.io/address/0x004e9c3ef86bc1ca1f0bb5c7662861ee93350568): 0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568
- [Vault](https://etherscan.io/address/0x047d41f2544b7f63a8e991af2068a363d210d6da): 0x047D41F2544B7F63A8e991aF2068a363d210d6Da

**Holesky Testnet Deployment**

- [ProxyAdmin](https://holesky.etherscan.io/address/0xC0c9E78BfC3996E8b68D872b29340816495D7e89): 0xC0c9E78BfC3996E8b68D872b29340816495D7e89
- [mockFBTC](https://holesky.etherscan.io/address/0x087133ECddD986Da71e9b055d58964d3d7d8dc03): 0x087133ECddD986Da71e9b055d58964d3d7d8dc03
- [mockWBTC](https://holesky.etherscan.io/address/0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0): 0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0
- [uniBTC](https://holesky.etherscan.io/address/0x16221CaD160b441db008eF6DA2d3d89a32A05859): 0x16221CaD160b441db008eF6DA2d3d89a32A05859
- [Vault](https://holesky.etherscan.io/address/0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823): 0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823
- [Peer](): No deployment because [Celer](https://im-docs.celer.network/developer/contract-addresses-and-rpc-info) Network doesn't support the [Holesky](https://holesky.etherscan.io/) Testnet currently.


**Avalanche C-Chain Fuji Testnet Deployment**

- [ProxyAdmin](https://testnet.snowtrace.io/address/0x8746649B65eA03A22e559Eb03059018baEDFBA9e): 0x8746649B65eA03A22e559Eb03059018baEDFBA9e
- [mockFBTC](https://testnet.snowtrace.io/address/0xEB74BB04aD28b9b7ec1f2fd1812e7242170C6d1B): 0xEB74BB04aD28b9b7ec1f2fd1812e7242170C6d1B
- [mockWBTC](https://testnet.snowtrace.io/address/0x49D6844cbcef64952E6793677eeaBae324f895aD): 0x49D6844cbcef64952E6793677eeaBae324f895aD
- [uniBTC](https://testnet.snowtrace.io/address/0x2c914Ba874D94090Ba0E6F56790bb8Eb6D4C7e5f): 0x2c914Ba874D94090Ba0E6F56790bb8Eb6D4C7e5f
- [Vault](https://testnet.snowtrace.io/address/0x85792f60633DBCF7c2414675bcC0a790B1b65CbB): 0x85792f60633DBCF7c2414675bcC0a790B1b65CbB
- [Peer](https://testnet.snowtrace.io/address/0xe7431fc992a54fAA435125Ca94E00B4a8c89095c): 0xe7431fc992a54fAA435125Ca94E00B4a8c89095c        


**BSC Testnet Deployment**

- [ProxyAdmin](https://testnet.bscscan.com/address/0x49D6844cbcef64952E6793677eeaBae324f895aD): 0x49D6844cbcef64952E6793677eeaBae324f895aD
- [mockFBTC](https://testnet.bscscan.com/address/0xc87E37848B913f289Aee0E2A9d3Ed94bA98D2A60): 0xc87E37848B913f289Aee0E2A9d3Ed94bA98D2A60
- [mockWBTC](https://testnet.bscscan.com/address/0xe7431fc992a54faa435125ca94e00b4a8c89095c): 0xe7431fc992a54fAA435125Ca94E00B4a8c89095c
- [uniBTC](https://testnet.bscscan.com/address/0x2c914ba874d94090ba0e6f56790bb8eb6d4c7e5f): 0x2c914Ba874D94090Ba0E6F56790bb8Eb6D4C7e5f
- [Vault](https://testnet.bscscan.com/address/0x85792f60633dbcf7c2414675bcc0a790b1b65cbb): 0x85792f60633DBCF7c2414675bcC0a790B1b65CbB
- [Peer](https://testnet.bscscan.com/address/0xd59677a6efe9151c0131e8cf174c8bbceb536005): 0xd59677a6eFe9151c0131E8cF174C8BBCEB536005


**Fantom Testnet Deployment**

- [ProxyAdmin](https://testnet.ftmscan.com/address/0x8746649B65eA03A22e559Eb03059018baEDFBA9e): 0x8746649B65eA03A22e559Eb03059018baEDFBA9e
- [mockFBTC](https://testnet.ftmscan.com/address/0xeb74bb04ad28b9b7ec1f2fd1812e7242170c6d1b): 0xEB74BB04aD28b9b7ec1f2fd1812e7242170C6d1B
- [mockWBTC](https://testnet.ftmscan.com/address/0x49d6844cbcef64952e6793677eeabae324f895ad): 0x49D6844cbcef64952E6793677eeaBae324f895aD
- [uniBTC](https://testnet.ftmscan.com/address/0x802d4900209b2292bf7f07ecae187f836040a709): 0x802d4900209b2292bF7f07ecAE187f836040A709
- [Vault](https://testnet.ftmscan.com/address/0x06c186ff3a0da2ce668e5b703015f3134f4a88ad): 0x06c186Ff3a0dA2ce668E5B703015f3134F4a88Ad
- [Peer](https://testnet.ftmscan.com/address/0xe7431fc992a54faa435125ca94e00b4a8c89095c): 0xe7431fc992a54fAA435125Ca94E00B4a8c89095c


### 3. Error Codes from contracts
1. SYS001: INVALID_WBTC_ADDRESS
1. SYS002: INVALID_UNIBTC_ADDRESS
1. SYS003: WBTC_PAUSED
1. SYS004: TOKEN_PAUSED
1. SYS005: INVALID_TOKEN_ADDRESS
1. SYS006: INCORRECT_DECIMALS
1. SYS007: MINIMUM_VALUE_SHOULD_BE_A_POSITIVE_MULTIPLE_OF_100000
1. SYS008: INVALID_INPUT_ARRAY_LENGTHS
1. SYS009: CHAIN_ID_CANNOT_BE_ZERO
1. SYS010: INVALID_PEER_ADDRESS
1. SYS011: IRREDEEMABLE_STATUS
1. USR001: UNIBTC: LEAST_ONE_RECIPIENT_ADDRESS
1. USR002: UNIBTC: NUMBER_OF_RECIPIENT_ADDRESSES_DOES_NOT_MATCH_THE_NUMBER_OF_TOKENS
1. USR003: INSUFFICIENT_QUOTA
1. USR004: INVALID_CHAINID
1. USR005: DESTINATION_PEER_DOES_NOT_EXIST
1. USR006: INVALID_AMOUNT_TO_TRANSFER
1. USR007: TRANSFER_TO_THE_ZERO_ADDRESS
1. USR008: INCORRECT_FEE
1. USR009: ILLEGAL_REMOTE_CALLER
2. USR010: INSUFFICIENT_AMOUNT