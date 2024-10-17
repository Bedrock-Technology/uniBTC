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
<!-- 
| Contract                     | Address                                    |
|------------------------------|--------------------------------------------|
| ProxyAdmin                   | 0x029E4FbDAa31DE075dD74B2238222A08233978f6 |
| uniBtcVault                  | 0x047D41F2544B7F63A8e991aF2068a363d210d6Da |
|------------------------------|--------------------------------------------|
| directBTC proxy              | 0x290ae25790112D619EEF07E878674D7AAbe9CbF0 |
| directBTC imple              | 0xeDd7E3DF86E80E5237bFa2436fE4575733CD6533 |
|------------------------------|--------------------------------------------|
| DirectBTCMinter proxy        | 0xF2EB1dc3cE6bf85AbB089101642CFC92a6bAB931 |
| DirectBTCMinter imple        | 0x5760c5050ffE04703804C31624B1C6969a5B455e |
|------------------------------|--------------------------------------------| -->

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
