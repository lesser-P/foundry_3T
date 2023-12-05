// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IRouterClient} from "@chainlink/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {LinkTokenInterface} from "@chainContracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract TTTDemo is CCIPReceiver, OwnerIsCreator {
    ///////////////
    ///  ERROR  ///
    ///////////////

    error NoMessageReceived();
    error IndexOutOfBound(uint256 providedIndex, uint256 maxIndex);
    error MessageIdNotExist(bytes32 messageId);
    error NothingToWithdraw();
    error FailedToWithdrawEth(address owner, address target, uint256 value);
    error NotEnoughBalance(uint256 balance, uint256 fees);

    LinkTokenInterface s_linkToke;

    struct GameSession {
        bytes32 sessionId;
        address player1;
        address player2;
        address winner;
        address turn; //check who takes action in next step
        uint8[9] play1Status; // current statis for player 1
        uint8[9] play2Status; // current statis for player 2
    }

    mapping(bytes32 => GameSession) public gameSessions;
    bytes32[] public sessionIds;

    uint8[9] initialCombination = [0, 0, 0, 0, 0, 0, 0, 0, 0];

    function getPlay1Status(bytes32 _sessionId) external view returns (uint8[9] memory) {
        return gameSessions[_sessionId].play1Status;
    }

    function getPlay2Status(bytes32 _sessionId) external view returns (uint8[9] memory) {
        return gameSessions[_sessionId].play2Status;
    }

    ///////////////////
    ///  Event  ///////
    ///////////////////

    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        GameSession message,
        uint256 fee
    );
    event MessageReceived( // the chain selector of the source chain
        // the address of the sender on the source chain
    bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, GameSession message);

    // Struct to hold details of message
    struct Message {
        uint64 sourceChainSelector;
        address sender;
        GameSession message;
    }

    // storage variables
    bytes32[] public receivedmessages; // Array to keep track of the IDS of received messages
    mapping(bytes32 => Message) public messageDetail; // Mapping from message ID to message Struct ,storing details of each received message
    address public _router; // this router is destination router
    address public _linkToken; // this address of linkToken

    constructor(address router) CCIPReceiver(router) {} // this router is receiver router

    function updateRouter(address router) external {
        _router = router;
    }

    function updateLinkToken(address linkToken) external {
        _linkToken = linkToken;
    }

    function start(uint64 destinationChainSelector, address receiver) external {
        bytes32 uniqueId = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        sessionIds.push(uniqueId);
        gameSessions[uniqueId] = GameSession(
            uniqueId, msg.sender, address(0), address(0), msg.sender, initialCombination, initialCombination
        );
        sendMessage(destinationChainSelector, receiver, gameSessions[uniqueId]);
    }

    function checkWin(uint8[9] memory playerStatus) public pure returns (bool _return) {
        if (horizontalCheck(playerStatus) || verticalCheck(playerStatus) || diagonalCheck(playerStatus)) {
            return true;
        }
        return false;
    }

    function horizontalCheck(uint8[9] memory playerStatus) private pure returns (bool horizontalValidation) {
        if (playerStatus[0] == 1 && playerStatus[1] == 1 && playerStatus[2] == 1) {
            horizontalValidation = true;
        } else if (playerStatus[3] == 1 && playerStatus[4] == 1 && playerStatus[5] == 1) {
            horizontalValidation = true;
        } else if (playerStatus[6] == 1 && playerStatus[7] == 1 && playerStatus[8] == 1) {
            horizontalValidation = true;
        } else {
            horizontalValidation = false;
        }
    }

    function verticalCheck(uint8[9] memory playerStatus) private pure returns (bool verticalValidation) {
        if (playerStatus[0] == 1 && playerStatus[3] == 1 && playerStatus[6] == 1) {
            verticalValidation = true;
        } else if (playerStatus[1] == 1 && playerStatus[4] == 1 && playerStatus[7] == 1) {
            verticalValidation = true;
        } else if (playerStatus[2] == 1 && playerStatus[5] == 1 && playerStatus[8] == 1) {
            verticalValidation = true;
        } else {
            verticalValidation = false;
        }
    }

    function diagonalCheck(uint8[9] memory playerStatus) private pure returns (bool diagonalValidation) {
        if (playerStatus[0] == 1 && playerStatus[4] == 1 && playerStatus[8] == 1) {
            diagonalValidation = true;
        } else if (playerStatus[2] == 1 && playerStatus[4] == 1 && playerStatus[6] == 1) {
            diagonalValidation = true;
        } else {
            diagonalValidation = false;
        }
    }

    function sendMessage(uint64 destinationChainSelector, address receiver, GameSession memory message)
        public
        returns (bytes32 messageId)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(message),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 400_000, strict: false})),
            feeToken: _linkToken
        });
        IRouterClient router = IRouterClient(_router);

        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);

        s_linkToke = LinkTokenInterface(_linkToken);

        if (fees > s_linkToke.balanceOf(address(this))) {
            revert NotEnoughBalance(s_linkToke.balanceOf(address(this)), fees);
        }

        s_linkToke.approve(address(router), fees);

        // 两种付费模式，可用原生代币也可使用Link代币

        messageId = router.ccipSend(destinationChainSelector, evm2AnyMessage);

        emit MessageSent(messageId, destinationChainSelector, receiver, message, fees);

        return messageId;
    }

    function move(
        uint256 x,
        uint256 y,
        uint256 player,
        bytes32 sessionId,
        uint64 destinationChainSelector,
        address receiver
    ) public {
        GameSession memory gs = gameSessions[sessionId];

        // make sure the ganme setup and not over
        require(gs.player1 != address(0), "Game not setup");
        require(gs.winner == address(0), "the game is over");

        require(player == 1 || player == 2, "you must be player1 or player2");

        if (player == 1) {
            require(gs.player1 == msg.sender || gs.turn == msg.sender, "it is not your turn");

            if (gs.play1Status[x * 3 + y] == 0 && gs.play2Status[x * 3 + y] == 0) {
                gameSessions[sessionId].play1Status[x * 3 + y] = 1;

                if (checkWin(gameSessions[sessionId].play1Status)) {
                    gameSessions[sessionId].winner = gameSessions[sessionId].player1;
                } else {
                    gameSessions[sessionId].turn = gameSessions[sessionId].player2;
                }
                sendMessage(destinationChainSelector, receiver, gameSessions[sessionId]);
            } else {
                revert("the position is occupied");
            }
        } else if (player == 2) {
            require(
                gs.player2 == msg.sender && gs.turn == msg.sender || gs.player2 == address(0), "it is not your turn"
            );
            if (gs.player2 == address(0)) {
                gameSessions[sessionId].player2 = msg.sender;
            }

            //////////////////////////////////////
            //  x=0 y=0  // x=0 y=1  // x=0 y=2 //
            //////////////////////////////////////
            //  x=1 y=0  // x=1 y=1  // x=1 y=2 //
            /////////////////////////////////////
            //  x=2 y=0  // x=2 y=1  // x=2 y=2 //
            //////////////////////////////////////

            if (gs.play1Status[x * 3 + y] == 0 && gs.play2Status[x * 3 + y] == 0) {
                gameSessions[sessionId].play2Status[x * 3 + y] = 1;

                if (checkWin(gameSessions[sessionId].play2Status)) {
                    gameSessions[sessionId].winner = gameSessions[sessionId].player2;
                } else {
                    gameSessions[sessionId].turn = gameSessions[sessionId].player1;
                }
                sendMessage(destinationChainSelector, receiver, gameSessions[sessionId]);
            } else {
                revert("the position is occupied");
            }
        }
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        bytes32 messageId = message.messageId;
        uint64 sourceChainSelector = message.sourceChainSelector;
        address sender = abi.decode(message.sender, (address));

        // save gameSession info
        GameSession memory _gameSession = abi.decode(message.data, (GameSession));
        receivedmessages.push(messageId);
        Message memory detail = Message(sourceChainSelector, sender, _gameSession);
        messageDetail[messageId] = detail;
        gameSessions[_gameSession.sessionId] = _gameSession;
        sessionIds.push(_gameSession.sessionId);

        emit MessageReceived(messageId, sourceChainSelector, sender, _gameSession);
    }

    function getNumberOfreceivedMessage() external view returns (uint256 number) {
        return receivedmessages.length;
    }

    function getLastReceivedMessageDetails()
        external
        view
        returns (bytes32 messageId, uint64 sourceChainSelector, address sender, GameSession memory message)
    {
        if (receivedmessages.length == 0) {
            revert NoMessageReceived();
        }

        messageId = receivedmessages[receivedmessages.length - 1];
        Message memory detail = messageDetail[messageId];

        return (messageId, detail.sourceChainSelector, detail.sender, detail.message);
    }

    receive() external payable {}

    function widthdraw(address beneficary) public onlyOwner {
        uint256 amount = address(this).balance;

        if (amount <= 0) revert NothingToWithdraw();

        (bool sent,) = beneficary.call{value: amount}("");

        if (!sent) {
            revert FailedToWithdrawEth(msg.sender, beneficary, amount);
        }
    }

    function description() public pure returns (string memory) {
        return "this is version 0.0";
    }
}
