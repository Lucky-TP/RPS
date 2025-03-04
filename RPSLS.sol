
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";

contract RPSLS {
    CommitReveal public commitReveal;

    uint public numPlayer = 0;
    uint public reward = 0;
    uint public numRevealed = 0;

    mapping(address => uint) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - Spock, 4 - Lizard
    mapping(address => bool) public player_not_played;

    address[] public players;

    address[4] public whitelistedAddresses = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    constructor(address _commitRevealAddress) {
        commitReveal = CommitReveal(_commitRevealAddress);
    }

    function generateRandomInput(uint8 choice) public view returns (bytes32, bytes32) {
        require(choice < 5, "Invalid choice (must be 0-4)");

        // Generate 31 random bytes using keccak256 (pseudo-random)
        bytes32 randBytes = keccak256(abi.encodePacked(block.timestamp, msg.sender));

        // Clear the last byte to zero
        randBytes &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00;
        
        // Add choice to the last byte
        bytes32 dataInput = randBytes | bytes32(uint256(choice)); 

        // Return both the raw input and its hash
        return (dataInput, keccak256(abi.encodePacked(dataInput)));
    }

    function getHash(bytes32 data) public view returns(bytes32){
        return commitReveal.getHash(data);
    }

    function commitChoice(bytes32 dataHash) public {
        require(numPlayer == 2, "Need 2 players.");
        commitReveal.commit(msg.sender, dataHash);
    }

    function revealChoice(bytes32 revealData) public {
        require(numPlayer == 2, "Game has not started.");

        // Extract commit data from tuple
        bytes32 commit = commitReveal.getPlayerCommit(msg.sender);
        bool isRevealed = commitReveal.getPlayerRevealed(msg.sender);

        require(commit != bytes32(0), "Commit not found.");
        require(!isRevealed, "Already revealed.");

        // Call reveal in CommitReveal.sol
        commitReveal.reveal(msg.sender, revealData);

        // Extract choice from the last byte of revealData
        uint choice = uint(uint8(revealData[31])) % 5;
        player_choice[msg.sender] = choice;
        numRevealed++;

        if (numRevealed == 2) {
            _checkWinnerAndPay();
        }
    }

    function isWhitelisted(address _player) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _player) {
                return true;
            }
        }
        return false;
    }
    function addPlayer() public payable {
        require(isWhitelisted(msg.sender), "Not authorized to play.");
        require(numPlayer < 2, "Players Full.");
        if (numPlayer > 0) {
            require(msg.sender != players[0]);
        }
        require(msg.value == 1 ether);
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;
    }


    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);
        // change winner logic to work with Rock, Paper, Scissors, Spock, Lizard
        if ((p0Choice + 1) % 5 == p1Choice || (p0Choice + 3) % 5 == p1Choice) {
            // to pay player[1]
            account1.transfer(reward);
        }
        else if ((p1Choice + 1) % 5 == p0Choice || (p1Choice + 3) % 5 == p0Choice) {
            // to pay player[0]
            account0.transfer(reward);
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        resetGame();
    }

    function resetGame() private {
        for (uint i = 0; i < players.length; i++) {
            commitReveal.resetPlayerCommits(players[i]);
            delete player_choice[players[i]];
            delete player_not_played[players[i]];
        }
        delete players;
        numPlayer = 0;
        reward = 0;
        numRevealed = 0;
    }
}
