#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "raylib.h"
#include <time.h>

const char* words[] = {
"apple","banana","orange","grape","watermelon","strawberry","blueberry","cherry","peach","pear","plum","mango","papaya","kiwi","lemon","lime","apricot","coconut","fig","pomegranate",
"dragonfruit","avocado","melon","guava","blackberry","raspberry","cranberry","pineapple","nectarine","date","tomato","carrot","potato","onion","garlic","lettuce","broccoli","cauliflower",
"spinach","cabbage","celery","parsley","basil","oregano","thyme","rosemary","mint","cilantro","ginger","pepper","cucumber","zucchini","pumpkin","eggplant","asparagus","mushroom","radish",
"turnip","beet","corn","peas","bean","lentil","rice","wheat","barley","oats","quinoa","bread","butter","cheese","milk","yogurt","cream","honey","jam","sugar","salt","coffee","tea","juice",
"water","soda","cola","chocolate","candy","cookie","cake","pie","pudding","icecream","sandwich","burger","pizza","pasta","spaghetti","lasagna","taco","burrito","sushi","ramen","noodle",
"salad","steak","chicken","fish","shrimp","lobster","crab","egg","omelette","sausage","bacon","toast","pancake","waffle","cereal","mayonnaise","ketchup","mustard","vinegar","oil","olive",
"soup","stew","fries","chips","popcorn","snack","dessert","meal","breakfast","lunch","dinner","midnight","sunrise","sunset","morning","evening","afternoon","night","twilight","dawn","dusk",
"spring","summer","autumn","winter","rain","snow","storm","thunder","lightning","fog","mist","cloud","wind","breeze","tornado","hurricane","earthquake","volcano","fire","flood","wave","tide",
"ocean","sea","river","lake","pond","stream","waterfall","mountain","valley","hill","desert","forest","jungle","field","meadow","garden","island","beach","coast","cave","rock","stone","sand",
"soil","tree","plant","flower","grass","leaf","root","branch","bark","seed","petal","rose","tulip","daisy","lily","orchid","sunflower","violet","lavender","bamboo","oak","pine","birch","maple",
"willow","acorn","moss","fern","ivy","cactus","animal","dog","cat","rabbit","mouse","rat","horse","cow","goat","sheep","pig","donkey","chicken","duck","turkey","goose","bird","eagle","falcon",
"owl","sparrow","crow","raven","pigeon","parrot","shark","whale","dolphin","seal","turtle","snake","lizard","frog","spider","ant","bee","butterfly","beetle","fly","mosquito","worm","snail",
"crab","lobster","octopus","penguin","bear","lion","tiger","leopard","wolf","fox","monkey","zebra","giraffe","elephant","rhino","hippo","kangaroo","camel","deer","moose","buffalo","bat",
"squirrel","panda","starfish","seahorse","peacock","rooster","human","man","woman","child","baby","boy","girl","father","mother","brother","sister","uncle","aunt","cousin","friend","teacher",
"student","doctor","nurse","lawyer","engineer","scientist","artist","musician","writer","actor","director","singer","dancer","painter","police","soldier","firefighter","driver","chef","waiter",
"farmer","mechanic","builder","plumber","electrician","pilot","sailor","astronaut","president","mayor","king","queen","prince","princess","knight","wizard","witch","dragon","ghost","vampire",
"zombie","monster","fairy","elf","dwarf","goblin","troll","giant","robot","alien","cyborg","android","computer","keyboard","mouse","monitor","screen","laptop","tablet","phone","camera","radio",
"television","speaker","microphone","printer","scanner","router","server","internet","website","browser","email","message","password","code","program","software","hardware","data","database",
"algorithm","variable","function","loop","array","string","integer","boolean","object","class","method","module","library","syntax","compiler","debugger","memory","storage","file","folder",
"network","cloud","security","encryption","robotics","artificial","intelligence","machine","learning","neural","pixel","graphics","sprite","texture","shader","engine","frame","animation",
"collision","physics","render","camera","scene","entity","player","enemy","boss","weapon","armor","shield","potion","magic","quest","map","level","score","coin","gem","treasure","inventory",
"menu","save","load","exit","pause","resume","restart","victory","defeat","health","energy","mana","power","speed","strength","skill","ability","mission","story","dialogue","ending","chapter",
"character","hero","villain","companion","npc","city","village","castle","dungeon","temple","tower","bridge","gate","door","key","lock","chest","trap","puzzle","portal","spell","curse",
"blessing","light","darkness","shadow","fireball","ice","wind","earth","water","stone","metal","gold","silver","bronze","diamond","ruby","emerald","sapphire","crystal","pearl","ring",
"necklace","bracelet","sword","bow","arrow","dagger","axe","hammer","staff","wand","helmet","boots","gloves","cloak","cape","belt","torch","lantern","book","scroll","compass","mirror",
"crown","flask","bag","camp","fortress","arena","kingdom","empire","realm","world","galaxy","universe","planet","star","moon","sun","asteroid","comet","space","rocket","satellite","blackhole",
"gravity","orbit","meteor","nebula","cosmos","lightyear","telescope","astronomy","physics","chemistry","biology","math","geometry","algebra","calculus","history","geography","literature",
"poetry","music","art","painting","dance","film","cinema","photography","philosophy","psychology","sociology","anthropology","politics","economy","law","justice","freedom","peace","war",
"battle","revolution","dynasty","republic","government","nation","society","language","culture","tradition","religion","belief","faith","hope","love","anger","joy","sadness","fear","dream",
"memory","thought","mind","soul","heart","body","spirit","life","death","birth","time","past","present","future","moment","eternity","infinity","reality","illusion","truth","lie","wisdom",
"knowledge","science","creation","destruction","balance","chaos","order","fate","destiny","choice","chance","luck","courage","honor","glory","sleep","awake","rest","work","play","learn",
"teach","build","destroy","create","think","feel","dream","believe","fight","run","walk","fly","swim","jump","fall","rise","smile","cry","sing","dance","write","draw","paint","read","speak",
"listen","watch","wait","hope","remember","forget","begin","end","live","die"
};

bool reset_game = false;

int total_words = sizeof(words)/sizeof(words[0]);


int current_stage = 0;
int headposx = 200;
int headposy = 200;

int initial_alphabet_position_x = 500;
int initial_alphabet_position_y = 200;


int cursor_visual_position_x = 497;
int cursor_visual_position_y = 225;
int cursor_logical_position[2] = {0,0};

char cursorlog[20] = {"////////////////////"};
int cursorlog_index = 0;

char alphabet[7][4] = {{'a','b','c','d'},{'e','f','g','h'},{'i','j','k','l'},{'m','n','o','p'},{'q','r','s','t'},{'u','v','w','x'},{'y','z',' ',' '}};
char letter = '1';

bool hang_the_man = true;


bool initializeGame = false;

void initializeScreen();
void render();
void hangman_visual();
void alphabet_logic();
void input_action();
void replay();
char* generate_random_word();



int main() {
    initializeScreen();
    render();
    CloseWindow();
}


void initializeScreen() {
    InitWindow(800,800,"Hangman");
    SetTargetFPS(60);
}
void hangman_visual(int stage) {
   
    
    Rectangle armleft = {headposx-40,headposy+100,20,100};
    Vector2 armleft_origin = {armleft.width/2,armleft.height/2};
    float armleft_rotation = 45.0f;
    
    Rectangle armright = {headposx+40,headposy+100,20,100};
    Vector2 armright_origin = {armright.width/2,armright.height/2};
    float armright_rotation = 135.0f;
    
    Rectangle legleft = {headposx-40,headposy+210,20,100};
    Vector2 legleft_origin = {legleft.width/2,legleft.height/2};
    float legleft_rotation = 45.0f;

    Rectangle legright = {headposx+40,headposy+210,20,100};
    Vector2 legright_origin = {legright.width/2,legright.height/2};
    float legright_rotation = 135.0f;
    
    Rectangle hangstick_vertical = {headposx,headposy-90,10,110};
    Vector2 hangstick_vertical_origin = {hangstick_vertical.width/2,hangstick_vertical.height/2};
    float hangstick_vertical_rotation = 0.0f;
    
    Rectangle hangstick_horizantal = {headposx-50,headposy-140,10,150};
    Vector2 hangstick_horizantal_origin = {hangstick_horizantal.width/2,hangstick_vertical.height/2};
    float hangstick_horizantal_rotation = 90.0f;
    
    Rectangle hangstick_big = {headposx-150,headposy+80,10,440};
    Vector2 hangstick_big_origin = {hangstick_big.width/2,hangstick_big.height/2};
    float hangstick_big_rotation = 0.0f;
    switch(stage) {
        
        case 0:
            DrawRectanglePro(hangstick_vertical,hangstick_vertical_origin,hangstick_vertical_rotation,BLACK);
            DrawRectanglePro(hangstick_horizantal,hangstick_horizantal_origin,hangstick_horizantal_rotation,BLACK);
            DrawRectanglePro(hangstick_big,hangstick_big_origin,hangstick_big_rotation,BLACK);
            break;
        case 1:
            DrawRectanglePro(hangstick_vertical,hangstick_vertical_origin,hangstick_vertical_rotation,BLACK);
             DrawCircle(headposx,headposy,40,BLACK);
             DrawRectanglePro(hangstick_horizantal,hangstick_horizantal_origin,hangstick_horizantal_rotation,BLACK);
             DrawRectanglePro(hangstick_big,hangstick_big_origin,hangstick_big_rotation,BLACK);
             break;
        case 2:
            DrawRectanglePro(hangstick_vertical,hangstick_vertical_origin,hangstick_vertical_rotation,BLACK);
            DrawCircle(headposx,headposy,40,BLACK);
            DrawRectangle(headposx-10,headposy+40,20,150,BLACK);
            DrawRectanglePro(hangstick_horizantal,hangstick_horizantal_origin,hangstick_horizantal_rotation,BLACK);
            DrawRectanglePro(hangstick_big,hangstick_big_origin,hangstick_big_rotation,BLACK);
            break;
        case 3:
            DrawRectanglePro(hangstick_vertical,hangstick_vertical_origin,hangstick_vertical_rotation,BLACK);
            DrawCircle(headposx,headposy,40,BLACK);
            DrawRectangle(headposx-10,headposy+40,20,150,BLACK);
            DrawRectanglePro(armright,armright_origin,armright_rotation,BLACK);
            DrawRectanglePro(hangstick_horizantal,hangstick_horizantal_origin,hangstick_horizantal_rotation,BLACK);
            DrawRectanglePro(hangstick_big,hangstick_big_origin,hangstick_big_rotation,BLACK);
            
            break;
        case 4:
            DrawRectanglePro(hangstick_vertical,hangstick_vertical_origin,hangstick_vertical_rotation,BLACK);
            DrawCircle(headposx,headposy,40,BLACK);
            DrawRectangle(headposx-10,headposy+40,20,150,BLACK);
            DrawRectanglePro(armright,armright_origin,armright_rotation,BLACK); 
            DrawRectanglePro(armleft,armleft_origin,armleft_rotation,BLACK);
            DrawRectanglePro(hangstick_horizantal,hangstick_horizantal_origin,hangstick_horizantal_rotation,BLACK);
            DrawRectanglePro(hangstick_big,hangstick_big_origin,hangstick_big_rotation,BLACK);
            break;
        case 5:
            DrawRectanglePro(hangstick_vertical,hangstick_vertical_origin,hangstick_vertical_rotation,BLACK);
            DrawCircle(headposx,headposy,40,BLACK);
            DrawRectangle(headposx-10,headposy+40,20,150,BLACK);
            DrawRectanglePro(armright,armright_origin,armright_rotation,BLACK); 
            DrawRectanglePro(armleft,armleft_origin,armleft_rotation,BLACK);
            DrawRectanglePro(legleft,legleft_origin,legleft_rotation,BLACK);
            DrawRectanglePro(hangstick_horizantal,hangstick_horizantal_origin,hangstick_horizantal_rotation,BLACK);
            DrawRectanglePro(hangstick_big,hangstick_big_origin,hangstick_big_rotation,BLACK);
            break;
        case 6:
            DrawRectanglePro(hangstick_vertical,hangstick_vertical_origin,hangstick_vertical_rotation,BLACK);
            DrawCircle(headposx,headposy,40,BLACK);
            DrawRectangle(headposx-10,headposy+40,20,150,BLACK);
            DrawRectanglePro(armright,armright_origin,armright_rotation,BLACK); 
            DrawRectanglePro(armleft,armleft_origin,armleft_rotation,BLACK);
            DrawRectanglePro(legleft,legleft_origin,legleft_rotation,BLACK);
            DrawRectanglePro(legright,legright_origin,legright_rotation,BLACK);
            DrawRectanglePro(hangstick_horizantal,hangstick_horizantal_origin,hangstick_horizantal_rotation,BLACK);
            DrawRectanglePro(hangstick_big,hangstick_big_origin,hangstick_big_rotation,BLACK);
            break;

    }

}
void render() {
    //reset all settings
    reset_game = 0;
    
    //current stage resetted
    current_stage = 0;
    
    
    // position of cursor (letter A)
    cursor_visual_position_x = 497;
    cursor_visual_position_y = 225;
    
    //logical position (in array, 0,0)
    cursor_logical_position[0] = 0;
    cursor_logical_position[1] = 0;
    
    //cursor log, initially invalid value
    for (size_t i = 0; i < 20; i++) {
        cursorlog[i] = '/';
    }
    //index of cursor, resetted to 0
    cursorlog_index = 0;
    
    //initial letter, which is invalid '1' to prevent using a wrong guess in start
    char letter = '1';
    
    //it doesnt matter what hang_the_man value is
    hang_the_man = true;
    
    
    //game came back to the main menu
    initializeGame = false;
     
    
    
    char *word = generate_random_word();
    size_t wordsize = strlen(word);
    char gameword[wordsize];
    for (size_t i = 0; i < wordsize; i++) {
        gameword[i] = '_';
    }
    if (initializeGame == false) {

        while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText("HANGMAN",150,200,100,BLACK);
        DrawText("Press space to play",150,300,50,BLACK);
        EndDrawing();
        if (IsKeyPressed(KEY_SPACE)) {
            initializeGame = true;
            break;
        } 
        }
        }
    
    if (initializeGame == true) {
        while (!WindowShouldClose()) {
                size_t wordsize = strlen(gameword);
        
        
                for (size_t i = 0; i < wordsize; i++) {
                for (size_t j = 0; j < strlen(cursorlog); j++) {
                if (cursorlog[j] == word[i]) {
                gameword[i] = word[i];
                
            }
            
        }
        
        }
            if (IsKeyPressed(KEY_ENTER)) {
            letter = alphabet[cursor_logical_position[1]][cursor_logical_position[0]];
            cursorlog[cursorlog_index] = letter;
            cursorlog_index+= 1;
            if (strchr(word,letter) != NULL) {
                hang_the_man = false;
            } else {
                hang_the_man = true;
            }
            if (hang_the_man) {
                current_stage+=1;
                
            }
            if (current_stage == 6) {
                break;
            }
            
        }
        BeginDrawing();
            ClearBackground(RAYWHITE);
            DrawText(gameword,300,600,40,BLACK);
            hangman_visual(current_stage);
            alphabet_logic();
            input_action();
            
            
        EndDrawing();

        }
        
            if (current_stage == 6) {
            while (!WindowShouldClose()) {
            BeginDrawing();
            ClearBackground(RAYWHITE);
            DrawText(TextFormat("Game ended, the word was \"%s\"",word),100,300,30,BLACK);
            DrawText("Press R to play again or press Q to quit.",100,400,20,BLACK);
            if (IsKeyPressed(KEY_R)) {
                reset_game = true;
                break;
                  
            } 
            if (IsKeyPressed(KEY_Q)) {
                break;
            }
            
            EndDrawing();
        }
        }

    }
    if (reset_game) {
        render();
    }
    CloseWindow();
    }
void alphabet_logic() {
    int putposx = initial_alphabet_position_x; 
    int putposy = initial_alphabet_position_y;
    for (size_t i = 0; i < 7; i++) {
        putposx = initial_alphabet_position_x;
        putposy += 25;
        for (size_t j = 0; j < 4; j++) {
            DrawText(TextFormat("%c",alphabet[i][j]),putposx,
            putposy,20,BLACK);
            putposx += 30;
            
         
        }
    }
    DrawRectangleLines(cursor_visual_position_x,cursor_visual_position_y,20,20,RED);
    
    
}
void input_action() {
    
    if (initializeGame == true) {
        if ((IsKeyPressed(KEY_DOWN) || IsKeyPressed(KEY_S)) &&  
        cursor_logical_position[1] < 6) {
           cursor_visual_position_y += 25; 
           cursor_logical_position[1] += 1;
        }
        else if ((IsKeyPressed(KEY_UP) || IsKeyPressed(KEY_W)) && 
        cursor_logical_position[1] > 0) {
            cursor_visual_position_y -= 25;
            cursor_logical_position[1] -= 1;
        } else if ((IsKeyPressed(KEY_RIGHT) || IsKeyPressed(KEY_D)) && cursor_logical_position[0] < 3) {
            cursor_visual_position_x += 30;
            cursor_logical_position[0] += 1;
        } else if ((IsKeyPressed(KEY_LEFT) || IsKeyPressed(KEY_A)) && cursor_logical_position[0] > 0) {
            cursor_visual_position_x -= 30;
            cursor_logical_position[0] -= 1; 
        }

    }
    
}





char* generate_random_word() {
    srand(time(NULL));
    int random_index = rand() % total_words;
    return words[random_index];
}
void replay() {
    render();
}
    
    
