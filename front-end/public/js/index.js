var Auction_sol;
var Item_sol;
var Supply_sol;
var governance;
var ItemAddress;
var flag = false;

// 페이지 로드될때마다, 컨트랙트랑 연동시켜주기


async function test(){
	var _itemId = 1000000;
	
	console.log(idx);
	console.log(idx.length);
}


async function startApp() {
	ItemAddress = "0x35dFC62FB74E6DF12c998F3AD238ebA2E3EB55fA";
	var SupplyAddress = "0x863302bba2084A89EeD0C42Bb35B435b1b2200A9";
	var AuctionAddress = "0x37da64D7aF08F6d3A2FF15B00944f2A5E9557261";
	governance = "0x3B858b7bC1e2891a1234A58B99F4b30a79485F7E";

		
	Auction_sol = await new web3.eth.Contract(AuctionABI, AuctionAddress);
	console.log("Auction Create");
	Item_sol = await new web3.eth.Contract(ItemABI, ItemAddress);
	Supply_sol = await new web3.eth.Contract(SupplyABI, SupplyAddress);
	console.log("Supply create")

}



window.addEventListener('load', function() {
	// Web3가 브라우저에 주입되었는지 확인(Mist/MetaMask)
	if (typeof web3 !== 'undefined') {
	// Mist/MetaMask의 프로바이더 사용
		web3 = new Web3(window.ethereum);
		//console.log(web3)
	} else {
		this.alert("메타 마스크를 설치하세요");
	}

	startApp();


	console.log("smart contract , 메타마스크 연결 완료");
	
})
