const Bayes = artifacts.require("Bayes");

module.exports = function (deployer) {
    deployer.deploy(Bayes);
}