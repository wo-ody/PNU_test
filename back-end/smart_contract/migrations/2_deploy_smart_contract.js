const AuctionContract = artifacts.require("AuctionContract");
const ItemContract = artifacts.require("ItemContract");
const SupplyContract = artifacts.require("SupplyContract"); // (구) rwSupplyData


module.exports = async function (deployer) {
  await deployer.deploy(ItemContract,"QmZZyctD1KqnYYqQUQDAWXV5rwumDx5rbfT6NMWfrzvQHf");
  await deployer.deploy(SupplyContract, ItemContract.address);
  //console.log("SupplyManaging", SupplyManagingContract.address);

  //console.log(deployer.deployed.address)

  //console.log("OwnerData", OwnerDataContract.address);
  
  await deployer.deploy(AuctionContract, ItemContract.address, SupplyContract.address, "QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn");
};