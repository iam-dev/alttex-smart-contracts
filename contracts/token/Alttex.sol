pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Alttex is StandardToken, Ownable {
    string public name  = "Alttex";
    string public symbol = "ALTX";
    uint256 public constant decimals = 8;
    uint256 public initialBalance = 50000000*10**8; 

    function Alttex() public {
        owner = msg.sender;
        balances[owner] = initialBalance; // balance of Token address will be 100% of the HME company shares when initialize the contract 
        totalSupply_ = initialBalance;
    }

    //fallback function
    function () external payable{
        revert();
    }

    //the ability to change the name of the token
    function setName(string _name) public onlyOwner {
        name = _name;
    }

    //the ability to change the symbol of the token
    function setSymbol(string _symbol) public onlyOwner {
        symbol = _symbol;
    }
}