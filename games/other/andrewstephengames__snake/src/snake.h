#ifndef SNAKE_H_
#define SNAKE_H_

#include <ctime>
#include <vector>
#include "menu.h"

using std::vector;

typedef enum {
     Title,
     Button1,
     Button2,
     Score,
} ui_element;

class Fruit {
     private:
          Vector2 center;
          float radius;
          Texture2D texture;
          int points;
          Color color;
     public:
          Fruit (char *file_name, Color color) {
               texture = LoadTexture (file_name);
               points = 0;
               this->color = color;
          }
          ~Fruit() {
               if (texture.id > 0) {
                    UnloadTexture (texture);
               }
          }
          Vector2 get_center() {
               return center;
          }
          void set_center(Vector2 center) {
               this->center = center;
          }
          float get_radius() {
               return radius;
          }
          void set_radius (float radius) {
               this->radius = radius;
          }
          Color get_color () {
               return color;
          }
          void set_color (Color color) {
               this->color = color;
          }
          Texture2D get_texture () {
               return texture;
          }
          void set_points (int points) {
               this->points = points;
          }
          int get_points () {
               return points;
          }
          void generate (Vector2 canvas);
          void draw (Vector2 canvas);
};

class Snake {
     private:
          Rectangle rect;
          Texture2D texture;
          float speed;
          bool keys[512];
          size_t length;
          Color color;
     public:
          Snake (char *file_name, float speed, Color color) {
               texture = LoadTexture (file_name);
               this->speed = speed;
               length = 0;
               this->color = color;
          }
          Texture2D get_texture () {
               return texture;
          }
          ~Snake() {
               if (texture.id > 0) {
                    UnloadTexture(texture);
               }
          }
          void set_rect (Rectangle rect) {
               this->rect = rect;
          }
          Rectangle get_rect () {
               return rect;
          }
          float get_speed () {
               return speed;
          }
          void set_speed (float speed) {
               this->speed = speed;
          }
          Color get_color () {
               return color;
          }
          void set_color (Color color) {
               this->color = color;
          }
          size_t get_length() {
               return length;
          }
          void set_length (size_t length) {
               this->length = length;
          }
          void generate (Vector2 canvas);
          void draw_head ();
          void draw_tail (Vector2 canvas, int last_direction);
          void reset_keys ();
          int handle_keys (Vector2 canvas);
};

class Game {
     private:
          GameState game_state;
          Vector2 canvas;
          Texture2D background;
          int score;
     public:
          vector<Element> e;
          Game (GameState game_state, Vector2 canvas, Texture2D background, int score) {
               this->game_state = game_state;
               this->canvas = canvas;
               this->background = background;
               this->score = score;
          }
          ~Game() {
               if (background.id > 0) {
                    UnloadTexture (background);
               }
          }
          GameState get_game_state () {
               return game_state;
          }
          void set_game_state (GameState game_state) {
               this->game_state = game_state;
          }
          Vector2 get_canvas () {
               return canvas;
          }
          void set_canvas (Vector2 canvas) {
               this->canvas = canvas;
          }
          int get_score () {
               return score;
          }
          void set_score (int score) {
               this->score = score;
          }
          Texture2D get_background() {
               return background;
          }
          void state_machine (Snake *snake, Fruit *fruit);
          void mouse_on_element (Element *e, GameState current_state, GameState prev_state);
          void draw_button (Element *e, bool texture, bool center, Vector2 canvas, GameState current_state, GameState prev_state);
          void print_game_state();
          void handle_collision (Snake *snake, Fruit *fruit, Vector2 canvas);
};

#endif // SNAKE_H_

void Fruit::generate(Vector2 canvas) {
     float margin = canvas.x/60;
     Vector2 canvas2 = {
          .x = canvas.x-margin,
          .y = canvas.y-margin,
     };
     Vector2 point = {
          .x = (float)GetRandomValue (margin, canvas2.x),
          .y = (float)GetRandomValue (margin, canvas2.y),
     };
     Fruit::set_center (point);
     Fruit::set_radius (margin);
}

void Fruit::draw (Vector2 canvas) {
     float margin = canvas.x/60;
     if (Fruit::get_texture().id > 0) {
          Rectangle texture_rec = {
               .x = canvas.x-margin,
               .y = canvas.y-margin,
               .width = margin,
               .height = margin,
          };
          DrawRectangleRec (texture_rec, WHITE);
     } else {
          DrawCircleV (Fruit::get_center(), Fruit::get_radius(), Fruit::color);
     }
}

void Snake::generate (Vector2 canvas) {
     float margin = canvas.x/60;
     Vector2 canvas2 = {
          .x = canvas.x-margin,
          .y = canvas.y-margin,
     };
     Rectangle snake_box = {
          .x = (float)GetRandomValue (margin, canvas2.x),
          .y = (float)GetRandomValue (margin, canvas2.y),
          .width = margin*2,
          .height = margin*2,
     };
     Snake::set_rect (snake_box);
}

void Snake::draw_head() {
     if (Snake::get_texture().id > 0) {
          DrawTextureRec (Snake::get_texture(), Snake::get_rect(), rec_to_v(Snake::get_rect()), WHITE);
     } else {
          DrawRectangleRec (Snake::get_rect(), Snake::color);
     }
}

void Snake::draw_tail(Vector2 canvas, int last_direction) {
     float margin = canvas.x/60;
     Vector2 w = {canvas.x-margin, canvas.y-margin};
     bool texture = Snake::get_texture().id > 0;
     Rectangle rec2;
     for (size_t i = 0; i < Snake::get_length(); ++i) {
          rec2 = Snake::get_rect();
          switch (last_direction) {
               case KEY_W: {
                    rec2.y -= (i+1)*margin;
               } break;
               case KEY_A: {
                    rec2.x -= (i+1)*margin;
               } break;
               case KEY_S: {
                    rec2.y += (i+1)*margin;
               } break;
               case KEY_D: {
                    rec2.x += (i+1)*margin;
               } break;
          }
          if (texture) {
               DrawTextureRec (Snake::get_texture(), rec2, rec_to_v(rec2), WHITE);
          } else {
               DrawRectangleRec (rec2, Snake::color);
          }
     }
}

void Snake::reset_keys () {
     for (int i = 0; i < 512; ++i) {
          Snake::keys[i] = false;
     }
}

int Snake::handle_keys (Vector2 canvas) {
     int ret;
     Vector2 dir = {1, 1};
     float margin = canvas.x/60;
     if (IsKeyPressed (KEY_W)) {
          Snake::reset_keys();
          Snake::keys[KEY_W] = true;
          ret = KEY_W;
     }
     if (IsKeyPressed (KEY_A)) {
          Snake::reset_keys();
          Snake::keys[KEY_A] = true;
          ret = KEY_A;
     }
     if (IsKeyPressed (KEY_S)) {
          Snake::reset_keys();
          Snake::keys[KEY_S] = true;
          ret = KEY_S;
     }
     if (IsKeyPressed (KEY_D)) {
          Snake::reset_keys();
          Snake::keys[KEY_D] = true;
          ret = KEY_D;
     }
     if (rect.x > canvas.x-margin) {
          rect.x = margin;
     }
     if (rect.x < margin) {
          rect.x = canvas.x-margin;
     }
     if (rect.y > canvas.y-margin) {
          rect.y = margin;
     }
     if (rect.y < margin) {
          rect.y = canvas.y-margin;
     }
     if (Snake::keys[KEY_W]) {
          rect.y -= margin*Snake::speed;
     }
     if (Snake::keys[KEY_A]) {
          rect.x -= margin*Snake::speed;
     }
     if (Snake::keys[KEY_S]) {
          rect.y += margin*Snake::speed;
     }
     if (Snake::keys[KEY_D]) {
          rect.x += margin*Snake::speed;
     }
     return ret;
}

void Game::handle_collision (Snake *snake, Fruit *fruit, Vector2 canvas) {
     if (CheckCollisionCircleRec (fruit->get_center(), fruit->get_radius(), snake->get_rect())) {
          Game::set_score(Game::get_score()+1);
          snake->set_length(snake->get_length()+1);
          fruit->generate(canvas);
     }
}

void Game::print_game_state() {
     switch (Game::get_game_state()) {
          case 0: {
               printf ("Menu\n");
          } break;
          case 1: {
               printf ("Start\n");
          } break;
          case 2: {
               printf ("End\n");
          } break;
          default:
               printf ("Unknown\n");
     }
}

void Game::mouse_on_element (Element *e, GameState current_state, GameState prev_state) {
     Vector2 mouse = GetMousePosition();
     if (CheckCollisionPointRec (mouse, e->box)) {
          e->fg = LIME;
          e->bg = WHITE;
          if (IsMouseButtonPressed (MOUSE_BUTTON_LEFT)) {
               Game::set_game_state (current_state);
          }
     } else {
          e->fg = BLACK;
          e->bg = WHITE;
     }
}

void Game::draw_button (Element *e, bool texture, bool center, Vector2 canvas, GameState current_state, GameState prev_state) {
     if (center) {
          center_element (e, canvas);
     }
     e->box.width = MeasureText(e->label, e->font_size);
     e->box.height = e->font_size;
     if (texture) {
          DrawTextureRec (e->texture, e->box, rec_to_v(e->box), e->bg);
     } else {
          float thick = e->box.x/100;
          Rectangle temp = {
               .x = e->box.x - thick*3,
               .y = e->box.y - thick*3,
               .width = e->box.width + thick*5,
               .height = e->box.height + thick*5,
          };
          DrawRectangleLinesEx (temp, thick, e->fg);
     }
     DrawText (e->label, e->box.x, e->box.y, e->font_size, e->fg);
     mouse_on_element (e, current_state, prev_state);
}

void Game::state_machine (Snake *snake, Fruit *fruit) {
     bool use_texture, center;
     Vector2 w = Game::get_canvas();
     switch (Game::get_game_state()) {
          case Menu: {
               if (IsKeyPressed (KEY_Q)) {
                    Game::set_game_state (End);
               }
               draw_background (w, 255, Game::get_background());
               use_texture = false;
               center = true;
               Vector2 canvas = {
                    .x = w.x,
                    .y = w.y/2,
               };
               draw_label (&Game::e.at(Title), use_texture, center, canvas);

               use_texture = false;
               center = true;
               canvas.y = w.y;
               Game::draw_button (&Game::e.at(Button1), use_texture, center, canvas, Start, Menu);

               use_texture = false;
               center = true;
               canvas.y = w.y + w.y/2;
               Game::draw_button (&Game::e.at(Button2), use_texture, center, canvas, End, Menu);
               if (IsKeyPressed (KEY_Q)) {
                    Game::set_game_state (End);
               }
               Game::set_score(0);
               snake->set_length(0);
               snake->generate(w);
               snake->reset_keys();
               fruit->generate(w);
          } break;
          case Start: {
               draw_background (w, 255, Game::get_background());
               if (IsKeyPressed (KEY_Q)) {
                    Game::set_game_state (Menu);
               }
               center = false;
               use_texture = false;
               sprintf (Game::e.at(Score).label, "Score: %d", Game::get_score());
               draw_label (&Game::e.at(Score), center, use_texture, w);
               snake->draw_head();
               int last_dir = snake->handle_keys(w);
               snake->draw_tail(canvas, last_dir);
               fruit->draw(w);
               Game::handle_collision (snake, fruit, w);
               if (IsKeyPressed (KEY_R)) {
                    Game::set_game_state (Menu);
               }
          } break;
          case End: {
               draw_background (canvas, 255, Game::get_background());
               exit(EXIT_SUCCESS);
          } break;
          default: {
               fprintf (stderr, "Unknown game state\n");
               exit(EXIT_FAILURE);
          }
     }
}
