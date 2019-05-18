var Parking = artifacts.require("./Parking.sol"); //deploy ExampleContract
var APtoken = artifacts.require("./APtoken.sol"); //deploy ExampleContract


module.exports = function(deployer) {
  deployer.deploy(APtoken, 1000000, 100);
  deployer.deploy(Parking);


  // deployer.deploy(APtoken, 1000000, 100).then(function() {
  //   return deployer.deploy(Parking, APtoken.address, '0xca35b7d915458ef540ade6068dfe2f44e8fa733c');
  // });

};
