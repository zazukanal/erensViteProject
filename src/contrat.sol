// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WordlEDU {
    address public owner;
    string private secretWord; 
    uint256 public tokenCost; 
    uint256 public hintCost; 
    mapping(address => uint256) public balances; 
    mapping(address => string) public lastGuess; // Kullanıcının son tahmini saklayacak harita
    mapping(address => string) public lastFeedback; // Kullanıcının son feedback'ini saklayacak harita

    event GuessMade(address indexed player, string guess, string feedback);
    event TokensTransferred(address indexed player, uint256 amount);
    event TokenCostUpdated(uint256 newTokenCost);
    event ContractBalanceUpdated(uint256 newBalance);
    event HintRevealed(string hint);  

    constructor() payable {
        require(msg.value == 100 gwei, "Contract needs 100 Gwei.");
        owner = msg.sender;
        tokenCost = 100 gwei;
        hintCost = (address(this).balance * 20) / 100;  
        emit ContractBalanceUpdated(address(this).balance); 
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    function setSecretWord(string memory _word) public onlyOwner {
        require(bytes(_word).length == 5, "Word must be exactly 5 characters.");
        secretWord = _word;
    }

    function makeGuess(string memory _guess) public payable {
        uint256 newTokenCost = (address(this).balance * 10) / 100;
        tokenCost = newTokenCost;
        emit TokenCostUpdated(tokenCost);

        require(bytes(secretWord).length == 5, "Secret word not set.");
        require(bytes(_guess).length == 5, "Guess must be exactly 5 characters.");
        

        string memory feedback = _analyzeGuess(_guess);

        if (keccak256(abi.encodePacked(_guess)) == keccak256(abi.encodePacked(secretWord))) {
            uint256 contractBalance = address(this).balance;
            uint256 ownerShare = (contractBalance * 10) / 100;
            payable(owner).transfer(ownerShare);

            uint256 userShare = (contractBalance * 90) / 100;
            balances[msg.sender] += userShare;
        }

        // Son tahmin ve feedback'i sakla
        lastGuess[msg.sender] = _guess;
        lastFeedback[msg.sender] = feedback;

        emit GuessMade(msg.sender, _guess, feedback);
    }

    function _analyzeGuess(string memory _guess) private view returns (string memory) {
    bytes memory secretBytes = bytes(secretWord);
    bytes memory guessBytes = bytes(_guess);
    bytes memory feedback = new bytes(5);
    bool[5] memory secretUsed = [false, false, false, false, false]; // Hangi secret harflerin kullanıldığını takip etmek için.

    // İlk olarak doğru yerdeki harfleri işaretle (G)
    for (uint256 i = 0; i < 5; i++) {
        if (guessBytes[i] == secretBytes[i]) {
            feedback[i] = "G"; 
            secretUsed[i] = true;  // Bu harf zaten doğru konumda kullanıldı
        } else {
            feedback[i] = "B"; // Başlangıçta "B" olarak işaretle
        }
    }

    // Daha sonra yanlış yerdeki doğru harfleri işaretle (Y)
    for (uint256 i = 0; i < 5; i++) {
        if (feedback[i] == "B") {  // Yalnızca "B" olanları kontrol et
            for (uint256 j = 0; j < 5; j++) {
                // Harfi başka bir yerde bulursak, feedback[i]'yi "Y" yapalım ve secretUsed[j]'yi true yapalım
                if (!secretUsed[j] && guessBytes[i] == secretBytes[j]) {
                    feedback[i] = "Y"; 
                    secretUsed[j] = true; // Bu harf de kullanıldı
                    break;
                }
            }
        }
    }

    return string(feedback); 
}




    function withdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw.");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit TokensTransferred(msg.sender, amount);
    }

    function withdrawOwner() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Hint satın alma fonksiyonu
    function buyHint() public payable {
        
        require(bytes(secretWord).length == 5, "Secret word not set.");

        emit HintRevealed("Hint: The secret word is 5 letters long.");
    }

    // Owner'ın hinti değiştirmesi için fonksiyon
    function setHint(string memory _hint) public onlyOwner {
        emit HintRevealed(_hint);
    }

    // Kullanıcının son tahmini ve feedback'ini almasına izin veren fonksiyon
    function getLastGuessAndFeedback() public view returns (string memory, string memory) {
        return (lastGuess[msg.sender], lastFeedback[msg.sender]);
    }
}
