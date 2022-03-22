const { PRIVATE_KEY, PRIVATE_KEY2, URL_ALCHEMY, CONTRACT_ADDRESS} = process.env

async function main() {

        const contractAddress = CONTRACT_ADDRESS
        const provider = new ethers.providers.JsonRpcProvider(URL_ALCHEMY)
        const admin = new ethers.Wallet(PRIVATE_KEY, provider)
        const signer = new ethers.Wallet(PRIVATE_KEY2, provider)
        const myContract = await ethers.getContractAt('ERC20token', contractAddress, admin)
        const value = ethers.utils.parseEther('5')
        
        try {
          
          const contractBalance = await myContract.totalSupply()
          const contractBalanceEth = ethers.utils.formatEther(contractBalance)  
          console.log(`"Balance before transfer:${contractBalanceEth} BLR`)
          await myContract.connect(admin).approve(signer.address, value)
          await myContract.connect(signer).transferFrom(admin.address, signer.address, value)
          const BalanceEth = await ethers.utils.formatEther(value)
          console.log(`sent from address:${admin.address} 
                       to address:${signer.address} - ${BalanceEth} BLR`)

        } catch (error) {
          console.log('Something went wrong', error)
        }
}
    
main()
.then(() => process.exit(0))    
.catch((error) => {
  console.error(error)
  process.exit(1)
})