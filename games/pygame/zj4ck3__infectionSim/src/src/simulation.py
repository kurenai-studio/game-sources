from person import Person
import matplotlib.pyplot as plt
from random import choice, shuffle
from numpy import full
import pygame

class Simulation:
    def __init__(self, SHAPE:tuple, window_size:tuple = (1200, 800)) -> None:
        # matrix variables
        self.SHAPE = self.WIDTH, self.HEIGHT = SHAPE
        self.matrix = full(self.SHAPE, None, dtype=object) # full the matrix with None
        self.neighbour = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

        # feature variables
        self.BLACK = (0, 0, 0)
        self.GEN = 0
        self.graph = [[],[],[],[],[],[], []] # susceptible, carrier, infected, recovered, dead, immune, gen

        # windows and screen variables
        self.paused = False
        self.WINDOW_SIZE = window_size
        self.ticking = 3
        return

    def prompt_percentage(self, label: str) -> float: # for user handling in ask_pre_info
        while True:
            answer = input(f"[?] {label} (0-100%): ")
            try:
                percentage = int(answer)
            except ValueError:
                print("[X] Please enter a whole number from 0 to 100.\n")
                continue

            if 0 <= percentage <= 100:
                return percentage / 100
            print("[X] Please enter a value from 0 to 100.\n")
        return
    
    def ask_pre_info(self) -> None: # ask user before start some variables
        print("\n[#] Info configuration:")
        self.diseaseConstants = {"density": 0.0, "susceptible": 0.0, "immune": 0.0, "carrier": 0.0, "infected": 0.0, "mortality":0.0}
        self.diseaseConstants["density"] = self.prompt_percentage("Population density")

        while True:
            self.diseaseConstants["susceptible"] = self.prompt_percentage("Susceptible people")
            self.diseaseConstants["immune"] = self.prompt_percentage("Immune people")
            self.diseaseConstants["carrier"] = self.prompt_percentage("Carrier people")
            self.diseaseConstants["infected"] = self.prompt_percentage("Infected people")
            status_total = sum(list(self.diseaseConstants.values())[1:5])

            if status_total == 1:
                break
            print("[X] Those percentages together don't make 100%. Please enter them again.\n")

        self.diseaseConstants["mortality"] = self.prompt_percentage("Mortality rate")        
        print("\n[V] Configuration completed correctly")
        print("[#] Initializing grid...")
        print("[#] X to exit, ESC to exit with graph")
        print("[#] Full screen for better experience")
        return

    def init__grid(self) -> None: # initialize the grid with people based on the density and proportions
        # Total population based on density
        population = round(self.SHAPE[0] * self.SHAPE[1] * self.diseaseConstants["density"])
        statuses = ["susceptible", "immune", "carrier", "infected"]
        proportions = [self.diseaseConstants[s] for s in statuses]

        # Calculate the initial counts
        raw_counts = [population * p for p in proportions]
        counts_list = [int(n) for n in raw_counts]

        # Calculate how many people are missing
        # ES: 3,9 and 2.1 = 3,1 but 1 person is missing
        remaining = population - sum(counts_list)

        # Store each index with its decimal remainder
        # this is for redistribute the missing people based on largest decimal
        remainders = []
        for i in range(len(statuses)):
            remainder = raw_counts[i] - counts_list[i]
            remainders.append((i, remainder))

        # Sort from the largest remainder to the smallest
        remainders.sort(key=lambda item: item[1], reverse=True)

        # Distribute the missing people
        for i in range(remaining):
            index = remainders[i][0]
            counts_list[index] += 1

        counts = dict(zip(statuses, counts_list))
        # Generate all possible positions and shuffle them
        positions = [
            (x, y)
            for x in range(self.SHAPE[0])
            for y in range(self.SHAPE[1])
        ]
        shuffle(positions)

        # Assign people to random positions
        for i in range(population):
            while True:
                choice_made = choice(statuses)

                if counts[choice_made] > 0:
                    counts[choice_made] -= 1
                    break

            self.matrix[positions[i]] = Person(choice_made)
        return

    def draw(self) -> None:
        screen_width, screen_height = self.screen.get_size()
        rows, columns = self.matrix.shape

        # Calculate a single size for square cells
        cell_size = min(
            screen_width / columns,
            screen_height / rows
        )

        grid_width = columns * cell_size
        grid_height = rows * cell_size
        offset_x = 0
        offset_y = 0

        # Draw the cells
        for row in range(rows):
            for column in range(columns):
                x = round(offset_x + column * cell_size)
                y = round(offset_y + row * cell_size)
                next_x = round(offset_x + (column + 1) * cell_size)
                next_y = round(offset_y + (row + 1) * cell_size)

                cell = pygame.Rect(
                    x,
                    y,
                    next_x - x,
                    next_y - y
                )

                person = self.matrix[row, column]

                if person is None or person == 0:
                    cell_color = self.BLACK
                else:
                    cell_color = person.color

                pygame.draw.rect(self.screen, cell_color, cell)

        # Draw subtle grid lines only once
        grid_color = (45, 45, 45)

        for column in range(columns + 1):
            x = round(offset_x + column * cell_size)
            pygame.draw.line(
                self.screen,
                grid_color,
                (x, round(offset_y)),
                (x, round(offset_y + grid_height)),
                1
            )

        for row in range(rows + 1):
            y = round(offset_y + row * cell_size)
            pygame.draw.line(
                self.screen,
                grid_color,
                (round(offset_x), y),
                (round(offset_x + grid_width), y),        1
            )
        return

    def score_neighbours(self, row: int, column: int) -> dict:
        near_cell = {"transmissible": 0, "untransmissible": 0}

        for di, dj in self.neighbour:
            ni = row + di
            nj = column + dj

            # Check that the neighbour is inside the matrix
            if 0 <= ni < self.SHAPE[0] and 0 <= nj < self.SHAPE[1]:
                person = self.matrix[ni, nj]

                if person is None:
                    near_cell["untransmissible"] += 1
                elif person.status in ["susceptible", "recovered", "dead", "immune"]:
                    near_cell["untransmissible"] += 1
                else:
                    near_cell["transmissible"] += 1
        return near_cell

    def update(self) -> None:
        self.put_in_graph()
        inter_matrix = self.matrix.copy()

        for row in range(self.SHAPE[0]):
            for column in range(self.SHAPE[1]):

                near_cell = self.score_neighbours(row,column)
                person = self.matrix[row,column]

                if person is not None:
                    new_type = person.calculate_change(near_cell, self.diseaseConstants["mortality"])

                    if new_type != person.status:
                        if new_type is not None:
                            inter_matrix[row,column] = Person(new_type)
                        else:
                            inter_matrix[row,column] = None
        self.matrix = inter_matrix
        self.info()
        return

    def put_in_graph(self) -> None: # put in a matrix the various counts
        susceptible, carrier, infected = 0, 0, 0
        dead, recovered, immune = 0, 0, 0

        for i in range(self.WIDTH):
            for j in range(self.HEIGHT):
                if self.matrix[i,j] is not None:
                    if self.matrix[i,j].status == "susceptible":
                        susceptible += 1
                    elif self.matrix[i,j].status == "carrier":
                        carrier += 1
                    elif self.matrix[i,j].status == "infected":
                        infected += 1
                    elif self.matrix[i,j].status == "dead":
                        dead += 1
                    elif self.matrix[i,j].status == "recovered":
                        recovered += 1
                    elif self.matrix[i,j].status == "immune":
                        immune += 1

        self.graph[0].append(susceptible)
        self.graph[1].append(carrier)
        self.graph[2].append(infected)
        self.graph[3].append(recovered)
        self.graph[4].append(dead)
        self.graph[5].append(immune)
        self.graph[6].append(self.GEN)
        return 

    def make_graph(self) -> None:
        # susceptible, carrier, infected, recovered, dead, immune, gen
        plt.figure(figsize=(12, 8))
        plt.plot(self.graph[6], self.graph[0], color="blue", label="susceptible", lw=2.5)
        plt.plot(self.graph[6], self.graph[1], color="yellow", label="carrier", lw=2.5)
        plt.plot(self.graph[6], self.graph[2], color="red", label="infected", lw=2.5)
        plt.plot(self.graph[6], self.graph[3], color="purple", label="recovered", lw=2.5)
        plt.plot(self.graph[6], self.graph[4], color="brown", label="dead", lw=2.5)
        plt.plot(self.graph[6], self.graph[5], color="green", label="immune", lw=2.5)

        plt.title("Trend of type of people:")
        plt.xlabel("Generation")
        plt.ylabel("N. type of person")
        plt.legend(loc="upper right", bbox_to_anchor=(0.85, 0.95))
        plt.grid(True)
        plt.show()
        return

    def run(self) -> None:
        pygame.init()
        self.screen = pygame.display.set_mode(self.WINDOW_SIZE, pygame.RESIZABLE)
        pygame.display.set_caption("Infection simulation")
        self.clock = pygame.time.Clock()
        windowed_size = self.screen.get_size()
        fullscreen = False
        
        running = True
        selected_status = "susceptible"

        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False

                elif event.type == pygame.VIDEORESIZE and not fullscreen:
                    windowed_size = event.size
                    self.screen = pygame.display.set_mode(windowed_size, pygame.RESIZABLE)

                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_F11:
                        if fullscreen:
                            self.screen = pygame.display.set_mode(windowed_size, pygame.RESIZABLE)
                        else:
                            windowed_size = self.screen.get_size()
                            self.screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
                        fullscreen = not fullscreen

                    elif event.key == pygame.K_SPACE:
                        self.paused = not self.paused

                    elif event.key in (pygame.K_KP_PLUS, pygame.K_PLUS):
                        self.ticking += 2

                    elif event.key in (pygame.K_KP_MINUS, pygame.K_MINUS):
                        self.ticking = max(1, self.ticking - 2)

                    elif event.key == pygame.K_r:
                        for i in range(self.SHAPE[0]):
                            for j in range(self.SHAPE[1]):
                                if self.matrix[i,j] is not None:
                                    if self.matrix[i,j].status in ["infected", "carrier"]:
                                        self.matrix[i,j].change_status("recovered")
                    
                    elif event.key == pygame.K_s:
                        selected_status = "susceptible"
                    elif event.key == pygame.K_v:
                        selected_status = "immune"
                    elif event.key == pygame.K_c:
                        selected_status = "carrier"
                    elif event.key == pygame.K_i:
                        selected_status = "infected"
                    elif event.key == pygame.K_d:
                        selected_status = "dead"
                    elif event.key == pygame.K_n:
                        selected_status = None
                    elif event.key == pygame.K_h:
                        selected_status = "recovered"
                    elif event.key == pygame.K_ESCAPE:
                        self.put_in_graph()
                        running = False
                        self.make_graph()
                
                elif event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 1:  # sx mouse button
                        mouse_x, mouse_y = event.pos
                        screen_width, screen_height = self.screen.get_size()
                        rows, columns = self.matrix.shape

                        cell_size = min(
                            screen_width / columns,
                            screen_height / rows
                        )

                        grid_width = columns * cell_size
                        grid_height = rows * cell_size

                        offset_x = 0
                        offset_y = 0

                        if (offset_x <= mouse_x < offset_x + grid_width
                            and offset_y <= mouse_y < offset_y + grid_height):
                            column = int((mouse_x - offset_x) / cell_size)
                            row = int((mouse_y - offset_y) / cell_size)

                            if selected_status is None:
                                self.matrix[row, column] = None
                            else:
                                self.matrix[row, column] = Person(selected_status)

            self.screen.fill(self.BLACK)
            self.draw()
            self.info()
            pygame.display.flip()
            self.clock.tick(self.ticking)

            if not self.paused:
                self.GEN += 1
                self.update()
        pygame.quit()
        return

    def info(self) -> None: # display information
        text_init = pygame.font.SysFont(None, 36)
        screen_width, screen_height = self.screen.get_size()
        cell_size = min(screen_width / self.SHAPE[1], screen_height / self.SHAPE[0])
        grid_right = round(self.SHAPE[1] * cell_size)

        # state
        if self.paused:
            state = text_init.render("State: paused", True, (255,0,0))
        else:
            state = text_init.render("State: running", True, (0,255,0))
        
        state_rect = state.get_rect(topleft=(grid_right + 20, 30))
        self.screen.blit(state, state_rect)
        
        # ticking
        tick = text_init.render(f"Speed: {self.ticking}", True, (255,255,255))    
        tick_rect = tick.get_rect(topleft=(grid_right + 20, 60))
        self.screen.blit(tick, tick_rect)

        # generation
        generation = text_init.render(f"Generation: {self.GEN}", True, (255,255,255))    
        generation_rect = generation.get_rect(topleft=(grid_right + 20, 90))
        self.screen.blit(generation, generation_rect)

        # population not dead
        population, non, susc, imm, carr, inf, rec, death = 0, 0, 0, 0, 0, 0, 0, 0
        for i in self.matrix.flat:
            if i is not None:
                if i.status != "dead":
                    if i.status == "susceptible":
                        susc += 1
                    elif i.status == "immune":
                        imm += 1
                    elif i.status == "carrier":
                        carr += 1
                    elif i.status == "infected":
                        inf += 1
                    elif i.status == "recovered":
                        rec += 1
                    population += 1
                else:
                    death += 1
            else:
                non += 1

        N_cell = self.SHAPE[0] * self.SHAPE[1]
        tot = text_init.render(f"Total cells: {N_cell}", True, (255,255,255))    
        tot_rect = tot.get_rect(topleft=(grid_right + 20, 120))
        self.screen.blit(tot, tot_rect)

        non_pop = text_init.render(f"Clear cells: {round((non/N_cell)*100,2)} % - {non}", True, (255,255,255))    
        non_pop_rect = non_pop.get_rect(topleft=(grid_right + 20, 150))
        self.screen.blit(non_pop, non_pop_rect)

        pop = text_init.render(f"Population: {round((population/N_cell)*100,2)} % - {population}", True, (255,255,255))    
        pop_rect = pop.get_rect(topleft=(grid_right + 20, 180))
        self.screen.blit(pop, pop_rect)

        susc_pop = text_init.render(f"Susceptible: {round((susc/N_cell)*100,2)} % - {susc}", True, (255,255,255))
        susc_pop_rect = susc_pop.get_rect(topleft=(grid_right + 20, 210))
        self.screen.blit(susc_pop, susc_pop_rect)

        imm_pop = text_init.render(f"Immune: {round((imm/N_cell)*100,2)} % - {imm}", True, (255,255,255))
        imm_pop_rect = imm_pop.get_rect(topleft=(grid_right + 20, 240))
        self.screen.blit(imm_pop, imm_pop_rect)

        carr_pop = text_init.render(f"Carrier: {round((carr/N_cell)*100,2)} % - {carr}", True, (255,255,255))
        carr_pop_rect = carr_pop.get_rect(topleft=(grid_right + 20, 270))
        self.screen.blit(carr_pop, carr_pop_rect)

        inf_pop = text_init.render(f"Infected: {round((inf/N_cell)*100,2)} % - {inf}", True, (255,255,255))
        inf_pop_rect = inf_pop.get_rect(topleft=(grid_right + 20, 300))
        self.screen.blit(inf_pop, inf_pop_rect)

        rec_pop = text_init.render(f"Recovered: {round((rec/N_cell)*100,2)} % - {rec}", True, (255,255,255))
        rec_pop_rect = rec_pop.get_rect(topleft=(grid_right + 20, 330))
        self.screen.blit(rec_pop, rec_pop_rect)

        death_pop = text_init.render(f"Deaths: {round((death/N_cell)*100,2)} % - {death}", True, (255,255,255))
        death_pop_rect = death_pop.get_rect(topleft=(grid_right + 20, 360))
        self.screen.blit(death_pop, death_pop_rect)

        mortality_rate = text_init.render(f"Mortality: {round(self.diseaseConstants['mortality']*100,2)} %", True, (255,255,255))
        mortality_rate_rect = mortality_rate.get_rect(topleft=(grid_right + 20, 390))
        self.screen.blit(mortality_rate, mortality_rate_rect)

        inf_rate = text_init.render(f"Infection rate: {round((inf/population)*100,2)} %", True, (255,255,255))
        inf_rate_rect = inf_rate.get_rect(topleft=(grid_right + 20, 420))
        self.screen.blit(inf_rate, inf_rate_rect)

        if rec + death == 0:
            s_rate = 100.0
        else: 
            s_rate = round(((rec/(rec+death)))*100,2)
        
        survival_rate = text_init.render(f"Survival Rate (SR): {s_rate} %", True, (255,255,255))
        survival_rate_rect = survival_rate.get_rect(topleft=(grid_right + 20, 450))
        self.screen.blit(survival_rate, survival_rate_rect)
        return