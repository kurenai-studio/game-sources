#pragma once
#include "../utils/GameConfig.h"
#include <raylib.h>
#include <string>
#include <unordered_map>

namespace SpaceShooter {

class ResourceManager
{
  private:
    static ResourceManager* instance;
    std::unordered_map<std::string, Texture2D> textures;
    std::unordered_map<std::string, Sound> sounds;

    ResourceManager() = default;

  public:
    ~ResourceManager();

    static ResourceManager* GetInstance();
    static void DestroyInstance();

    // Texture management
    bool LoadTexture(const std::string& name, const std::string& path);
    Texture2D* GetTexture(const std::string& name);
    void UnloadTexture(const std::string& name);

    // Sound management
    bool LoadSound(const std::string& name, const std::string& path);
    Sound* GetSound(const std::string& name);
    void UnloadSound(const std::string& name);

    // Load all game assets
    bool LoadAllAssets();
    void UnloadAllAssets();
};
} // namespace SpaceShooter
