// SPDX-License-Identifier: MIT OR Apache-2.0 
pragma solidity >= 0.5.0 < 0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

import "./Organization.sol";

contract Ticketer is Ownable {
    using SafeMath for uint256; 
    using Strings for string; 
    uint256 public rate;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    
    constructor () public {
        rate = 0.0001 ether;
    }
    
    EnumerableSet.AddressSet private registeredOrganizations;

    struct OrganizationStruct {
        bytes organizationName;
        bytes organizationEmail;
        bytes organizationOwnerEmail;
        address organizationAddress;
        address organizationOwner;
        bool nameTaken;
    }
    
    function adjustCost(uint256 newRate) public onlyOwner() returns(bool) {
        rate = newRate.mul(0.00000001 ether);
    }
    
    mapping (bytes => OrganizationStruct) private organizations;
    // mapping(address => OrganizationStruct) private organizations;
    
    modifier isRegistered (string memory _orgName) {
        address orgAddress = _fetchOrgAddress(_orgName);
        require(registeredOrganizations.contains(orgAddress), "No such organization registered with ticketer");
        _;
    }
    
    function howManyTokensFor(uint256 _toPay) public view returns(uint256) {
        return (_toPay.mul(0.00000001 ether)).div(rate);
    }
    
    function registeredOrganizationCount () view public returns(uint256) {
        return registeredOrganizations.length();
    }
    
    function _fetchOrgAddress(string memory _orgName) view private returns(address){
        return organizations[bytes(_orgName)].organizationAddress;
    }
    

    function _organizationInstance(string memory orgName) view private returns(Organization) {
        address orgAddress = _fetchOrgAddress(orgName);
          Organization organization = Organization(orgAddress);
          return organization;
    }
    
    function fetchOwnerDetails(string memory orgName) view public returns(address ownerAddress, string memory ownerEmail){
        address orgAddress = organizations[bytes(orgName)].organizationAddress;
        require(registeredOrganizations.contains(orgAddress), "Organization is not registered");
        Organization organization = Organization(orgAddress);
        return organization.showOwnerDetails();
    }
    
    function notExits(string memory _name) private view returns(bool){
        address orgAddress = organizations[bytes(_name)].organizationAddress;
        require(!registeredOrganizations.contains(orgAddress));
        return true;
    }
    
    function createNewOrganization(
        string memory tokenName,
        string memory tokenSymbol,
        string memory organizationName,
        string memory organizationEmail,
        string memory creatorEmail
    ) public payable returns(address organization, address owner) {
        require(msg.value > 0 ether, "You need to pay something so we can keep running the business");
        // require(!organizations[bytes(organizationName)].nameTaken, "Name is already taken");
        require(notExits(organizationName), "Name is already taken");
        uint256 _tokenAmount = msg.value.div(rate);
        
        // uint256 forGas  // TODO send 5% goes to the organization to cater for future gas price

        Organization newOrganization = new Organization(
            _tokenAmount,
            tokenName,
            tokenSymbol,
            bytes(organizationEmail),
            bytes(organizationName),
            bytes(creatorEmail),
            // address(this),
            msg.sender
        );
        
        
        registeredOrganizations.add(address(newOrganization));
        organizations[bytes(organizationName)].organizationOwner = msg.sender; 
        organizations[bytes(organizationName)].nameTaken = true; 
        organizations[bytes(organizationName)].organizationName = bytes(organizationName); 
        organizations[bytes(organizationName)].organizationEmail = bytes(organizationEmail);
        organizations[bytes(organizationName)].organizationAddress = address(newOrganization);
        
        return (address(newOrganization), msg.sender);
    }
    
    fallback() external {}
}


