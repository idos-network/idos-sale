## idOS token sale contract

This is a token Sale contract, adapted from the original Citizend contract at https://github.com/subvisual/citizend

Overall features:

- Rising tide mechanism (off-chain calculation, on-chain validation)
- min/max raise amounts (sale is canceled if below min target, and capped at max target)
- configurable duration
- merkle tree whitelisting

## Deploy

```bash
forge script script/Deploy.s.sol:Deploy \
--rpc-url $RPC_URL \
--broadcast \
--verify \
--etherscan-api-key $ETHERSCAN_API_KEY \
--private-key $PRIVATE_KEY
```
