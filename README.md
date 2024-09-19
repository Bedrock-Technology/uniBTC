# uniBTC


### 1. Compile Contracts
This repository uses submodules to manage dependencies on other repositories.

- Command to clone this repository: `git clone --recurse-submodules git@github.com:Bedrock-Technology/uniBTC.git`.

- If you have already cloned, from the `uniBTC/` directory, run `git submodule update --init --recursive`.

After all submodules are updated as required, you can build contracts with this Brownie command: `brownie compile`.

### 2. Mainnet Deployed Contracts
#### 2.1 Bitcoin Ecosystem

| Contract             | B² Mainnet                                                                                                                         | Bitlayer Mainnet                                                                                                                          | Merlin Mainnet                                                                                                               |
|----------------------|------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| ProxyAdmin           | [0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19](https://explorer.bsquared.network/address/0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19) | [0x0a3f2582ff649fcaf67d03483a8ed1a82745ea19](https://www.btrscan.com/address/0x0a3f2582ff649fcaf67d03483a8ed1a82745ea19?tab=Transactions) | [0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19](https://scan.merlinchain.io/address/0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19) |
| uniBTC               | [0x93919784C523f39CACaa98Ee0a9d96c3F32b593e](https://explorer.bsquared.network/address/0x93919784C523f39CACaa98Ee0a9d96c3F32b593e) | [0x93919784C523f39CACaa98Ee0a9d96c3F32b593e](https://www.btrscan.com/address/0x93919784C523f39CACaa98Ee0a9d96c3F32b593e?tab=Transactions) | [0x93919784C523f39CACaa98Ee0a9d96c3F32b593e](https://scan.merlinchain.io/address/0x93919784C523f39CACaa98Ee0a9d96c3F32b593e) |
| Vault                | [0xF9775085d726E782E83585033B58606f7731AB18](https://explorer.bsquared.network/address/0xF9775085d726E782E83585033B58606f7731AB18) | [0xF9775085d726E782E83585033B58606f7731AB18](https://www.btrscan.com/address/0xF9775085d726E782E83585033B58606f7731AB18?tab=Transactions) | [0xF9775085d726E782E83585033B58606f7731AB18](https://scan.merlinchain.io/address/0xF9775085d726E782E83585033B58606f7731AB18) |
| WBTC                 | [0x4200000000000000000000000000000000000006](https://explorer.bsquared.network/address/0x4200000000000000000000000000000000000006) | [0xfF204e2681A6fA0e2C3FaDe68a1B28fb90E4Fc5F](https://www.btrscan.com/address/0xfF204e2681A6fA0e2C3FaDe68a1B28fb90E4Fc5F?tab=Transactions) | [0xF6D226f9Dc15d9bB51182815b320D3fBE324e1bA](https://scan.merlinchain.io/address/0xF6D226f9Dc15d9bB51182815b320D3fBE324e1bA) |
| M-BTC                | -                                                                                                                                  | -                                                                                                                                         | [0xB880fd278198bd590252621d4CD071b1842E9Bcd](https://scan.merlinchain.io/address/0xB880fd278198bd590252621d4CD071b1842E9Bcd) |
| BitLayerNativeProxy  | - | [0xcb28dab5e89f6bf2feb2de200564baff77d59957](https://www.btrscan.com/address/0xcb28dab5e89f6bf2feb2de200564baff77d59957?tab=Transactions)| - |                                                                                                                           |

#### 2.2 Ethereum Ecosystem

| Contract | Ethereum Mainnet | Mantle Mainnet | Optimism Mainnet | Mode Mainnet | Arbitrum Mainnet                                                                                                     |
|------------|-------------|--------|-------|-------|----------------------------------------------------------------------------------------------------------------------|
| ProxyAdmin | [0x029E4FbDAa31DE075dD74B2238222A08233978f6](https://etherscan.io/address/0x029E4FbDAa31DE075dD74B2238222A08233978f6) | [0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19](https://mantlescan.xyz/address/0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19) | [0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19](https://optimistic.etherscan.io/address/0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19)  | [0xb3f925B430C60bA467F7729975D5151c8DE26698](https://modescan.io/address/0xb3f925B430C60bA467F7729975D5151c8DE26698) | [0xb3f925B430C60bA467F7729975D5151c8DE26698](https://arbiscan.io/address/0xb3f925B430C60bA467F7729975D5151c8DE26698) |
| uniBTC | [0x004e9c3ef86bc1ca1f0bb5c7662861ee93350568](https://etherscan.io/address/0x004e9c3ef86bc1ca1f0bb5c7662861ee93350568) | [0x93919784C523f39CACaa98Ee0a9d96c3F32b593e](https://mantlescan.xyz/address/0x93919784C523f39CACaa98Ee0a9d96c3F32b593e) | [0x93919784C523f39CACaa98Ee0a9d96c3F32b593e](https://optimistic.etherscan.io/address/0x93919784C523f39CACaa98Ee0a9d96c3F32b593e) | [0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a](https://modescan.io/address/0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a) | [0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a](https://arbiscan.io/address/0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a) |
| Vault | [0x047d41f2544b7f63a8e991af2068a363d210d6da](https://etherscan.io/address/0x047d41f2544b7f63a8e991af2068a363d210d6da) | [0xF9775085d726E782E83585033B58606f7731AB18](https://mantlescan.xyz/address/0xF9775085d726E782E83585033B58606f7731AB18) | [0xF9775085d726E782E83585033B58606f7731AB18](https://optimistic.etherscan.io/address/0xF9775085d726E782E83585033B58606f7731AB18) | [0x84E5C854A7fF9F49c888d69DECa578D406C26800](https://modescan.io/token/0x84E5C854A7fF9F49c888d69DECa578D406C26800) | [0x84E5C854A7fF9F49c888d69DECa578D406C26800](https://arbiscan.io/address/0x84E5C854A7fF9F49c888d69DECa578D406C26800) |
| FBTCProxy | [0x56c3024eB229Ca0570479644c78Af9D53472B3e4](https://etherscan.io/address/0x56c3024eB229Ca0570479644c78Af9D53472B3e4) | [0x56c3024eB229Ca0570479644c78Af9D53472B3e4](https://explorer.mantle.xyz/address/0x56c3024eB229Ca0570479644c78Af9D53472B3e4) | - | - | -                                                                                                                    |
| LockedFBTC | [0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c](https://etherscan.io/address/0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c) | [0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c](https://explorer.mantle.xyz/address/0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c) | - | - | -                                                                                                                    |
| FBTC | [0xc96de26018a54d51c097160568752c4e3bd6c364](https://etherscan.io/address/0xc96de26018a54d51c097160568752c4e3bd6c364) | [0xc96de26018a54d51c097160568752c4e3bd6c364](https://mantlescan.xyz/address/0xc96de26018a54d51c097160568752c4e3bd6c364) | - | - | -                                                                                                                    |
| WBTC | [0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599](https://etherscan.io/address/0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) | - | [0x68f180fcCe6836688e9084f035309E29Bf0A2095](https://optimistic.etherscan.io/address/0x68f180fcCe6836688e9084f035309E29Bf0A2095) | [0xcDd475325D6F564d27247D1DddBb0DAc6fA0a5CF](https://modescan.io/token/0xcDd475325D6F564d27247D1DddBb0DAc6fA0a5CF) | [0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f](https://arbiscan.io/address/0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f) |
| M-BTC | - | - | - | [0x59889b7021243dB5B1e065385F918316cD90D46c](https://modescan.io/token/0x59889b7021243dB5B1e065385F918316cD90D46c) | -                                                                                                                    |


#### 2.3 Hybrid L2 Ecosystem
**BOB Mainnet Deployment**

| Contract | BOB Mainnet |
|------------|-------------|
| ProxyAdmin | [0x56c3024eB229Ca0570479644c78Af9D53472B3e4](https://explorer.gobob.xyz/address/0x56c3024eB229Ca0570479644c78Af9D53472B3e4) |
| uniBTC | [0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894](https://explorer.gobob.xyz/address/0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894) |
| Vault | [0x2ac98DB41Cbd3172CB7B8FD8A8Ab3b91cFe45dCf](https://explorer.gobob.xyz/address/0x2ac98DB41Cbd3172CB7B8FD8A8Ab3b91cFe45dCf) |
| WBTC | [0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3](https://explorer.gobob.xyz/address/0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3) |


#### 2.4 L1 Blockchains
**ZetaChain Mainnet Deployment**

| Contract   | ZetaChain Mainnet                                                                                                                 | BSC Mainnet                                                                                                           |
|------------|-----------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------|
| ProxyAdmin | [0xb3f925B430C60bA467F7729975D5151c8DE26698](https://zetachain.blockscout.com/address/0xb3f925B430C60bA467F7729975D5151c8DE26698) | [0xb3f925B430C60bA467F7729975D5151c8DE26698](https://bscscan.com/address/0xb3f925B430C60bA467F7729975D5151c8DE26698)  |
| uniBTC     | [0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a](https://zetachain.blockscout.com/address/0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a) | [0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a](https://bscscan.com/address/0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a)  |
| Vault      | [0x84E5C854A7fF9F49c888d69DECa578D406C26800](https://zetachain.blockscout.com/address/0x84E5C854A7fF9F49c888d69DECa578D406C26800) | [0x84E5C854A7fF9F49c888d69DECa578D406C26800](https://bscscan.com/address/0x84E5C854A7fF9F49c888d69DECa578D406C26800)  |
| zBTC       | [0x13A0c5930C028511Dc02665E7285134B6d11A5f4](https://zetachain.blockscout.com/address/0x13A0c5930C028511Dc02665E7285134B6d11A5f4) | -                                                                                                                     |
| FBTC       | -                                                                                                                                 | [0xC96dE26018A54D51c097160568752c4E3BD6C364](https://bscscan.com/address/0xC96dE26018A54D51c097160568752c4E3BD6C364)  |                                                                                                                    
| BTCB       | -                                                                                                                                 | [0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c](https://bscscan.com/address/0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c)  |                                                                                                                    

#### 2.5 Chainlink Adapters Deployment

| Contract    | Ethereum Mainnet                                                                                                      | Optimism Mainnet                                                                                                                  | Arbitrum Mainnet                                                                                                 |
|-------------|-----------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| uniBTCRate  | [0xf6f6F27A38e5CFb94954200b01B1c4Bf621A56EA](https://etherscan.io/address/0xf6f6F27A38e5CFb94954200b01B1c4Bf621A56EA) | [0x56c3024eB229Ca0570479644c78Af9D53472B3e4](https://optimistic.etherscan.io/address/0x56c3024eB229Ca0570479644c78Af9D53472B3e4)  | [0xBE43aE6E89c2c74B49cfAB956a9E36a35B5fdE06](https://arbiscan.io/address/0xBE43aE6E89c2c74B49cfAB956a9E36a35B5fdE06) |
| uniBTCRawBTCExchangeRateChainlinkAdapter| [0xb3f925B430C60bA467F7729975D5151c8DE26698](https://etherscan.io/address/0xb3f925B430C60bA467F7729975D5151c8DE26698)                                                                                                                  | [0xb3f925B430C60bA467F7729975D5151c8DE26698](https://optimistic.etherscan.io/address/0xb3f925B430C60bA467F7729975D5151c8DE26698)  | [0x4DFfCaf5d0B3B83a31405443bF5A4D6a3F9903F5](https://arbiscan.io/address/0x4DFfCaf5d0B3B83a31405443bF5A4D6a3F9903F5) |                                                                                                                |                                                                                                                    |


### 3. Testnet Deployed Contracts
#### 3.1 Bitcoin Ecosystem

| Contract | B² Testnet  | Bitlayer Testnet | Merlin Testnet |
|------------|-------------|--------|-------|
| ProxyAdmin | [0x56c3024eB229Ca0570479644c78Af9D53472B3e4](https://testnet-explorer.bsquared.network/address/0x56c3024eB229Ca0570479644c78Af9D53472B3e4)  | [0x56c3024eb229ca0570479644c78af9d53472b3e4](https://testnet.btrscan.com/address/0x56c3024eb229ca0570479644c78af9d53472b3e4?tab=Transactions) | [0x56c3024eb229ca0570479644c78af9d53472b3e4](https://testnet-scan.merlinchain.io/address/0x56c3024eb229ca0570479644c78af9d53472b3e4) |
| uniBTC | [0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894](https://testnet-explorer.bsquared.network/address/0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894) | [0x16221CaD160b441db008eF6DA2d3d89a32A05859](https://testnet.btrscan.com/address/0x16221CaD160b441db008eF6DA2d3d89a32A05859?tab=Transactions) | [0x16221CaD160b441db008eF6DA2d3d89a32A05859](https://testnet-scan.merlinchain.io/address/0x16221CaD160b441db008eF6DA2d3d89a32A05859) |
| Vault | [0x2ac98DB41Cbd3172CB7B8FD8A8Ab3b91cFe45dCf](https://testnet-explorer.bsquared.network/address/0x2ac98DB41Cbd3172CB7B8FD8A8Ab3b91cFe45dCf) | [0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823](https://testnet.btrscan.com/address/0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823?tab=Transactions) | [0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823](https://testnet-scan.merlinchain.io/address/0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823) |
| mockFBTC | [0xC0c9E78BfC3996E8b68D872b29340816495D7e89](https://testnet-explorer.bsquared.network/address/0xC0c9E78BfC3996E8b68D872b29340816495D7e89) | [0xC0c9E78BfC3996E8b68D872b29340816495D7e89](https://testnet.btrscan.com/address/0xC0c9E78BfC3996E8b68D872b29340816495D7e89?tab=Transactions) | - |
| mockWBTC | [0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0](https://testnet-explorer.bsquared.network/address/0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0) | [0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0](https://testnet.btrscan.com/address/0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0?tab=Transactions) | - |
| mockWBTC18 | [0x4ed4739E6F6820f2357685592168f6C6c003714f](https://testnet-explorer.bsquared.network/address/0x4ed4739E6F6820f2357685592168f6C6c003714f) | [0x1d481E87C3f3C967Ad8F17156A99D69D0052dC67](https://testnet.btrscan.com/address/0x1d481E87C3f3C967Ad8F17156A99D69D0052dC67?tab=Transactions) | - |
| mockmBTC | -  | - | [0x2F9Ae77C5955c68c2Fbbca2b5b9F917e90929f7b](https://testnet-scan.merlinchain.io/address/0x2F9Ae77C5955c68c2Fbbca2b5b9F917e90929f7b) |


#### 3.2 Ethereum Ecosystem

| Contract | Holesky Testnet | Avalanche Fuji Testnet | BSC Testnet | Fantom Testnet |
|------------|-------------|--------|-------|-------|
| ProxyAdmin | [0xC0c9E78BfC3996E8b68D872b29340816495D7e89](https://holesky.etherscan.io/address/0xC0c9E78BfC3996E8b68D872b29340816495D7e89) | [0x8746649B65eA03A22e559Eb03059018baEDFBA9e](https://testnet.snowtrace.io/address/0x8746649B65eA03A22e559Eb03059018baEDFBA9e) | [0x49D6844cbcef64952E6793677eeaBae324f895aD](https://testnet.bscscan.com/address/0x49D6844cbcef64952E6793677eeaBae324f895aD) | [0x8746649B65eA03A22e559Eb03059018baEDFBA9e](https://testnet.ftmscan.com/address/0x8746649B65eA03A22e559Eb03059018baEDFBA9e) |
| uniBTC | [0x16221CaD160b441db008eF6DA2d3d89a32A05859](https://holesky.etherscan.io/address/0x16221CaD160b441db008eF6DA2d3d89a32A05859) | [0x2c914Ba874D94090Ba0E6F56790bb8Eb6D4C7e5f](https://testnet.snowtrace.io/address/0x2c914Ba874D94090Ba0E6F56790bb8Eb6D4C7e5f) | [0x2c914ba874d94090ba0e6f56790bb8eb6d4c7e5f](https://testnet.bscscan.com/address/0x2c914ba874d94090ba0e6f56790bb8eb6d4c7e5f) | [0x802d4900209b2292bf7f07ecae187f836040a709](https://testnet.ftmscan.com/address/0x802d4900209b2292bf7f07ecae187f836040a709) |
| Vault | [0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823](https://holesky.etherscan.io/address/0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823)  | [0x85792f60633DBCF7c2414675bcC0a790B1b65CbB](https://testnet.snowtrace.io/address/0x85792f60633DBCF7c2414675bcC0a790B1b65CbB) | [0x85792f60633dbcf7c2414675bcc0a790b1b65cbb](https://testnet.bscscan.com/address/0x85792f60633dbcf7c2414675bcc0a790b1b65cbb) | [0x06c186ff3a0da2ce668e5b703015f3134f4a88ad](https://testnet.ftmscan.com/address/0x06c186ff3a0da2ce668e5b703015f3134f4a88ad) |
| Peer | [0x6EFc200c769E54DAab8fcF2d339b79F92cFf4EC9](https://holesky.etherscan.io/address/0x6EFc200c769E54DAab8fcF2d339b79F92cFf4EC9) | [0xe7431fc992a54fAA435125Ca94E00B4a8c89095c](https://testnet.snowtrace.io/address/0xe7431fc992a54fAA435125Ca94E00B4a8c89095c) | [0xd59677a6efe9151c0131e8cf174c8bbceb536005](https://testnet.bscscan.com/address/0xd59677a6efe9151c0131e8cf174c8bbceb536005) | [0xe7431fc992a54faa435125ca94e00b4a8c89095c](https://testnet.ftmscan.com/address/0xe7431fc992a54faa435125ca94e00b4a8c89095c) |
| mockFBTC | [0x5C367C804ce9F00464Cba3199d6Fb646E8287146](https://holesky.etherscan.io/address/0x5C367C804ce9F00464Cba3199d6Fb646E8287146) | [0xEB74BB04aD28b9b7ec1f2fd1812e7242170C6d1B](https://testnet.snowtrace.io/address/0xEB74BB04aD28b9b7ec1f2fd1812e7242170C6d1B) | [0xc87E37848B913f289Aee0E2A9d3Ed94bA98D2A60](https://testnet.bscscan.com/address/0xc87E37848B913f289Aee0E2A9d3Ed94bA98D2A60) | [0xeb74bb04ad28b9b7ec1f2fd1812e7242170c6d1b](https://testnet.ftmscan.com/address/0xeb74bb04ad28b9b7ec1f2fd1812e7242170c6d1b) |
| mockWBTC | [0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0](https://holesky.etherscan.io/address/0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0) | [0x49D6844cbcef64952E6793677eeaBae324f895aD](https://testnet.snowtrace.io/address/0x49D6844cbcef64952E6793677eeaBae324f895aD) | [0xe7431fc992a54faa435125ca94e00b4a8c89095c](https://testnet.bscscan.com/address/0xe7431fc992a54faa435125ca94e00b4a8c89095c) | [0x49d6844cbcef64952e6793677eeabae324f895ad](https://testnet.ftmscan.com/address/0x49d6844cbcef64952e6793677eeabae324f895ad) |


#### 3.3 L1 Blockchains

| Contract   | Berachain Testnet                                                                                                             |
|------------|-------------------------------------------------------------------------------------------------------------------------------|
| ProxyAdmin | [0xC0c9E78BfC3996E8b68D872b29340816495D7e89](https://bartio.beratrail.io/address/0xC0c9E78BfC3996E8b68D872b29340816495D7e89)  |
| uniBTC     | [0x16221CaD160b441db008eF6DA2d3d89a32A05859](https://bartio.beratrail.io/address/0x16221CaD160b441db008eF6DA2d3d89a32A05859)  | 
| Vault      | [0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823](https://bartio.beratrail.io/address/0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823)  | 
| mockedWBTC | [0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0](https://bartio.beratrail.io/address/0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0)  |
| WBTC | [0x286F1C3f0323dB9c91D1E8f45c8DF2d065AB5fae](https://bartio.beratrail.io/address/0x286F1C3f0323dB9c91D1E8f45c8DF2d065AB5fae)  |

### 4. Error Codes from contracts
1. SYS001: INVALID_UNIBTC_ADDRESS
1. SYS002: TOKEN_PAUSED
1. SYS003: INVALID_TOKEN_ADDRESS
1. SYS004: INCORRECT_DECIMALS
1. SYS005: MINIMUM_VALUE_SHOULD_BE_A_POSITIVE_MULTIPLE_OF_100000
1. SYS006: INVALID_INPUT_ARRAY_LENGTHS
1. SYS007: CHAIN_ID_CANNOT_BE_ZERO
1. SYS008: INVALID_PEER_ADDRESS
1. SYS009: IRREDEEMABLE_STATUS
2. USR001: UNIBTC: LEAST_ONE_RECIPIENT_ADDRESS
2. USR002: UNIBTC: NUMBER_OF_RECIPIENT_ADDRESSES_DOES_NOT_MATCH_THE_NUMBER_OF_TOKENS
2. USR003: INSUFFICIENT_QUOTA
2. USR004: INVALID_CHAINID
2. USR005: DESTINATION_PEER_DOES_NOT_EXIST
2. USR006: INVALID_AMOUNT_TO_TRANSFER
2. USR007: TRANSFER_TO_THE_ZERO_ADDRESS
2. USR008: INCORRECT_FEE
2. USR009: ILLEGAL_REMOTE_CALLER
2. USR010: INSUFFICIENT_AMOUNT
2. USR011: INVALID_SLIPPAGE
2. USR012: SET_DELAY_REDEEM_BLOCK_TOO_LARGE
2. USR013: SET_DAY_CAP_TOO_LARGE
2. USR014: AMOUNT_TOO_LESS
2. USR015: AMOUNT_TOO_MORE