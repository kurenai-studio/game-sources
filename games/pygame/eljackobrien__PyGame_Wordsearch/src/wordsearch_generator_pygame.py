# -*- coding: utf-8 -*-
"""
Created on Mon Oct 25 20:39:10 2021

@author: eljac
"""
# =============================================================================
# Fill in words:
#     Decide if diagonal/backwards allowed.
#     Check all possible locations to insert chosen word, including across already inserted words.
#         *word crossover is rarely happens by chance, could alter code to favour this.
# Add some menu options to change grid size, word themes, word length, word density etc...
# =============================================================================

import pygame as pg
import numpy as np

# Some colours to use
BTN_BKG, BTN_TXT, BTN_CLK, BTN_DONE = (255,255,255), (0,0,0), (255,255,0), (170,210,250)

# Default parameters
grid_size = [15, 15]
sidebar_size = 220
(H,W) = (690,690+sidebar_size)

# Get word list and filter out unsuitable words
data = np.genfromtxt('formatted_oxford_dictionary_word_list.txt', str, encoding='utf-8')
words0, lengths0 = data[:,0], data[:,1].astype(int)

MAX_WORD_LENGTH = 8


# Make sure any variables we might want to change in menu options are inside initialise()
# Could speed things up with more systematic algorithm and less randomness, but not necessary
def initialise():
    grid_size = [15, 15]
    max_length, min_length = MAX_WORD_LENGTH, 4

    inds = (lengths0 > min_length) & (lengths0 <= max_length)
    words = words0[inds]

    max_letters = int( 0.80 * np.prod(grid_size) )  # control word density

    grid = np.repeat(' ', np.prod(grid_size)).reshape(grid_size)
    ID_grid = np.arange(np.prod(grid_size)).reshape(grid_size)

    direction = ['right', 'down', 'diag']

    letters, words_list, ID_list = 0, [], []

    # Loop through and fill the grid with random words from the list
    # Choose a random direction and then a random possible position to start the word
    # If chosen position does not conflict with a previous word, insert the new word
    # Terminate after max_letters is reached, or after a set number of iterations
    for iteration in range(10000):
        word, direc = np.random.choice(words), np.random.choice(direction)
        if word in words_list: continue
        L = len(word)

        gw, gh = grid_size[1], grid_size[0]
        if direc == 'down':
            for i in np.random.choice(np.arange(gh-L), gh-L, False):
                for j in np.random.choice(np.arange(gw), gw, False):
                    old_grid = grid[i:i+L, j]
                    change = 1
                    for k in range(L):  # Check if word can be inserted here
                        if not (old_grid[k] == word[k] or old_grid[k] == ' '): change = 0
                    if change:  # Insert word into grid if there are no conflicts
                        letters += L
                        grid[i:i+L, j] = list(word)
                        ID = ID_grid[i:i+L, j]  # Store grid positions of word
                        words_list.append(word), ID_list.append(ID)
                        break
                if change: break

        if direc == 'right':
            for i in np.random.choice(np.arange(gh), gh, False):
                for j in np.random.choice(np.arange(gw-L), gw-L, False):
                    old_grid = grid[i, j:j+L]
                    change = 1
                    for k in range(L):
                        if not (old_grid[k] == word[k] or old_grid[k] == ' '): change = 0
                    if change:
                        letters += L
                        grid[i, j:j+L] = list(word)
                        ID = ID_grid[i, j:j+L]
                        words_list.append(word), ID_list.append(ID)
                        break
                if change: break

        if direc == 'diag':
            for i in np.random.choice(np.arange(gh-L), gh-L, False):
                for j in np.random.choice(np.arange(gw-L), gw-L, False):
                    old_grid = grid[np.arange(i,i+L),np.arange(j,j+L)]
                    change = 1
                    for k in range(L):
                        if not (old_grid[k] == word[k] or old_grid[k] == ' '): change = 0
                    if change:
                        letters += L
                        grid[np.arange(i,i+L),np.arange(j,j+L)] = list(word)
                        ID = ID_grid[np.arange(i,i+L),np.arange(j,j+L)]
                        words_list.append(word), ID_list.append(ID)
                        break
                if change: break


        if letters >= max_letters:
            break

    L = len(words_list)

    # Fill the remaining grid squares with letters. Only use letters that occur in the words.
    # Also weight the selection by the frequency that the letters occur in the words.
    temp = list(''.join(words_list))
    letters, weights = np.unique(temp, return_counts=True)
    for i in range(gh):
        for j in range(gw):
            if grid[i,j] == ' ': grid[i,j] = np.random.choice(letters, p=weights/np.sum(weights))

    return grid, words_list, ID_list

grid, words_list, ID_list = initialise()


#%%
pg.init()
IDs = []

class button():
    def __init__(self, ID, text,  x,y,  w,h,  font_size=28):
        self.ID = ID
        self.text = text
        self.x, self.y = x, y
        self.default_clr = BTN_BKG
        self.bg_clr, self.txt_clr = self.default_clr, BTN_TXT
        self.width, self.height = w, h
        self.rect = pg.Rect(self.x, self.y, self.width, self.height)
        self.font_size = font_size
        self.word_found = False

    def draw(self, win):
        pg.draw.rect(win, self.bg_clr, self.rect)
        font = pg.font.SysFont('Times New Roman', self.font_size)
        text = font.render(self.text, 1, self.txt_clr)
        # Some maths to center the text in the button, using the size of the button and text
        win.blit(text, ( self.x + round(self.width/2) - round(text.get_width()/2) ,\
                        self.y + round(self.height/2) - round(text.get_height()/2) ))
        # If this is part of the word list and the word has been found
        if self.word_found: pg.draw.line(win, BTN_DONE, (self.x, self.y+self.height/2),\
                                         (self.x+self.width, self.y+self.height/2), 3)

    def toggle(self):  # change button colour and add/remove this button ID to selected-list
        if self.bg_clr != BTN_CLK:
            IDs.append(self.ID)
            IDs.sort()
            self.bg_clr = BTN_CLK
        else:
            IDs.remove(self.ID)
            self.bg_clr = self.default_clr


def main():
    window = pg.display.set_mode((W,H))
    clock = pg.time.Clock()

    # Set up the button positions
    btns, lines_xy = [], []
    (nx, ny) = grid_size
    top, bottom, left, right = [np.empty(grid_size) for i in range(4)]

    # Define the letter buttons and store their positions in an array to check collisions
    for i in range(nx):
        for j in range(ny):
            w, h = (W-sidebar_size)/grid_size[0], H/grid_size[1]
            x, y = j*w+2,i*h+2

            top[i,j], left[i,j], bottom[i,j], right[i,j] = y, x, y+h, x+w

            btn = button(i*ny+j, grid[i,j],  x,y,  w-2,h-2)
            btns.append(btn)

    # Define the "buttons" that will constitute the sidebar words list
    wrd_btns, L = [], len(words_list)
    for i,word in enumerate(words_list):
        btn = button(i, word,  W-sidebar_size+4,i*H/L,  sidebar_size-4,H/L,  24)
        wrd_btns.append(btn)

    # Define the retry button(s)
    retry_w, retry_h = 450, 80
    end_message = ['All Words Found!','Well Done!','Play Again?']
    retry_btns = []
    for i,(text,frac)in enumerate(zip(end_message, [-3/2, -1/2, 1/2])):
        btn = button(None, text,  W/2-retry_w/2,H/2+retry_h*frac,  retry_w,retry_h,  60)
        btn.bg_clr = BTN_DONE
        retry_btns.append(btn)


    run, found_words = True, 0
    while run:

        for event in pg.event.get():
            # Check if quit button is clicked, terminate everything if so
            if event.type == pg.QUIT: return False

            if event.type == pg.MOUSEBUTTONDOWN:
                px, py = event.pos
                top_b, left_b, bottom_b, right_b = py>top, px>left, px<right, py<bottom
                i,j = np.where( top_b & left_b & bottom_b & right_b )
                try:  # can yield an error if you click BETWEEN letter buttons
                    i,j = i[0],j[0]
                except:
                    continue
                ID = i*ny+j

                btns[ID].toggle()

        # loop over unfound words, check if selected word is the right length, then check if IDs match
        for i in range(len(ID_list)):
            if len(IDs) == len(ID_list[i]):
                if (IDs == ID_list[i]).all():
                    # Strikethrough word in list and remove from words_list and ID_list
                    wrd_btns[i].word_found = 1
                    found_words += 1
                    # Store start and end letter positions to draw line on found words
                    x0 = btns[IDs[0]].x + btns[IDs[0]].width//2
                    y0 = btns[IDs[0]].y + btns[IDs[0]].height//2
                    x1 = btns[IDs[-1]].x + btns[IDs[-1]].width//2
                    y1 = btns[IDs[-1]].y + btns[IDs[-1]].height//2
                    lines_xy.append([x0, y0, x1, y1])

                    # toggling the buttons changes the IDs list, so need to iterate over a copy: 1*IDs
                    for ID in 1*IDs:
                        btns[ID].default_clr = BTN_DONE
                        btns[ID].toggle()
                    break


        # Draw everything to the screen (in correct order) and update the display, then tick the clock
        window.fill(BTN_TXT)

        pg.draw.rect(window, BTN_BKG, pg.Rect(W-sidebar_size+2, 0, sidebar_size-2, H))
        for btn in btns: btn.draw(window)
        for wrd_btn in wrd_btns: wrd_btn.draw(window)
        for x0,y0,x1,y1 in lines_xy:
            pg.draw.line(window, BTN_CLK, (x0,y0), (x1,y1), 2)

        # If all the words are found
        if found_words == L: run = False

        pg.display.flip()  # update the entire display surface to the screen

        clock.tick(30)


    # Display a victory message and wait for quit or retry button clicked
    while True:
        for event in pg.event.get():
            if event.type == pg.QUIT: return False

            if event.type == pg.MOUSEBUTTONDOWN:
                px, py = event.pos
                for retry_btn in retry_btns:
                    if retry_btn.rect.collidepoint(px, py): return True

        window.fill(BTN_TXT)

        pg.draw.rect(window, BTN_BKG, pg.Rect(W-sidebar_size+2, 0, sidebar_size-2, H))
        for btn in btns: btn.draw(window)
        for wrd_btn in wrd_btns: wrd_btn.draw(window)

        # Blit a new semi-transparent surface over the whole window, and draw the retry button
        s = pg.Surface((W,H))
        s.set_alpha(128), s.fill(BTN_CLK)
        window.blit(s, (0,0))
        for retry_btn in retry_btns: retry_btn.draw(window)

        pg.display.flip()

        clock.tick(15)



#%%
if __name__ == '__main__':
    retry = True
    while retry:
        retry = main()
        grid, words_list, ID_list = initialise()
    pg.quit()


