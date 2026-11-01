from __future__ import annotations

import random
import shelve
from pathlib import Path

from .config import DATA_DIR


class Lucky9:
    def __init__(self, player, data_dir: Path | None = None):
        self.dealers = {
            5: {"Robin": 1_000_000},
            4: {"Caesar": 800_000},
            3: {"Jeric": 600_000},
            2: {"Joko": 400_000},
            1: {"Ace": 200_000},
        }
        self.level = 1
        self.player = player
        self.deck = self.createDeck()
        self.dealer = self.inviteDealer()
        self.dataFolder = Path(data_dir) if data_dir is not None else DATA_DIR
        self.dataFolder.mkdir(parents=True, exist_ok=True)
        self.database = self.dataFolder / "lucky_data"
        self.isLoaded = False

    @staticmethod
    def createDeck():
        suits = [
            chr(9830),
            chr(9829),
            chr(9824),
            chr(9827),
        ]
        ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
        cards = [(rank, suit) for rank in ranks for suit in suits]
        random.shuffle(cards)
        return cards

    def inviteDealer(self):
        dealer = self.dealers.get(self.level)
        if dealer is None:
            raise ValueError(f"No dealer configured for level {self.level}")
        dealerName = list(dealer.keys())[0]
        dealerMoney = dealer.get(dealerName)
        return Dealer(dealerName, dealerMoney)

    def settle_round(self, bet: int) -> str:
        player_value = int(self.player.getHandValue())
        dealer_value = int(self.dealer.getHandValue())
        if player_value < dealer_value:
            self.player.money -= bet
            self.dealer.money += bet
            return "dealer"
        if player_value > dealer_value:
            self.player.money += bet
            self.dealer.money -= bet
            return "player"
        return "tie"

    def advance_level(self) -> Dealer | None:
        if self.level >= 5:
            return None
        self.level += 1
        self.dealer = self.inviteDealer()
        return self.dealer

    def debt_offer_available(self) -> bool:
        return self.player.money * 0.5 >= self.player.debt >= 10_000

    def settle_debt(self, pay: bool) -> str:
        if pay:
            self.player.money -= self.player.debt
            self.player.debt = 0
            return "paid"
        if self.player.timesRefusedToPay == 3:
            self.player.money -= self.player.debt * 2
            self.player.debt = 0
            self.player.timesRefusedToPay = 0
            return "penalty"
        self.player.timesRefusedToPay += 1
        return "refused"

    def getPlayerNames(self):
        with shelve.open(self.database) as db:
            return list(db.keys())

    def saveData(self, name=""):
        if not name:
            name = self.player.name
        with shelve.open(self.database, writeback=True) as db:
            db[name] = {
                "level": self.level,
                "money": self.player.money,
                "debt": self.player.debt,
                "dealer name": self.dealer.name,
                "dealer money": self.dealer.money,
                "times refused to pay": self.player.timesRefusedToPay,
            }

    def loadGameData(self, name):
        with shelve.open(self.database) as db:
            self.level = db[name]["level"]
            self.player.debt = db[name]["debt"]
            self.player.money = db[name]["money"]
            self.player.timesRefusedToPay = db[name]["times refused to pay"]
            dealerName = db[name]["dealer name"]
            dealerMoney = db[name]["dealer money"]
            self.dealer = Dealer(dealerName, dealerMoney)

    def deletePlayerData(self, name):
        with shelve.open(self.database) as db:
            del db[name]

    def clearData(self):
        for file in self.dataFolder.glob("lucky_data*"):
            file.unlink()


class Player:
    def __init__(self, name: str, money=10_000):
        self.name = name
        self.money = money
        self._debt = 0
        self.hand = []
        self.bet = None
        self.timesRefusedToPay = 0
        self.drewCard = False

    def __str__(self):
        return f"\nPangalan: {self.name} \nPera: {self.money:,} Pesos \nUtang: {self.debt:,} Pesos"

    @property
    def debt(self):
        return self._debt

    @debt.setter
    def debt(self, value):
        self._debt = value

    def showHand(self, revealHand=True):
        lines = ["", "", "", ""]
        for card in self.hand:
            if not revealHand:
                lines[0] += " ___ "
                lines[1] += "|#  |"
                lines[2] += "| ##|"
                lines[3] += "|__#|"
            else:
                rank, suit = card
                lines[0] += " ___ "
                lines[1] += "|{} |".format(rank.ljust(2))
                lines[2] += "| {} |".format(suit)
                lines[3] += "|_{}|".format(rank.rjust(2, "_"))
        for line in lines:
            print(line)

    def getHandValue(self, revealHandValue=True) -> int | str:
        value = 0
        aces = []
        ranks = []

        if not revealHandValue:
            return "??"

        for card in self.hand:
            rank, suit = card
            ranks.append(rank)
            if rank == "A":
                value += 1
                aces.append(card)
            else:
                value += int(rank)

        value %= 10

        cardCounts = len(self.hand)
        if (cardCounts == 3 and len(set(ranks)) == 1) or (
            cardCounts == 2 and len(aces) == 2
        ):
            value = 9

        return value


class Dealer(Player):
    def __init__(self, name, money):
        self.name = name
        self.money = money
        self.hand = []

    def __str__(self):
        return f"{self.name}\nPera: {self.money:,} Pesos"
