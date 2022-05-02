# ERC721EthPrice

<img src="img/1-5.png" width="200">

ERC721 extension that modifies tokenURI based on roughly past 24 hours of eth price change in percentages.
Using ..
- Solidity 0.8.1
- Chainlink 0.4.0
- OpenZeppelin 0.4.5

Some things to taken into your considerations
- No unit test written yet. This is only made for recreational purposes.
- The contract currently uses the Chainlink Eth-USDT feed. It is a view function that we can call for free, but there is no gurantee that it will stay that way. 

DM @metaverseosaru or @osaru_lab on Twitter for questions. 
