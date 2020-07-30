// SPDX-License-Identifier: MIT OR Apache-2.0 
pragma solidity >= 0.5.0 < 0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

contract Organization is ERC20, ERC20Burnable {
    
    mapping (address => uint256) private _balances;
    
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    
    EnumerableSet.AddressSet private _admins;
    bool private _verified;

    bytes32 constant private ADMIN = keccak256("admin");
    address private _owner;
    bytes private OWNER_EMAIL;
    uint256 private _tokenRate = 0 ether;
    uint256 private _maximumBuy;
    uint256 private _initialSupply;
    
    bool private _acceptingDonations;
    address private _controlPanel;
    
    struct Admin {
        bytes email;
        address walletAddress;
        uint256 spendingLimit;
        EnumerableSet.AddressSet members;
    }

    struct _Organization {
        bytes _organizationName;
        bytes _organizationEmail;
        address _organizationAddress;
        address _owner;
        mapping(address => Admin) _admins;
        mapping(bytes => Admin) _readableAdmins;
    }
    
    mapping(address => _Organization) organizationStruct;
    mapping(bytes => Admin) internal adminStruct;

    constructor(
      uint256 initialSupply,
      string memory name,
      string memory symbol,
      bytes memory organization_email,
      bytes memory organization_name,
      bytes memory creator_email,
    //   address _ticketer,
      address creator
     ) public payable ERC20(name, symbol) 
    {
    _maximumBuy = initialSupply.div(3); // You can only buy a third of the total tokens, subject to change
    _owner = creator; // hand over ownership to the creator of the contract
    _initialSupply = initialSupply;
    
    // Define the organization
    OWNER_EMAIL = creator_email;
    organizationStruct[address(this)]._organizationName = organization_name;
    organizationStruct[address(this)]._organizationEmail = organization_email;
    organizationStruct[address(this)]._organizationAddress = address(this);
    organizationStruct[address(this)]._owner = _owner;
    
    
    // Define Owner's Admin struct
    adminStruct[creator_email].email = creator_email;
    adminStruct[creator_email].walletAddress = _owner;
    adminStruct[creator_email].spendingLimit = totalSupply();
    // _mint(creator, initialSupply);
  }
  
  // Admin Logic - STARTS
  
  function hasRole(address userAddress) public view returns(bool) {
      return _admins.contains(userAddress);
  }
   
  modifier isOwner(address _caller) {
      require(_caller == _owner, "Only the owner can do this");
      _;
   }
   
   modifier callerIsAdmin(address _caller) {
      require(hasRole(_caller), "You are not an admin of this organization");
      _;
   }
   
   modifier isControlPanel() {
       require(msg.sender == _controlPanel); // Only ticketer can make the calls
       _;
   }
   
   function verifyOwnership(address _caller) external returns(bool) {
        require(_caller == _owner, "You cannot claim what is not yours");
        require(!_verified, "This account has already been verified, please go to the control panel to interract with the contract");
        _verified = true;
        _owner = _caller;
        _controlPanel = msg.sender;
        _admins.add(msg.sender);
        _admins.add(_caller);
        _mint(msg.sender, _initialSupply);
        approve(_caller, totalSupply());
        return true;
   }
   
   function setRate(uint256 _newRate, address _caller) external isControlPanel isOwner(_caller) returns(uint256, string memory) {
       _tokenRate = _newRate.mul(0.00000001 ether);
       return (_tokenRate, symbol());
   }
   
//   function setMaximumBuy(uint256 _newMaximumBuy, address _caller) external isControlPanel isOwner(_caller) returns(bool, uint256) {
//       _maximumBuy = _newMaximumBuy;
//       return (true, _maximumBuy);
//   }

    function transferTo(address to, uint256 amount, address _caller) callerIsAdmin(_caller) external returns(bool) {
        transferFrom(_caller, to, amount);
        return true;
    }
   
   function getTokenRate() external view returns(uint256, uint256){
      require(_tokenRate > 0, "Admin is yet to set the rate for this tokens/tickets");
      return (_tokenRate, _maximumBuy);
   }
   
   function getOrganizationDetail() external view returns(uint256, string memory, address, string memory) {
      return (totalSupply(), string(adminStruct[OWNER_EMAIL].email), address(this), symbol());
   }
  
  function getTotalSupply()public view returns(uint){
      return totalSupply();
  }
  
  function getAdminCount() external view returns(uint256) {
      return _admins.length();
  }
   
  function addAdmin(
    address _newAdminAddress,
    string calldata _newAdminEmail,
    uint256 _newAdminSpendingLimit,
    address _caller
    ) isControlPanel isOwner(_caller) external returns(string memory, uint256)
  {
      require(!_admins.contains(_newAdminAddress));
      adminStruct[bytes(_newAdminEmail)].email = bytes(_newAdminEmail);
      adminStruct[bytes(_newAdminEmail)].walletAddress = _newAdminAddress;
      _admins.add(_newAdminAddress);
      approve(_newAdminAddress, _newAdminSpendingLimit);
      return (_newAdminEmail, _newAdminSpendingLimit);
  }
  
  function removeAdmin(bytes calldata _adminEmail, address _caller) isControlPanel isOwner(_caller) external returns (address){
      address adminAddress = adminStruct[_adminEmail].walletAddress;
      _admins.remove(adminAddress);
      approve(adminAddress, 0);
      return adminAddress;
  }
  
  function getAdminDetail(bytes calldata _adminEmail) view external returns(address, string memory, uint256) {
      address _walletAddress = adminStruct[_adminEmail].walletAddress;
      require(hasRole(_walletAddress), "Not a valid admin");
      string memory _email = string(_adminEmail);
      uint256 _spendingLimit = adminStruct[_adminEmail].spendingLimit;
      return (_walletAddress, _email, _spendingLimit);
  }
  
  function getAdminBalance(bytes calldata _adminEmail) external view returns(address, uint256){
      address _userAddress = adminStruct[_adminEmail].walletAddress;
      require(hasRole(_userAddress), "Not an admin account");
      uint256 _balance = balanceOf(_userAddress);
      return (_userAddress, _balance);
  }
  
  function getAddressBalance(address _userAddress) external view returns(address, uint256){
      return (_userAddress, balanceOf(_userAddress));
  }
 
  function getMyAllowance() external view returns(uint256) {
      return allowance(_owner, msg.sender);
  }
  
  function approveSpending(bytes calldata _adminEmail, uint256 _amount, address _caller) isControlPanel isOwner(_caller) external returns(bool success) {
      address _adminAddress = _getAdminAddressFromEmail(_adminEmail);
      require(hasRole(_adminAddress), "Not a valid admin");
      approve(_adminAddress, 0);
      approve(_adminAddress, _amount);
      return true;
  }
  
  function _getAdminAddressFromEmail(bytes memory _adminEmail) private view returns(address){
        address _adminAddress = adminStruct[_adminEmail].walletAddress;
        require(hasRole(_adminAddress), "Not a valid Admin");
        return _adminAddress;
  }
  
  function buyTokens(address buyer, uint256 amount) public returns(address, uint256){
     transfer(buyer, amount);
     return (buyer, amount);
  } 
  
  // Admin Logic -ENDS
  
  function showOwnerDetails() external view returns(address ownerAddress, string memory ownerEmail){
      address _ownerAddress = adminStruct[OWNER_EMAIL].walletAddress;
      string memory _ownerEmail = string(adminStruct[OWNER_EMAIL].email);
      return (_ownerAddress, _ownerEmail);
  }
  
  function _tokenSymbol() external view returns(string memory) {
      return symbol();
  }
  
  function toggleDonations(address _caller) isControlPanel isOwner(_caller) external returns(bool){
      _acceptingDonations = !_acceptingDonations;
      return true;
  }
  // Organization Functions - ENDS
  
  fallback() external {
      // I have no idea what to put here yet
      
  }
 
}