#ifndef MAP_H
#define MAP_H

#include <string>
#include <vector>
#include <memory>

using mapdef = std::vector<char>;

using historynode = struct _HISTORYNODE {
  mapdef map;
  std::unique_ptr<_HISTORYNODE> next = nullptr;
  _HISTORYNODE *prev = nullptr;
};

using position = struct _POSITION {
  int x;
  int y;
};

using world = struct _WORLD {
  int mapwidth = -1;
  int mapheight = -1;
  position playerPosition;
  int turns = -1;
  historynode *historyHead = nullptr;
  historynode *historyCurrent = nullptr;
};

int GetGridYPosition(const int i, const int mapwidth);
int GetGridXPosition(const int i, const int mapwidth);

void ReadMap(world *world, const std::string file);

void UpdatePlayerPosition(world *world);

void RestoreTileFromOriginal(world *world, const size_t playerIndex, mapdef *nextmap);

void TryMovePlayerRight(world *world);
void TryMovePlayerLeft(world *world);
void TryMovePlayerUp(world *world);
void TryMovePlayerDown(world *world);

void ResetMap(world *world);

world InitWorld();

void addToHistory(world *world, mapdef entry);

void undo(world *world);

#endif /* MAP_H */
