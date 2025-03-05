# 📝 Rock, Paper, Scissors, Lizard, Spock (RPSLS) Solidity Smart Contract

## 📌 Project Overview
This project implements a **secure and fair blockchain-based Rock, Paper, Scissors, Lizard, Spock (RPSLS) game** using Solidity.  

### ✅ Key Features:
- **Commit-Reveal Mechanism** → Prevents front-running attacks.  
- **Time-Locked Withdrawals** → Ensures ETH is not locked indefinitely.  
- **Whitelisted Players Only** → Restricts access to specific accounts.  
- **Game Reset After Completion** → Allows continuous gameplay.  
- **Fair Winner Determination** → Uses smart contract logic to decide the outcome.  

---

## 📌 Requirement

✅ **ทำให้ contract ใช้งานได้ใหม่ เมื่อจ่ายรางวัลไปแล้ว**  
✅ **อนุญาตให้คนที่จะเล่นเกมส์นี้ได้ต้องใช้ account จาก 4 account ต่อไปนี้เท่านั้น:**  

      0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
      0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
      0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
      0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

✅ **จากเกมเป่ายิ้งฉุบธรรมดา แปลงให้เป็นเกมเป่ายิ้งฉุบที่น่าสนใจมากขึ้น**  
(เปลี่ยนเป็น **Rock, Paper, Scissors, Lizard, Spock (RPSLS) game**)  
- 🌍 [**Big Bang Theory Fandom - RPSLS**](https://bigbangtheory.fandom.com/wiki/Rock,_Paper,_Scissors,_Lizard,_Spock)  
- 🎥 [**Gameplay Explanation (YouTube)**](https://www.youtube.com/watch?v=x5Q6-wMx-K8)

✅ **แก้ front-running โดยใช้การ commit-reveal เพื่อซ่อนการเลือก**  
✅ **แก้ปัญหาเงินของ player 0 อาจถูกล๊อกไว้ ถ้าไม่มี player 1 มาลงขันต่อ**  
✅ **กรณีได้ player ทั้ง 2 แล้ว แต่มีเพียง player เดียวที่ลง choice มา แต่อีก player ไม่ยอมเรียก input function เพื่อส่ง choice มาให้ smart contract ได้ตัดสินแพ้ ชนะ เสมอ**  
- **ต้องใช้ฟังก์ชั่นเกี่ยวกับเวลาเพื่อเปิดโอกาสให้มีการถอนเงินออกหลังจากระยะเวลาผ่านไประยะหนึ่ง**  

---

## 📌 Smart Contracts Included
| **File** | **Description** |
|----------|--------------|
| `RPSLS.sol` | The main game contract implementing Rock, Paper, Scissors, Lizard, Spock with commit-reveal and time-unit logic. |
| `RPS.sol` | The Original game contract for Rock, Paper, Scissors without commit-reveal and time-unit logic. |
| `CommitReveal.sol` | A separate contract handling **commit-reveal** to prevent front-running. |
| `TimeUnit.sol` | A contract handling **time-based logic** to avoid fund lock issues. |
| `Convert.sol` | A contract handling convert, getHash, and getAddress functions. |

---

## 📌 How the Game Works

### 1️⃣ **Players Join**
- Only **whitelisted** accounts can play.
- Players must **stake 1 ETH** to participate.
- The game starts when **2 players have joined**.

### 2️⃣ **Commit Phase (Hiding Choices)**
- Each player **concatenates their choice with a random string**, which you can do with `generateRandomInput(choice)` function and keep the output for commit and reveal later on.
- The resulting value is **hashed** and stored via the `commitChoice()` function.
- This prevents the opponent from knowing the first player's choice (**prevents front-running**).

### 3️⃣ **Reveal Phase (Showing Choices)**
- Both players must reveal their original **random string + choice** using `revealChoice()`.
- The contract **verifies the commitment** to ensure no changes were made.
- Once both choices are revealed, the contract **determines the winner** and **pays the rewards**.

### 4️⃣ **Game Reset**
- After rewards are distributed, the game **resets automatically** so new players can join.

### 5️⃣ **Timeout Handling (Ensuring ETH Doesn't Get Locked)**
- If **Player 1 joins but no Player 2 joins within X minutes**, Player 1 can **withdraw their ETH**.
- If **one player commits or reveals but the other doesn’t within Y minutes**, both players get **refunded equally**.
- If **no players commit or reveal within Y minutes**, both players get **refunded equally**.
- This prevents ETH from being **stuck in the contract forever**.
- And it will reset the game after refunded.
---

## 📌 Code Functions

### 1️⃣ อธิบายโค้ดที่ป้องกันการ lock เงินไว้ใน contract

    function refundIfNoOpponent() public {
        require(numPlayer == 1, "Can only withdraw if waiting for an opponent.");
        require(timeUnit.elapsedMinutes() >= PLAYER_JOIN_TIMEOUT_MINUTES, "Not Timeout Yet.");

        // Refund to only 1 player
        payable(players[0]).transfer(reward);

        emit PlayerRefundIfNoOpponent(players[0], reward);

        resetGame();
    }
    
- โดยในโค้ดนี้จะตรวจสอบว่ามี player แค่ 1 คนใช่หรือไม่ และต่อมาจะเช็กว่าเกินกำหนดเวลาในหน่วยนาที ที่ตั้งไว้หรือไม่
- เมื่อผ่านเงื่อนไขแล้ว หลังจากนั้นจะทำการ refund ให้ player คนเดียว ที่อยู่ในระบบ และ ทำการเก็บ log โดยใช้ emit กับ event PlayerRefundIfNoOpponent(players[0], reward);
- และต่อมาจะทำการ resetGame() เพื่อให้เริ่มเกมใหม่ได้
  
#### อีกแบบหนึ่งจะเป็นการ refund ถ้าเกิดว่าผู้เล่นไม่ยอมกด reveal ซึ่งทำให้เกิดการ lock เงินไว้
      function refundIfNoReveal() public {
        require(numPlayer == 2, "Game not started");
        require(numRevealed < 2, "Both players have revealed.");
        require(timeUnit.elapsedMinutes() >= REVEAL_TIMEOUT_MINUTES, "Reveal period not over yet.");

        // If 1 or 2 players didn't reveal within the time, so refund both equally
        payable(players[0]).transfer(reward / 2);
        payable(players[1]).transfer(reward / 2);

        emit PlayersRefundIfNoReveal(players[0], players[1], reward);

        resetGame();
    }
- จะทำการเช็กก่อนว่าผู้เล่นมีครบทั้ง 2 คนมั้ย และ reveal ไปทั้ง 2 คนแล้วหรือยัง และ เช็กว่าเวลาเกินจาก REVEAL_TIMEOUT_MINUTES ที่ตั้งไว้หรือไม่
- ถ้าเกิดผ่านเงื่อนไขแล้วจะคืนเงินให้ผู้เล่นทั้ง 2 คน
- ทำการเก็บ log โดยใช้ emit กับ event PlayersRefundIfNoReveal(players[0], players[1], reward);
- และต่อมาจะทำการ resetGame() เพื่อให้เริ่มเกมใหม่ได้

### 2️⃣ อธิบายโค้ดส่วนที่ทำการซ่อน choice และ commit
    function generateRandomInput(uint8 choice) public view returns (bytes32, bytes32) {
        require(choice < 5, "Invalid choice (must be 0-4)");

        // Generate 31 random bytes using keccak256 (pseudo-random)
        bytes32 randBytes = keccak256(abi.encodePacked(block.timestamp, msg.sender));

        // Clear the last byte to zero
        randBytes &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00;
        
        // Add choice to the last byte
        bytes32 revealData = randBytes | bytes32(uint256(choice)); 

        // Compute the commit hash (dataHash)
        bytes32 dataHash = keccak256(abi.encodePacked(revealData));

        return (revealData, dataHash);
    }
- ผมเปลี่ยน logic ในการสุ่มจาก ตัวอย่าง choice_hiding_v2.ipynb ให้มาอยู่ใน contract ของ RPSLS เลยจะได้เล่นได้ง่ายขึ้น
- โค้ดในส่วนนี้จะเป็นการซ่อน choice โดยให้ผู้เล่นเลือกเลข 0 ถึง 4 และต่อมาจะทำการสุ่ม random bytes โดยใช้ keccak256 กับ block.timestamp, msg.sender (ข้อเสียคือมันไม่ได้ truly random)
- และนำ choice ไปต่อกับ random string ที่สร้างมา
- และ return ค่า revealData (เป็นค่าที่ random + choice มา ) กับ ค่าที่เป็น hashed จาก revealData ซึ่งคือ dataHash
- เมื่อสุ่มแล้วให้เก็บค่า revealData ไว้ใช้สำหรับ reveal และ dataHash ไว้ใช้สำหรับการ commit

      function commitChoice(bytes32 dataHash) public {
          require(numPlayer == 2, "Need 2 players.");
          require(isPlayer(msg.sender), "You are not a player in this game.");
          require(numRevealed == 0, "Can't change choice because someone has revealed.");
          commitReveal.commit(msg.sender, dataHash);
      }

- โดยจะทำการตรวจสอบว่ามีผู้เล่นเข้ามาแล้ว 2 คนหรือไม่ และตรวจสอบว่าคนที่กด commit ใช้ผู้เล่น 1 ใน 2 คนนั้นหรือไม่
- ต่อมาเราควรเช็กว่ามีคน revealed ไปแล้วรึยังจาก numRevealed เพราะถ้าหากมีคน revealed แล้วเราไม่ควรให้อีกคนหนึ่งเปลี่ยนช้อยส์ใน commit ได้ (ป้องกันเรื่อง front-running ด้วย เพราะถ้าอีกคนใส่ revealData แล้ว เราสามารถดูช้อยส์ของเขาได้ เพราะงั้นจึงห้ามเปลี่ยน commit หลังมีคน revealed)
- และทำการใช้ฟังก์ชัน commit จาก CommitReveal (ผมได้ทำการเปลี่ยนแปลงโค้ดใน CommitReveal ให้เก็บค่าตาม address ที่ส่งไปได้ ซึ่งก็คือ msg.sender) 

### 3️⃣ อธิบายโค้ดส่วนที่จัดการกับความล่าช้าที่ผู้เล่นไม่ครบทั้งสองคนเสียที (กรณีปัญหาเงินของ player 0 อาจถูกล๊อกไว้ ถ้าไม่มี player 1 มาลงขันต่อ)

    function refundIfNoOpponent() public {
        require(numPlayer == 1, "Can only withdraw if waiting for an opponent.");
        require(timeUnit.elapsedMinutes() >= PLAYER_JOIN_TIMEOUT_MINUTES, "Not Timeout Yet.");

        // Refund to only 1 player
        payable(players[0]).transfer(reward);

        emit PlayerRefundIfNoOpponent(players[0], reward);

        resetGame();
    }
    
- โดยในโค้ดนี้จะตรวจสอบว่ามี player แค่ 1 คนใช่หรือไม่ และต่อมาจะเช็กว่าเกินกำหนดเวลาในหน่วยนาที ที่ตั้งไว้หรือไม่
- เมื่อผ่านเงื่อนไขแล้ว หลังจากนั้นจะทำการ refund ให้ player คนเดียว ที่อยู่ในระบบ และ ทำการเก็บ log โดยใช้ emit กับ event PlayerRefundIfNoOpponent(players[0], reward);
- และต่อมาจะทำการ resetGame() เพื่อให้เริ่มเกมใหม่ได้

### 4️⃣ อธิบายโค้ดส่วนทำการ reveal และนำ choice มาตัดสินผู้ชนะ 
    function revealChoice(bytes32 revealData) public {
        require(numPlayer == 2, "Game has not started.");
        require(isPlayer(msg.sender), "You are not a player in this game.");

        bool isPlayer0Committed = commitReveal.getPlayerCommit(players[0]) != bytes32(0);
        bool isPlayer1Committed = commitReveal.getPlayerCommit(players[1]) != bytes32(0);
        bool areBothPlayersCommitted = (isPlayer0Committed && isPlayer1Committed);
        require(areBothPlayersCommitted, "Both players have to committed");
        // Extract commit data from tuple
        bytes32 commit = commitReveal.getPlayerCommit(msg.sender);
        bool isRevealed = commitReveal.getPlayerRevealed(msg.sender);

        require(commit != bytes32(0), "Commit not found.");
        require(!isRevealed, "Already revealed.");

        // Call reveal in CommitReveal.sol
        commitReveal.reveal(msg.sender, revealData);

        // Extract choice from the last byte of revealData
        uint choice = uint(uint8(revealData[31]));
        player_choice[msg.sender] = choice;
        numRevealed++;

        if (numRevealed == 2) {
            _checkWinnerAndPay();
        }
    }
- ในส่วนของการ reveal จะทำการตรวจสอบว่ามี Players ครบ 2 คนมั้ย และ player ที่กด reveal เป็นผู้เล่นที่อยู่ในเกมหรือไม่ จาก isPlayer(msg.sender)
- ตรวจสอบว่า Players ทั้ง 2 ทำการ commit หรือยัง เพราะทั้ง 2 Players ควร commit ก่อนถึงจะ reveal ได้
- ตรวจสอบว่าคนที่กด reveal ทำการ commit กับ  reveal มาแล้วหรือไม่
- ถ้าผ่านเงื่อนไขจะทำการเรียกฟังก์ชัน reveal จาก CommitReveal.sol
- และเก็บช้อยส์ของผู้เล่นไว้ใน player_choice จาก โดยเราจะรู้ช้อยส์จาก revealData[31]
- และเมื่อ numRevealed == 2 จะทำการตัดสินผู้ชนะโดยใช้ _checkWinnerAndPay()

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
- วิธีตรวจสอบว่าใครชนะเราจะดึงข้อมูลมาจาก player_choice และกำหนดไปใน p0Choice กับ p1Choice และกำหนด address ของแต่ละ account
- เราจะใช้ logic ที่คล้ายๆกับ RPS แต่จะเปลี่ยนโดยเพิ่มเงื่อนไข (choice + 3) เข้ามา และเปลี่ยนจากเดิมที่ %3 เป็น %5 ซึ่งสามารถดูได้ตามรูปวิธีการเล่นจากใน [**Big Bang Theory Fandom - RPSLS**](https://bigbangtheory.fandom.com/wiki/Rock,_Paper,_Scissors,_Lizard,_Spock)
- ซึ่งถ้าหาก choice ที่ (choice1 + 1) % 5 หรือ (choice1 + 3) % 5 แล้วตรงกับ choice2 ของอีกคน คนที่เลือกในรูปแบบ choice1 จะแพ้
- เพราะฉะนั้นเราจะโอนเงินให้ผู้ที่ชนะ
- และเมื่อมีการเสมอจะโอนเงินคืนให้เท่าๆกัน
- และทำการ resetGame()

### 5️⃣ อธิบายโค้ดการ Reset Game
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
        timeUnit.setStartTime();
    }
- จะทำการลบข้อมูล players ที่เล่นจากใน commitReveal.resetPlayerCommits และ player_choice กับ player_not_played
- ลบข้อมูล players ปัจจุบัน
- reset ค่าต่างๆ (numPlayer, reward, numRevealed)
- reset ค่าเวลาให้เริ่มคิด startTime ใหม่

### 6️⃣ อธิบายโค้ดการที่อนุญาตให้คนที่จะเล่นเกมส์นี้ได้ต้องใช้่ account จาก 4 account ที่กำหนดเท่านั้น
    address[4] public whitelistedAddresses = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];
    
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
        require(numPlayer < 2, "Cannot join: Maximum players reached.");
        if (numPlayer > 0) {
            require(msg.sender != players[0]);
        }
        require(msg.value == 1 ether, "Must bet 1 ETH.");
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
- จะทำการตรวจสอบว่าผู้เล่นอยู่ใน whitelist หรือไม่ และตรวจสอบว่ามีผู้เล่นเต็ม 2 คนหรือยัง
- เริ่มการนับเวลาเมื่อผู้เล่นเข้า 1 คน เผื่อในกรณีที่ไม่มีผู้เล่นอีกคนเข้ามาในระยะเวลาที่กำหนด
- หากมีผู้เล่นอีกคนเข้ามาจะทำการนับเวลาใหม่อีกครั้ง เพื่อใช้คิดในกรณีที่ไม่มีการ commit หรือ reveal ในระยะเวลาที่กำหนด
---

## 📌 How to Deploy
### Deploy Contracts
- Deploy CommitReveal.sol
- Deploy TimeUnit.sol
- Deploy RPSLS.sol, passing the addresses of CommitReveal and TimeUnit.

---

## 📌 How to Play

### 🎮 **Playing the Game**  
1️⃣ **Two whitelisted players join by sending 1 ETH each.**  
2️⃣ **Each player generates their `revealData and dataHash` using `generateRandomInput(choice)`.**  
3️⃣ **Players commit their choice using `commitChoice(dataHash)`.**  
4️⃣ **Players reveal their choice using `revealChoice(revealData)`.**  
5️⃣ **The contract verifies choices and determines the winner.**  
6️⃣ **The winner gets the reward, and the game resets.**  
7️⃣ **If a player does not reveal, both players are refunded.**  
8️⃣ **If no second player joins, the first player can withdraw their funds.**  

---

## Images
![image](https://github.com/user-attachments/assets/b84995cc-225d-41d7-b6c7-667f3f52af50)
