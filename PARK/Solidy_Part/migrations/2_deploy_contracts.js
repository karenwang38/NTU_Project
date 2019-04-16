var Parking = artifacts.require("./Parking.sol");

module.exports = function(deployer) {
  deployer.deploy(Parking);
};
