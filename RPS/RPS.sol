//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
    constructor ()payable {}

    

    enum Hand {
        rock, paper, scissors
    }

    enum PlayerStatus {
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPILE, STATUS_ERROR
    }

    struct Player{
        address payable addr;
        uint256 playerBetAmount;
        uint256 determine;
        PlayerStatus playerStatus;
    }

    struct Game {
        Player originator;
        Player taker;
        uint256 betAmount;
        GameStatus gameStatus;
    }

    mapping(uint => Game) rooms;
    uint roomLen = 0;

    modifier isValidHand (Hand _hand){
        require((_hand == Hand.rock || _hand == Hand.paper || _hand == Hand.scissors));
        _;
    }

    event win_result(address winner, uint8 winner_hand, address looser, uint8 looser_hand);
    event tie_result(address originator, uint8 originator_hand, address taker, uint8 taker_hand);

    function createRoom (uint _determine) public payable returns (uint roomNum){
        rooms[roomLen] = Game({
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                determine: _determine,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            taker: Player({
                determine: _determine,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });

        roomNum = roomLen;
        roomLen = roomLen+1;
    }

    function joinRoom(uint roomNum, uint256 _determine) public payable{
        rooms[roomNum].taker = Player({
            determine : _determine,
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });

        rooms[roomNum].betAmount += msg.value;
        compareHands(roomNum);
    }

    function compareHands(uint roomNum) private {
        uint8 originator = uint8(
            (uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) + rooms[roomNum].originator.determine)  % 3
        );
        uint8 taker = uint8(
            (uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) + rooms[roomNum].taker.determine)  % 3
        );

        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;

        if(taker == originator){
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
            emit tie_result(rooms[roomNum].originator.addr, originator, rooms[roomNum].taker.addr, taker);
        } else if((taker + 1)% 3 == originator){
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
            emit win_result(rooms[roomNum].originator.addr, originator, rooms[roomNum].taker.addr, taker);
        } else if((originator + 1) % 3  == taker){
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            emit win_result(rooms[roomNum].taker.addr, taker, rooms[roomNum].originator.addr, originator);
        } else {
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
    }

    function checkTotalPay (uint roomNum) public view returns(uint roomNumPay){
        return rooms[roomNum].betAmount;
    }

    modifier isPlayer(uint roomNum, address sender){
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }

    function payout (uint roomNum) public payable isPlayer(roomNum, msg.sender) {
        if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE){
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        } else {
            if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN){
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
            } else if(rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN){
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            } else{
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            }
        }
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPILE;
    }

    function maxBetRoom () public view returns(uint roomNum){
        require(roomLen > 0, "NOT AVAILABLE GAME");
        uint maxBet = 0;
        uint maxIdx = 0;

        for (uint i = 0; i < roomLen; i++){
            if (rooms[i].gameStatus == GameStatus.STATUS_NOT_STARTED && rooms[i].betAmount > maxBet){
                maxBet = rooms[i].betAmount;
                maxIdx = i;
            }
        }

        return maxIdx;
    }

    function numPersonInRoom(uint256 _numIdx) public view returns(uint256){
        // 사람 수 반환시키기
    }
}