// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// Dev imports
// import "hardhat/console.sol";

contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable , KeeperCompatibleInterface , VRFConsumerBaseV2{
    using Counters for Counters.Counter;

    VRFCoordinatorV2Interface public COORDINATOR;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint32 gasLimit = 500000;
    uint64 public s_subscriptionId ;
    bytes32 keyHash =  0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc ;

    Counters.Counter private _tokenIdCounter;
    uint public interval;
    uint public lastTimeStamp;

    AggregatorV3Interface public priceFeed;
    int256 public currentPrice;

    enum MarketTrend{BULL, BEAR} // Create Enum
    MarketTrend public currentMarketTrend = MarketTrend.BULL; 

    string [] bullUriIfps = [
        "https://ipfs.io/ipfs/QmdcURmN1kEEtKgnbkVJJ8hrmsSWHpZvLkRgsKKoiWvW9g?filename=simple_bull.json" ,
        "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json" ,
        "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json"
    ];

    string [] bearUriIfps = [
        "https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json" ,
        "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json" ,
        "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json"
    ];

    event tokensUpdated(string marketTrend);

    constructor(uint updatedInterval , address _feedAddress , address _vrfCoordinator) ERC721("Bull&Bear", "BBTK") VRFConsumerBaseV2(_vrfCoordinator) {

        interval = updatedInterval;
        lastTimeStamp = block.timestamp;

        priceFeed = AggregatorV3Interface(_feedAddress);

        currentPrice = getLatestPrice();
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        string memory defaultUri = bullUriIfps[0];
        _setTokenURI(tokenId , defaultUri);
    }

    function checkUpkeep(bytes calldata) external view override returns(bool upKeepNeeded , bytes memory ) {
        upKeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata) external override {

        if( (block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            int latestPrice = getLatestPrice();

            if(latestPrice == currentPrice ){
                return;
            }
            if(currentPrice<latestPrice){
                currentMarketTrend = MarketTrend.BEAR;
            }
            else{
                currentMarketTrend = MarketTrend.BULL;
            }
            generateRandomNum();

            currentPrice = latestPrice;
        }
    }

     function getLatestPrice() public view returns (int256) {
         (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return price; //  example price returned 3034715771688
    }

    function setInterval(uint256 newInterval) public onlyOwner {
        interval = newInterval;
    }
 
    function setPriceFeed(address newFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(newFeed);
    }
    
    function generateRandomNum() internal {
        require(s_subscriptionId != 0 , "Subscription id is not funded");

        s_requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, 3, gasLimit, 1);
    }

    function fulfillRandomWord(uint256 /*requestId*/ , uint256 [] memory randomWords) internal override {
        s_randomWords = randomWords;

        
    string[] memory urisForTrend = currentMarketTrend == MarketTrend.BULL ? bullUrisIpfs : bearUrisIpfs;
    uint256 idx = randomWords[0] % urisForTrend.length; 


    for (uint i = 0; i < _tokenIdCounter.current() ; i++) {
        _setTokenURI(i, urisForTrend[idx]);
    } 

    string memory trend = currentMarketTrend == MarketTrend.BULL ? "bullish" : "bearish";
    
    emit TokensUpdated(trend);
    }

    function updatedAllTokenUris(string memory trend)  internal {

        if(compareStrings("bear" , trend)){
            for(uint i = 0 ; i<_tokenIdCounter.current() ; i++){
                _setTokenURI(i , bearUriIfps[0]);
            }
        }else{
            for(uint i = 0 ; i<_tokenIdCounter.current() ; i++){
                _setTokenURI(i , bullUriIfps[0]); 
            }
        }

        emit tokensUpdated(trend);
    }

     function setSubscriptionId(uint64 _id) public onlyOwner {
      s_subscriptionId = _id;
  }


  function setCallbackGasLimit(uint32 maxGas) public onlyOwner {
      gasLimit = maxGas;
  }

  function setVrfCoodinator(address _address) public onlyOwner {
    COORDINATOR = VRFCoordinatorV2Interface(_address);
  }

    function compareStrings(string memory a , string memory b) internal pure returns(bool){
        return ( keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)) );
    }

    


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}