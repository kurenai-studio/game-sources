#include "AudioManager.h"
#include <iostream>
#include <vector>

namespace SpaceShooter {

AudioManager* AudioManager::instance = nullptr;

AudioManager::~AudioManager()
{
    UnloadAllAudio();
}

AudioManager* AudioManager::GetInstance()
{
    if(instance == nullptr) {
        instance = new AudioManager();
        // Initialize background music variables
        instance->currentBackgroundMusic = "";
        instance->currentMusicIndex = 0;
        instance->isLaserBeamLoaded = false;
        instance->isLaserPlaying = false;
    }
    return instance;
}

void AudioManager::DestroyInstance()
{
    if(instance != nullptr) {
        delete instance;
        instance = nullptr;
    }
}

bool AudioManager::LoadSound(const std::string& name, const std::string& path)
{
    if(sounds.find(name) != sounds.end()) {
        std::cout << "Sound '" << name << "' already loaded." << std::endl;
        return true;
    }

    Sound sound = ::LoadSound(path.c_str());
    if(!IsAudioDeviceReady()) {
#ifdef _DEBUG
        std::cout << "Audio device not ready!" << std::endl;
#endif
        return false;
    }

    sounds[name] = sound;
    std::cout << "Loaded sound: " << name << " from " << path << std::endl;
    return true;
}

void AudioManager::PlaySound(const std::string& name)
{
    auto it = sounds.find(name);
    if(it != sounds.end()) {
        ::PlaySound(it->second);
    }
}

void AudioManager::UnloadSound(const std::string& name)
{
    auto it = sounds.find(name);
    if(it != sounds.end()) {
        ::UnloadSound(it->second);
        sounds.erase(it);
    }
}

bool AudioManager::LoadMusic(const std::string& name, const std::string& path)
{
    if(music.find(name) != music.end()) {
        std::cout << "Music '" << name << "' already loaded." << std::endl;
        return true;
    }

    Music musicTrack = ::LoadMusicStream(path.c_str());
    if(!IsAudioDeviceReady()) {
        std::cout << "Audio device not ready!" << std::endl;
        return false;
    }

    music[name] = musicTrack;
    std::cout << "Loaded music: " << name << " from " << path << std::endl;
    return true;
}

void AudioManager::PlayMusic(const std::string& name, bool loop)
{
    auto it = music.find(name);
    if(it != music.end()) {
        it->second.looping = loop;
        ::PlayMusicStream(it->second);
    }
}

void AudioManager::StopMusic(const std::string& name)
{
    auto it = music.find(name);
    if(it != music.end()) {
        ::StopMusicStream(it->second);
    }
}

void AudioManager::UpdateMusic()
{
    for(auto& pair : music) {
        ::UpdateMusicStream(pair.second);
    }
    UpdateLaserBeam();

    // Check if background music has ended and switch to next track
    if(!currentBackgroundMusic.empty() && !IsBackgroundMusicPlaying()) {
        NextBackgroundTrack();
    }
}

bool AudioManager::LoadLaserBeam(const std::string& path)
{
    laserBeamMusic = ::LoadMusicStream(path.c_str());
    if(!IsAudioDeviceReady()) {
        std::cout << "Audio device not ready for laser beam!" << std::endl;
        return false;
    }

    isLaserBeamLoaded = true;
    isLaserPlaying = false;

    // Set timestamps based on supercharge timing
    laserStartTime = 2.790f; // 0.02.790 - when laser shooting starts
    laserEndTime = 6.29f;    // 6.29s - warmup + duration (2.79 + 3.5)

    std::cout << "Loaded laser beam music from " << path << std::endl;
    return true;
}

void AudioManager::PlayLaserBeam()
{
    if(isLaserBeamLoaded && !isLaserPlaying) {
        // Start from the beginning (0.0) to include warmup sound
        SeekMusicStream(laserBeamMusic, 0.0f);
        laserBeamMusic.looping = false; // Disable looping so it stops naturally
        ::PlayMusicStream(laserBeamMusic);
        isLaserPlaying = true;
        laserStartTimestamp = GetCurrentTimestamp();
        lastDebugTime = laserStartTimestamp;
        std::cout << "[DEBUG] Playing laser beam sound from beginning at timestamp: " << laserStartTimestamp
                  << std::endl;
    }
}

void AudioManager::StopLaserBeam()
{
    if(isLaserBeamLoaded && isLaserPlaying) {
        ::StopMusicStream(laserBeamMusic);
        isLaserPlaying = false;
        double stopTime = GetCurrentTimestamp();
        double playDuration = stopTime - laserStartTimestamp;
        std::cout << "[DEBUG] Stopped laser beam at timestamp: " << stopTime << ", duration: " << playDuration << "s"
                  << std::endl;
    }
}

void AudioManager::UpdateLaserBeam()
{
    if(isLaserBeamLoaded && isLaserPlaying) {
        ::UpdateMusicStream(laserBeamMusic);

        // Print debug info every second
        double currentTime = GetCurrentTimestamp();
        if(currentTime - lastDebugTime >= 1.0) {
            PrintLaserDebugInfo();
            lastDebugTime = currentTime;
        }

        // Only stop if music naturally stopped playing (reached its end)
        if(!IsMusicStreamPlaying(laserBeamMusic)) {
            std::cout << "[DEBUG] Music stream stopped playing naturally" << std::endl;
            StopLaserBeam();
        }
    }
}

bool AudioManager::LoadAllAudio()
{
    std::cout << "Loading all game audio..." << std::endl;

    bool success = true;

    // Load sound effects
    success &= LoadSound("shoot", "assets/audio/shoot.wav");

    // Load laser beam music
    success &= LoadLaserBeam("assets/audio/laser_beam.mp3");

    // Load background music tracks
    success &=
        LoadMusic("background_music_1", "assets/audio/waera - harinezumi _ New Jazz _ NCS - Copyright Free Music.mp3");
    success &=
        LoadMusic("background_music_2",
                  "assets/audio/FLAYA PLAYA, Maikubi, Nomeli - uWu BURST _ Phonk _ NCS - Copyright Free Music.mp3");

    if(success) {
        std::cout << "All audio loaded successfully!" << std::endl;
    } else {
        std::cout << "Some audio files failed to load!" << std::endl;
    }

    return success;
}

void AudioManager::UnloadAllAudio()
{
    std::cout << "Unloading all audio..." << std::endl;

    for(auto& pair : sounds) {
        ::UnloadSound(pair.second);
    }
    sounds.clear();

    for(auto& pair : music) {
        ::UnloadMusicStream(pair.second);
    }
    music.clear();

    if(isLaserBeamLoaded) {
        ::UnloadMusicStream(laserBeamMusic);
        isLaserBeamLoaded = false;
    }
}

void AudioManager::StartBackgroundMusic()
{
    // List of background music tracks
    const std::vector<std::string> tracks = {"background_music_1", "background_music_2"};

    if(!tracks.empty()) {
        currentMusicIndex = 0;
        currentBackgroundMusic = tracks[currentMusicIndex];
        PlayMusic(currentBackgroundMusic, true);

        // Set background music volume to 50%
        auto it = music.find(currentBackgroundMusic);
        if(it != music.end()) {
            ::SetMusicVolume(it->second, 0.5f);
        }

        std::cout << "Started background music: " << currentBackgroundMusic << " at 50%% volume" << std::endl;
    }
}

void AudioManager::StopBackgroundMusic()
{
    if(!currentBackgroundMusic.empty()) {
        StopMusic(currentBackgroundMusic);
        currentBackgroundMusic = "";
        std::cout << "Stopped background music" << std::endl;
    }
}

void AudioManager::NextBackgroundTrack()
{
    std::vector<std::string> tracks = {"background_music_1", "background_music_2"};

    if(!tracks.empty()) {
        // Stop current track
        if(!currentBackgroundMusic.empty()) {
            StopMusic(currentBackgroundMusic);
        }

        // Move to next track
        currentMusicIndex = (currentMusicIndex + 1) % tracks.size();
        currentBackgroundMusic = tracks[currentMusicIndex];
        PlayMusic(currentBackgroundMusic, true);

        // Set background music volume to 50%
        auto it = music.find(currentBackgroundMusic);
        if(it != music.end()) {
            ::SetMusicVolume(it->second, 0.5f);
        }

        std::cout << "Switched to background music: " << currentBackgroundMusic << " at 50%% volume" << std::endl;
    }
}

bool AudioManager::IsBackgroundMusicPlaying() const
{
    if(currentBackgroundMusic.empty())
        return false;

    auto it = music.find(currentBackgroundMusic);
    if(it != music.end()) {
        return IsMusicStreamPlaying(it->second);
    }
    return false;
}

void AudioManager::SetMasterVolume(float volume)
{
    ::SetMasterVolume(volume);
}

void AudioManager::SetSoundVolume(float volume)
{
    // Set volume for all sounds
    for(auto& pair : sounds) {
        ::SetSoundVolume(pair.second, volume);
    }
}

void AudioManager::SetMusicVolume(float volume)
{
    // Set volume for all music
    for(auto& pair : music) {
        ::SetMusicVolume(pair.second, volume);
    }

    if(isLaserBeamLoaded) {
        ::SetMusicVolume(laserBeamMusic, volume);
    }
}

double AudioManager::GetCurrentTimestamp()
{
    return ::GetTime();
}

void AudioManager::PrintLaserDebugInfo()
{
    if(!isLaserPlaying)
        return;

    double currentTimestamp = GetCurrentTimestamp();
    double elapsedTime = currentTimestamp - laserStartTimestamp;
    float musicTime = GetMusicTimePlayed(laserBeamMusic);
    float musicLength = GetMusicTimeLength(laserBeamMusic);
    bool isPlaying = IsMusicStreamPlaying(laserBeamMusic);

    std::cout << "[DEBUG] Laser Status - Elapsed: " << elapsedTime << "s, "
              << "Music Time: " << musicTime << "s/" << musicLength << "s, "
              << "Playing: " << (isPlaying ? "YES" : "NO") << std::endl;
}
} // namespace SpaceShooter
