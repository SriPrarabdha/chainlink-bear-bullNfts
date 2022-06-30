require("@nomiclabs/hardhat-waffle");
const dotenv = require('dotenv')
dotenv.config()

const PRIVATE_KEY = process.env.PRIVATE_KEY
const ALCHEMY_API_URL = process.env.ALCHEMY_API_KEY_URL


module.exports = {
  solidity: "0.8.4",
  networks : {
    rinkeby : {
      url : ALCHEMY_API_URL ,
      accounts : [PRIVATE_KEY],
    },
  },
};
