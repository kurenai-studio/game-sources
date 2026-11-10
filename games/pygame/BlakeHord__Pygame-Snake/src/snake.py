import pygame
import sys    
from random import randint

class snake:
    def __init__(self):
        self.pos = [25,25]
        self.length = 1
        self.direction = [1,0]

    def draw(self, screen):
        pygame.draw.rect(screen, green, [self.pos[0]*CELLSIZE,self.pos[1]*CELLSIZE,10,10])

class node:
    def __init__(self, position):
        self.pos = position

    def draw(self,screen):
        pygame.draw.rect(screen, red, [self.pos[0]*CELLSIZE,self.pos[1]*CELLSIZE,10,10])
        
class lines:
    def __init__(self):
        self.num = 49

    def draw(self, screen):
        for i in range(1,self.num + 1):
            if i < self.num - 1:
                pygame.draw.line(screen, black, [0,CELLSIZE*i], [500,CELLSIZE*i])
            pygame.draw.line(screen, black, [CELLSIZE*i,0], [CELLSIZE*i,470])
            
def timeStep(blockList):
    for j in range(len(blockList)-1,0,-1):
        blockList[j].pos[0] = blockList[j-1].pos[0]
        blockList[j].pos[1] = blockList[j-1].pos[1]
    blockList[0].pos[0] += blockList[0].direction[0]
    blockList[0].pos[1] += blockList[0].direction[1]

def gameOver(screen):
    font = pygame.font.Font(None, 60)
    text = font.render("GAME OVER", 1, red)
    textpos = text.get_rect()
    textpos.centerx = screen.get_rect().centerx
    textpos.centery = screen.get_rect().centery
    screen.blit(text, textpos)
    pygame.display.flip()
    while 1:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.display.quit()
                pygame.quit()
                sys.exit()

def randomLocation():
    x = randint(0,49)
    y = randint(0,46)
    return [x,y]
                
CELLSIZE = 10

size = width, height = 500, 500
white = 255,255,255
black = 0,0,0
red = 255,0,0
green = 0,255,0
yellow = 255,255,0

pygame.init()

screen = pygame.display.set_mode(size)

grid = lines()
player = snake()

blocks = []
blocks.append(player)
moreBlocks = 0
score = 0

# Initial random location for prize
prize = [1,1]
a = 0
while 1:
    prize = randomLocation()
    for thing in blocks:
        if thing.pos == prize:
            a = 1
            break
    if a == 0:
        break

# Score text
font = pygame.font.Font(None, 36)
score_string = "Score:"
text = font.render(score_string, 1, red)
textpos = text.get_rect()
textpos.bottomleft = [400,500]
textpos.bottomright = [420,500]

score_num = str(score)
text1 = font.render(score_num, 1, red)
textpos1 = text.get_rect()
textpos1.bottomleft = [490,500]
textpos1.bottomright = [500,500]
    
# Initial Display
screen.fill(white)
pygame.draw.rect(screen, yellow, [prize[0]*CELLSIZE,prize[1]*CELLSIZE,10,10])
player.draw(screen)
grid.draw(screen)
screen.blit(text, textpos)
screen.blit(text1, textpos1)
pygame.display.flip()

p = 0
while 1:
    for event in pygame.event.get():
        if event.type == pygame.KEYDOWN:
            p = 1
        if event.type == pygame.QUIT:
            pygame.display.quit()
            pygame.quit()
            sys.exit()
    if p == 1:
        break

while 1:
    # Keyboard input and quitting
    for event in pygame.event.get():
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_RIGHT and player.direction != [-1,0]:
                player.direction = [1,0]
            if event.key == pygame.K_DOWN and player.direction != [0,-1]:
                player.direction = [0,1]
            if event.key == pygame.K_LEFT and player.direction != [1,0]:
                player.direction = [-1,0]
            if event.key == pygame.K_UP and player.direction != [0,1]:
                player.direction = [0,-1]
        if event.type == pygame.QUIT:
            pygame.display.quit()
            pygame.quit()
            sys.exit()

    # Check if the next location of the head is invalid (outside the box or hitting itself)
    next = [player.pos[0] + player.direction[0],player.pos[1] + player.direction[1]]
    for thing in blocks:
        if thing.pos == next:
            gameOver(screen)
    if next[0] > 49 or next[1] > 46 or next[0] < 0 or next[1] < 0:
        gameOver(screen)

    # Check if the next location of the head is the prize
    if next == prize:
        moreBlocks += 3
        score += 10
        a = 0
        while 1:
            prize = randomLocation()
            for thing in blocks:
                if thing.pos == prize:
                    a = 1
                    break
            if a == 0:
                break
        
    # Step one 
    timeStep(blocks)

    # Update score
    score_string = "Score:"
    text = font.render(score_string, 1, red)
    textpos = text.get_rect()
    textpos.bottomleft = [400,500]
    textpos.bottomright = [420,500]

    score_num = str(score)
    text1 = font.render(score_num, 1, red)
    textpos1 = text.get_rect()
    textpos1.bottomleft = [490,500]
    textpos1.bottomright = [500,500]
    
    # Draw onto screen
    screen.fill(white)
    for i in range(len(blocks)):
        blocks[i].draw(screen)
    pygame.draw.rect(screen, yellow, [prize[0]*CELLSIZE,prize[1]*CELLSIZE,10,10])
    grid.draw(screen)
    screen.blit(text, textpos)
    screen.blit(text1, textpos1)
    pygame.display.flip()

    # Add more blocks to end of chain
    if moreBlocks > 0:
        moreBlocks += -1
        buff = node([player.pos[0]-player.direction[0],player.pos[1]-player.direction[1]])
        blocks.append(buff)

    # Add a buffer for the timesetp (SCALE LATER BY THE LENGTH OF THE SNAKE)
    length = 100 - int(0.3*len(blocks))
    pygame.time.wait(length)
    


