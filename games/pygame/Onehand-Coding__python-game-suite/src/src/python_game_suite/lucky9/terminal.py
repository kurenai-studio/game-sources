import sys
import time

from python_game_suite.common.game_template import Game

from .terminal_engine import Lucky9, Player

TAGALOG_COUNT = {
    1: "Isa",
    2: "Dalawa",
    3: "Tatlo",
    4: "Apat",
    5: "Lima",
    6: "Anim",
    7: "Pito",
    8: "Walo",
    9: "Siyam",
    10: "Sampu",
}


def getPlayerBet():
    while True:
        print("\nmagkano taya mo? (Q) pagka ayaw na.")

        bet = input("> ").upper().strip()

        if not bet.isdigit():
            executeCommand(bet)
            continue

        bet = int(bet)

        if 0 >= bet:
            continue
        elif bet > lucky9.player.money:
            print(f"{lucky9.player.money:,} Pesos lang ang pera mo uyy!.")
            continue
        else:
            lucky9.player.bet = bet
            return


def getPlayerMove():
    while True:
        move = input("(G)ood o (H)irit: ").upper().strip()
        if move not in ("H", "G"):
            print("(H) pag hihirit ka (G) pagka goods na.")
            continue
        else:
            lucky9.player.move = move
            return


def executeCommand(command):
    match command:
        case "EXIT" | "Q":
            time.sleep(1)
            print("\npaalam! Salamat sa paglalaro.")
            sys.exit()
        case "SAVE":
            saveGame()
        case "CLEAR":
            clearAllGameData()
        case "DELETE":
            deleteCurrentGame()
        case "PLAYERS":
            showPlayers()


def deal():
    for _ in range(2):
        lucky9.player.hand.append(lucky9.deck.pop())
        lucky9.dealer.hand.append(lucky9.deck.pop())


def clearHands():
    lucky9.dealer.hand = []
    lucky9.player.hand = []


def isBroke(money):
    return money <= 0


def displayHands(revealDealerHand=True):
    if revealDealerHand:
        playerHandValue = lucky9.player.getHandValue()
        dealerHandValue = lucky9.dealer.getHandValue()
        print(f"Bangka: {dealerHandValue}")
        lucky9.dealer.showHand()
        print()
        print(f"Ikaw: {playerHandValue}")
        lucky9.player.showHand()

    else:
        playerHandValue = lucky9.player.getHandValue()
        dealerHandValue = lucky9.dealer.getHandValue(revealHandValue=False)
        print(f"Bangka: {dealerHandValue}")
        lucky9.dealer.showHand(revealHand=False)
        print()
        print(f"Ikaw: {playerHandValue}")
        lucky9.player.showHand()


def checkWinner():
    return lucky9.settle_round(lucky9.player.bet)


def displayWinner():
    winner = checkWinner()
    if lucky9.dealer.money > 0:
        print(f"\nBangka: {lucky9.dealer.name}")
        print(f"Pera: {lucky9.dealer.money:,}")

    if winner == "dealer":
        print("\npanalo ang bangka!")
        if isBroke(lucky9.player.money):
            print("\nUbos na ang pera mo.")
        else:
            print(f"\nmay {lucky9.player.money:,} Pesos ka nalang.")

    elif winner == "player":
        print("\npanalo ka!")
        print(f"\nmay {lucky9.player.money:,} Pesos kana.")

    else:
        print("\ntabla!")
        print(f"\nmay {lucky9.player.money:,} Pesos ka parin.")


def borrowMoney(loanLimit=5_000):
    print("\nGusto mo utang?")
    if yesOrNo():
        print("magkano?")
        while True:
            try:
                loan = int(input("> ").strip())
                if 1 > loan:
                    print("\nHuwag naman sobrang kuripot idol.")
                    continue
                elif loan > loanLimit:
                    print(f"\nHanggang {loanLimit:,} lang idol.")
                    continue
                else:
                    lucky9.player.money += loan
                    lucky9.player.debt += loan

            except ValueError:
                print("mangungutang kaba o hindi? ")

            else:
                print(
                    f"\nmay {lucky9.player.money:,} Pesos ka na ulit!\nutang yan ha. :)"
                )
                return True


def levelUp():
    old_dealer = lucky9.dealer
    new_dealer = lucky9.advance_level()
    if new_dealer is None:
        print(
            f"\nUyy Congrats panalo kana!!!, maari mo ng i bangko iyang "
            f"{lucky9.player.money:,} Pesos mo."
        )
        time.sleep(2)
        input()
        saveGame()
        sys.exit()
        return

    print(f"\nUbos na ang pera ni {old_dealer.name} :)")
    print("\nmagpapalit ng bangka...")
    time.sleep(3)
    input("\n\tgame?")
    print(f"\nbagong Bangka:\n{new_dealer}")


def checkDeckCount():
    deckCount = len(lucky9.deck)
    if deckCount <= 10:
        if deckCount <= 0:
            print("\nUbos na ang baraha.")

        elif deckCount in (4, 6, 9):
            print(f"\n{TAGALOG_COUNT.get(deckCount)} na baraha na lamang ang natitira.")

        else:
            print(f"\n{TAGALOG_COUNT.get(deckCount)}ng baraha na lamang ang natitira.")
            time.sleep(1)

        print("\nbinabalasa...")
        time.sleep(3)
        input("\n\tGame?")
        lucky9.deck = lucky9.createDeck()


def continuePreviousGame():
    name = lucky9.player.name
    if name in lucky9.getPlayerNames():
        lucky9.loadGameData(name)
        lucky9.isLoaded = True
        print(f"\nIto ang nakaraang tala ng iyong laro:\n{lucky9.player}")
        print(f"\nBangka: {lucky9.dealer}")
        print("\nGusto mo bang ituloy?\n")
        if yesOrNo():
            return True
        else:
            lucky9.level = 1
            lucky9.player = Player(name)
            lucky9.dealer = lucky9.inviteDealer()
            lucky9.isLoaded = False
    return False


def showPlayers():
    names = lucky9.getPlayerNames()
    if not names:
        print("\nWala pang larong naitatala.")
        return

    print("\nMga pangalan ng nakatalang laro:")
    for name in names:
        print(name)


def saveGame():
    def notify(name=""):
        if name:
            text = f"\nSinisave ang laro mo sa pangalang {name}"

        else:
            text = "\nSinisave ang iyong laro"

        printWithDots(text)

    if not lucky9.isLoaded and lucky9.player.name in lucky9.getPlayerNames():
        print("\nMay naka save ng laro sa pangalang ito.")

        def overWriteSave():
            print("\nPalitan ang naka save na laro?")
            return yesOrNo()

        def saveToNewName():
            print("\nIsave sa ibang pangalan?")
            return yesOrNo()

        if overWriteSave():
            lucky9.saveData()
            lucky9.isLoaded = True
            notify()

        elif saveToNewName():
            newName = getNewName()
            lucky9.saveData(newName)
            lucky9.isLoaded = True
            notify(newName)

    else:
        lucky9.saveData()
        notify()


def deleteCurrentGame():
    name = lucky9.player.name
    print(f"\n{name}, Burahin ang tala ng iyong kasalukuyang laro?")

    if yesOrNo() and name in lucky9.getPlayerNames():
        lucky9.deletePlayerData(name)
        text = "\nBinubura ang tala ng iyong laro"
        printWithDots(text)
        return

    print(f"\n{name}, hindi pa naka save ang larong ito.")


def clearAllGameData():
    print("\nBurahin ang lahat na tala ng laro?")

    if yesOrNo():
        lucky9.clearData()
        text = "\nBinubura ang lahat na tala ng laro"
        printWithDots(text)
        return


def printWithDots(text, dotCount=8, delay=0.3):
    print(text, end="")

    for _ in range(dotCount):
        print(".", end="")
        time.sleep(delay)

    time.sleep(delay)
    print("Tapos!")


def getNewName():
    print("\nIlgay ng bagong pangalan.")
    while True:
        newName = input("> ").strip()

        if not newName or (newName in lucky9.getPlayerNames()):
            print("\nGumamit ng ibang pangalan.")
            continue

        return newName


def collectPlayerDebt():
    if not lucky9.debt_offer_available():
        return

    print("\nHuy malaki laki na ang pera mo ah, magbabayad kana ba ng utang?")
    print(f"{lucky9.player.debt:,} Pesos ang utang mo.")
    refusals = lucky9.player.timesRefusedToPay
    outcome = lucky9.settle_debt(yesOrNo())

    if outcome == "penalty":
        print(
            f"\n{refusals} beses kanang umiwas magbayad, "
            "babawasan ng doble ang pera mo."
        )
        time.sleep(2)
        print(lucky9.player)
        input("\n\tGame?")
    elif outcome == "refused":
        print("\nnaku! pagka kuripot naman?")
        time.sleep(2)
    else:
        print("\nnagbabayad ng utang...")
        time.sleep(3)
        print("\nAyan bayad na utang mo.")
        time.sleep(1)
        print(f"{lucky9.player}")
        input("\n\tGame?")


def yesOrNo():
    while True:
        response = input("Oo/hindi: ").upper().strip()

        if response not in ("OO", "HINDI"):
            continue

        return True if response == "OO" else False


class TerminalLucky9(Game):
    @staticmethod
    def get_name():
        return "Lucky9 (Terminal)"

    def run(self):
        global lucky9

        name = ""
        print("\nAnong pangalan mo?")
        while not name:
            name = input("> ").strip()

        player = Player(name)
        lucky9 = Lucky9(player)
        lucky9.isLoaded = False

        if lucky9.player.name not in lucky9.getPlayerNames():
            print(f"\ntara {lucky9.player.name}! laro muna tayo ng lucky9.")
            time.sleep(1)
            input("\n\tgame?")

        if not continuePreviousGame():
            print(f"\nAyan {lucky9.player.money:,} Pesos, pera mo pangpuhunan.")
            print(f"\nBangka: {lucky9.dealer}")

        else:
            print("\n\tPAALALA!\nIsave ang laro bago lumabas!")
            if isBroke(lucky9.player.money):
                print("\nWala kang pera!")

        while True:
            lucky9.player.drewCard = False

            if isBroke(lucky9.player.money) and not borrowMoney():
                print("\nBetter Luck next time amigo.")
                if lucky9.isLoaded:
                    lucky9.saveData()
                executeCommand("EXIT")

            if isBroke(lucky9.dealer.money):
                levelUp()

            checkDeckCount()
            getPlayerBet()
            deal()
            displayHands(False)
            getPlayerMove()

            if lucky9.player.move == "H":
                lucky9.player.drewCard = True
                lucky9.player.hand.append(lucky9.deck.pop())
                rank, suit = lucky9.player.hand[-1]
                print("\nHumihirit...")
                time.sleep(2)
                print(f"\n{rank} na {suit} ang hirit mo")

            if lucky9.dealer.getHandValue() < 7:
                lucky9.dealer.hand.append(lucky9.deck.pop())

                rank, suit = lucky9.dealer.hand[-1]

                if lucky9.player.drewCard:
                    print("\nHihirit din ang bangka...")
                else:
                    print("\nHihirit ang banka...")

                time.sleep(2)
                print(f"\n{rank} na {suit} ang hirit ng bangka.")

            input("\n\tGame?")

            displayHands()
            displayWinner()
            clearHands()
            collectPlayerDebt()
