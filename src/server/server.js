import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

// Unknown (0), On Time (10) or Late Airline (20), Late Weather (30), Late Technical (40), or Late Other (50)
const statusCodes = [0, 10, 20, 30, 40, 50];

// Upon startup, 20+ oracles are registered and their assigned indexes are persisted in memory
var oracles = [];

// Server will loop through all registered oracles,
// identify those oracles for which the OracleRequest event applies, and respond
// by calling into FlightSuretyApp contract with random status code of Unknown (0), On Time (10) or Late Airline (20),
// Late Weather (30), Late Technical (40), or Late Other (50)



async () => {
  const accounts = web3.eth.getAccounts();
  accounts.forEach(account => {
    flightSuretyApp.methods.registerOracle().send({
      "from": account,
      "value": fee
    });
  
    const indexes = flightSuretyApp.methods.getMyIndexes().call({ from: account });
    
    // generate random status code
    const statusCode = statusCodes[Math.floor(Math.random() * statusCodes.length)] 
  
    let oracle = { account, indexes, statusCode };
  
    console.log("Oracle: ", statusCode);
  
    oracles.push(oracle);
  });  
};


// Update flight status requests from client Dapp result in OracleRequest event emitted 
// by Smart Contract that is captured by server (displays on console and handled in code)
flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    console.log("server.js#flightSuretyApp.events.OracleRequest: ",event)
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


