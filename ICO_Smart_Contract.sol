// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControlEnumerable.sol";
 
contract TTTContract is AccessControlEnumerable, ERC20{
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ICO_ADMIN_ROLE = keccak256("ICO_ADMIN_ROLE");
    bytes32 public constant TRANSFER_WHITELIST_ROLE = keccak256("TRANSFER_WHITELIST_ROLE");
    
    bool public ICOstatus = true;

    constructor() ERC20("Test Token", "TTT") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(ICO_ADMIN_ROLE, _msgSender());
        _setupRole(TRANSFER_WHITELIST_ROLE, _msgSender());
    }
    
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role to mint");
        _mint(to, amount);
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (ICOstatus) {
            require(hasRole(TRANSFER_WHITELIST_ROLE, _msgSender()), "Must be in whitelist to transfer while ICO");
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function closeICO() public onlyRole(ICO_ADMIN_ROLE) {
        ICOstatus = false;
    }
    
    function openICO() public onlyRole(ICO_ADMIN_ROLE) {
        ICOstatus = true;
    }
}

contract Crowdsale is Context {
    // The token being sold
    TTTContract private _token;

    address payable private _wallet;

    uint256 private _rate;

    uint256 private _weiRaised;
    
    uint256 constant FIRST_PERIOD_DURATION = 3 days;
    uint256 constant SECOND_PERIOD_DURATION = 30 days;
    uint256 constant THIRD_PERIOD_DURATION = 2 weeks;
    
    
    uint256 ICO_FIRST_PERIOD_START_TIMESTAMP;
    uint256 ICO_SECOND_PERIOD_START_TIMESTAMP;
    uint256 ICO_THIRD_PERIOD_START_TIMESTAMP;
    uint256 ICO_END_TIMESTAMP;
    
    
    enum ICOStage { DEFAULT, FIRST, SECOND, THIRD, ENDED }
    
    ICOStage stage = ICOStage.DEFAULT;
    
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor (address payable wallet, address tokenAddress)  {
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(tokenAddress != address(0), "Crowdsale: token is the zero address");

        _wallet = wallet;
        _token = TTTContract(tokenAddress);
        
        
         ICO_FIRST_PERIOD_START_TIMESTAMP = block.timestamp;
         ICO_SECOND_PERIOD_START_TIMESTAMP = ICO_FIRST_PERIOD_START_TIMESTAMP + FIRST_PERIOD_DURATION;
         ICO_THIRD_PERIOD_START_TIMESTAMP = ICO_SECOND_PERIOD_START_TIMESTAMP + SECOND_PERIOD_DURATION;
         ICO_END_TIMESTAMP = ICO_THIRD_PERIOD_START_TIMESTAMP + THIRD_PERIOD_DURATION;
    }
    
 
    
    function _checkStage() internal{
        require(block.timestamp >= ICO_FIRST_PERIOD_START_TIMESTAMP, "ICO hasn`t started yet");
        require(stage != ICOStage.ENDED, "ICO has finished already");
        
        if (block.timestamp >= ICO_FIRST_PERIOD_START_TIMESTAMP
                                    && block.timestamp < ICO_SECOND_PERIOD_START_TIMESTAMP 
                                            && stage != ICOStage.FIRST) {
            stage = ICOStage.FIRST;
             _rate = 42;
        } else if (block.timestamp >= ICO_SECOND_PERIOD_START_TIMESTAMP
                                            && block.timestamp < ICO_THIRD_PERIOD_START_TIMESTAMP
                                                     && stage != ICOStage.SECOND) {
            stage = ICOStage.SECOND;
            _rate = 21;
        } else if (block.timestamp >= ICO_THIRD_PERIOD_START_TIMESTAMP
                                            && block.timestamp < ICO_END_TIMESTAMP
                                                    && stage != ICOStage.THIRD) {
            stage = ICOStage.THIRD;
            _rate = 8;
        } else if (block.timestamp >= ICO_END_TIMESTAMP) {
            stage = ICOStage.ENDED;
            _token.closeICO();
            revert("ICO has finished already");
            
        }
        
    }

    receive() external payable {
        buyTokens(_msgSender());
    }

    function getToken() public view returns (IERC20) {
        return _token;
    }

    function getWallet() public view returns (address payable) {
        return _wallet;
    }


    function getRate() public view returns (uint256) {
        return _rate;
    }


    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }


    function buyTokens(address beneficiary) public payable {
        _checkStage();
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised += weiAmount;

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);


        _forwardFunds();
    }


    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }


    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.mint(beneficiary, tokenAmount);
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }


    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount * _rate ;
    }

  
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}