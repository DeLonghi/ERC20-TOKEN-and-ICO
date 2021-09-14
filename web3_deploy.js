// Right click on the script name and hit "Run" to execute
(async () => {
    try {
        console.log('Running deployWithWeb3 script...')
        
        const TTTContract = 'TTTContract' // Change this for other contract
        const Crowdsale = "Crowdsale"
        const TTTContract_constructorArgs = []    // Put constructor args (if any) here for your contract
    
        // Note that the script needs the ABI which is generated from the compilation artifact.
        // Make sure contract is compiled and artifacts are generated
        const TTTContract_artifactsPath = `browser/contracts/artifacts/${TTTContract}.json` // Change this for different path
        const Crowdsale_artifactsPath = `browser/contracts/artifacts/${Crowdsale}.json` // Change this for different path

        const TTTContract_metadata = JSON.parse(await remix.call('fileManager', 'getFile', TTTContract_artifactsPath))
        const Crowdsale_metadata = JSON.parse(await remix.call('fileManager', 'getFile', Crowdsale_artifactsPath)); 
        
        const accounts = await web3.eth.getAccounts()
    
        let TTTContract_contract = new web3.eth.Contract(TTTContract_metadata.abi)
    
        TTTContract_contract = TTTContract_contract.deploy({
            data: TTTContract_metadata.data.bytecode.object,
            arguments: TTTContract_constructorArgs
        })
    
        const newContractInstance = await TTTContract_contract.send({
            from: accounts[0],
            gas: 8000000,
            gasPrice: '30000000000'
        })
        console.log('Contract deployed at address: ', newContractInstance.options.address)
        
        const Crowdsale_constructorArgs = ["0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", newContractInstance.options.address]
        
        let Crowdsale_contract = new web3.eth.Contract(Crowdsale_metadata.abi)
    
        
        Crowdsale_contract = Crowdsale_contract.deploy({
            data: Crowdsale_metadata.data.bytecode.object,
            arguments: Crowdsale_constructorArgs
        })
        
        const newContractInstance_ = await Crowdsale_contract.send({
            from: accounts[0],
            gas: 8000000,
            gasPrice: '30000000000'
        })
        
        
        console.log('Contract deployed at address: ', newContractInstance_.options.address)
        
        const MINTER_ROLE = await newContractInstance.methods.MINTER_ROLE().call({from: accounts[0]})
        console.log("MINTER_ROLE hash: " + MINTER_ROLE) 
        
        newContractInstance.methods.grantRole(MINTER_ROLE, newContractInstance_.options.address)
        .send({from: accounts[0]}, function(err, res){
            console.log("Grant role result:")
            console.log(err)
            console.log(res)
        });
        
    } catch (e) {
        console.log(e.message)
    }
  })()