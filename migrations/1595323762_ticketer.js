const Ticketer = artifacts.require('Ticketer.sol');

module.exports = function(_deployer) {
  // Use deployer to state migration tasks.
  _deployer.deploy(Ticketer);
};
