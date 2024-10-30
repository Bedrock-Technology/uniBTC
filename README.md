# uniBTC

### 1. Compile Contracts

This repository uses submodules to manage dependencies on other repositories.

- Command to clone this repository: `git clone --recurse-submodules git@github.com:Bedrock-Technology/uniBTC.git`.

- If you have already cloned, from the `uniBTC/` directory, run `git submodule update --init --recursive`.

After all submodules are updated as required, you can build contracts with this Brownie command: `brownie compile`.

### 2. Mainnet Deployed Contracts

Please check [here](https://github.com/Bedrock-Technology/uniBTC/tree/main/deployments) for more information.

### 3. Testnet Deployed Contracts

#### 3.1 Bitcoin Ecosystem

| Contract   | B² Testnet                                                                                                                                 | Bitlayer Testnet                                                                                                                              | Merlin Testnet                                                                                                                       |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| ProxyAdmin | [0x56c3024eB229Ca0570479644c78Af9D53472B3e4](https://testnet-explorer.bsquared.network/address/0x56c3024eB229Ca0570479644c78Af9D53472B3e4) | [0x56c3024eb229ca0570479644c78af9d53472b3e4](https://testnet.btrscan.com/address/0x56c3024eb229ca0570479644c78af9d53472b3e4?tab=Transactions) | [0x56c3024eb229ca0570479644c78af9d53472b3e4](https://testnet-scan.merlinchain.io/address/0x56c3024eb229ca0570479644c78af9d53472b3e4) |
| uniBTC     | [0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894](https://testnet-explorer.bsquared.network/address/0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894) | [0x16221CaD160b441db008eF6DA2d3d89a32A05859](https://testnet.btrscan.com/address/0x16221CaD160b441db008eF6DA2d3d89a32A05859?tab=Transactions) | [0x16221CaD160b441db008eF6DA2d3d89a32A05859](https://testnet-scan.merlinchain.io/address/0x16221CaD160b441db008eF6DA2d3d89a32A05859) |
| Vault      | [0x2ac98DB41Cbd3172CB7B8FD8A8Ab3b91cFe45dCf](https://testnet-explorer.bsquared.network/address/0x2ac98DB41Cbd3172CB7B8FD8A8Ab3b91cFe45dCf) | [0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823](https://testnet.btrscan.com/address/0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823?tab=Transactions) | [0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823](https://testnet-scan.merlinchain.io/address/0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823) |
| mockFBTC   | [0xC0c9E78BfC3996E8b68D872b29340816495D7e89](https://testnet-explorer.bsquared.network/address/0xC0c9E78BfC3996E8b68D872b29340816495D7e89) | [0xC0c9E78BfC3996E8b68D872b29340816495D7e89](https://testnet.btrscan.com/address/0xC0c9E78BfC3996E8b68D872b29340816495D7e89?tab=Transactions) | -                                                                                                                                    |
| mockWBTC   | [0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0](https://testnet-explorer.bsquared.network/address/0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0) | [0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0](https://testnet.btrscan.com/address/0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0?tab=Transactions) | -                                                                                                                                    |
| mockWBTC18 | [0x4ed4739E6F6820f2357685592168f6C6c003714f](https://testnet-explorer.bsquared.network/address/0x4ed4739E6F6820f2357685592168f6C6c003714f) | [0x1d481E87C3f3C967Ad8F17156A99D69D0052dC67](https://testnet.btrscan.com/address/0x1d481E87C3f3C967Ad8F17156A99D69D0052dC67?tab=Transactions) | -                                                                                                                                    |
| mockmBTC   | -                                                                                                                                          | -                                                                                                                                             | [0x2F9Ae77C5955c68c2Fbbca2b5b9F917e90929f7b](https://testnet-scan.merlinchain.io/address/0x2F9Ae77C5955c68c2Fbbca2b5b9F917e90929f7b) |

#### 3.2 Ethereum Ecosystem

| Contract   | Holesky Testnet                                                                                                               | Avalanche Fuji Testnet                                                                                                        | BSC Testnet                                                                                                                  | Fantom Testnet                                                                                                               |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| ProxyAdmin | [0xC0c9E78BfC3996E8b68D872b29340816495D7e89](https://holesky.etherscan.io/address/0xC0c9E78BfC3996E8b68D872b29340816495D7e89) | [0x8746649B65eA03A22e559Eb03059018baEDFBA9e](https://testnet.snowtrace.io/address/0x8746649B65eA03A22e559Eb03059018baEDFBA9e) | [0x49D6844cbcef64952E6793677eeaBae324f895aD](https://testnet.bscscan.com/address/0x49D6844cbcef64952E6793677eeaBae324f895aD) | [0x8746649B65eA03A22e559Eb03059018baEDFBA9e](https://testnet.ftmscan.com/address/0x8746649B65eA03A22e559Eb03059018baEDFBA9e) |
| uniBTC     | [0x16221CaD160b441db008eF6DA2d3d89a32A05859](https://holesky.etherscan.io/address/0x16221CaD160b441db008eF6DA2d3d89a32A05859) | [0x2c914Ba874D94090Ba0E6F56790bb8Eb6D4C7e5f](https://testnet.snowtrace.io/address/0x2c914Ba874D94090Ba0E6F56790bb8Eb6D4C7e5f) | [0x2c914ba874d94090ba0e6f56790bb8eb6d4c7e5f](https://testnet.bscscan.com/address/0x2c914ba874d94090ba0e6f56790bb8eb6d4c7e5f) | [0x802d4900209b2292bf7f07ecae187f836040a709](https://testnet.ftmscan.com/address/0x802d4900209b2292bf7f07ecae187f836040a709) |
| Vault      | [0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823](https://holesky.etherscan.io/address/0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823) | [0x85792f60633DBCF7c2414675bcC0a790B1b65CbB](https://testnet.snowtrace.io/address/0x85792f60633DBCF7c2414675bcC0a790B1b65CbB) | [0x85792f60633dbcf7c2414675bcc0a790b1b65cbb](https://testnet.bscscan.com/address/0x85792f60633dbcf7c2414675bcc0a790b1b65cbb) | [0x06c186ff3a0da2ce668e5b703015f3134f4a88ad](https://testnet.ftmscan.com/address/0x06c186ff3a0da2ce668e5b703015f3134f4a88ad) |
| Peer       | [0x6EFc200c769E54DAab8fcF2d339b79F92cFf4EC9](https://holesky.etherscan.io/address/0x6EFc200c769E54DAab8fcF2d339b79F92cFf4EC9) | [0xe7431fc992a54fAA435125Ca94E00B4a8c89095c](https://testnet.snowtrace.io/address/0xe7431fc992a54fAA435125Ca94E00B4a8c89095c) | [0xd59677a6efe9151c0131e8cf174c8bbceb536005](https://testnet.bscscan.com/address/0xd59677a6efe9151c0131e8cf174c8bbceb536005) | [0xe7431fc992a54faa435125ca94e00b4a8c89095c](https://testnet.ftmscan.com/address/0xe7431fc992a54faa435125ca94e00b4a8c89095c) |
| mockFBTC   | [0x5C367C804ce9F00464Cba3199d6Fb646E8287146](https://holesky.etherscan.io/address/0x5C367C804ce9F00464Cba3199d6Fb646E8287146) | [0xEB74BB04aD28b9b7ec1f2fd1812e7242170C6d1B](https://testnet.snowtrace.io/address/0xEB74BB04aD28b9b7ec1f2fd1812e7242170C6d1B) | [0xc87E37848B913f289Aee0E2A9d3Ed94bA98D2A60](https://testnet.bscscan.com/address/0xc87E37848B913f289Aee0E2A9d3Ed94bA98D2A60) | [0xeb74bb04ad28b9b7ec1f2fd1812e7242170c6d1b](https://testnet.ftmscan.com/address/0xeb74bb04ad28b9b7ec1f2fd1812e7242170c6d1b) |
| mockWBTC   | [0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0](https://holesky.etherscan.io/address/0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0) | [0x49D6844cbcef64952E6793677eeaBae324f895aD](https://testnet.snowtrace.io/address/0x49D6844cbcef64952E6793677eeaBae324f895aD) | [0xe7431fc992a54faa435125ca94e00b4a8c89095c](https://testnet.bscscan.com/address/0xe7431fc992a54faa435125ca94e00b4a8c89095c) | [0x49d6844cbcef64952e6793677eeabae324f895ad](https://testnet.ftmscan.com/address/0x49d6844cbcef64952e6793677eeabae324f895ad) |

#### 3.3 L1 Blockchains

| Contract   | Berachain Testnet                                                                                                            |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------- |
| ProxyAdmin | [0xC0c9E78BfC3996E8b68D872b29340816495D7e89](https://bartio.beratrail.io/address/0xC0c9E78BfC3996E8b68D872b29340816495D7e89) |
| uniBTC     | [0x16221CaD160b441db008eF6DA2d3d89a32A05859](https://bartio.beratrail.io/address/0x16221CaD160b441db008eF6DA2d3d89a32A05859) |
| Vault      | [0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823](https://bartio.beratrail.io/address/0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823) |
| mockedWBTC | [0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0](https://bartio.beratrail.io/address/0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0) |
| WBTC       | [0x286F1C3f0323dB9c91D1E8f45c8DF2d065AB5fae](https://bartio.beratrail.io/address/0x286F1C3f0323dB9c91D1E8f45c8DF2d065AB5fae) |

### 4. Error Codes from contracts

1. SYS001: INVALID_ADDRESS
1. SYS002: TOKEN_PAUSED
1. SYS003: INVALID_TOKEN_ADDRESS
1. SYS004: INCORRECT_DECIMALS
1. SYS005: MINIMUM_VALUE_SHOULD_BE_A_POSITIVE_MULTIPLE_OF_100000
1. SYS006: INVALID_INPUT_ARRAY_LENGTHS
1. SYS007: CHAIN_ID_CANNOT_BE_ZERO
1. SYS008: INVALID_PEER_ADDRESS
1. SYS009: IRREDEEMABLE_STATUS
1. SYS010: INCONSISTENT_DECIMALS
1. SYS011: OUT_OF_SERVICE
1. SYS012: NATIVE_BTC_NOT_SUPPORTED
1. USR001: UNIBTC: LEAST_ONE_RECIPIENT_ADDRESS
1. USR002: UNIBTC: NUMBER_OF_RECIPIENT_ADDRESSES_DOES_NOT_MATCH_THE_NUMBER_OF_TOKENS
1. USR003: INSUFFICIENT_QUOTA
1. USR004: INVALID_CHAINID
1. USR005: DESTINATION_PEER_DOES_NOT_EXIST
1. USR006: INVALID_AMOUNT_TO_TRANSFER
1. USR007: TRANSFER_TO_THE_ZERO_ADDRESS
1. USR008: INCORRECT_FEE
1. USR009: ILLEGAL_REMOTE_CALLER
1. USR010: INSUFFICIENT_AMOUNT
1. USR011: INVALID_SLIPPAGE
1. USR012: SET_DELAY_REDEEM_BLOCK_TOO_LARGE
1. USR013: SET_DAY_CAP_TOO_LARGE
1. USR014: AMOUNT_TOO_LESS
1. USR015: AMOUNT_TOO_MORE
1. USR016: CAN_ONLY_TRANSFER_TO_DEDICATED_RECIPIENT
1. USR017: TOKEN_CAP_ERROR
1. USR018: NO_POOLS_FOR_LEADING_TOKEN
1. USR019: PRINCIPAL_REDEEM_TIME_MISMATCH
1. USR020: VARIABLE_VALUE_IS_EXITED
1. USR021: VARIABLE_VALUE_IS_INVALID
1. USR022: VARIABLE_VALUE_IS_NOT_EXITED
1. USR023: SIGN_ERROR
1. USR024: SYS_SIGNER_NOT_SET
1. USR025: CALL_FAILED
1. USR026: NOT_EOA
