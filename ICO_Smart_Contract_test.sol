// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/ICO_Smart_Contract.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract ICOTest {
    
    TTTContract ttt;
    Crowdsale crowdsale;
    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // <instantiate contract>
        ttt = new TTTContract();
        crowdsale = new Crowdsale(payable(TestsAccounts.getAccount(1)), address(ttt));
    }

    function checkDescriptionFields() public {
        // Use 'Assert' methods: https://remix-ide.readthedocs.io/en/latest/assert_library.html
        Assert.equal(ttt.name(), "Test Token", "Should be equal to 'Test Token'");
        Assert.equal(ttt.symbol(), "TTT", "Should be equal to 'Test Token'");
        Assert.equal(ttt.totalSupply(), 0, "Initial supply should be equal to 0");
    }

    
    function checkMint() public  {
        ttt.mint(TestsAccounts.getAccount(0), 100);
        Assert.equal(ttt.balanceOf(TestsAccounts.getAccount(0)), 100, "Balance should change to 100");
        Assert.equal(ttt.totalSupply(), 100, "Supply should change to 0");
    }
    
    /// #sender: account-1
    /// #value: 100
    function checkBuyTokenFailsWithoutMinterRole() public payable {
        // return !crowdsale.buyTokens(TestsAccounts.getAccount(0));
        (bool success, bytes memory data) = address(crowdsale).call(
            abi.encodeWithSignature("buyTokens(address)", TestsAccounts.getAccount(1))
        );
        
        Assert.ok(!success, "Transaction should fail");
    }
    
    
    function grantMinterRole() public {
        ttt.grantRole(ttt.MINTER_ROLE(), address(crowdsale));
        Assert.ok(ttt.hasRole(ttt.MINTER_ROLE(), address(crowdsale)), "Crowdsale should have minter role");
        
    }
    
    function checkBuyTokenSucceedWithMinterRole() public payable {
        crowdsale.buyTokens{value: 100}(TestsAccounts.getAccount(1));
        Assert.ok(ttt.hasRole(ttt.MINTER_ROLE(), address(crowdsale)), "Crowdsale should have minter role");
        Assert.equal(ttt.balanceOf(TestsAccounts.getAccount(1)), 100 * 42, "Account-1 should have 4200 tokens");   
    }
    

}


contract TestToken is TTTContract {

     /// #sender: account-1
    function checkTransferWhiteListExcluded() public payable {
        Assert.ok(!hasRole(TRANSFER_WHITELIST_ROLE, TestsAccounts.getAccount(1)), "Account-1 should not have TRANSFER_WHITELIST_ROLE this test");
        (bool success, bytes memory data) = address(this).call(
            abi.encodeWithSignature("transfer(address)", TestsAccounts.getAccount(2))
        );
      
        Assert.ok(!success, "Transfer should fail since ICO is open and accout is not in white list");
    }
    
    
    function grantWhiteListRole() public {
        grantRole(TRANSFER_WHITELIST_ROLE, TestsAccounts.getAccount(1));
        Assert.ok(hasRole(TRANSFER_WHITELIST_ROLE, TestsAccounts.getAccount(1)), "Account-1 should have TRANSFER_WHITELIST_ROLE this test");
    }
    
    /// #sender: account-1
    function checkTransferWhiteListIncluded() public {
        Assert.ok(hasRole(TRANSFER_WHITELIST_ROLE, TestsAccounts.getAccount(1)), "Account-1 should have TRANSFER_WHITELIST_ROLE this test");
        Assert.ok(transfer(TestsAccounts.getAccount(2), 0), "Transfer should succeed");
    }


}
