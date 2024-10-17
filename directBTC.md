# Direct BTC

## about

  directBTC is a wrapped version of BTC on Ethereum. It is
  pegged 1:1 with BTC on Bitcoin chain.
  
  The BTC is locked in a custody wallet and the corresponding amount of directBTC is minted on Ethereum.
  
  The custodian wallet is managed by a third party.

## deploy contract: holesky

  | Contract                     | Address                                    |
  |------------------------------|--------------------------------------------|
  | ProxyAdmin                   | 0xC0c9E78BfC3996E8b68D872b29340816495D7e89 |
  | uniBtc Vault                 | 0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823 |
  |------------------------------|--------------------------------------------|
  | directBTC proxy              | 0xe3747f26A74E4831Cdd0f3E54733B379D7842c7A |
  | directBTC imple              | 0x647Dc65c8DFb6f1a09C0A1f9F56AEed941ef2277 |
  |------------------------------|--------------------------------------------|
  | DirectBTCMinter proxy        | 0x0F433A202611Afa304B873D31149731Bd746a943 |
  | DirectBTCMinter imple        | 0xD4c9C929CE4904D8b79ad1734f69777feFF51af7 |

## deploy contract: mainnet
### B2
| Contract (B2)                | Address                                    |
|------------------------------|--------------------------------------------|
| ProxyAdmin                   | 0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19 |
| uniBtcVault                  | 0xF9775085d726E782E83585033B58606f7731AB18 |
|------------------------------|--------------------------------------------|
| directBTC proxy              | 0x3e904af0Cf56b304d0D286C8fB6eA5A84E33EAb5 |
| directBTC imple              | 0xF1376bceF0f78459C0Ed0ba5ddce976F1ddF51F4 |
|------------------------------|--------------------------------------------|
| DirectBTCMinter proxy        | 0xa0c8D36EBDA8bC2F3466836D8bEa87a736b8c467 |
| DirectBTCMinter imple        | 0x4beFa2aA9c305238AA3E0b5D17eB20C045269E9d |
|------------------------------|--------------------------------------------|


### ERROR code from contract

- SYS001: INVALID_ADDRESS
- SYS002: TOKEN_PAUSED
- SYS003: INVALID_TOKEN_ADDRESS

- USR001: LEAST_ONE_RECIPIENT_ADDRESS
- USR002: NUMBER_OF_RECIPIENT_ADDRESSES_DOES_NOT_MATCH_THE_NUMBER_OF_TOKENS
- USR011: RECEIVE_EVENT_PARAM_ERROR
- USR012: RECIPIENT_NOT_AUTHORIZED
- USR013: RECEIVE_EVENT_TX_EXIST
- USR014: EVENT_STATUS_ERROR
