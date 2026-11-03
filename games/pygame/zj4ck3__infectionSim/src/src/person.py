from random import random
P_TRASMISSION = 0.05 # probability that only 1 infected infect a susceptible
P_CARRIER = 0.6 # Probability that a susceptible enters in carrier status and not infected
P_HEALTYFROMCARRIER = 0.1

class Person:
    def __init__(self, status:str) -> None:
        self.change_status(status)
        return

    def change_status(self, status: str) -> None:
        self.days_in_state = 0

        if status == "susceptible":
            self.status = status
            self.id = 1
            self.color = (0, 0, 255) # blue
        elif status == "infected":
            self.status = status
            self.id = 2
            self.color = (255, 0, 0) # red
        elif status == "carrier":
            self.status = status
            self.id = 3
            self.color = (255, 255, 0) # yellow
        elif status == "immune":
            self.status = status
            self.id = 4
            self.color = (0, 255, 0) # green
        elif status == "dead":
            self.status = status
            self.id = 5
            self.color = (64,32,0) # brown
        elif status == "recovered":
            self.status = status
            self.id = 6
            self.color = (255,0,255) # fucsia
        else:
            raise ValueError("invalid status")
        return

    def calculate_change(self, neighbour:dict, mortality:float) -> str: # it change the type of person based on probability
        # if a person is dead, there isn't any change possible
        if self.status == "dead":
            return self.status
        
        # if a person is recovered, is immune for a bit of time, then it become again susceptible
        elif self.status == "recovered":
            if self.days_in_state >= 30:
                return "susceptible"
            else:
                self.days_in_state += 1
            return self.status

        # if a person is infected, after a bit of time can become dead or recovered with a probability
        elif self.status == "infected":
            if self.days_in_state >= 9: 
                if random() > mortality:
                    return "recovered"
                else:
                    return "dead"
            else:
                self.days_in_state += 1
                return self.status

        # if a person is immune, the status doesen't change for a bit of time
        elif self.status == "immune":
            if self.days_in_state >= 65:
                return "susceptible"
            else:
                self.days_in_state += 1
                return self.status

        # if a person is carrier after a bit of time can be recovered or infected
        elif self.status == "carrier":
            if self.days_in_state >= 5:
                if random() < P_HEALTYFROMCARRIER:
                    return "recovered"
                else:
                    return "infected"
            else:
                self.days_in_state += 1
                return self.status
        
        # if a person is susceptible with a probability based on neighbour can become infected or carrier or susceptible again
        else:
            P_infect = 1-((1-P_TRASMISSION)**neighbour["transmissible"])

            if random() < P_infect:
                if random() < P_CARRIER:
                    return "infected"
                else:
                    return "carrier"
            else:
                return self.status