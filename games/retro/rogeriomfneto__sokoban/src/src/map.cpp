#include <algorithm>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <tileson.hpp>
#include "map.h"

bool Map::loadFromFile(const char* path) {
    int dataSize = 0;
    unsigned char* fileData = LoadFileData(path, &dataSize);
    if (fileData == nullptr)
        return false;

    auto jsonParser = std::make_unique<tson::Json11>();
    jsonParser->directory(std::filesystem::path(path).parent_path());
    tson::Tileson parser(std::move(jsonParser));

    std::unique_ptr<tson::Map> tilesonMap =
        parser.parse(fileData, static_cast<size_t>(dataSize));
    UnloadFileData(fileData);

    if (!tilesonMap || tilesonMap->getStatus() != tson::ParseStatus::OK)
        return false;

    loadMap(*tilesonMap);
    return true;
}

void Map::loadMap(tson::Map& tileson) {
    width = tileson.getSize().x;
    height = tileson.getSize().y;
    auto& layer = tileson.getLayers()[0];

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int index = y * width + x;
            int gid = layer.getData()[index];
            layout[y][x] = gid;
        }
    }
}

bool Map::isWall(int x, int y) {
    return layout[y][x] == 1 || layout[y][x] == 2 || layout[y][x] == 3;
}

bool Map::isEmpty(int x, int y) {
    return layout[y][x] == 6 || layout[y][x] == 4 || layout[y][x] == 7;
}

bool Map::isButton(int x, int y) {
    return layout[y][x] == 4;
}

void Map::loadBoxes(Box newBoxes[], int n) {
    boxCount = n;

    for (int i = 0; i < n; i++) {
        Box box = newBoxes[i];
        boxes[i] = box;
    }
}

void Map::moveBox(Box* box, Direction direction) {
    Vector2 pos = applyDirectionToPosition((*box).pos, direction);

    box->pos.x = pos.x;
    box->pos.y = pos.y;

    if (layout[(int)pos.y][(int)pos.x] == 4)
        box->inPlace = true;
    else
        box->inPlace = false;
}

bool Map::canMoveBox(Box box, Direction direction) {
    Vector2 pos = applyDirectionToPosition(box.pos, direction);
    int x = pos.x;
    int y = pos.y;

    if (!isEmpty(pos.x, pos.y) || getBox(x, y) != nullptr)
        return false;

    return true;
}

Box* Map::getBox(int x, int y) {
    for (int i = 0; i < boxCount; i++) {
        if ((int)boxes[i].pos.x == x && (int)boxes[i].pos.y == y)
            return &boxes[i];
    }

    return nullptr;
}
