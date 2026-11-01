#include "ResourceManager.h"
#include <iostream>

namespace SpaceShooter {

ResourceManager* ResourceManager::instance = nullptr;

ResourceManager::~ResourceManager()
{
    UnloadAllAssets();
}

ResourceManager* ResourceManager::GetInstance()
{
    if(instance == nullptr) {
        instance = new ResourceManager();
    }
    return instance;
}

void ResourceManager::DestroyInstance()
{
    if(instance != nullptr) {
        delete instance;
        instance = nullptr;
    }
}

bool ResourceManager::LoadTexture(const std::string& name, const std::string& path)
{
    if(textures.find(name) != textures.end()) {
        std::cout << "Texture '" << name << "' already loaded." << std::endl;
        return true;
    }

    Texture2D texture = ::LoadTexture(path.c_str());
    if(texture.id == 0) {
        std::cout << "Failed to load texture: " << path << std::endl;
        return false;
    }

    textures[name] = texture;
    std::cout << "Loaded texture: " << name << " from " << path << std::endl;
    return true;
}

Texture2D* ResourceManager::GetTexture(const std::string& name)
{
    auto it = textures.find(name);
    if(it != textures.end()) {
        return &it->second;
    }
    std::cout << "Texture '" << name << "' not found!" << std::endl;
    return nullptr;
}

void ResourceManager::UnloadTexture(const std::string& name)
{
    auto it = textures.find(name);
    if(it != textures.end()) {
        ::UnloadTexture(it->second);
        textures.erase(it);
    }
}

bool ResourceManager::LoadSound(const std::string& name, const std::string& path)
{
    if(sounds.find(name) != sounds.end()) {
        std::cout << "Sound '" << name << "' already loaded." << std::endl;
        return true;
    }

    Sound sound = ::LoadSound(path.c_str());
    if(!IsAudioDeviceReady()) {
        std::cout << "Audio device not ready!" << std::endl;
        return false;
    }

    sounds[name] = sound;
    std::cout << "Loaded sound: " << name << " from " << path << std::endl;
    return true;
}

Sound* ResourceManager::GetSound(const std::string& name)
{
    auto it = sounds.find(name);
    if(it != sounds.end()) {
        return &it->second;
    }
    std::cout << "Sound '" << name << "' not found!" << std::endl;
    return nullptr;
}

void ResourceManager::UnloadSound(const std::string& name)
{
    auto it = sounds.find(name);
    if(it != sounds.end()) {
        ::UnloadSound(it->second);
        sounds.erase(it);
    }
}

bool ResourceManager::LoadAllAssets()
{
    std::cout << "Loading all game assets..." << std::endl;

    bool success = true;

    // Load textures
    success &= LoadTexture("background", BACKGROUND_TEXTURE);
    success &= LoadTexture("player", PLAYER_TEXTURE);
    success &= LoadTexture("player_bullet", PLAYER_BULLET_TEXTURE);
    success &= LoadTexture("enemy_bullet", ENEMY_BULLET_TEXTURE);

    success &= LoadTexture("basic_enemy", BASIC_ENEMY_TEXTURE);
    success &= LoadTexture("fast_enemy", FAST_ENEMY_TEXTURE);
    success &= LoadTexture("heavy_enemy", HEAVY_ENEMY_TEXTURE);

    // Load explosion frames
    for(int i = 0; i < 4; i++) {
        success &= LoadTexture("explosion_" + std::to_string(i), EXPLOSION_TEXTURES[i]);
    }

    success &= LoadTexture("powerup_double_shot", POWERUP_DOUBLE_SHOT_TEXTURE);
    success &= LoadTexture("powerup_shield", POWERUP_SHIELD_TEXTURE);
    success &= LoadTexture("powerup_speed_boost", POWERUP_SPEED_BOOST_TEXTURE);

    success &= LoadTexture("heart", HEART_TEXTURE);
    success &= LoadTexture("star", STAR_TEXTURE);

    if(success) {
        std::cout << "All assets loaded successfully!" << std::endl;
    } else {
        std::cout << "Some assets failed to load!" << std::endl;
    }

    return success;
}

void ResourceManager::UnloadAllAssets()
{
    std::cout << "Unloading all assets..." << std::endl;

    for(auto& pair : textures) {
        ::UnloadTexture(pair.second);
    }
    textures.clear();

    for(auto& pair : sounds) {
        ::UnloadSound(pair.second);
    }
    sounds.clear();
}
} // namespace SpaceShooter
