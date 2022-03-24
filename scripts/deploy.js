
async function main() {
  const ltokenAddress = '0xF4927988BB35a7C0469C183f0e29adC8B16f0878' // BLR/SSSR UNI-V2
  const rewardsAddress = '0xaa907E805779bf0Cd18B26f60D1AD5544140298e' // WETH 
  // freeztime = 1 // 1 minutes (период калькуляции rewards)
  freeztime = 60 // 60 minutes (период калькуляции rewards)
  rewardPerHour1 = 2000; 
  rewardPerHour2 = 1000; 

  const Staking = await ethers.getContractFactory("StakingContract");
  const staking = await Staking.deploy(ltokenAddress, rewardsAddress, freeztime, rewardPerHour1, rewardPerHour2);

  console.log("Staking address:", staking.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
      console.error(error);
      process.exit(1);
  });


// async function main() {

//   const [deployer] = await ethers.getSigners()

//   console.log("Deploying contracts with the account:", deployer.address)

//   console.log("Account balance:", (await deployer.getBalance()).toString())

//   const ERC20token = await ethers.getContractFactory("WETH")
//   const erc20token = await ERC20token.deploy()

//   console.log("Token contract address:", erc20token.address)
  
// }

// main()
//   .then(() => process.exit(0))
//   .catch((error) => {
//     console.error(error)
//     process.exit(1)
//   })