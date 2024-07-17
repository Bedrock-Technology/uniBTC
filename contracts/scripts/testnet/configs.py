# Reference: https://im-docs.celer.network/developer/contract-addresses-and-rpc-info#testnet

contracts = {
    "holesky-test": {
        "chain_id": 17000,
        "proxy_admin": "0xC0c9E78BfC3996E8b68D872b29340816495D7e89",
        "message_bus": "0xbB161Bcc64A320A085E08A8AaE2ba40e9bB2D47C",
        "fbtc": "0x5C367C804ce9F00464Cba3199d6Fb646E8287146",
        "wbtc": "0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0",
        "uni_btc": "0x16221CaD160b441db008eF6DA2d3d89a32A05859",
        "vault": "0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823",
        "peer": "0x6EFc200c769E54DAab8fcF2d339b79F92cFf4EC9"
    },
    "avax-test": {
        "chain_id": 43113,
        "proxy_admin": "0x8746649B65eA03A22e559Eb03059018baEDFBA9e",
        "message_bus": "0xE9533976C590200E32d95C53f06AE12d292cFc47",
        "fbtc": "0xEB74BB04aD28b9b7ec1f2fd1812e7242170C6d1B",
        "wbtc": "0x49D6844cbcef64952E6793677eeaBae324f895aD",
        "uni_btc": "0x2c914Ba874D94090Ba0E6F56790bb8Eb6D4C7e5f",
        "vault": "0x85792f60633DBCF7c2414675bcC0a790B1b65CbB",
        "peer": "0xe7431fc992a54fAA435125Ca94E00B4a8c89095c"
    },
    "bsc-test": {
        "chain_id": 97,
        "proxy_admin": "0x49D6844cbcef64952E6793677eeaBae324f895aD",
        "message_bus": "0xAd204986D6cB67A5Bc76a3CB8974823F43Cb9AAA",
        "fbtc": "0xc87E37848B913f289Aee0E2A9d3Ed94bA98D2A60",
        "wbtc": "0xe7431fc992a54fAA435125Ca94E00B4a8c89095c",
        "uni_btc": "0x2c914Ba874D94090Ba0E6F56790bb8Eb6D4C7e5f",
        "vault": "0x85792f60633DBCF7c2414675bcC0a790B1b65CbB",
        "peer": "0xd59677a6eFe9151c0131E8cF174C8BBCEB536005"
    },
    "ftm-test": {
        "chain_id": 4002,
        "proxy_admin": "0x8746649B65eA03A22e559Eb03059018baEDFBA9e",
        "message_bus": "0xb92d6933A024bcca9A21669a480C236Cbc973110",
        "fbtc": "0xEB74BB04aD28b9b7ec1f2fd1812e7242170C6d1B",
        "wbtc": "0x49D6844cbcef64952E6793677eeaBae324f895aD",
        "uni_btc": "0x802d4900209b2292bF7f07ecAE187f836040A709",
        "vault": "0x06c186Ff3a0dA2ce668E5B703015f3134F4a88Ad",
        "peer": "0xe7431fc992a54fAA435125Ca94E00B4a8c89095c"
    },
    "b2-test": {
        "chain_id": 1123,
        "proxy_admin": "0x56c3024eB229Ca0570479644c78Af9D53472B3e4",
        "message_bus": "",
        "fbtc": "0xC0c9E78BfC3996E8b68D872b29340816495D7e89",
        "wbtc": "0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0",
        "wbtc18": "0x4ed4739E6F6820f2357685592168f6C6c003714f",
        "uni_btc": "0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894",
        "vault": "0x2ac98DB41Cbd3172CB7B8FD8A8Ab3b91cFe45dCf",
        "peer": ""
    },
    "bitlayer-test": {
        "chain_id": 200810,
        "proxy_admin": "0x56c3024eB229Ca0570479644c78Af9D53472B3e4",
        "message_bus": "",
        "fbtc": "0xC0c9E78BfC3996E8b68D872b29340816495D7e89",
        "wbtc": "0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0",
        "wbtc18": "0x1d481E87C3f3C967Ad8F17156A99D69D0052dC67",
        "uni_btc": "0x16221CaD160b441db008eF6DA2d3d89a32A05859",
        "vault": "0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823",
        "peer": ""
    },
    "merlin-test": {
        "chain_id": 686868,
        "proxy_admin": "0x56c3024eB229Ca0570479644c78Af9D53472B3e4",
        "message_bus": "",
        "mbtc": "0x2F9Ae77C5955c68c2Fbbca2b5b9F917e90929f7b",
        "uni_btc": "0x16221CaD160b441db008eF6DA2d3d89a32A05859",
        "vault": "0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823",
        "peer": ""
    },
}

amount = 1e8

caps = [1e4 * 1e8, 1e4 * 1e18]

recipients = ["0xe8A335a8502625Fb6c6e900a547694770D764484",  # Zhong Jian
              "0xF69F4471C7EdF4299bc16dbE829F57942f90572f",  # Calvin Zhou
              "0xdc4A11eEcea1E2e7Aa92161909cD7fa6b667a9cd"]  # Vincent Liu
