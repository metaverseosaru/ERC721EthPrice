// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ERC721EthPrice is ERC721, Ownable{
    using Strings for uint256;

    uint256 private tokenCounter;                   //TokenIdTracker.
    mapping(uint256 => uint80) public _roundSpans;  //Mapping that tracks roundspans for each tokenId.
    mapping(uint256 => string) private _tokenURIs;  //Default tokenId tracker.
    AggregatorV3Interface public priceFeed;         //Chainlink priceFeed interface.

    // Initialize parameters.
    constructor(address _priceFeed) public ERC721("ERC721EthPrice", "EEP"){
        priceFeed = AggregatorV3Interface(_priceFeed);
        tokenCounter = 1;
    }

    // Standard mint function
    function mint(string memory inputTokenURI, uint80 _roundSpan) public onlyOwner returns (uint256){
        // get token ID
        uint256 newTokenId = tokenCounter;
        // mint with token ID
        _safeMint(msg.sender, newTokenId);
        // set token URI associated with the ID
        _setTokenURI(newTokenId, inputTokenURI);
        // set round span associated with the ID
        _setRoundSpan(newTokenId, _roundSpan);
        tokenCounter = tokenCounter + 1;
        return newTokenId;
    }   

    // Get current eth price in USD
    function getCurrentEthPrice() public view returns (uint256, uint80) {
        (uint80 roundId, int256 answer, , , ) = priceFeed.latestRoundData();
        //Converting to USD
        return (uint256(answer / 100000000), roundId);
    }

    // Get past eth price in USD
    function getPastEthPrice(uint80 input) public view returns (uint256, uint80) {
        (uint80 roundId, int256 answer, , , ) = priceFeed.getRoundData(input);
        //Converting to USD
        return (uint256(answer / 100000000), roundId);
    }

    // Get percent change in eth price for particular token ID
    // Returns % at the unit of 0.01 (e.g. 5% is 500. 11% is 1100)
    function getPercentChange(int curPrice, int pastPrice) public view returns (int) {
        int percentChange = (curPrice-pastPrice)*10000/pastPrice;
        return percentChange;
    }

    // Converts percent change to image index.
    // 6 different price changes at the following threwhold. -5%, -2.5%, 0%, 2.5%, 5%
    function percent2index(int percentChange) internal view returns (uint256){

        uint256 index     = 5;
        if(percentChange < -500){
            index = 0;
        }else if(percentChange < -250){
            index = 1;
        }else if(percentChange < 0){
            index = 2;
        }else if(percentChange < 250){
            index = 3;
        }else if(percentChange < 500){
            index = 4;
        }
        return index;
    }
    
    // baseURI returner. This should be empty.
    function _baseURI() internal view override returns (string memory) {
        return "";
    }
    
    // Returns tokenURI based on percent change in eth price.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721EthPrice: URI query for nonexistent token");

        string memory _tokenURI            = _tokenURIs[tokenId];
        string memory base                 = _baseURI();
        (uint256 curPrice, uint80 roundId) = getCurrentEthPrice();
        (uint256 pastPrice, )              = getPastEthPrice(roundId - _roundSpans[tokenId]);
        int percentChange                  = getPercentChange(int(curPrice), int(pastPrice));
        uint256 imageindex                 = percent2index(percentChange);

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return string(abi.encodePacked(_tokenURI, imageindex.toString()));
        }

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI, imageindex.toString()));
        }
        
        return super.tokenURI(tokenId);
    }
    
    /* *
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     * Requirements:
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721EthPrice: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /* *
     * @dev Sets `_roundSpan` as the round span of `tokenId`.
     * Requirements:
     * - `tokenId` must exist.
     */
    function _setRoundSpan(uint256 tokenId, uint80 _roundSpan) internal virtual {
        require(_exists(tokenId), "ERC721EthPrice: round span set of nonexistent token");
        _roundSpans[tokenId] = _roundSpan;
    }

    /* * 
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

}