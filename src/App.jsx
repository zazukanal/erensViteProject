import React, { useState, useEffect } from 'react';
import Web3 from 'web3';
import WordIEEDU from "./WordlEDU.json";

const contractABI = WordIEEDU;
const contractAddress = import.meta.env.VITE_CONTRACT_ADDRESS; // Kontrat adresinizi buraya ekleyin


const App = () => {
  const [web3, setWeb3] = useState(null);
  const [account, setAccount] = useState('');
  const [contract, setContract] = useState(null);
  const [balance, setBalance] = useState(0);
  const [tokenCost, setTokenCost] = useState(0);
  const [hintCost, setHintCost] = useState(0);
  const [lastGuess, setLastGuess] = useState('');
  const [lastFeedback, setLastFeedback] = useState('');
  const [guess, setGuess] = useState('');
  const [hint, setHint] = useState('');
  const [isOwner, setIsOwner] = useState(false);

  useEffect(() => {
    if (window.ethereum) {
      const web3Instance = new Web3(window.ethereum);
      setWeb3(web3Instance);

      const init = async () => {
        const accounts = await web3Instance.eth.requestAccounts();
        setAccount(accounts[0]);

        const contractInstance = new web3Instance.eth.Contract(contractABI, contractAddress);
        setContract(contractInstance);

        const tokenCost = await contractInstance.methods.tokenCost().call();
        const hintCost = await contractInstance.methods.hintCost().call();
        setTokenCost(web3Instance.utils.fromWei(tokenCost, 'ether'));
        setHintCost(web3Instance.utils.fromWei(hintCost, 'ether'));

        const contractBalance = await web3Instance.eth.getBalance(contractAddress);
        setBalance(web3Instance.utils.fromWei(contractBalance, 'ether'));

        const lastGuess = await contractInstance.methods.lastGuess(accounts[0]).call();
        const lastFeedback = await contractInstance.methods.lastFeedback(accounts[0]).call();
        setLastGuess(lastGuess);
        setLastFeedback(lastFeedback);

        const ownerAddress = await contractInstance.methods.owner().call();
        setIsOwner(accounts[0].toLowerCase() === ownerAddress.toLowerCase());
      };

      init();
    } else {
      alert('Please install MetaMask!');
    }
  }, []);

  const makeGuess = async () => {
    if (contract && guess) {
      const weiCost = web3.utils.toWei(tokenCost, 'ether');
      await contract.methods.makeGuess(guess).send({ from: account, value: weiCost });
    }
  };

  const buyHint = async () => {
    if (contract) {
      const weiHintCost = web3.utils.toWei(hintCost, 'ether');
      await contract.methods.buyHint().send({ from: account, value: weiHintCost });
    }
  };

  const getLastGuessAndFeedback = async () => {
    if (contract) {
      const result = await contract.methods.getLastGuessAndFeedback().call({ from: account });
      setLastGuess(result[0]);
      setLastFeedback(result[1]);
    }
  };

  const setSecretWord = async () => {
    if (contract && isOwner) {
      const word = prompt('Enter the secret word (5 characters):');
      if (word && word.length === 5) {
        await contract.methods.setSecretWord(word).send({ from: account });
      } else {
        alert('The secret word must be exactly 5 characters.');
      }
    }
  };

  return (
    <div>
      <h1>WordlEDU</h1>
      <p>Account: {account}</p>
      <p>Contract Balance: {balance} ETH</p>
      <p>Token Cost: {tokenCost} ETH</p>
      <p>Hint Cost: {hintCost} ETH</p>

      <div>
        <h2>Your Last Guess</h2>
        <p>Guess: {lastGuess}</p>
        <p>Feedback: {lastFeedback}</p>
      </div>

      <div>
        <h2>Make a Guess</h2>
        <input
          type="text"
          placeholder="Enter your guess (5 letters)"
          value={guess}
          onChange={(e) => setGuess(e.target.value)}
        />
        <button onClick={makeGuess}>Submit Guess</button>
      </div>

      <div>
        <h2>Buy a Hint</h2>
        <button onClick={buyHint}>Buy Hint</button>
      </div>

      <div>
        <h2>Get Last Guess and Feedback</h2>
        <button onClick={getLastGuessAndFeedback}>Fetch Last Guess and Feedback</button>
      </div>

      {isOwner && (
        <div>
          <h2>Set Secret Word</h2>
          <button onClick={setSecretWord}>Set Secret Word</button>
        </div>
      )}
    </div>
  );
};

export default App;
