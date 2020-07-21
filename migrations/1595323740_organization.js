const Organization = artifacts.require('Organization.sol');

module.exports = function(_deployer) {
  // Use deployer to state migration tasks.
  _deployer.deploy(Organization);
};
