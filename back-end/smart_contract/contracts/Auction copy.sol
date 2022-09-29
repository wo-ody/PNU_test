// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./Supply.sol";
import "./Item.sol";

contract AuctionContract {

    ItemContract itemToken;

    SupplyContract supplyContract;

    address payable internal governance;

    constructor(address _itemToken, address _supplyContract)
    {
        itemToken = ItemContract(_itemToken);
        supplyContract = SupplyContract(_supplyContract);
        governance = itemToken.getGovernance();
    }

    Auction[] public auctions;

    mapping(uint256 => Bid[] ) public auctionBids;
    mapping(address => mapping(uint256 => string[][])) pathMap; // map[buyer][itemId] = history[];

    
    struct Bid{
        address payable from;
        uint256 amount;
        string shippingTo;
    }
    

    struct Auction{
        uint256 auctionId;
        string name;
        uint256 startTime;
        uint256 blockDeadline;
        uint256 startPrice;
        uint256 amount;
        bool active;
        bool finalized;
        uint256 itemId;
        string[2] shippingAddr;
        address payable[2] traders;
    }


    modifier onlySeller(uint256 _auctionId) {
        require(auctions[_auctionId].traders[0] == msg.sender);
        _;
    }

    function getAllOfAuctions() public view returns(Auction[] memory){
        return auctions;
    }

    function getAuctionsLength() public view returns(uint256){
        return auctions.length;
    }

    function getItemByAuction(uint256 _auctionId) public view returns(uint256){
        return auctions[_auctionId].itemId;
    }

    function getBidsCount(uint256 _auctionId) public view returns(uint256){
        return auctionBids[_auctionId].length;
    }

    function getOwnedAuctions(address _user) public view returns(Auction[] memory){
       Auction[] memory ownedAuctions;
       uint256 ownedId = 0;
       for(uint256 i=0; i<auctions.length; i++){
            if(auctions[i].traders[0] == payable(_user)){
                ownedAuctions[ownedId++] = auctions[i];
            }
        } 
        return ownedAuctions;
    }

    
    function getCurrentBid(uint _auctionId) public view returns(uint256, address) {
        uint bidsLength =auctionBids[_auctionId].length;

        if(bidsLength > 0){
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            return (lastBid.amount, lastBid.from);
        }

        return (uint256(0), address(0));
    }

    function getAuctionById(uint _auctionId) public view returns(Auction memory){
        Auction memory auc = auctions[_auctionId];
        //address _owner = ownerDataContract.getOwnerByAucId(_auctionId);
        return (auc);
    }

    function getAuctionNameByAuctionId(uint256 _auctionId) public view returns(string memory){
        return auctions[_auctionId].name;
    }

    function createAuction( uint256 _itemId, string memory _auctionTitle, uint256 _startPrice, 
       uint256 _amount, string memory _shippingFrom, uint256 _startTime,  uint256 _blockDeadline) public {

        Auction memory newAuction;

        require(_amount <= itemToken.balanceOf(msg.sender, _itemId), "lack of balance");

        itemToken.safeTransferFrom(msg.sender, governance, _itemId, _amount, "");

        newAuction.itemId = _itemId;
        newAuction.name = _auctionTitle;
        newAuction.startPrice = _startPrice;
        newAuction.amount = _amount;
        newAuction.startTime = _startTime;
        newAuction.blockDeadline = _blockDeadline;
        newAuction.active = true;
        newAuction.finalized = false;
        newAuction.shippingAddr[0] = _shippingFrom;

        auctions.push(newAuction);
        //ownerDataContract.updateItemOwner(msg.sender, _itemId);
        //ownerData.pushOwnedBy(msg.sender, _itemId);
    }

    //function restartAuction(uint256 _auctionId, )

    function cancelAuction(uint _auctionId) public onlySeller(_auctionId){
        Auction memory auc = auctions[_auctionId];
        uint bidsLength = auctionBids[_auctionId].length;

        if(bidsLength > 0){
            Bid memory lastBid = auctionBids[_auctionId][bidsLength -1];
            itemToken.safeTransferFrom(governance, lastBid.from, 0, lastBid.amount, "");
            itemToken.safeTransferFrom(governance, auc.traders[0], auc.itemId, lastBid.amount, "");
        }
    }

    function finalizeAuction(uint256 _auctionId) public onlySeller(_auctionId) returns(uint256) {
        Auction memory auc = auctions[_auctionId];
        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 timeStamp = block.timestamp;
        //address payable aucOwner = ownerDataContract.getOwnerByAucId(_auctionId);
        

        if(timeStamp < auc.blockDeadline){
            revert();
        }
        
        if(bidsLength == 0) {
            cancelAuction(_auctionId);
        }else{

            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];

            itemToken.safeTransferFrom(governance, msg.sender, 0, lastBid.amount, "");
            itemToken.safeTransferFrom(msg.sender, lastBid.from, auc.itemId, auc.amount, "");
            auc.shippingAddr[1] = lastBid.shippingTo;
            auctions[_auctionId].finalized = true;

            updateMap(_auctionId);
            supplyContract.deliveryPrepareByItemId(_auctionId);
        }

        auctions[_auctionId].active = false;
        return 0;
    }

    function getShippingAddrByAucId(uint256 _auctionId) public view returns(string[2] memory){
        return auctions[_auctionId].shippingAddr;
    }

    function bidOnAuction(uint _auctionId, string memory _to, uint _amount) external payable {
        uint256 timestamp = block.timestamp;
        //address aucOwner = ownerDataContract.getOwnerByAucId(_auctionId);
        Auction memory auc = auctions[_auctionId];
        uint256 startTime = auc.startTime;
        uint256 deadline = auc.blockDeadline;
/*
        if(aucOwner == msg.sender){
            revert();
        }
*/
        if( (timestamp > deadline) || (timestamp < startTime) ){
            revert();
        }
        
        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = auc.startPrice;
        Bid memory lastBid;
        
        if(_amount < tempAmount){
            revert();
        }

        require(_amount > tempAmount, "Lower than start price");

        if(bidsLength > 0){
            lastBid = auctionBids[_auctionId][bidsLength -1];
            tempAmount = lastBid.amount;

            require(_amount > tempAmount, "Lower than currentBid");

            itemToken.safeTransferFrom(msg.sender, governance, 0, _amount, "");
            itemToken.safeTransferFrom(governance, lastBid.from, 0, lastBid.amount, "");
        }
        
        Bid memory newBid;
        newBid.from = payable(msg.sender);
        newBid.amount = _amount;
        newBid.shippingTo = _to;
        auctionBids[_auctionId].push(newBid);
    }

    function getActiveByAuctionId(uint256 _auctionId) public view returns(bool){
        return auctions[_auctionId].active;
    }

    function getWinningPrice(uint256 _auctionId) public view returns(uint256){
        uint256 len = auctionBids[_auctionId].length;
        return auctionBids[_auctionId][len-1].amount;
    } // 옥션의 최종 낙찰가를 리턴
/*
    function updateMap(uint256 _auctionId) internal {
        Auction memory auc = auctions[_auctionId];
        uint256 _itemId = auc.itemId;

        uint256[] memory newRecord;
        uint256[][] memory prevMap = aucMap[auc.traders[0]][_itemId];
        uint256[][] memory nextMap = aucMap[auc.traders[1]][_itemId];
            
        if(prevMap.length == 0){
            newRecord[0] = _auctionId;
            nextMap[nextMap.length] = newRecord;
        }

        for(uint256 i=0;i<prevMap.length;i++){
            newRecord = prevMap[i];
            newRecord[newRecord.length] = _auctionId;
            nextMap[nextMap.length] = newRecord; 
        }

        aucMap[auc.traders[1]][_itemId] = nextMap;
    }

    function getPathByItemId(uint256 _itemId) public view returns(string[][] memory){
        string[][] memory pathArr;
        for(uint i=0;i<aucMap[msg.sender][_itemId].length; i++){
            string[] memory path;
            uint256[] memory row = aucMap[msg.sender][_itemId][i];
            for(uint j=0;j<row.length;j++){
                path[path.length] = auctions[row[j]].shippingAddr[0];
                path[path.length] = auctions[row[j]].shippingAddr[1];
            }
            pathArr[pathArr.length] = path;
        }

        return pathArr;
    }
*/  
    function updateMap(uint256 _auctionId) internal {
        Auction memory auc = auctions[_auctionId];
        uint256 _itemId = auc.itemId;

        string[] memory newRecord;
        string[][] memory prevMap = pathMap[auc.traders[0]][_itemId];
        string[][] memory nextMap = pathMap[auc.traders[1]][_itemId];
            
        if(prevMap.length == 0){
            newRecord[0] = auc.shippingAddr[0];
            newRecord[1] = auc.shippingAddr[1];
            nextMap[nextMap.length] = newRecord;
        }

        for(uint256 i=0;i<prevMap.length;i++){
            newRecord = prevMap[i];
            newRecord[newRecord.length] = auc.shippingAddr[0];
            newRecord[newRecord.length] = auc.shippingAddr[0];

            nextMap[nextMap.length] = newRecord; 
        }

        pathMap[auc.traders[1]][_itemId] = nextMap;
    }

    function getPathByItemId(uint256 _itemId) public view returns(string[][] memory){
        return pathMap[msg.sender][_itemId];
    }

}

