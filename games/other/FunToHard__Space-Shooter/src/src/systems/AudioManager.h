#pragma once
#include <raylib.h>
#include <string>
#include <unordered_map>

namespace SpaceShooter {

class AudioManager
{
  private:
    static AudioManager* instance;
    std::unordered_map<std::string, Sound> sounds;
    std::unordered_map<std::string, Music> music;

    // Laser beam specific
    Music laserBeamMusic;
    bool isLaserBeamLoaded;
    bool isLaserPlaying;
    float laserStartTime;
    float laserEndTime;

    // Background music management
    std::string currentBackgroundMusic;
    int currentMusicIndex;

    // Debug timing
    double laserStartTimestamp;
    double lastDebugTime;

    AudioManager() = default;

  public:
    ~AudioManager();

    static AudioManager* GetInstance();
    static void DestroyInstance();

    // Sound management
    bool LoadSound(const std::string& name, const std::string& path);
    void PlaySound(const std::string& name);
    void UnloadSound(const std::string& name);

    // Music management
    bool LoadMusic(const std::string& name, const std::string& path);
    void PlayMusic(const std::string& name, bool loop = true);
    void StopMusic(const std::string& name);
    void UpdateMusic();

    // Background music management
    void StartBackgroundMusic();
    void StopBackgroundMusic();
    void NextBackgroundTrack();
    bool IsBackgroundMusicPlaying() const;

    // Laser beam specific functions
    bool LoadLaserBeam(const std::string& path);
    void PlayLaserBeam();
    void StopLaserBeam();
    bool IsLaserBeamPlaying() const
    {
        return isLaserPlaying;
    }
    void UpdateLaserBeam();

    // Debug functions
    void PrintLaserDebugInfo();
    double GetCurrentTimestamp();

    // Load all game audio
    bool LoadAllAudio();
    void UnloadAllAudio();

    // Volume control
    void SetMasterVolume(float volume);
    void SetSoundVolume(float volume);
    void SetMusicVolume(float volume);
};
} // namespace SpaceShooter
