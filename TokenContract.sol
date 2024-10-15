// SPDX-License-Identifier: Unlicenced
pragma solidity 0.8.18;

contract TokenContract {
    address public owner;

    struct Receivers {
        string name;
        uint256 tokens;
    }

    mapping(address => Receivers) public users;
        modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor(){
        owner = msg.sender;
        users[owner].tokens = 100;
    }

    function double(uint _value) public pure returns (uint){
    return _value*2;
    }

    function register(string memory _name) public{
    users[msg.sender].name = _name;
    }

    function giveToken(address _receiver, uint256 _amount) onlyOwner public{
        require(users[owner].tokens >= _amount);
        users[owner].tokens -= _amount;
        users[_receiver].tokens += _amount;
    }
// Function to purchase tokens with Ether
    function buyTokens() public payable {
        uint256 tokensToBuy = msg.value / 5 ether;  // 1 token costs 5 Ether
        require(tokensToBuy > 0, "Insufficient Ether sent");
        require(users[owner].tokens >= tokensToBuy, "Not enough tokens available for sale");

        // Transfer the tokens to the buyer
        users[owner].tokens -= tokensToBuy;
        users[msg.sender].tokens += tokensToBuy;
    }
    
    // Function to check the balance of Ether in the contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to withdraw Ether from the contract (only owner)
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
