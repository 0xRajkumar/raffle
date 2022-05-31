//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract RaffleContract is Ownable, IERC721Receiver, ReentrancyGuard {
    using Counters for Counters.Counter;
    address public immutable USDC;
    address public immutable NFT;
    uint256 public withdrawablePool;
    Counters.Counter public _raffleId;
    Counters.Counter private _raffleCompleted;
    Counters.Counter private _raffleCancelled;

    enum RaffleStatus {
        Cancelled,
        Active,
        Completed
    }

    enum TicketsLimit {
        Finite,
        Infinite
    }

    enum PrizeTypes {
        Tokens,
        NFT
    }

    enum PaidStatus {
        No,
        Yes
    }

    struct Raffle {
        uint256 raffleId;
        uint256 rafflePrize;
        PrizeTypes prizeType;
        uint256 price;
        uint256 totalTickets;
        TicketsLimit ticketLimit;
        uint256 mininumTickets;
        uint256 endIn;
        address winner;
        address[] participants;
        RaffleStatus status;
        PaidStatus isPaid;
    }

    mapping(uint256 => Raffle) raffles;
    mapping(uint256 => mapping(address => uint256)) ticketPurchased;
    mapping(uint256 => uint256) totalTicketSold;

    constructor(address usdcAddress, address nftAddress) {
        USDC = usdcAddress;
        NFT = nftAddress;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function createRaffleUSDC(
        uint256 rafflePrizeAmount_,
        uint256 price_,
        uint256 endIn_,
        uint256 totalTickets_,
        TicketsLimit ticketLimit_,
        uint256 minimumTickets_
    ) public onlyOwner {
        require(
            IERC20(USDC).allowance(owner(), address(this)) >=
                rafflePrizeAmount_,
            'Contract not approved'
        );
        require(
            IERC20(USDC).balanceOf(owner()) >= rafflePrizeAmount_,
            'Not enough USDC tokens'
        );
        IERC20(USDC).transferFrom(owner(), address(this), rafflePrizeAmount_);

        _raffleId.increment();
        raffles[_raffleId.current()] = Raffle(
            _raffleId.current(),
            rafflePrizeAmount_,
            PrizeTypes.Tokens,
            price_,
            totalTickets_,
            ticketLimit_,
            minimumTickets_,
            block.timestamp + endIn_,
            address(0),
            new address[](0),
            RaffleStatus.Active,
            PaidStatus.No
        );
    }

    function createRaffleNFT(
        uint256 rafflePrizeTokenId_,
        uint256 price_,
        uint256 endIn_,
        uint256 totalTickets_,
        TicketsLimit ticketLimit_,
        uint256 minimumTickets_
    ) public onlyOwner {
        require(
            IERC721(NFT).isApprovedForAll(msg.sender, address(this)),
            'Contract not approved'
        );
        require(
            IERC721(NFT).ownerOf(rafflePrizeTokenId_) == msg.sender,
            'Only owner'
        );
        IERC721(NFT).safeTransferFrom(
            owner(),
            address(this),
            rafflePrizeTokenId_
        );
        _raffleId.increment();
        raffles[_raffleId.current()] = Raffle(
            _raffleId.current(),
            rafflePrizeTokenId_,
            PrizeTypes.NFT,
            price_,
            totalTickets_,
            ticketLimit_,
            minimumTickets_,
            block.timestamp + endIn_,
            address(0),
            new address[](0),
            RaffleStatus.Active,
            PaidStatus.No
        );
    }

    function raffleById(uint256 id) public view returns (Raffle memory) {
        require(
            id <= _raffleId.current() && id > 0,
            'Raffle id does not exist'
        );
        return raffles[id];
    }

    function ticketPurchasedById(uint256 id, address adr)
        public
        view
        returns (uint256)
    {
        require(
            id <= _raffleId.current() && id > 0,
            'Raffle id does not exist'
        );
        return ticketPurchased[id][adr];
    }

    function cancelRaffle(uint256 id) public onlyOwner {
        require(
            id <= _raffleId.current() && id > 0,
            'Raffle id does not exist'
        );
        Raffle storage raffle = raffles[id];
        require(
            raffle.status == RaffleStatus.Active,
            'Raffle status is not active'
        );
        raffle.status = RaffleStatus.Cancelled;
        _raffleCancelled.increment();
        if (raffle.prizeType == PrizeTypes.Tokens) {
            IERC20(USDC).transfer(owner(), raffle.rafflePrize);
        } else {
            IERC721(NFT).safeTransferFrom(
                address(this),
                owner(),
                raffle.rafflePrize
            );
        }
    }

    function fetchCompletedRaffle() public view returns (Raffle[] memory) {
        uint256 raffleCount = _raffleId.current();
        uint256 leftCompletedRaffles = _raffleCompleted.current();
        uint256 currentIndex = 0;
        Raffle[] memory CompletedRaffles = new Raffle[](leftCompletedRaffles);
        for (uint256 i = 0; i < raffleCount; i++) {
            if (raffles[i + 1].status == RaffleStatus.Completed) {
                uint256 currentId = i + 1;
                Raffle storage currentRaffle = raffles[currentId];
                CompletedRaffles[currentIndex] = currentRaffle;
                currentIndex += 1;
            }
        }
        return CompletedRaffles;
    }

    function fetchCancelledRaffle() public view returns (Raffle[] memory) {
        uint256 raffleCount = _raffleId.current();
        uint256 leftCancelledRaffles = _raffleCancelled.current();
        uint256 currentIndex = 0;
        Raffle[] memory CancelledRaffles = new Raffle[](leftCancelledRaffles);
        for (uint256 i = 0; i < raffleCount; i++) {
            if (raffles[i + 1].status == RaffleStatus.Cancelled) {
                uint256 currentId = i + 1;
                Raffle storage currentRaffle = raffles[currentId];
                CancelledRaffles[currentIndex] = currentRaffle;
                currentIndex += 1;
            }
        }
        return CancelledRaffles;
    }

    function unclaimedWonRaffles(address wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 raffleCount = _raffleId.current();
        uint256 unclaimedWins;
        for (uint256 i = 0; i < raffleCount; i++) {
            if (
                raffles[i + 1].winner == wallet &&
                raffles[i + 1].isPaid == PaidStatus.No
            ) {
                unclaimedWins++;
            }
        }

        uint256[] memory raffleIds = new uint256[](unclaimedWins);
        uint256 index;
        for (uint256 i = 0; i < raffleCount; i++) {
            if (
                raffles[i + 1].winner == wallet &&
                raffles[i + 1].isPaid == PaidStatus.No
            ) {
                raffleIds[index] = i + 1;
                index++;
            }
        }
        return raffleIds;
    }

    function getRaffleHistory(uint256 limit)
        public
        view
        returns (Raffle[] memory)
    {
        require(limit > 0, 'Can"t get zero ');
        Raffle[] memory cancelledRaffles = fetchCancelledRaffle();
        Raffle[] memory completedRaffles = fetchCompletedRaffle();
        uint256 totalRaffleHistory = cancelledRaffles.length +
            completedRaffles.length;
        require(
            totalRaffleHistory > 0,
            'No cancelled or completed raffles exist'
        );
        uint256 correctLimit = limit;
        if (totalRaffleHistory < limit) {
            correctLimit = totalRaffleHistory;
        }
        uint256 raffleCount = _raffleId.current();
        uint256 currentIndex = 0;
        Raffle[] memory limitRaffles = new Raffle[](correctLimit);
        for (
            uint256 i = raffleCount;
            ((i > 0) && (currentIndex < correctLimit));
            i--
        ) {
            if (
                raffles[i].status == RaffleStatus.Cancelled ||
                raffles[i].status == RaffleStatus.Completed
            ) {
                uint256 currentId = i;
                Raffle storage currentRaffle = raffles[currentId];
                limitRaffles[currentIndex] = currentRaffle;
                currentIndex += 1;
            }
        }
        return limitRaffles;
    }

    function fetchActiveRaffle() public view returns (Raffle[] memory) {
        uint256 raffleCount = _raffleId.current();
        uint256 leftActiveRaffles = _raffleId.current() -
            _raffleCompleted.current() -
            _raffleCancelled.current();
        uint256 currentIndex = 0;

        Raffle[] memory activeRaffles = new Raffle[](leftActiveRaffles);
        for (uint256 i = 0; i < raffleCount; i++) {
            if (raffles[i + 1].status == RaffleStatus.Active) {
                uint256 currentId = i + 1;
                Raffle storage currentRaffle = raffles[currentId];
                activeRaffles[currentIndex] = currentRaffle;
                currentIndex += 1;
            }
        }
        return activeRaffles;
    }

    function purchasedTicket(uint256 id, address userAddress)
        public
        view
        returns (uint256)
    {
        require(
            id <= _raffleId.current() && id > 0,
            'Raffle id does not exist'
        );
        return ticketPurchased[id][userAddress];
    }

    function purchaseTicket(uint256 id, uint256 quantity) public {
        require(
            id <= _raffleId.current() && id > 0,
            'Raffle id does not exist'
        );
        Raffle storage raffle = raffles[id];
        require(
            raffle.status == RaffleStatus.Active,
            'Raffle status is not active'
        );
        require(block.timestamp < raffle.endIn, 'Raffle has ended');
        require(quantity > 0, 'Quantity is less than zero');
        if (raffle.ticketLimit == TicketsLimit.Finite) {
            require(
                quantity <= raffle.totalTickets,
                'Quantity is more than total tickets'
            );
            require(
                totalTicketSold[id] + quantity <= raffle.totalTickets,
                'Ticket limit exceeded'
            );
        }
        uint256 totalPrice = quantity * raffle.price;
        require(
            IERC20(USDC).allowance(msg.sender, address(this)) >= totalPrice,
            'Contract not approved'
        );
        require(
            IERC20(USDC).balanceOf(msg.sender) >= totalPrice,
            'Not enough USDC tokens'
        );
        IERC20(USDC).transferFrom(msg.sender, address(this), totalPrice);
        for (uint256 index = 0; index < quantity; index++) {
            raffle.participants.push(msg.sender);
            ticketPurchased[id][msg.sender]++;
            totalTicketSold[id]++;
        }
    }

    function random(uint256 limit) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, owner())
                )
            ) % limit;
    }

    function selectRandomWinner(uint256 id) public onlyOwner {
        require(
            id <= _raffleId.current() && id > 0,
            'Raffle id does not exist'
        );
        Raffle storage raffle = raffles[id];
        require(
            totalTicketSold[id] >= raffle.mininumTickets,
            'Minimum tickets should be sold out'
        );
        require(raffle.winner == address(0), 'Winner already decided');
        require(block.timestamp >= raffle.endIn, 'Raffle has not ended yet');
        uint256 totalTicketSoldOfId = totalTicketSold[id];
        withdrawablePool = withdrawablePool += (totalTicketSoldOfId *
            raffle.price);
        uint256 randomNumber = random(totalTicketSoldOfId);
        address randomWinner = raffle.participants[randomNumber];
        raffle.winner = randomWinner;
        raffle.status = RaffleStatus.Completed;
        _raffleCompleted.increment();
    }

    function claim(uint256 id) public nonReentrant {
        require(
            id <= _raffleId.current() && id > 0,
            'Raffle id does not exist'
        );
        Raffle storage raffle = raffles[id];
        require(
            totalTicketSold[id] >= raffle.mininumTickets,
            'Minimum tickets should be sold out'
        );
        require(block.timestamp >= raffle.endIn, 'Raffle has not ended yet');
        require(ticketPurchased[id][msg.sender] > 0, 'No tickets purchased');
        require(raffle.winner == msg.sender, 'Only winner can claim');
        require(
            raffle.isPaid == PaidStatus.No,
            'Raffle prize already paid out'
        );
        if (raffle.prizeType == PrizeTypes.Tokens) {
            IERC20(USDC).transfer(msg.sender, raffle.rafflePrize);
        } else {
            IERC721(NFT).safeTransferFrom(
                address(this),
                msg.sender,
                raffle.rafflePrize
            );
        }
        raffle.isPaid = PaidStatus.Yes;
    }

    function claimFees(uint256 id) public nonReentrant {
        require(
            id <= _raffleId.current() && id > 0,
            'Raffle id does not exist'
        );
        require(ticketPurchased[id][msg.sender] > 0, 'No tickets purchased');
        Raffle storage raffle = raffles[id];
        require(
            raffle.status == RaffleStatus.Cancelled,
            'Raffle status is not cancelled'
        );
        uint256 feesToReturn = ticketPurchased[id][msg.sender] * raffle.price;
        ticketPurchased[id][msg.sender] = 0;
        IERC20(USDC).transfer(msg.sender, feesToReturn);
    }

    function withdrawUSDC() external onlyOwner {
        require(withdrawablePool > 0, 'Pool is empty');
        uint256 withdrawAmount = withdrawablePool;
        withdrawablePool = 0;
        IERC20(USDC).transfer(owner(), withdrawAmount);
    }
}
