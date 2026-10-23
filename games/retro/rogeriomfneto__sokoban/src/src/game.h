#pragma once

#include "map.h"
#include "player.h"

void update(Player& player, Map& map);
void draw(Player player, Map map, int xOffset, int yOffset);
