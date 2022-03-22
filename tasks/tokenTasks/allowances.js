const { PRIVATE_KEY, PRIVATE_KEY2, URL_ALCHEMY, CONTRACT_ADDRESS } = process.env

async function main() {

    const contractAddress = CONTRACT_ADDRESS
    const provider = new ethers.providers.JsonRpcProvider(URL_ALCHEMY)
    const admin = new ethers.Wallet(PRIVATE_KEY, provider)
    const signer = new ethers.Wallet(PRIVATE_KEY2, provider)
    const myContract = await ethers.getContractAt('ERC20token', contractAddress, admin)
    
    try {
        const response = await myContract.connect(signer).allowance(admin.address, signer.address)
        const responseEth = ethers.utils.formatEther(response)
        console.log(`Address ${signer.address} 
        is allowed to withdraw off:${responseEth} BLR from the address ${admin.address}`)

    } catch (error) {
        console.log('Something went wrong: ', error)
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })