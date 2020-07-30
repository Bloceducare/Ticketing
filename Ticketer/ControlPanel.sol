// SPDX-License-Identifier: MIT OR Apache-2.0 
pragma solidity >= 0.5.0 < 0.7.0;

import 'Organization.sol';

contract ControlPanel {
    
    using SafeMath for uint256;
    using Address for address;
    
    address private _owner;
    bool private _allowSales;
    
    Organization organization;
    constructor(address orgAddress) public {
        organization = Organization(orgAddress);
    }
    
    function verifyOwnership() public returns(bool success){
        organization.verifyOwnership(msg.sender);
        _owner = msg.sender;
        return true;
    }
    
    function setRate(uint256 newRate) public returns(uint256 updatedRate, string memory symbol) {
        return organization.setRate(newRate, msg.sender);
    }
    
    // function setMaxBuy(uint256 maxBuy) public returns(bool success, uint256 updatedMaximumBuyAmount) {
    //     return organization.setMaximumBuy(maxBuy, msg.sender);
    // }
    
    function adminCount() public view returns(uint256 admins) {
        return organization.getAdminCount();
    }
    
    function showOrganizationDetail() public view returns(
      uint256 TotalTokens,
      string memory OwnerEmail,
      address Address,
      string memory TokenSymbol
      ) {
        return organization.getOrganizationDetail();
    }
    
    function addAdmin(
        address newAdminAddress,
        string memory newAdminEmail,
        uint256 newAdminSpendingLimit
    ) public returns (string memory, uint256) {
        return organization.addAdmin(newAdminAddress, newAdminEmail, newAdminSpendingLimit, msg.sender);
    }
    
    function removeAdmin(string memory adminEmail) public returns(address removedAdmin) {
        return organization.removeAdmin(bytes(adminEmail), msg.sender);
    }
    
    function showAdminDetail(string memory adminEmail) view public returns(address walletAddress, string memory email, uint256 spendingLimit) {
        return organization.getAdminDetail(bytes(adminEmail));
    }
    
    function getAdminBalance(string memory adminEmail) public view returns(address user, uint256 balance) {
        return organization.getAdminBalance(bytes(adminEmail));
    }
    
    function getAddressBalance(address userAddress) public view returns(address user, uint256 balance) {
        return organization.getAddressBalance(userAddress);
    }
    
    function transfer(address to, uint256 amount) public returns(bool success) {
        return organization.transferTo(to, amount, msg.sender);
    }
    
    function toggleSales() public returns(bool success, bool salesOpen){
        require(msg.sender == _owner, "You do no have the permission to do this");
        _allowSales = !_allowSales;
        return(true, _allowSales);
    }
    
    function getRate() public view returns(uint256 tokenRate, uint256 maximumBuy) {
        require(_allowSales, "Sales is currently disabled. Contact administrator is this is a mistake");
        (uint256 _rate, uint256 _maximumBuy) = organization.getTokenRate();
        return (_rate, _maximumBuy);
    }
    
    function buyTokens() public payable returns(address purchasedBy, uint256 amount) {
        require(_allowSales, "Sales is currently disabled. Contact administrator is this is a mistake");
        require(msg.value > 0, "The tokens aren't free!");
        (uint256 tokenRate,) = getRate();
        require(tokenRate > 0, "Admin has not specified rate of tokens");
        require(msg.value >= tokenRate, "You do not have enough to make a purchase, please check rate.");
        uint256 totalTokens = msg.value.mul(1 ether).div(tokenRate);
        return organization.buyTokens(msg.sender, totalTokens);
    }
    
    function acceptDonations() payable public returns(string memory) {
        (bool sent, ) = address(organization).call{value:msg.value}("");
        require(sent, "Something went wrong");
        return "Thank you for you generous donation";
    }
    
    function toggleDonations() public returns(bool success) {
        return organization.toggleDonations(msg.sender);
    }
}