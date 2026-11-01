#include "map.hpp"

#include <assert.h>
#include <fstream>

#include <loguru.hpp>

#ifndef NDEBUG

#define ASSERT_SANE_WORLD                                                      \
  CHECK_F(world->historyCurrent != nullptr &&                                  \
              world->historyCurrent->map.size() != 0,                          \
          "The map seems to be empty");
#define ASSERT_SANE_PLAYER                                                     \
  CHECK_F(playerIndex > 0, "The map doesn't seem to contain a player");
#define ASSERT_SANE_WORLD_PLAYER                                               \
  ASSERT_SANE_WORLD                                                            \
  ASSERT_SANE_PLAYER
#define ASSERT_SANE_WORLD_PLAYER_TARGET                                        \
  ASSERT_SANE_WORLD_PLAYER                                                     \
  CHECK_F(targetIndex > 0, "The target doesn't seem to exist");                \
  CHECK_F(playerIndex != targetIndex,                                          \
          "Player and target seem to be the same thing");

#else
#define ASSERT_SANE_WORLD
#define ASSERT_SANE_PLAYER
#define ASSERT_SANE_WORLD_PLAYER
#define ASSERT_SANE_WORLD_PLAYER_TARGET
#endif

int GetGridYPosition(const int i, const int mapwidth) { return i / mapwidth; }
int GetGridXPosition(const int i, const int mapwidth) { return i % mapwidth; }

void ReadMap(world *world, const std::string file) {
  std::string line;
  std::ifstream mapfile(file);
  int linecount = 0;
  bool playerFound = false;
  int boxCount = 0;
  mapdef map;

  CHECK_F(mapfile.good(), "The mapfile doesn't seem to work or be readable");
  if (mapfile.is_open()) {
    LOG_F(INFO, "Reading file %s", file.c_str());
    while (getline(mapfile, line)) {
      DLOG_F(INFO, "Line: %s", line.c_str());
      if (linecount == 0) {
        world->mapwidth = std::stoi(line);
        DLOG_F(INFO, "Map width is %i", world->mapwidth);
      } else {
        CHECK_F((int)line.length() == world->mapwidth,
                "The line length doesn't match the set map width");
        for (std::string::size_type i = 0; i < line.length(); ++i) {
          std::string::value_type character = line[i];
          if (character == '@') {
            playerFound = true;
          }
          if (character == 'b') {
            boxCount++;
          }
          map.push_back(character);
        }
      }
      linecount++;
    }
    world->mapheight = linecount + 1;
  } else {
    LOG_F(ERROR, "Failed to open file %s", file.c_str());
  }
  addToHistory(world, map);
  CHECK_F(playerFound, "Didn't find a player on the map");
  CHECK_F(boxCount > 0, "Didn't find a single box on the map");
  UpdatePlayerPosition(world);
}

void UpdatePlayerPosition(world *world) {
  ASSERT_SANE_WORLD;
  auto currentmap = world->historyCurrent->map;
  for (std::vector<char>::size_type i = 0; i != currentmap.size(); i++) {
    if (currentmap[i] == '@') {
      world->playerPosition.x = GetGridXPosition(i, world->mapwidth);
      world->playerPosition.y = GetGridYPosition(i, world->mapwidth);
      return;
    }
  }
}

void RestoreTileFromOriginal(world *world, const size_t playerIndex,
                             mapdef *nextmap) {
  ASSERT_SANE_WORLD_PLAYER;
  // This will be useful later on when we have targets to push blocks on
  auto originalmap = world->historyHead->map;
  if (originalmap[playerIndex] == '.') {
    nextmap->at(playerIndex) = originalmap[playerIndex];
  } else {
    nextmap->at(playerIndex) = '.';
  }
}

void MoveBlockAndPlayerOnMap(world *world, const size_t playerIndex,
                             const size_t targetIndex) {
  /* we need to find the direction that the player is trying to push the block
     towards which can be done by comparing playerIndex and targetIndex

     @b -> playerIndex = targetIndex - 1
     b@ -> playerIndex = targetIndex + 1
     @
     b -> playerIndex < targetIndex
     b
     @ -> playerIndex > targetIndex
  */
  ASSERT_SANE_WORLD_PLAYER_TARGET;
  auto currentmap = world->historyCurrent->map;
  if (playerIndex == targetIndex - 1) {
    size_t blockTargetIndex = targetIndex + 1;
    if (currentmap[blockTargetIndex] == '.') {
      mapdef nextmap(currentmap);
      nextmap[blockTargetIndex] = 'b';
      nextmap[targetIndex] = '@';
      RestoreTileFromOriginal(world, playerIndex, &nextmap);
      addToHistory(world, nextmap);
      world->turns++;
    }
  } else if (playerIndex == targetIndex + 1) {
    size_t blockTargetIndex = targetIndex - 1;
    if (currentmap[blockTargetIndex] == '.') {
      mapdef nextmap(currentmap);
      nextmap[blockTargetIndex] = 'b';
      nextmap[targetIndex] = '@';
      RestoreTileFromOriginal(world, playerIndex, &nextmap);
      addToHistory(world, nextmap);
      world->turns++;
    }
  } else if (playerIndex < targetIndex) {
    size_t blockTargetIndex = targetIndex + world->mapwidth;
    if (currentmap[blockTargetIndex] == '.') {
      mapdef nextmap(currentmap);
      nextmap[blockTargetIndex] = 'b';
      nextmap[targetIndex] = '@';
      RestoreTileFromOriginal(world, playerIndex, &nextmap);
      addToHistory(world, nextmap);
      world->turns++;
    }
  } else if (playerIndex > targetIndex) {
    size_t blockTargetIndex = targetIndex - world->mapwidth;
    if (currentmap[blockTargetIndex] == '.') {
      mapdef nextmap(currentmap);
      nextmap[blockTargetIndex] = 'b';
      nextmap[targetIndex] = '@';
      RestoreTileFromOriginal(world, playerIndex, &nextmap);
      addToHistory(world, nextmap);
      world->turns++;
    }
  }
}

void MovePlayerOnMap(world *world, const size_t playerIndex,
                     const size_t targetIndex) {
  ASSERT_SANE_WORLD_PLAYER_TARGET;
  auto currentmap = world->historyCurrent->map;
  switch (currentmap[targetIndex]) {
  case '.': { // Target space is empty
    mapdef nextmap(currentmap);
    RestoreTileFromOriginal(world, playerIndex, &nextmap);
    nextmap[targetIndex] = '@';
    world->turns++;
    addToHistory(world, nextmap);
    break;
  }
  case 'b': { // Target space is a moveable block
    MoveBlockAndPlayerOnMap(world, playerIndex, targetIndex);
    break;
  }
  }
}

void TryMovePlayerRight(world *world) {
  ASSERT_SANE_WORLD;
  // Player is already at the right edge of the map
  if (world->playerPosition.x == world->mapwidth - 1) {
    return;
  }

  size_t playerIndex =
      world->playerPosition.y * world->mapwidth + world->playerPosition.x;

  MovePlayerOnMap(world, playerIndex, playerIndex + 1);
}

void TryMovePlayerLeft(world *world) {
  ASSERT_SANE_WORLD;
  // Player is already at the left edge of the map
  if (world->playerPosition.x == 0) {
    return;
  }

  size_t playerIndex =
      world->playerPosition.y * world->mapwidth + world->playerPosition.x;

  MovePlayerOnMap(world, playerIndex, playerIndex - 1);
}

void TryMovePlayerUp(world *world) {
  ASSERT_SANE_WORLD;

  // Player is already at the top edge of the map
  if (world->playerPosition.y == 0) {
    return;
  }

  size_t playerIndex =
      world->playerPosition.y * world->mapwidth + world->playerPosition.x;
  size_t targetIndex =
      (world->playerPosition.y - 1) * world->mapwidth + world->playerPosition.x;

  MovePlayerOnMap(world, playerIndex, targetIndex);
}

void TryMovePlayerDown(world *world) {
  ASSERT_SANE_WORLD;
  // Player is already at the bottom edge of the map
  if (world->playerPosition.y == world->mapheight - 1) {
    return;
  }

  size_t playerIndex =
      world->playerPosition.y * world->mapwidth + world->playerPosition.x;
  size_t targetIndex =
      (world->playerPosition.y + 1) * world->mapwidth + world->playerPosition.x;

  MovePlayerOnMap(world, playerIndex, targetIndex);
}

void ResetMap(world *world) {
  ASSERT_SANE_WORLD;
  CHECK_F(world->historyHead != nullptr && world->historyHead->map.size() > 0,
          "The original map seems to be empty");
  world->historyCurrent = world->historyHead;
  world->historyCurrent->next.reset();
  world->turns = 0;
}

world InitWorld() {
  world world;
  world.turns = 0;
  return world;
}

void addToHistory(world *world, mapdef entry) {
  if (world->historyHead == nullptr) {
    world->historyHead = new historynode{entry};
    world->historyCurrent = world->historyHead;
  } else {
    world->historyCurrent->next =
        std::unique_ptr<historynode>(new historynode{entry});
    world->historyCurrent->next->prev = world->historyCurrent;
    world->historyCurrent = world->historyCurrent->next.get();
  }
}

void undo(world *world) {
  if (world->historyCurrent->prev != nullptr) {
    world->historyCurrent = world->historyCurrent->prev;
    world->historyCurrent->next.reset();
    world->turns--;
  }
}
