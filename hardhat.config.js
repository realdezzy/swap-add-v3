require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.5.0",
        settings: {
        optimizer: {
          enabled: true,
          runs: 1000,
        },
      },
      },
      {
        version: "0.7.6",
        settings: {
        optimizer: {
          enabled: true,
          runs: 1000,
        },
      },
      },
      {
        version: "0.8.0",
        settings: {
        optimizer: {
          enabled: true,
          runs: 1000,
        },
      },
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://bsc-dataseed1.binance.org/",
      }
    }
  }
};

