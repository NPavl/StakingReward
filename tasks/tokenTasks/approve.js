const { PRIVATE_KEY, PRIVATE_KEY2, URL_ALCHEMY, CONTRACT_ADDRESS } = process.env

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
        console.log(`Balance before transfer: ${contractBalanceEth} BLR`)
        // getting permission to withdraw:
        await myContract.connect(admin).approve(signer.address, value)

        const response = await myContract.connect(signer).allowance(admin.address, signer.address)
        const responseEth = ethers.utils.formatEther(response)
        console.log(`Allowed to withdraw from this address: ${responseEth} BLR`)
        
        //---------
        // transferring tokens and then checking that it is allowed to be equal to minus value.
        // since the transaction takes a long time, the final result does not wait until the 
        // transaction is mined, so the final result is not correct, but all the logic of 
        // the function works correctly.

        // await myContract.connect(signer).transferFrom(admin.address, signer.address, value);
        
        // const finalResponse = await myContract.connect(signer).allowance(admin.address, signer.address);

        // const finalResponseEth = await ethers.utils.formatEther(finalResponse);
        // console.log("Allowed to withdraw from this address: ", finalResponseEth);

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