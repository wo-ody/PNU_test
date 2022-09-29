// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./Supply.sol";
import "./Item.sol";

contract AuctionContract is ERC1155 {

    ItemContract itemToken;

    SupplyContract supplyContract;

    uint256 internal auctionId;

    address payable internal governance;

    string[2] baseURI = ["https://ipfs.io/ipfs/", "/{id}.json"];

    mapping(uint256 => string) uriMap; // items length => dirCID;
    mapping(uint256 => Bid[] ) public auctionBids;
    mapping(address => mapping(uint256 => string[][])) pathMap; // map[buyer][itemId] = history[];




    constructor(address _itemToken, address _supplyContract, string memory _dirCID) public ERC1155(string.concat(string.concat(baseURI[0], _dirCID),baseURI[1]))
    {
        auctionId = 0;
        itemToken = ItemContract(_itemToken);
        supplyContract = SupplyContract(_supplyContract);
        governance = payable(msg.sender);
    }

 
    
    struct Bid{
        address payable from;
        uint256 amount;
        string shippingTo;
    }


    modifier onlySeller(uint256 _auctionId) {
        require(balanceOf(msg.sender, _auctionId) == 1);
        _;
    }

    modifier onlyGovernance(){
        require(msg.sender == governance, "only gorvernance can call this");
        _;
    }

    function getAuctionId() public view returns(uint256){
        return auctionId;
    }

    function getBidsCount(uint256 _auctionId) public view returns(uint256){
        return auctionBids[_auctionId].length;
    }
    
    function getCurrentBid(uint _auctionId) public view returns(uint256) {
        uint bidsLength =auctionBids[_auctionId].length;

        if(bidsLength > 0){
            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            return (lastBid.amount);
        }

        return (uint256(0));
    }

    function createAuction(string memory _dirCID) public {
        auctionId++;
        string memory newURI = string.concat(string.concat(baseURI[0], _dirCID), baseURI[1]);
        uriMap[auctionId] = newURI;
        _setURI(newURI);
        _mint(governance, auctionId, 1, "");
    }

    //function restartAuction(uint256 _auctionId, )

    function cancelAuction(uint256 _auctionId, uint256 _itemId, address _seller) public onlySeller(_auctionId){
        uint256 bidsLength = auctionBids[_auctionId].length;

        if(bidsLength > 0){
            Bid memory lastBid = auctionBids[_auctionId][bidsLength -1];
            itemToken.safeTransferFrom(governance, lastBid.from, 0, lastBid.amount, "");
            itemToken.safeTransferFrom(governance, _seller, _itemId, lastBid.amount, "");
            safeTransferFrom(governance, _seller, _auctionId, 1, "");
        }
    }

    function finalizeAuction(uint256 _auctionId, uint256 _itemId, address _seller, uint256 _amount, uint256 _blockDeadline, string memory _shippingFrom) public onlySeller(_auctionId) {
        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 timeStamp = block.timestamp;
        //address payable aucOwner = ownerDataContract.getOwnerByAucId(_auctionId);
        

        if(timeStamp < _blockDeadline){
            revert();
        }
        
        if(bidsLength == 0) {
            cancelAuction(_auctionId, _itemId, _seller);
        }else{

            Bid memory lastBid = auctionBids[_auctionId][bidsLength - 1];

            itemToken.safeTransferFrom(governance, msg.sender, 0, lastBid.amount, "");
            itemToken.safeTransferFrom(msg.sender, lastBid.from, _itemId, _amount, "");
            safeTransferFrom(governance, lastBid.from, _auctionId, 1, "");

            updateMap(_auctionId, _itemId, _seller, lastBid.from, _shippingFrom, lastBid.shippingTo);
            supplyContract.deliveryPrepareByItemId(_auctionId);
        }
    }

    function bidOnAuction(uint _auctionId, string memory _to, uint _amount, uint256 _startPrice, uint256 _startTime, uint256 _blockDeadline) external payable {
        uint256 timestamp = block.timestamp;
        uint256 startTime = _startTime;
        uint256 deadline = _blockDeadline;
/*
        if(aucOwner == msg.sender){
            revert();
        }
*/
        if( (timestamp > deadline) || (timestamp < startTime) ){
            revert();
        }
        
        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = _startPrice;
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

    function getWinningPrice(uint256 _auctionId) public view returns(uint256){
        uint256 len = auctionBids[_auctionId].length;
        return auctionBids[_auctionId][len-1].amount;
    } // 옥션의 최종 낙찰가를 리턴

    function getBidderInfo(uint256 _auctionId) public view returns(Bid memory){
        Bid[] memory BidArr = auctionBids[_auctionId];
        return auctionBids[_auctionId][BidArr.length];
    }

    function burn(address _from, uint256 _id, uint256 _amount) public {
        _burn(_from, _id, _amount);
    }
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
    function updateMap(uint256 _auctionId, uint256 _itemId, address _seller, address _buyer, string memory _shippingFrom, string memory _shippingTo) internal {

        string[] memory newRecord;
        string[][] memory prevMap = pathMap[_seller][_itemId];
        string[][] memory nextMap = pathMap[_buyer][_itemId];
            
        if(prevMap.length == 0){
            newRecord[0] = _shippingFrom;
            newRecord[1] = _shippingTo;
            nextMap[nextMap.length] = newRecord;
        }

        for(uint256 i=0;i<prevMap.length;i++){
            newRecord = prevMap[i];
            newRecord[newRecord.length] = _shippingFrom;
            newRecord[newRecord.length] = _shippingFrom;

            nextMap[nextMap.length] = newRecord; 
        }

        pathMap[_buyer][_itemId] = nextMap;
    }

    function getPathByItemId(uint256 _itemId) public view returns(string[][] memory){
        return pathMap[msg.sender][_itemId];
    }

    function setApprovalForAll(address _user, bool flag) public override{
        address from = _user;
        address to = governance;
        if(_user != governance){
            _setApprovalForAll(from, to, flag);
            itemToken.setApprovalForAll(from, flag);
        }
    }

    function isApprovedForAll(address _user, address _contract) public view override returns(bool){
        address from = _user;
        address to = governance;

        if(_user == governance){
            to = _contract;
        }

        return (super.isApprovedForAll(from,to) && itemToken.isApprovedForAll(from, to));    
    }

    function setUserToGovernance(address _user) public onlyGovernance(){
        governance = payable(_user);
    }

}

