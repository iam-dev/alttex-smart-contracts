pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract AlttexCrowdsale is Ownable {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    uint256 public startTime = 1520067600;  // Human time (GMT): Saturday 3 March 2018 09:00:00
    uint256 discountValue;
    uint256 discountStage1 = 30;
    uint256 discountStage2 = 20;
    uint256 discountStage3 = 10;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;
    //Total sold tokens with ETH contributions
    uint256 public totalTokenSoldEth;

    // Amount of wei raised that contribute with BTC. Satoshi is converted manualy to wei amount
    uint256 public satoshiToWeiRaised;
    //Total sold tokens with BTC contributions
    uint256 public totalTokenSoldBtc;

    // Amount of tokens cap for ETH contributions
    uint256 public ethTokenCap; // 70% ETH
    // Amount of tokens cap for BTC contributions
    uint256 public btcTokenCap; // 30% BTC

    bool public isActive = true;

     uint256 public constant TOKEN_PRICE_N = 1 ether;                // initial price in wei (numerator)  


    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * @param _rate Number of token units a buyer gets per wei
    * @param _wallet Address where collected funds will be forwarded to
    * @param _token Address of the token being sold
    */
    function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    /**
    * @dev Throws if status of the sale is not active
    */
    modifier onlyActive() {
        require(isActive);
        _;
    }

    /**
    * @dev Reverts if not in crowdsale time range. 
    */
    modifier onlyWhileOpen {
        require(now >= startTime);
        _;
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
    * @dev USD to ETH rate will be set each 2 weeks
    * USD price is average price in 2 weeks
    */
    function setRate(uint256 _rate) public onlyOwner{
        require(_rate != 0);
        rate = _rate;    
    }


    function setEthTokenCap(uint256 _ethTokenCap) public onlyOwner onlyActive {
        require(_ethTokenCap != 0);
        ethTokenCap = _ethTokenCap;
    }

    function setBtcTokenCap(uint256 _btcTokenCap) public onlyOwner onlyActive {
        require(_btcTokenCap != 0);
        btcTokenCap = _btcTokenCap;
    }

    function setWallet(address _wallet) public onlyOwner onlyActive {
        wallet = _wallet;
    }

    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }  

    /**
    * @dev low level token purchase ***DO NOT OVERRIDE***
    * @param _beneficiary Address performing the token purchase
    */
    function buyTokens(address _beneficiary) 
        public
        payable
        onlyActive
        onlyWhileOpen
    {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        _processPurchase(_beneficiary, tokens);
        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        totalTokenSoldEth = totalTokenSoldEth.add(tokens);

        _forwardFunds();
    }

    function contributeBtc(address _beneficiary, uint256 _weiAmount) public onlyOwner onlyActive {
        _preValidateBtcPurchase(_beneficiary, _weiAmount);

        // update state
        satoshiToWeiRaised = satoshiToWeiRaised.add(_weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(_weiAmount);

        _processPurchase(_beneficiary, tokens);
        TokenPurchase(msg.sender, _beneficiary, _weiAmount, tokens);
        totalTokenSoldBtc = totalTokenSoldBtc.add(tokens);
    }
    

    /**
    * @dev Checks whether the ETH cap has been reached. 
    * @return Whether the ETH cap was reached
    */
    function ethTokenCapReached() public view returns (bool) {
        return totalTokenSoldEth >= ethTokenCap;
    }

    /**
    * @dev Checks whether the BTC cap has been reached. 
    * @return Whether the BTC cap was reached
    */
    function btcTokenCapReached() public view returns (bool) {
        return totalTokenSoldBtc >= btcTokenCap;
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
    * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view{
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(weiRaised.add(_weiAmount) <= ethTokenCap);
    }

    /**
    * @dev Validation of an incoming BTC purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidateBtcPurchase(address _beneficiary, uint256 _weiAmount) internal view {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(satoshiToWeiRaised.add(_weiAmount) <= btcTokenCap);
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }

    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _beneficiary Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    function _getTokenAmount(uint256 _weiAmount) internal returns (uint256){
        if (now <= startTime && now < startTime + 1 days) {
            discountValue = discountStage1;
        } else if(now >= startTime + 1 days && now < startTime + 21 days) {
            discountValue = discountStage2;
        } else if(now >= startTime + 21 days && now < startTime + 28 days) {
            discountValue = discountStage3;
        } else {
            discountValue = 0;
        }  
        // calculate token amount to be created
        uint256 all = 100;
        uint256 tokens;
        // calculate token amount 
        tokens = _weiAmount.mul(rate).mul(100).div(all.sub(discountValue));
        return tokens;
    }
      

    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}
