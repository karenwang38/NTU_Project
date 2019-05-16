var Parking = artifacts.require("./Parking.sol"); //deploy ExampleContract

module.exports = function(deployer) {
  deployer.deploy(Parking);
};
