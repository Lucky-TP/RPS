
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract RPSLS {
    CommitReveal public commitReveal;
    TimeUnit public timeUnit;

    uint public numPlayer = 0;
    uint public reward = 0;
    uint public numRevealed = 0;

    uint public revealStartTime;
    uint256 public constant PLAYER_JOIN_TIMEOUT = 1; // Timeout if another player does not join
    uint256 public constant REVEAL_TIMEOUT = 2; // Timeout if a player does not reveal
    event PlayerWithdraw(address player, uint amount);
    event PlayerForfeited(address forfeiter, address winner, uint amount);

    mapping(address => uint) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - Spock, 4 - Lizard
    mapping(address => bool) public player_not_played;

    address[] public players;

    address[4] public whitelistedAddresses = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    constructor(address _commitRevealAddress, address _timeUnitAddress) {
        commitReveal = CommitReveal(_commitRevealAddress);
        timeUnit = TimeUnit(_timeUnitAddress);
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

        if (numPlayer == 1) {
            timeUnit.setStartTime();
        } else if (numPlayer == 2) {
            timeUnit.setStartTime();
        }
    }

    function withdrawIfNoOpponent() public {
        require(numPlayer == 1, "Can only withdraw if waiting for an opponent.");
        require(players[0] == msg.sender, "Only Player 0 can withdraw.");
        require(timeUnit.elapsedMinutes() >= PLAYER_JOIN_TIMEOUT, "Not Timeout Yet");

        address payable player = payable(players[0]);
        uint amount = reward;
        
        resetGame();
        player.transfer(amount);
        
        emit PlayerWithdraw(player, amount);
    }

    function forfeitUnresponsivePlayer() public {
        require(numPlayer == 2, "Game not started.");
        require(numRevealed < 2, "Both players have revealed.");
        require(timeUnit.elapsedMinutes() >= REVEAL_TIMEOUT, "Reveal period not over yet.");

        address forfeiter;
        address payable receiver;

        if (player_choice[players[0]] == 0 && player_choice[players[1]] == 0) {
            // Both players failed to reveal → Refund both
            payable(players[0]).transfer(reward / 2);
            payable(players[1]).transfer(reward / 2);
            resetGame();
            return;
        } else if (player_choice[players[0]] == 0) {
            // Player 0 did not reveal, refund Player 1
            forfeiter = players[0];
            receiver = payable(players[1]);
        } else {
            // Player 1 did not reveal, refund Player 0
            forfeiter = players[1];
            receiver = payable(players[0]);
        }

        uint refundAmount = reward / 2;
        resetGame();
        receiver.transfer(refundAmount);

        emit PlayerForfeited(forfeiter, receiver, refundAmount);
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
