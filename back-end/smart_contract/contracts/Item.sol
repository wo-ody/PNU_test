// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ItemContract is ERC1155 {

    uint256 internal itemId;

    address payable internal governance;

    string[2] baseURI = ["https://ipfs.io/ipfs/", "/{id}.json"];

    mapping(uint256 => string) uriMap; // items length => dirCID;
    
    mapping(uint256 => address) public producerOf; // itemId => producer;
    mapping(address => bool) public isProducer;
    mapping(address => bool) public isManager;
    mapping(address => uint256[]) public mintList;


    constructor(string memory _dirCID) public ERC1155(string.concat(string.concat(baseURI[0], _dirCID),baseURI[1])) {
        itemId = 0;
        governance = payable(msg.sender);
        isProducer[governance] = true;
        isManager[governance] = true;
        _mint(governance, itemId, 10**18, "");
        mintList[governance].push(0); 
        uriMap[itemId] = _dirCID;
    }
    
    function getProducerOf(uint256 _itemId) external view returns(address){
        return producerOf[_itemId];
    }

    function getIsProducer(address _user) public view returns(bool){
        return isProducer[_user];
    }

    function getGovernance() public view returns(address payable){
        return governance;
    }

    modifier onlyProducer(){
        require(isProducer[msg.sender] || governance == msg.sender, "only producer can call this.");
        _;
    }

    modifier onlyGovernance(){
        require(msg.sender == governance, "only gorvernance can call this");
        _;
    }

    function WeitoMMT(uint256 _amount) public payable {
        require(_amount > 0, "This Wei is not enough to buy a token.");
        safeTransferFrom(governance, payable(msg.sender), 0, _amount, "");
    }

    function MMTtoWei(uint amount) public payable {
        require(amount > 0, "Over zero.");
        require(balanceOf(msg.sender, 0) >= amount, "Token is not enough to exchange for a Wei.");
        require(payable(msg.sender).send(amount), "failed to exchange");
        safeTransferFrom(msg.sender, governance, 0, msg.value, "");
    } 

    function mintMMT(uint _amount) public onlyGovernance(){
        _mint(msg.sender, 0, _amount, "");
    }

    function mintItemByItemId(uint _stock, uint _itemId) public onlyProducer(){
        require(_itemId <= itemId, "Unregistered item cannot be produced.");
        require(_itemId != 0 || msg.sender == governance, "Only the government can produce tokens.");
        _mint(msg.sender, _itemId, _stock, "");
    }

    function getNewItemId() public view returns(uint256){
        return itemId+1;
    }

    function createItem(uint256 _amount, string memory _dirCID) public onlyProducer(){
        itemId++;
        string memory newURI = string.concat(string.concat(baseURI[0], _dirCID), baseURI[1]);
        uriMap[itemId] = newURI;
        _setURI(newURI);
        _mint(msg.sender, itemId, _amount, "");
        mintList[msg.sender].push(itemId);
        producerOf[itemId] = msg.sender;
    }

    function getURILatest() public view returns(string memory){
        return uriMap[itemId];
    }

    function setApprovalForAll(address _user,bool flag) public override{
        address from = _user;
        address to = governance;
        if(_user != governance){
            _setApprovalForAll(from, to, flag);
        }
    }

    function burn(uint256 _itemId, uint256 _amount) public{
        _burn(msg.sender, _itemId, _amount);
    }

    function isApprovedForAll(address _user, address _contract) public view override returns(bool){
        address from = _user;
        address to = governance;

        if(_user == governance){
            to = _contract;
        }

        return super.isApprovedForAll(from,to);    
    }


    function setUserToGovernance(address _user) public onlyGovernance(){
        governance = payable(_user);
        isProducer[_user] = true;
        isManager[_user] = true;
    }

    function setUserToProducer(address _user, bool flag) public {
        setApprovalForAll(_user, flag);
        isProducer[msg.sender] = flag;
    }

    function setUserToManager(address _user, bool flag) public {
        setApprovalForAll(_user, flag);
        isManager[msg.sender] = flag;
    }

}