#include "raylib.h"
#include "raymath.h"
#include <vector>
#include <string>
#include <cmath>
#include <cstdlib>
#include <algorithm>
#include <sstream>
#include <random>

// ── Audio Procedural Synthesizer ───────────────────────────────────────────
struct SoundManager {
    Sound sndSlash;
    Sound sndHit;
    Sound sndDeath;
    Sound sndShoot;
    Sound sndDash;
    Sound sndCoin;
    Sound sndPotion;
    Sound sndLevelUp;
    Sound sndPortal;
    Sound sndHurt;
    Sound sndSpecial;
    Sound sndShield;
    Sound sndFreeze;

    void Init() {
        InitAudioDevice();
        sndSlash   = GenTone(0.12f, 440, 150, 3);
        sndHit     = GenTone(0.08f, 220, 80, 1);
        sndDeath   = GenTone(0.25f, 300, 50, 4);
        sndShoot   = GenTone(0.14f, 880, 440, 0);
        sndDash    = GenTone(0.15f, 600, 200, 3);
        sndHurt    = GenTone(0.12f, 180, 90, 2);
        sndSpecial = GenTone(0.35f, 180, 40, 0);
        sndFreeze  = GenTone(0.18f, 1200, 600, 0);

        sndCoin    = GenChime({ 988.0f, 1318.0f }, 0.08f);
        sndPotion  = GenChime({ 523.0f, 659.0f, 784.0f }, 0.07f);
        sndLevelUp = GenChime({ 523.0f, 659.0f, 784.0f, 1046.0f }, 0.12f);
        sndPortal  = GenChime({ 440.0f, 554.0f, 659.0f, 880.0f }, 0.15f);
        sndShield  = GenChime({ 880.0f, 1320.0f }, 0.09f);
    }

    void Close() {
        UnloadSound(sndSlash);
        UnloadSound(sndHit);
        UnloadSound(sndDeath);
        UnloadSound(sndShoot);
        UnloadSound(sndDash);
        UnloadSound(sndCoin);
        UnloadSound(sndPotion);
        UnloadSound(sndLevelUp);
        UnloadSound(sndPortal);
        UnloadSound(sndHurt);
        UnloadSound(sndSpecial);
        UnloadSound(sndShield);
        UnloadSound(sndFreeze);
        CloseAudioDevice();
    }

private:
    Sound GenTone(float duration, float startFreq, float endFreq, int type) {
        int sampleRate = 44100;
        int sampleCount = (int)(duration * sampleRate);
        short* samples = (short*)malloc(sampleCount * sizeof(short));
        float phase = 0.0f;

        for (int i = 0; i < sampleCount; ++i) {
            float t = (float)i / sampleCount;
            float freq = startFreq + (endFreq - startFreq) * t;
            float env = 1.0f - t;
            float s = 0.0f;
            if (type == 0) s = sinf(phase);
            else if (type == 1) s = (sinf(phase) >= 0 ? 0.6f : -0.6f);
            else if (type == 2) s = (2.0f * (phase / (2.0f * PI) - floorf(phase / (2.0f * PI) + 0.5f))) * 0.7f;
            else if (type == 3) s = ((float)rand() / RAND_MAX * 2.0f - 1.0f) * 0.5f;
            else if (type == 4) s = ((float)rand() / RAND_MAX * 2.0f - 1.0f) * (1.0f - t * 0.8f);

            phase += (2.0f * PI * freq) / sampleRate;
            samples[i] = (short)(s * env * 24000.0f);
        }

        Wave wave = { 0 };
        wave.frameCount = sampleCount;
        wave.sampleRate = sampleRate;
        wave.sampleSize = 16;
        wave.channels = 1;
        wave.data = samples;
        Sound snd = LoadSoundFromWave(wave);
        UnloadWave(wave);
        return snd;
    }

    Sound GenChime(const std::vector<float>& freqs, float noteDur) {
        int sampleRate = 44100;
        int noteSamples = (int)(noteDur * sampleRate);
        int totalSamples = (int)(noteSamples * freqs.size());
        short* samples = (short*)malloc(totalSamples * sizeof(short));

        for (size_t n = 0; n < freqs.size(); ++n) {
            float freq = freqs[n];
            float phase = 0.0f;
            for (int i = 0; i < noteSamples; ++i) {
                int idx = (int)(n * noteSamples + i);
                float t = (float)i / noteSamples;
                float env = powf(1.0f - t, 1.5f);
                float s = sinf(phase) * 0.7f;
                phase += (2.0f * PI * freq) / sampleRate;
                samples[idx] = (short)(s * env * 22000.0f);
            }
        }

        Wave wave = { 0 };
        wave.frameCount = totalSamples;
        wave.sampleRate = sampleRate;
        wave.sampleSize = 16;
        wave.channels = 1;
        wave.data = samples;
        Sound snd = LoadSoundFromWave(wave);
        UnloadWave(wave);
        return snd;
    }
};

// ── Game Data Structures ───────────────────────────────────────────────────
enum EnemyType { CHASER, RANGER, BRUTE, BOSS, BOMBER };
enum RelicType { RELIC_LIGHTNING, RELIC_TOXIC, RELIC_FROST, RELIC_AEGIS, RELIC_CHALICE, RELIC_COMBUSTION };
enum UpgradeType { UP_HP, UP_DMG, UP_SPEED, UP_ATTACK_RATE, UP_DASH, UP_LIFESTEAL, UP_ARMOR, UP_CRIT, UP_NOVA, UP_IGNITE, UP_FROST };

struct Relic {
    RelicType type;
    std::string name;
    std::string symbol;
    Color color;
};

struct Player {
    Vector2 pos;
    Vector2 vel;
    float maxHp = 100.0f;
    float hp = 100.0f;
    float speed = 280.0f;
    float baseDmg = 25.0f;
    float attackRate = 2.5f;
    float attackTimer = 0.0f;
    float dashTimer = 0.0f;
    float dashCooldown = 1.2f;
    bool isDashing = false;
    float dashDur = 0.2f;
    Vector2 dashDir;
    float specialTimer = 0.0f;
    float specialCooldown = 6.0f;
    float critChance = 0.05f;
    float lifesteal = 0.0f;
    float armor = 0.0f;
    int level = 1;
    int xp = 0;
    int xpNext = 50;
    int gold = 0;
    bool isInvuln = false;
    float invulnTimer = 0.0f;
    bool facingLeft = false;
    float walkTimer = 0.0f;
    std::vector<Relic> relics;
    bool shieldActive = false;
    float shieldTimer = 0.0f;
    int igniteLevel = 0; // Ember Edge: mỗi cấp = 50% sát thương cơ bản/giây trong 3s
    int frostLevel = 0;  // Frost Touch: mỗi cấp giảm 15% tốc độ quái (tối thiểu còn 40%)
};

struct Enemy {
    EnemyType type;
    Vector2 pos;
    Vector2 vel;
    float maxHp;
    float hp;
    float speed;
    float contactDmg;
    float radius;
    bool isElite = false;
    float bounceTimer = 0.0f;
    float attackCooldown = 0.0f;
    bool isAttacking = false;
    float attackTimer = 0.0f;
    bool facingLeft = false;
    float poisonTimer = 0.0f;
    float poisonDmg = 0.0f;
    float chillTimer = 0.0f;
    bool enraged = false;
    bool isWarden = false;   // mini-boss ở tầng 3 và 8
    bool fusing = false;     // Bomber đang cháy ngòi
    float fuseTimer = 0.0f;
    bool exploded = false;   // Bomber đã tự nổ (không rơi loot, không tính combo)
    float burnTimer = 0.0f;  // Ember Edge
    float burnDps = 0.0f;
    float slowTimer = 0.0f;  // Frost Touch
    float slowFactor = 1.0f;
};

struct Projectile {
    Vector2 pos;
    Vector2 vel;
    float damage;
    bool fromPlayer;
    float life;
    float radius;
    Color color;
};

struct Loot {
    int type; // 0: XP, 1: Gold, 2: Potion
    Vector2 pos;
    int value;
    float life;
};

struct DamagePopup {
    Vector2 pos;
    std::string text;
    Color color;
    float timer = 0.65f;
    float maxTimer = 0.65f;
};

struct SlashVisual {
    Vector2 pos;
    float angle;
    float timer = 0.15f;
    float maxTimer = 0.15f;
};

struct NovaVisual {
    Vector2 pos;
    float radius = 0.0f;
    float maxRadius = 180.0f;
    float timer = 0.35f;
    float maxTimer = 0.35f;
    Color color;
};

struct GhostTrail {
    Vector2 pos;
    bool facingLeft;
    float timer = 0.22f;
    float maxTimer = 0.22f;
};

struct Particle {
    Vector2 pos;
    Vector2 vel;
    Color color;
    float life;
    float maxLife;
    float size;
};

struct Mote {
    Vector2 pos;
    float speed;
    float phase;
    float size;
};

static Color LerpColor(Color a, Color b, float t) {
    t = std::max(0.0f, std::min(1.0f, t));
    return { (unsigned char)(a.r + (b.r - a.r) * t), (unsigned char)(a.g + (b.g - a.g) * t),
             (unsigned char)(a.b + (b.b - a.b) * t), (unsigned char)(a.a + (b.a - a.a) * t) };
}

static float Rand01() { return (float)rand() / (float)RAND_MAX; }

// ── Game State ─────────────────────────────────────────────────────────────
class Game {
public:
    SoundManager snd;
    Player player;
    std::vector<Enemy> enemies;
    std::vector<Projectile> projectiles;
    std::vector<Loot> loots;
    std::vector<DamagePopup> popups;
    std::vector<SlashVisual> slashes;
    std::vector<NovaVisual> novas;
    std::vector<GhostTrail> ghosts;
    std::vector<Vector2> pillars;

    int floor = 1;
    int enemiesSlain = 0;
    int comboCount = 0;
    float comboTimer = 0.0f;
    int bestFloor = 1;
    bool newRecord = false;
    bool portalOpen = false;
    Vector2 portalPos = { 0, -320 };

    float roomW = 1200;
    float roomH = 750;

    Camera2D camera = { 0 };
    float screenShakeTimer = 0.0f;
    float screenShakeMag = 0.0f;

    enum State { PLAYING, LEVEL_UP, GAME_OVER };
    State state = PLAYING;
    std::vector<UpgradeType> levelChoices;
    std::string bannerText = "";
    float bannerTimer = 0.0f;
    bool showMiniMap = true;

    // Hiệu ứng hình ảnh & sự kiện
    std::vector<Particle> particles;
    std::vector<Mote> motes;
    float damagePulse = 0.0f;   // viền màn hình nhấp đỏ khi bị đau
    float hitStop = 0.0f;       // khựng khung hình ngắn khi chí mạng
    int bestCombo = 0;
    bool hasShrine = false;
    bool shrineUsed = false;
    bool shrineHinted = false;
    Vector2 shrinePos = { 0, 0 };
    float shrineRefuse = 0.0f;
    float shrinePulse = 0.0f;

    void Init() {
        snd.Init();
        camera.zoom = 1.0f;
        camera.offset = { 1280 / 2.0f, 720 / 2.0f };
        InitMotes();
        RestartRun();
    }

    void RestartRun() {
        player = Player();
        player.pos = { 0, 240 };
        floor = 1;
        enemiesSlain = 0;
        comboCount = 0;
        bestCombo = 0;
        damagePulse = 0.0f;
        hitStop = 0.0f;
        particles.clear();
        newRecord = false;
        state = PLAYING;
        BuildFloor();
    }

    // ── Hiệu ứng hạt ──
    void Burst(Vector2 pos, Color c, int count, float speed, float life) {
        if (particles.size() > 700) return;
        if (particles.size() > 350) count = std::max(1, count / 3);
        for (int i = 0; i < count; ++i) {
            float a = Rand01() * 2.0f * PI;
            float sp = speed * (0.4f + 0.6f * Rand01());
            float shade = 0.8f + 0.35f * Rand01();
            Particle p;
            p.pos = pos;
            p.vel = { cosf(a) * sp, sinf(a) * sp };
            p.color = { (unsigned char)std::min(255.0f, c.r * shade), (unsigned char)std::min(255.0f, c.g * shade),
                        (unsigned char)std::min(255.0f, c.b * shade), 255 };
            p.maxLife = life * (0.7f + 0.4f * Rand01());
            p.life = p.maxLife;
            p.size = 2.0f + 3.0f * Rand01();
            particles.push_back(p);
        }
    }

    void InitMotes() {
        motes.clear();
        for (int i = 0; i < 40; ++i) {
            Mote m;
            m.pos = { (Rand01() - 0.5f) * roomW, (Rand01() - 0.5f) * roomH };
            m.speed = 8.0f + 22.0f * Rand01();
            m.phase = Rand01() * 10.0f;
            m.size = 1.2f + 2.0f * Rand01();
            motes.push_back(m);
        }
    }

    void UpdateEffects(float dt) {
        for (size_t i = 0; i < particles.size();) {
            Particle& p = particles[i];
            p.life -= dt;
            if (p.life <= 0) { particles[i] = particles.back(); particles.pop_back(); continue; }
            p.pos = Vector2Add(p.pos, Vector2Scale(p.vel, dt));
            p.vel = Vector2Scale(p.vel, std::max(0.0f, 1.0f - 4.5f * dt));
            ++i;
        }
        for (auto& m : motes) {
            m.pos.y -= m.speed * dt;
            m.pos.x += sinf((float)GetTime() * 0.7f + m.phase) * 6.0f * dt;
            if (m.pos.y < -roomH / 2.0f) { m.pos.y = roomH / 2.0f; m.pos.x = (Rand01() - 0.5f) * roomW; }
        }
        if (damagePulse > 0) damagePulse = std::max(0.0f, damagePulse - dt * 2.2f);
    }

    Color DeathColor(const Enemy& e) {
        if (e.isElite) return { 255, 217, 102, 255 };
        if (e.isWarden) return { 255, 199, 89, 255 };
        if (e.type == BOSS) return { 242, 77, 77, 255 };
        if (e.type == BOMBER) return { 255, 153, 38, 255 };
        if (e.type == BRUTE) return { 153, 102, 242, 255 };
        if (e.type == RANGER) return { 242, 77, 89, 255 };
        return { 102, 230, 89, 255 };
    }

    // ── Nâng cấp ──
    std::string UpgradeTitle(UpgradeType u) {
        switch (u) {
            case UP_HP: return "Titan's Heart";
            case UP_DMG: return "Sharpened Edge";
            case UP_SPEED: return "Swift Wind";
            case UP_ATTACK_RATE: return "Flurry";
            case UP_DASH: return "Blink Step";
            case UP_LIFESTEAL: return "Vampiric Touch";
            case UP_ARMOR: return "Iron Aegis";
            case UP_CRIT: return "Eagle Eye";
            case UP_NOVA: return "Arcane Focus";
            case UP_IGNITE: return "Ember Edge";
            case UP_FROST: return "Frost Touch";
        }
        return "";
    }

    std::string UpgradeDesc(UpgradeType u) {
        switch (u) {
            case UP_HP: return "+25 Max Health\n& Instant Recovery";
            case UP_DMG: return "+8 Melee Damage\nFor all attacks";
            case UP_SPEED: return "+15% Move Speed\nOutrun dangers";
            case UP_ATTACK_RATE: return "+30% Attack Speed\nRapid strikes";
            case UP_DASH: return "-0.2s Dash Cooldown\nGreater mobility";
            case UP_LIFESTEAL: return "+8% Lifesteal\nHeal on hit";
            case UP_ARMOR: return "+2 Flat Armor\nReduce damage";
            case UP_CRIT: return "+8% Crit Chance\nCrits deal x2 dmg";
            case UP_NOVA: return "-0.8s Nova Cooldown\nSpam Nova";
            case UP_IGNITE: return "Hits burn enemies 3s\n+50% dmg/s per level";
            case UP_FROST: return "Hits slow enemies 2s\n-15% speed per level";
        }
        return "";
    }

    void ShowBanner(const std::string& txt, float dur = 2.5f) {
        bannerText = txt;
        bannerTimer = dur;
    }

    void Shake(float dur, float mag) {
        screenShakeTimer = dur;
        screenShakeMag = mag;
    }

    void BuildFloor() {
        enemies.clear();
        projectiles.clear();
        loots.clear();
        slashes.clear();
        novas.clear();
        ghosts.clear();
        pillars.clear();
        particles.clear();

        portalOpen = false;
        portalPos = { 0, -roomH / 2.0f + 70.0f };
        player.pos = { 0, roomH / 2.0f - 90.0f };

        // Generate Pillars
        pillars.push_back({ -350, -100 });
        pillars.push_back({ 350, -100 });
        pillars.push_back({ -200, 120 });
        pillars.push_back({ 200, 120 });
        if (floor % 5 != 0) pillars.push_back({ 0, 0 });

        std::string theme = "Ancient Crypt";
        if (((floor - 1) / 3) % 4 == 1) theme = "Overgrown Ruins";
        else if (((floor - 1) / 3) % 4 == 2) theme = "Molten Depths";
        else if (((floor - 1) / 3) % 4 == 3) theme = "Frozen Halls";

        ShowBanner("FLOOR " + std::to_string(floor) + " - " + theme);

        bool isBoss = (floor % 5 == 0);
        if (isBoss) {
            SpawnEnemy(BOSS, { 0, -120 });
            for (int i = 0; i < 4; ++i) SpawnEnemy(CHASER, GetRandomSpawnPos());
        } else {
            int chasers = std::min(10, 3 + floor);
            int spitters = std::min(8, std::max(0, (floor - 1) * 2));
            int brutes = std::min(5, std::max(0, floor - 2));

            for (int i = 0; i < chasers; ++i) SpawnEnemy(CHASER, GetRandomSpawnPos());
            for (int i = 0; i < spitters; ++i) SpawnEnemy(RANGER, GetRandomSpawnPos());
            for (int i = 0; i < brutes; ++i) SpawnEnemy(BRUTE, GetRandomSpawnPos());

            // Bomber Slime: quái tự nổ từ tầng 4
            int bombers = (floor >= 4) ? std::min(4, 1 + (floor - 4) / 2) : 0;
            for (int i = 0; i < bombers; ++i) SpawnEnemy(BOMBER, GetRandomSpawnPos());

            // Warden Brute: mini-boss ở tầng 3 và 8
            if (floor == 3 || floor == 8) {
                SpawnWarden(GetRandomSpawnPos());
            }
        }

        // Bàn thờ máu: từ tầng 2, không phải tầng boss
        hasShrine = (floor >= 2 && floor % 5 != 0 && Rand01() < 0.3f);
        shrineUsed = false;
        shrineHinted = false;
        shrineRefuse = 0.0f;
        if (hasShrine) {
            for (int tries = 0; tries < 40; ++tries) {
                shrinePos = GetRandomSpawnPos();
                bool nearPillar = false;
                for (const auto& pl : pillars) if (Vector2Distance(shrinePos, pl) < 80.0f) nearPillar = true;
                if (!nearPillar) break;
            }
        }
    }

    void SpawnWarden(Vector2 pos) {
        SpawnEnemy(BRUTE, pos);
        Enemy& w = enemies.back();
        w.isWarden = true;
        w.isElite = false;
        w.maxHp = 180.0f * (1.0f + (floor - 1) * 0.15f);
        w.hp = w.maxHp;
        w.speed = 85.0f;
        w.contactDmg = 20.0f * (1.0f + (floor - 1) * 0.10f);
        w.radius = 36.0f;
    }

    Vector2 GetRandomSpawnPos() {
        for (int tries = 0; tries < 50; ++tries) {
            float x = ((float)rand() / RAND_MAX - 0.5f) * (roomW - 180);
            float y = ((float)rand() / RAND_MAX - 0.5f) * (roomH - 180);
            Vector2 p = { x, y };
            if (Vector2Distance(p, player.pos) > 180.0f) return p;
        }
        return { 0, -150 };
    }

    void SpawnEnemy(EnemyType type, Vector2 pos) {
        Enemy e;
        e.type = type;
        e.pos = pos;
        e.vel = { 0, 0 };
        float multHp = 1.0f + (floor - 1) * 0.15f;
        float multDmg = 1.0f + (floor - 1) * 0.10f;

        if (type == CHASER) {
            e.maxHp = 35.0f * multHp;
            e.speed = 175.0f;
            e.contactDmg = 12.0f * multDmg;
            e.radius = 18.0f;
        } else if (type == RANGER) {
            e.maxHp = 28.0f * multHp;
            e.speed = 150.0f;
            e.contactDmg = 8.0f * multDmg;
            e.radius = 18.0f;
        } else if (type == BRUTE) {
            e.maxHp = 85.0f * multHp;
            e.speed = 95.0f;
            e.contactDmg = 16.0f * multDmg;
            e.radius = 26.0f;
        } else if (type == BOMBER) {
            e.maxHp = 22.0f * multHp;
            e.speed = 190.0f;
            e.contactDmg = 6.0f * multDmg;
            e.radius = 17.0f;
        } else if (type == BOSS) {
            e.maxHp = 260.0f * multHp;
            e.speed = 115.0f;
            e.contactDmg = 20.0f * multDmg;
            e.radius = 42.0f;
        }
        e.hp = e.maxHp;

        // Elite variant chance on floor 3+
        if (type != BOSS && floor >= 3 && ((float)rand() / RAND_MAX < 0.20f)) {
            e.isElite = true;
            e.maxHp *= 1.8f;
            e.hp = e.maxHp;
            e.contactDmg *= 1.3f;
            e.radius *= 1.2f;
        }

        enemies.push_back(e);
    }

    void SpawnPopup(Vector2 pos, const std::string& txt, Color col) {
        DamagePopup p;
        p.pos = pos;
        p.text = txt;
        p.color = col;
        popups.push_back(p);
    }

    bool HasRelic(RelicType t) {
        for (const auto& r : player.relics) {
            if (r.type == t) return true;
        }
        return false;
    }

    void AddRelic(RelicType t) {
        if (HasRelic(t)) return;
        Relic r;
        r.type = t;
        if (t == RELIC_LIGHTNING) { r.name = "Thunder Conduit"; r.symbol = "⚡"; r.color = SKYBLUE; }
        else if (t == RELIC_TOXIC) { r.name = "Toxic Fang"; r.symbol = "☣"; r.color = LIME; }
        else if (t == RELIC_FROST) { r.name = "Frost Core"; r.symbol = "❄"; r.color = RAYWHITE; }
        else if (t == RELIC_AEGIS) { r.name = "Divine Aegis"; r.symbol = "🛡"; r.color = GOLD; player.shieldActive = true; }
        else if (t == RELIC_CHALICE) { r.name = "Blood Chalice"; r.symbol = "🩸"; r.color = RED; }
        else if (t == RELIC_COMBUSTION) { r.name = "Combustion Sigil"; r.symbol = "💥"; r.color = ORANGE; }
        player.relics.push_back(r);
        PlaySound(snd.sndLevelUp);
        ShowBanner("RELIC ACQUIRED: " + r.name + "!");
    }

    void Update(float dt) {
        if (bannerTimer > 0) bannerTimer -= dt;
        if (screenShakeTimer > 0) screenShakeTimer -= dt;

        // Hit-stop: khựng khung hình rất ngắn khi chí mạng
        if (hitStop > 0) { hitStop -= dt; return; }

        UpdateEffects(dt);

        if (state == LEVEL_UP) {
            // Number keys 1, 2, 3 to choose
            if (IsKeyPressed(KEY_ONE) && levelChoices.size() >= 1) ChooseUpgrade(levelChoices[0]);
            if (IsKeyPressed(KEY_TWO) && levelChoices.size() >= 2) ChooseUpgrade(levelChoices[1]);
            if (IsKeyPressed(KEY_THREE) && levelChoices.size() >= 3) ChooseUpgrade(levelChoices[2]);
            return;
        }

        if (state == GAME_OVER) {
            if (IsKeyPressed(KEY_R) || IsKeyPressed(KEY_SPACE) || IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
                RestartRun();
            }
            return;
        }

        // Toggle radar with M
        if (IsKeyPressed(KEY_M)) showMiniMap = !showMiniMap;

        // Player Timers
        if (player.dashTimer > 0) player.dashTimer -= dt;
        if (player.specialTimer > 0) player.specialTimer -= dt;
        if (player.attackTimer > 0) player.attackTimer -= dt;
        if (player.invulnTimer > 0) player.invulnTimer -= dt;
        player.isInvuln = (player.invulnTimer > 0 || player.isDashing);

        // Aegis Shield Recharging
        if (HasRelic(RELIC_AEGIS) && !player.shieldActive) {
            player.shieldTimer += dt;
            if (player.shieldTimer >= 12.0f) {
                player.shieldActive = true;
                player.shieldTimer = 0.0f;
                PlaySound(snd.sndShield);
            }
        }

        // Combo Decay
        if (comboTimer > 0) {
            comboTimer -= dt;
            if (comboTimer <= 0) comboCount = 0;
        }

        // ── Input & Movement ──
        Vector2 move = { 0, 0 };
        if (IsKeyDown(KEY_W) || IsKeyDown(KEY_UP)) move.y -= 1;
        if (IsKeyDown(KEY_S) || IsKeyDown(KEY_DOWN)) move.y += 1;
        if (IsKeyDown(KEY_A) || IsKeyDown(KEY_LEFT)) move.x -= 1;
        if (IsKeyDown(KEY_D) || IsKeyDown(KEY_RIGHT)) move.x += 1;
        if (Vector2Length(move) > 0) move = Vector2Normalize(move);

        Vector2 mouseWorld = GetScreenToWorld2D(GetMousePosition(), camera);
        Vector2 aimDir = Vector2Normalize(Vector2Subtract(mouseWorld, player.pos));
        if (fabs(aimDir.x) > 0.1f) player.facingLeft = (aimDir.x < 0);

        if (player.isDashing) {
            player.pos = Vector2Add(player.pos, Vector2Scale(player.dashDir, player.speed * 2.8f * dt));
            if (player.dashTimer <= player.dashCooldown - player.dashDur) {
                player.isDashing = false;
            }
        } else {
            player.pos = Vector2Add(player.pos, Vector2Scale(move, player.speed * dt));
            if (Vector2Length(move) > 0.1f) player.walkTimer += dt * 10.0f;
        }

        // Bounds Clamp
        float boundW = roomW / 2.0f - 30;
        float boundH = roomH / 2.0f - 30;
        player.pos.x = Clamp(player.pos.x, -boundW, boundW);
        player.pos.y = Clamp(player.pos.y, -boundH, boundH);

        // Dash Action
        if ((IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) || IsKeyPressed(KEY_LEFT_SHIFT) || IsKeyPressed(KEY_K)) && player.dashTimer <= 0) {
            player.isDashing = true;
            player.dashTimer = player.dashCooldown;
            player.dashDir = (Vector2Length(move) > 0.1f) ? move : aimDir;
            PlaySound(snd.sndDash);
            ghosts.push_back({ player.pos, player.facingLeft, 0.22f, 0.22f });
        }

        // Melee Slash Attack
        if ((IsMouseButtonDown(MOUSE_BUTTON_LEFT) || IsKeyDown(KEY_SPACE) || IsKeyDown(KEY_J)) && player.attackTimer <= 0 && !player.isDashing) {
            player.attackTimer = 1.0f / player.attackRate;
            PlaySound(snd.sndSlash);

            SlashVisual sv;
            sv.pos = Vector2Add(player.pos, Vector2Scale(aimDir, 35.0f));
            sv.angle = atan2f(aimDir.y, aimDir.x) * RAD2DEG;
            slashes.push_back(sv);

            // Hit query in front
            Vector2 hitCenter = Vector2Add(player.pos, Vector2Scale(aimDir, 45.0f));
            float hitRadius = 75.0f;
            bool hitAny = false;

            for (auto& e : enemies) {
                if (e.hp <= 0) continue;
                if (Vector2Distance(hitCenter, e.pos) <= hitRadius + e.radius) {
                    hitAny = true;
                    bool isCrit = ((float)rand() / RAND_MAX < player.critChance);
                    float dmg = player.baseDmg * (isCrit ? 2.0f : 1.0f);
                    Vector2 kb = Vector2Normalize(Vector2Subtract(e.pos, player.pos));
                    DamageEnemy(e, dmg, kb, isCrit ? 240.0f : 160.0f, isCrit);
                }
            }
            if (hitAny) {
                PlaySound(snd.sndHit);
                Shake(0.12f, 3.5f);
            }
        }

        // Special Nova Pulse (Q / E / U)
        if ((IsKeyPressed(KEY_Q) || IsKeyPressed(KEY_E) || IsKeyPressed(KEY_U)) && player.specialTimer <= 0) {
            player.specialTimer = player.specialCooldown;
            PlaySound(snd.sndSpecial);
            Shake(0.25f, 6.0f);
            Burst(player.pos, SKYBLUE, 34, 380.0f, 0.6f);

            NovaVisual nv;
            nv.pos = player.pos;
            nv.radius = 0;
            nv.maxRadius = 190.0f;
            nv.timer = 0.35f;
            nv.maxTimer = 0.35f;
            nv.color = SKYBLUE;
            novas.push_back(nv);

            for (auto& e : enemies) {
                if (e.hp <= 0) continue;
                if (Vector2Distance(player.pos, e.pos) <= nv.maxRadius) {
                    bool isCrit = ((float)rand() / RAND_MAX < player.critChance);
                    float dmg = player.baseDmg * 1.8f * (isCrit ? 2.0f : 1.0f);
                    Vector2 kb = Vector2Normalize(Vector2Subtract(e.pos, player.pos));
                    DamageEnemy(e, dmg, kb, 280.0f, isCrit);
                }
            }
        }

        // ── Enemies AI & Update ──
        for (auto& e : enemies) {
            if (e.hp <= 0) continue;

            // Poison DoT
            if (e.poisonTimer > 0) {
                e.poisonTimer -= dt;
                e.hp -= e.poisonDmg * dt;
                if (e.hp <= 0) { OnEnemyKilled(e); continue; }
            }
            // Chill
            float speedMod = 1.0f;
            if (e.chillTimer > 0) {
                e.chillTimer -= dt;
                speedMod = 0.5f;
            }
            // Frost Touch: làm chậm
            if (e.slowTimer > 0) {
                e.slowTimer -= dt;
                speedMod *= e.slowFactor;
            }
            // Ember Edge: đốt
            if (e.burnTimer > 0) {
                e.burnTimer -= dt;
                e.hp -= e.burnDps * dt;
                if (Rand01() < 0.15f) Burst(e.pos, { 255, 140, 40, 255 }, 1, 70.0f, 0.4f);
                if (e.hp <= 0) { OnEnemyKilled(e); continue; }
            }

            Vector2 toPlayer = Vector2Subtract(player.pos, e.pos);
            float dist = Vector2Length(toPlayer);
            Vector2 dir = Vector2Normalize(toPlayer);
            if (fabs(dir.x) > 0.05f) e.facingLeft = (dir.x < 0);

            if (e.type == CHASER) {
                e.bounceTimer += dt * 6.0f;
                float hop = std::max(0.2f, sinf(e.bounceTimer));
                e.vel = Vector2Scale(dir, e.speed * hop * speedMod);
                e.pos = Vector2Add(e.pos, Vector2Scale(e.vel, dt));
            } else if (e.type == RANGER) {
                e.attackTimer += dt;
                Vector2 moveDir = { 0, 0 };
                if (dist < 220) moveDir = Vector2Negate(dir);
                else if (dist > 340) moveDir = dir;
                else moveDir = { -dir.y, dir.x };
                e.pos = Vector2Add(e.pos, Vector2Scale(moveDir, e.speed * speedMod * dt));

                if (e.attackTimer >= 2.2f) {
                    e.attackTimer = 0;
                    PlaySound(snd.sndShoot);
                    Projectile p;
                    p.pos = Vector2Add(e.pos, Vector2Scale(dir, 20.0f));
                    p.vel = Vector2Scale(dir, 280.0f);
                    p.damage = e.contactDmg * 0.9f;
                    p.fromPlayer = false;
                    p.life = 3.0f;
                    p.radius = 7.0f;
                    p.color = RED;
                    projectiles.push_back(p);
                }
            } else if (e.type == BRUTE) {
                e.attackTimer += dt;
                if (dist < 110.0f && e.attackTimer >= 3.5f) {
                    e.attackTimer = 0;
                    PlaySound(snd.sndSpecial);
                    Shake(0.2f, 5.0f);
                    NovaVisual bv;
                    bv.pos = e.pos;
                    bv.radius = 0;
                    bv.maxRadius = 140.0f;
                    bv.timer = 0.3f;
                    bv.maxTimer = 0.3f;
                    bv.color = PURPLE;
                    novas.push_back(bv);

                    if (Vector2Distance(e.pos, player.pos) <= bv.maxRadius) {
                        DamagePlayer(e.contactDmg * 1.4f);
                    }
                } else {
                    e.pos = Vector2Add(e.pos, Vector2Scale(dir, e.speed * speedMod * dt));
                }
            } else if (e.type == BOMBER) {
                if (!e.fusing) {
                    e.pos = Vector2Add(e.pos, Vector2Scale(dir, e.speed * speedMod * dt));
                    if (dist < 78.0f) {
                        e.fusing = true;
                        e.fuseTimer = 0.0f;
                        PlaySound(snd.sndShoot);
                    }
                } else {
                    e.fuseTimer += dt;
                    if (e.fuseTimer >= 0.75f) {
                        BomberExplode(e);
                        continue;
                    }
                }
            } else if (e.type == BOSS) {
                if (!e.enraged && e.hp <= e.maxHp * 0.5f) {
                    e.enraged = true;
                    e.speed *= 1.3f;
                    PlaySound(snd.sndSpecial);
                    Shake(0.4f, 8.0f);
                    ShowBanner("THE VOID SOVEREIGN ENRAGES!");
                }

                e.attackTimer += dt;
                float interval = e.enraged ? 2.0f : 3.0f;
                if (e.attackTimer >= interval) {
                    e.attackTimer = 0;
                    PlaySound(snd.sndShoot);
                    // 12 or 16 way radial bullet burst
                    int count = e.enraged ? 16 : 12;
                    float step = (2.0f * PI) / count;
                    for (int i = 0; i < count; ++i) {
                        float a = i * step;
                        Vector2 bDir = { cosf(a), sinf(a) };
                        Projectile p;
                        p.pos = Vector2Add(e.pos, Vector2Scale(bDir, 35.0f));
                        p.vel = Vector2Scale(bDir, 220.0f);
                        p.damage = 16.0f;
                        p.fromPlayer = false;
                        p.life = 3.5f;
                        p.radius = 8.0f;
                        p.color = GOLD;
                        projectiles.push_back(p);
                    }
                } else {
                    e.pos = Vector2Add(e.pos, Vector2Scale(dir, e.speed * speedMod * dt));
                }
            }

            // Contact damage with player
            if (Vector2Distance(e.pos, player.pos) < e.radius + 18.0f) {
                DamagePlayer(e.contactDmg);
            }
        }

        // ── Projectiles ──
        for (size_t i = 0; i < projectiles.size();) {
            auto& p = projectiles[i];
            p.pos = Vector2Add(p.pos, Vector2Scale(p.vel, dt));
            p.life -= dt;

            bool hit = false;
            if (!p.fromPlayer) {
                if (Vector2Distance(p.pos, player.pos) < p.radius + 18.0f) {
                    DamagePlayer(p.damage);
                    hit = true;
                }
            }
            if (hit || p.life <= 0 || fabs(p.pos.x) > roomW / 2.0f || fabs(p.pos.y) > roomH / 2.0f) {
                projectiles.erase(projectiles.begin() + i);
            } else {
                ++i;
            }
        }

        // ── Loot collection ──
        for (size_t i = 0; i < loots.size();) {
            auto& l = loots[i];
            float d = Vector2Distance(l.pos, player.pos);
            if (d < 160.0f) {
                Vector2 pull = Vector2Normalize(Vector2Subtract(player.pos, l.pos));
                l.pos = Vector2Add(l.pos, Vector2Scale(pull, 420.0f * dt));
            }
            if (d < 24.0f) {
                if (l.type == 0) { // XP
                    player.xp += l.value;
                    Burst(l.pos, SKYBLUE, 3, 100.0f, 0.3f);
                    PlaySound(snd.sndCoin);
                    while (player.xp >= player.xpNext) {
                        player.xp -= player.xpNext;
                        player.level++;
                        player.xpNext = (int)(player.xpNext * 1.45f);
                        TriggerLevelUp();
                    }
                } else if (l.type == 1) { // Gold
                    player.gold += l.value;
                    Burst(l.pos, GOLD, 4, 120.0f, 0.35f);
                    PlaySound(snd.sndCoin);
                } else if (l.type == 2) { // Potion
                    player.hp = std::min(player.maxHp, player.hp + l.value);
                    SpawnPopup(player.pos, "+" + std::to_string(l.value), GREEN);
                    Burst(l.pos, { 255, 100, 128, 255 }, 8, 150.0f, 0.45f);
                    PlaySound(snd.sndPotion);
                }
                loots.erase(loots.begin() + i);
            } else {
                ++i;
            }
        }

        // ── Visual Animations ──
        for (size_t i = 0; i < popups.size();) {
            popups[i].pos.y -= 45.0f * dt;
            popups[i].timer -= dt;
            if (popups[i].timer <= 0) popups.erase(popups.begin() + i);
            else ++i;
        }
        for (size_t i = 0; i < slashes.size();) {
            slashes[i].timer -= dt;
            if (slashes[i].timer <= 0) slashes.erase(slashes.begin() + i);
            else ++i;
        }
        for (size_t i = 0; i < novas.size();) {
            float t = 1.0f - (novas[i].timer / novas[i].maxTimer);
            novas[i].radius = sqrtf(t) * novas[i].maxRadius;
            novas[i].timer -= dt;
            if (novas[i].timer <= 0) novas.erase(novas.begin() + i);
            else ++i;
        }
        for (size_t i = 0; i < ghosts.size();) {
            ghosts[i].timer -= dt;
            if (ghosts[i].timer <= 0) ghosts.erase(ghosts.begin() + i);
            else ++i;
        }

        // ── Bàn thờ máu ──
        if (hasShrine && !shrineUsed) {
            shrinePulse += dt * 3.0f;
            if (shrineRefuse > 0) shrineRefuse -= dt;
            float sd = Vector2Distance(player.pos, shrinePos);
            if (!shrineHinted && sd < 160.0f) {
                shrineHinted = true;
                ShowBanner("Blood Shrine - touch it to trade HP for a free upgrade", 3.0f);
            }
            if (sd < 44.0f && shrineRefuse <= 0) UseShrine();
        }

        // ── Check Room Clearance ──
        bool anyAlive = false;
        for (const auto& e : enemies) {
            if (e.hp > 0) { anyAlive = true; break; }
        }
        if (!anyAlive && !portalOpen) {
            portalOpen = true;
            PlaySound(snd.sndPortal);
            ShowBanner("ROOM CLEARED! ENTER THE PORTAL!");
        }

        // Teleport to next floor
        if (portalOpen && Vector2Distance(player.pos, portalPos) < 45.0f) {
            floor++;
            PlaySound(snd.sndPortal);
            BuildFloor();
        }

        // Camera Follow with Screen Shake
        camera.target = player.pos;
        if (screenShakeTimer > 0) {
            camera.target.x += ((float)rand() / RAND_MAX * 2.0f - 1.0f) * screenShakeMag;
            camera.target.y += ((float)rand() / RAND_MAX * 2.0f - 1.0f) * screenShakeMag;
        }
    }

    void DamageEnemy(Enemy& e, float dmg, Vector2 kb, float kbForce, bool isCrit) {
        e.hp -= dmg;
        e.pos = Vector2Add(e.pos, Vector2Scale(kb, kbForce * 0.05f));
        SpawnPopup(e.pos, (isCrit ? "!" : "") + std::to_string((int)dmg), isCrit ? YELLOW : WHITE);
        Burst(e.pos, isCrit ? Color{ 255, 217, 51, 255 } : WHITE, isCrit ? 9 : 4, isCrit ? 230.0f : 160.0f, isCrit ? 0.4f : 0.28f);
        if (isCrit) hitStop = 0.035f;

        // Ember Edge / Frost Touch
        if (player.igniteLevel > 0) {
            e.burnTimer = 3.0f;
            e.burnDps = std::max(e.burnDps, player.baseDmg * 0.5f * player.igniteLevel);
        }
        if (player.frostLevel > 0) {
            e.slowTimer = 2.0f;
            e.slowFactor = std::max(0.4f, 1.0f - 0.15f * player.frostLevel);
        }

        // Relics on hit
        if (HasRelic(RELIC_FROST) && isCrit) {
            e.chillTimer = 2.5f;
            PlaySound(snd.sndFreeze);
        }
        if (HasRelic(RELIC_TOXIC)) {
            e.poisonTimer = 3.0f;
            e.poisonDmg = dmg * 0.25f;
        }
        if (HasRelic(RELIC_LIGHTNING)) {
            // Zap another nearby enemy
            for (auto& other : enemies) {
                if (&other != &e && other.hp > 0 && Vector2Distance(e.pos, other.pos) < 180.0f) {
                    other.hp -= dmg * 0.5f;
                    SpawnPopup(other.pos, std::to_string((int)(dmg * 0.5f)), SKYBLUE);
                    break;
                }
            }
        }

        if (e.hp <= 0) {
            OnEnemyKilled(e);
        }
    }

    void OnEnemyKilled(Enemy& e) {
        Burst(e.pos, DeathColor(e), e.type == BOSS ? 40 : 16, 260.0f, 0.6f);

        // Bomber tự nổ: không rơi loot, không tính combo
        if (e.type == BOMBER && e.exploded) {
            PlaySound(snd.sndDeath);
            return;
        }

        enemiesSlain++;
        comboCount++;
        if (comboCount > bestCombo) bestCombo = comboCount;
        comboTimer = 3.0f;
        PlaySound(snd.sndDeath);

        // Combo gold payout every 5 kills
        if (comboCount % 5 == 0) {
            player.gold += comboCount * 2;
            SpawnPopup(player.pos, "+GOLD COMBO!", GOLD);
        }

        // Drops
        if (e.isWarden) {
            loots.push_back({ 2, Vector2Add(e.pos, { 0, 18 }), 35, 20.0f });
            loots.push_back({ 1, Vector2Add(e.pos, { 18, 0 }), 8, 20.0f });
            ShowBanner("WARDEN BRUTE DEFEATED!");
            hitStop = 0.08f;
        }
        if (e.type == BOSS) hitStop = 0.12f;
        loots.push_back({ 0, e.pos, (e.type == BOSS ? 150 : (e.isWarden ? 90 : (e.isElite ? 35 : 15))), 20.0f });
        if ((float)rand() / RAND_MAX < 0.6f || e.isElite) {
            loots.push_back({ 1, Vector2Add(e.pos, { 10, 0 }), rand() % 4 + 1, 20.0f });
        }
        if ((float)rand() / RAND_MAX < 0.2f || (HasRelic(RELIC_CHALICE) && (float)rand() / RAND_MAX < 0.3f)) {
            loots.push_back({ 2, Vector2Add(e.pos, { -10, 0 }), 35, 20.0f });
        }

        // Relic: Combustion explosion
        if (HasRelic(RELIC_COMBUSTION)) {
            NovaVisual exp;
            exp.pos = e.pos;
            exp.radius = 0;
            exp.maxRadius = 120.0f;
            exp.timer = 0.25f;
            exp.maxTimer = 0.25f;
            exp.color = ORANGE;
            novas.push_back(exp);
            for (auto& other : enemies) {
                if (&other != &e && other.hp > 0 && Vector2Distance(e.pos, other.pos) <= exp.maxRadius) {
                    other.hp -= 25.0f;
                    SpawnPopup(other.pos, "25", ORANGE);
                }
            }
        }

        // Boss drops Relic!
        if (e.type == BOSS) {
            std::vector<RelicType> pool = { RELIC_LIGHTNING, RELIC_TOXIC, RELIC_FROST, RELIC_AEGIS, RELIC_CHALICE, RELIC_COMBUSTION };
            for (auto r : pool) {
                if (!HasRelic(r)) { AddRelic(r); break; }
            }
        }
    }

    void DamagePlayer(float dmg) {
        if (player.isInvuln || player.hp <= 0) return;

        // Divine Aegis barrier check
        if (HasRelic(RELIC_AEGIS) && player.shieldActive) {
            player.shieldActive = false;
            player.shieldTimer = 0.0f;
            PlaySound(snd.sndShield);
            SpawnPopup(player.pos, "BLOCKED!", GOLD);
            Shake(0.12f, 3.0f);
            return;
        }

        float effDmg = std::max(1.0f, dmg * 100.0f / (100.0f + player.armor * 10.0f));
        player.hp = std::max(0.0f, player.hp - effDmg);
        comboCount = 0;
        damagePulse = std::min(1.0f, 0.45f + effDmg / 60.0f);
        player.invulnTimer = 0.45f;
        PlaySound(snd.sndHurt);
        Shake(0.18f, 5.0f);
        SpawnPopup(player.pos, std::to_string((int)effDmg), RED);

        if (player.hp <= 0) {
            state = GAME_OVER;
            PlaySound(snd.sndDeath);
            if (floor > bestFloor) {
                bestFloor = floor;
                newRecord = true;
            }
        }
    }

    void BomberExplode(Enemy& e) {
        const float blastRadius = 120.0f;
        e.exploded = true;
        PlaySound(snd.sndSpecial);
        Shake(0.3f, 9.0f);

        NovaVisual nv;
        nv.pos = e.pos;
        nv.radius = 0;
        nv.maxRadius = blastRadius;
        nv.timer = 0.3f;
        nv.maxTimer = 0.3f;
        nv.color = ORANGE;
        novas.push_back(nv);
        Burst(e.pos, { 255, 179, 51, 255 }, 30, 330.0f, 0.65f);
        Burst(e.pos, { 255, 77, 26, 255 }, 14, 200.0f, 0.5f);

        if (Vector2Distance(e.pos, player.pos) <= blastRadius + 18.0f) DamagePlayer(20.0f);

        // Friendly fire: vụ nổ cũng làm đau quái khác (không kích hoạt relic)
        for (auto& other : enemies) {
            if (&other == &e || other.hp <= 0) continue;
            if (Vector2Distance(e.pos, other.pos) <= blastRadius + other.radius * 0.5f) {
                other.hp -= 40.0f;
                SpawnPopup(other.pos, "40", ORANGE);
                if (other.hp <= 0) OnEnemyKilled(other);
            }
        }

        e.hp = 0;
        OnEnemyKilled(e);
    }

    void UseShrine() {
        float cost = std::max(10.0f, roundf(player.maxHp * 0.15f));

        // Không bao giờ giết người chơi
        if (player.hp <= cost + 5.0f) {
            shrineRefuse = 2.0f;
            SpawnPopup({ shrinePos.x, shrinePos.y - 50.0f }, "NEED " + std::to_string((int)cost) + " HP", LIGHTGRAY);
            return;
        }

        shrineUsed = true;
        player.hp -= cost;
        UpgradeType up = (UpgradeType)(rand() % 11);
        ApplyUpgrade(up);

        ShowBanner("BLOOD SHRINE: -" + std::to_string((int)cost) + " HP  ->  " + UpgradeTitle(up), 3.0f);
        SpawnPopup(player.pos, "-" + std::to_string((int)cost), RED);
        PlaySound(snd.sndSpecial);
        Shake(0.2f, 5.0f);
        Burst({ shrinePos.x, shrinePos.y - 34.0f }, { 255, 51, 64, 255 }, 28, 300.0f, 0.8f);
        damagePulse = 0.6f;
    }

    void TriggerLevelUp() {
        state = LEVEL_UP;
        PlaySound(snd.sndLevelUp);
        Burst(player.pos, { 255, 235, 115, 255 }, 26, 300.0f, 0.8f);
        Burst(player.pos, { 128, 242, 255, 255 }, 14, 180.0f, 0.7f);
        levelChoices = { UP_HP, UP_DMG, UP_ATTACK_RATE };
        std::vector<UpgradeType> all = { UP_HP, UP_DMG, UP_SPEED, UP_ATTACK_RATE, UP_DASH, UP_LIFESTEAL, UP_ARMOR, UP_CRIT, UP_NOVA, UP_IGNITE, UP_FROST };
        std::mt19937 rng((unsigned)rand());
        std::shuffle(all.begin(), all.end(), rng);
        levelChoices = { all[0], all[1], all[2] };
    }

    void ChooseUpgrade(UpgradeType up) {
        ApplyUpgrade(up);
        PlaySound(snd.sndPotion);
        state = PLAYING;
    }

    void ApplyUpgrade(UpgradeType up) {
        if (up == UP_HP) { player.maxHp += 25; player.hp += 25; }
        else if (up == UP_DMG) { player.baseDmg += 8; }
        else if (up == UP_SPEED) { player.speed += 30; }
        else if (up == UP_ATTACK_RATE) { player.attackRate += 0.8f; }
        else if (up == UP_DASH) { player.dashCooldown = std::max(0.4f, player.dashCooldown - 0.2f); }
        else if (up == UP_LIFESTEAL) { player.lifesteal = std::min(0.3f, player.lifesteal + 0.08f); }
        else if (up == UP_ARMOR) { player.armor += 2.0f; }
        else if (up == UP_CRIT) { player.critChance = std::min(0.6f, player.critChance + 0.08f); }
        else if (up == UP_NOVA) { player.specialCooldown = std::max(2.5f, player.specialCooldown - 0.8f); }
        else if (up == UP_IGNITE) { player.igniteLevel++; }
        else if (up == UP_FROST) { player.frostLevel++; }
    }

    // ── Drawing ──
    void Draw() {
        BeginDrawing();
        ClearBackground({ 20, 24, 32, 255 });

        BeginMode2D(camera);

        // 1. Room Floor & Checkerboard
        int halfW = (int)roomW / 2;
        int halfH = (int)roomH / 2;
        int tileSize = 48;
        for (int y = -halfH; y < halfH; y += tileSize) {
            for (int x = -halfW; x < halfW; x += tileSize) {
                bool alt = (((x / tileSize) + (y / tileSize)) & 1) == 0;
                Color tileCol = alt ? Color{ 38, 44, 58, 255 } : Color{ 32, 38, 50, 255 };
                DrawRectangle(x, y, tileSize, tileSize, tileCol);
            }
        }

        // Walls
        DrawRectangleLinesEx({ -roomW / 2.0f, -roomH / 2.0f, roomW, roomH }, 8.0f, { 60, 70, 90, 255 });

        // Bụi lơ lửng
        for (const auto& m : motes) {
            float a = 0.10f + 0.16f * (0.5f + 0.5f * sinf((float)GetTime() * 1.6f + m.phase));
            DrawCircleV(m.pos, m.size, Fade({ 190, 205, 235, 255 }, a));
        }

        // Pillars
        for (const auto& p : pillars) {
            DrawCircle((int)p.x, (int)p.y + 4, 28, { 0, 0, 0, 80 }); // Shadow
            DrawCircle((int)p.x, (int)p.y, 26, { 75, 85, 105, 255 });
            DrawCircleLines((int)p.x, (int)p.y, 26, { 110, 125, 150, 255 });
        }

        // Blood Shrine
        if (hasShrine) {
            float sx = shrinePos.x, sy = shrinePos.y;
            DrawEllipse((int)sx, (int)sy + 26, 30, 10, { 0, 0, 0, 100 });
            Color stone = shrineUsed ? Color{ 90, 88, 100, 255 } : Color{ 110, 104, 130, 255 };
            DrawRectangle((int)sx - 22, (int)sy + 14, 44, 14, stone);
            DrawRectangle((int)sx - 14, (int)sy - 20, 28, 36, stone);
            DrawRectangle((int)sx - 20, (int)sy - 28, 40, 10, stone);
            DrawRectangleLines((int)sx - 14, (int)sy - 20, 28, 36, { 34, 30, 44, 255 });
            DrawRectangleLines((int)sx - 20, (int)sy - 28, 40, 10, { 34, 30, 44, 255 });
            if (!shrineUsed) {
                float k = 0.75f + 0.25f * sinf(shrinePulse);
                DrawCircle((int)sx, (int)sy - 42, 18 + 3 * sinf(shrinePulse), Fade({ 255, 40, 70, 255 }, 0.18f));
                DrawCircle((int)sx, (int)sy - 42, 9, { 255, (unsigned char)(90 * k), (unsigned char)(100 * k), 255 });
                DrawCircleLines((int)sx, (int)sy - 42, 9, { 255, 170, 180, 255 });
                DrawText("BLOOD SHRINE", (int)sx - 52, (int)sy + 34, 14, { 255, 120, 130, 255 });
            } else {
                DrawCircle((int)sx, (int)sy - 42, 8, { 64, 50, 56, 255 });
            }
        }

        // Exit Portal
        if (portalOpen) {
            float pulse = sinf(GetTime() * 6.0f) * 6.0f;
            DrawCircle((int)portalPos.x, (int)portalPos.y, 34 + pulse, { 50, 200, 255, 60 });
            DrawCircle((int)portalPos.x, (int)portalPos.y, 26, { 100, 240, 255, 255 });
            DrawCircle((int)portalPos.x, (int)portalPos.y, 16, WHITE);
            DrawText("PORTAL", (int)portalPos.x - 26, (int)portalPos.y + 36, 14, SKYBLUE);
        }

        // Loots
        for (const auto& l : loots) {
            DrawCircle((int)l.pos.x, (int)l.pos.y, 8, l.type == 0 ? SKYBLUE : (l.type == 1 ? GOLD : RED));
            DrawCircleLines((int)l.pos.x, (int)l.pos.y, 8, WHITE);
        }

        // Ghost Trails
        for (const auto& g : ghosts) {
            float a = (g.timer / g.maxTimer) * 0.4f;
            DrawCircle((int)g.pos.x, (int)g.pos.y, 20, Fade(SKYBLUE, a));
        }

        // Slashes
        for (const auto& s : slashes) {
            float rad = s.angle * DEG2RAD;
            Vector2 end = Vector2Add(s.pos, { cosf(rad) * 45.0f, sinf(rad) * 45.0f });
            DrawLineEx(s.pos, end, 6.0f, WHITE);
            DrawCircleV(end, 8.0f, Fade(SKYBLUE, 0.8f));
        }

        // Novas
        for (const auto& n : novas) {
            float a = n.timer / n.maxTimer;
            DrawCircleLines((int)n.pos.x, (int)n.pos.y, n.radius, Fade(n.color, a));
            DrawCircleLines((int)n.pos.x, (int)n.pos.y, n.radius * 0.9f, Fade(WHITE, a * 0.7f));
        }

        // Enemies
        for (const auto& e : enemies) {
            if (e.hp <= 0) continue;
            // Shadow
            DrawEllipse((int)e.pos.x, (int)e.pos.y + e.radius * 0.8f, e.radius, e.radius * 0.4f, { 0, 0, 0, 90 });

            Color col = GREEN;
            if (e.type == RANGER) col = RED;
            else if (e.type == BRUTE) col = PURPLE;
            else if (e.type == BOSS) col = DARKPURPLE;
            else if (e.type == BOMBER) col = { 255, 140, 38, 255 };

            if (e.isWarden) col = { 255, 190, 90, 255 };
            if (e.isElite && e.type != BOMBER) col = GOLD; // Bomber elite giữ màu cam, chỉ viền vàng
            if (e.chillTimer > 0) col = SKYBLUE;
            if (e.slowTimer > 0) col = LerpColor(col, { 120, 200, 255, 255 }, 0.55f);
            if (e.burnTimer > 0) col = LerpColor(col, { 255, 120, 30, 255 }, 0.45f);

            float drawR = e.radius;
            if (e.type == BOMBER && e.fusing) {
                float t = e.fuseTimer / 0.75f;
                drawR = e.radius * (1.0f + 0.35f * t);
                bool blink = sinf(t * t * 40.0f) > 0.0f;
                DrawCircle((int)e.pos.x, (int)e.pos.y, 120.0f, Fade({ 255, 60, 30, 255 }, blink ? 0.22f : 0.10f));
                DrawCircleLines((int)e.pos.x, (int)e.pos.y, 120.0f, Fade({ 255, 90, 40, 255 }, blink ? 1.0f : 0.55f));
                if (blink) col = { 255, 60, 50, 255 };
            }

            DrawCircle((int)e.pos.x, (int)e.pos.y, drawR, col);
            DrawCircleLines((int)e.pos.x, (int)e.pos.y, drawR, (e.isWarden || (e.isElite && e.type == BOMBER)) ? Color{ 255, 230, 150, 255 } : WHITE);
            if (e.isElite && e.type == BOMBER) DrawCircleLines((int)e.pos.x, (int)e.pos.y, drawR + 3.0f, GOLD);

            // Ngòi nổ của Bomber
            if (e.type == BOMBER) {
                Vector2 top = { e.pos.x, e.pos.y - drawR };
                Vector2 tip = { e.pos.x + 5.0f, e.pos.y - drawR - 11.0f };
                DrawLineEx(top, tip, 3.0f, { 110, 70, 40, 255 });
                float tw = 0.6f + 0.4f * sinf((float)GetTime() * 25.0f);
                DrawCircleV(tip, 4.0f * tw + 1.5f, { 255, 235, 90, 255 });
                DrawCircleV(tip, 2.0f, WHITE);
            }

            // Eyes
            float eyeDir = e.facingLeft ? -1.0f : 1.0f;
            DrawCircle((int)(e.pos.x + eyeDir * (e.radius * 0.35f)), (int)(e.pos.y - 3), 4, WHITE);
            DrawCircle((int)(e.pos.x + eyeDir * (e.radius * 0.35f) + eyeDir * 1), (int)(e.pos.y - 3), 2, BLACK);

            // Boss Crown
            if (e.type == BOSS) {
                DrawText("👑", (int)e.pos.x - 14, (int)e.pos.y - e.radius - 22, 22, GOLD);
            }

            // Health bar
            float barW = e.radius * 2.2f;
            float pct = std::max(0.0f, e.hp / e.maxHp);
            DrawRectangle((int)(e.pos.x - barW / 2), (int)(e.pos.y - e.radius - 12), (int)barW, 5, BLACK);
            DrawRectangle((int)(e.pos.x - barW / 2), (int)(e.pos.y - e.radius - 12), (int)(barW * pct), 5, RED);
        }

        // Projectiles
        for (const auto& p : projectiles) {
            DrawCircleV(p.pos, p.radius, p.color);
            DrawCircleLines((int)p.pos.x, (int)p.pos.y, p.radius, WHITE);
        }

        // Player
        DrawEllipse((int)player.pos.x, (int)player.pos.y + 16, 20, 8, { 0, 0, 0, 100 }); // Shadow
        Color pCol = player.isInvuln ? Fade(SKYBLUE, 0.7f) : RAYWHITE;
        DrawCircle((int)player.pos.x, (int)player.pos.y, 18, pCol);
        DrawCircleLines((int)player.pos.x, (int)player.pos.y, 18, DARKBLUE);
        // Knight visor
        float pEyeDir = player.facingLeft ? -1.0f : 1.0f;
        DrawRectangle((int)(player.pos.x + (pEyeDir > 0 ? 0 : -10)), (int)player.pos.y - 4, 10, 4, DARKBLUE);

        // Aegis Barrier Glow
        if (player.shieldActive) {
            DrawCircleLines((int)player.pos.x, (int)player.pos.y, 28, Fade(GOLD, 0.8f));
        }

        // Hạt
        for (const auto& pt : particles) {
            float k = pt.life / pt.maxLife;
            DrawCircleV(pt.pos, pt.size * (0.3f + 0.7f * k), Fade(pt.color, k * k));
        }

        // Damage Popups
        for (const auto& p : popups) {
            DrawText(p.text.c_str(), (int)p.pos.x - 10, (int)p.pos.y, 18, p.color);
        }

        EndMode2D();

        // Vignette + viền đỏ khi bị đau
        {
            Color edge = LerpColor({ 0, 0, 0, 120 }, { 170, 0, 20, 200 }, damagePulse);
            Color clear = { edge.r, edge.g, edge.b, 0 };
            int bh = 150, bw = 240;
            DrawRectangleGradientV(0, 0, 1280, bh, edge, clear);
            DrawRectangleGradientV(0, 720 - bh, 1280, bh, clear, edge);
            DrawRectangleGradientH(0, 0, bw, 720, edge, clear);
            DrawRectangleGradientH(1280 - bw, 0, bw, 720, clear, edge);
        }

        // ── 2D Screen Space UI ──
        // Top-Left: HP, XP, Gold
        DrawRectangle(20, 20, 320, 28, { 40, 45, 55, 200 });
        float hpPct = std::max(0.0f, player.hp / player.maxHp);
        DrawRectangle(22, 22, (int)(316 * hpPct), 24, { 230, 50, 60, 255 });
        std::string hpTxt = "HP: " + std::to_string((int)player.hp) + " / " + std::to_string((int)player.maxHp);
        DrawText(hpTxt.c_str(), 110, 25, 18, WHITE);

        DrawRectangle(20, 56, 320, 18, { 40, 45, 55, 200 });
        float xpPct = (float)player.xp / player.xpNext;
        DrawRectangle(22, 58, (int)(316 * xpPct), 14, SKYBLUE);
        std::string xpTxt = "LVL " + std::to_string(player.level) + " - XP: " + std::to_string(player.xp) + "/" + std::to_string(player.xpNext);
        DrawText(xpTxt.c_str(), 110, 58, 14, WHITE);

        std::string goldTxt = "Gold: " + std::to_string(player.gold);
        DrawText(goldTxt.c_str(), 24, 84, 20, GOLD);

        // Relics Row
        std::string relicsStr = "Relics: ";
        if (player.relics.empty()) relicsStr += "None";
        else {
            for (const auto& r : player.relics) relicsStr += r.symbol + " " + r.name + "  ";
        }
        DrawText(relicsStr.c_str(), 24, 110, 16, SKYBLUE);

        // Top-Center: Floor & Combo
        std::string floorStr = "FLOOR " + std::to_string(floor);
        DrawText(floorStr.c_str(), 1280 / 2 - MeasureText(floorStr.c_str(), 32) / 2, 20, 32, RAYWHITE);

        if (comboCount > 1) {
            std::string comboStr = "COMBO x" + std::to_string(comboCount) + "!";
            Color cCol = comboCount >= 20 ? RED : (comboCount >= 10 ? ORANGE : YELLOW);
            DrawText(comboStr.c_str(), 1280 - 240, 160, 26, cCol);
        }

        // Mini-Map Radar (Top-Right)
        if (showMiniMap) {
            int mapX = 1280 - 180;
            int mapY = 20;
            int mapW = 160;
            int mapH = 110;
            DrawRectangle(mapX, mapY, mapW, mapH, { 15, 20, 30, 220 });
            DrawRectangleLines(mapX, mapY, mapW, mapH, { 70, 90, 130, 255 });
            DrawText("RADAR [M]", mapX + 48, mapY + 4, 11, SKYBLUE);

            float sX = (mapW - 16) / roomW;
            float sY = (mapH - 16) / roomH;
            float midX = mapX + mapW / 2.0f;
            float midY = mapY + mapH / 2.0f;

            // Player dot
            DrawCircle((int)(midX + player.pos.x * sX), (int)(midY + player.pos.y * sY), 3.5f, GREEN);
            // Portal dot
            if (portalOpen) DrawCircle((int)(midX + portalPos.x * sX), (int)(midY + portalPos.y * sY), 4.5f, SKYBLUE);
            // Enemy dots
            for (const auto& e : enemies) {
                if (e.hp <= 0) continue;
                DrawCircle((int)(midX + e.pos.x * sX), (int)(midY + e.pos.y * sY), e.type == BOSS ? 5.0f : 2.5f, e.type == BOSS ? GOLD : RED);
            }
        }

        // Skill Icons (Bottom Center)
        DrawRectangle(1280 / 2 - 60, 720 - 70, 50, 50, { 30, 35, 48, 220 });
        DrawText("DASH", 1280 / 2 - 54, 720 - 64, 12, YELLOW);
        DrawText("RMB", 1280 / 2 - 50, 720 - 36, 12, GRAY);
        if (player.dashTimer > 0) {
            float pct = player.dashTimer / player.dashCooldown;
            DrawRectangle(1280 / 2 - 60, (int)(720 - 70 + (1.0f - pct) * 50), 50, (int)(pct * 50), Fade(BLACK, 0.7f));
        }

        DrawRectangle(1280 / 2 + 10, 720 - 70, 50, 50, { 30, 35, 48, 220 });
        DrawText("NOVA", 1280 / 2 + 16, 720 - 64, 12, SKYBLUE);
        DrawText("Q / E", 1280 / 2 + 18, 720 - 36, 12, GRAY);
        if (player.specialTimer > 0) {
            float pct = player.specialTimer / player.specialCooldown;
            DrawRectangle(1280 / 2 + 10, (int)(720 - 70 + (1.0f - pct) * 50), 50, (int)(pct * 50), Fade(BLACK, 0.7f));
        }

        // Banner Toast
        if (bannerTimer > 0) {
            int bw = MeasureText(bannerText.c_str(), 26) + 60;
            DrawRectangle(1280 / 2 - bw / 2, 140, bw, 46, { 10, 15, 25, 230 });
            DrawRectangleLines(1280 / 2 - bw / 2, 140, bw, 46, GOLD);
            DrawText(bannerText.c_str(), 1280 / 2 - bw / 2 + 30, 150, 26, GOLD);
        }

        // ── Level Up Modal ──
        if (state == LEVEL_UP) {
            DrawRectangle(0, 0, 1280, 720, Fade(BLACK, 0.8f));
            DrawText("LEVEL UP! CHOOSE AN UPGRADE", 1280 / 2 - 250, 150, 34, GOLD);

            float cardW = 240;
            float startX = 1280 / 2 - (cardW * 3 + 40) / 2;

            for (size_t i = 0; i < levelChoices.size(); ++i) {
                float cx = startX + i * (cardW + 20);
                float cy = 240;
                DrawRectangle((int)cx, (int)cy, (int)cardW, 280, { 25, 32, 45, 245 });
                DrawRectangleLines((int)cx, (int)cy, (int)cardW, 280, SKYBLUE);

                std::string title = UpgradeTitle(levelChoices[i]);
                std::string desc = UpgradeDesc(levelChoices[i]);

                DrawText(title.c_str(), (int)cx + 20, (int)cy + 30, 22, GOLD);
                DrawText(desc.c_str(), (int)cx + 20, (int)cy + 85, 17, RAYWHITE);

                std::string btn = "PRESS [" + std::to_string(i + 1) + "]";
                DrawRectangle((int)cx + 30, (int)cy + 210, 180, 42, DARKBLUE);
                DrawText(btn.c_str(), (int)cx + 55, (int)cy + 222, 18, WHITE);
            }
        }

        // ── Game Over Modal ──
        if (state == GAME_OVER) {
            DrawRectangle(0, 0, 1280, 720, Fade(BLACK, 0.88f));
            DrawText("YOU HAVE FALLEN", 1280 / 2 - 180, 180, 44, RED);

            std::string st1 = "Floor Reached: " + std::to_string(floor);
            std::string st2 = "Final Level: " + std::to_string(player.level);
            std::string st3 = "Enemies Slain: " + std::to_string(enemiesSlain);
            std::string st4 = "Gold Accumulated: " + std::to_string(player.gold);
            std::string st5 = "Best Record: Floor " + std::to_string(bestFloor) + (newRecord ? "  (NEW RECORD!)" : "");

            DrawText(st1.c_str(), 1280 / 2 - 140, 260, 22, RAYWHITE);
            DrawText(st2.c_str(), 1280 / 2 - 140, 295, 22, RAYWHITE);
            DrawText(st3.c_str(), 1280 / 2 - 140, 330, 22, RAYWHITE);
            DrawText(st4.c_str(), 1280 / 2 - 140, 365, 22, GOLD);
            DrawText(st5.c_str(), 1280 / 2 - 140, 400, 22, newRecord ? GREEN : SKYBLUE);
            if (bestCombo >= 2) {
                std::string st6 = "Best Combo: x" + std::to_string(bestCombo);
                DrawText(st6.c_str(), 1280 / 2 - 140, 428, 22, ORANGE);
            }

            DrawRectangle(1280 / 2 - 130, 460, 260, 52, MAROON);
            DrawText("PLAY AGAIN (R)", 1280 / 2 - 75, 476, 22, WHITE);
        }

        EndDrawing();
    }
};

int main() {
    InitWindow(1280, 720, "Geometric Dungeon - Standalone Roguelike RPG");
    SetTargetFPS(60);

    Game game;
    game.Init();

    while (!WindowShouldClose()) {
        float dt = GetFrameTime();
        if (dt > 0.05f) dt = 0.05f;
        game.Update(dt);
        game.Draw();
    }

    game.snd.Close();
    CloseWindow();
    return 0;
}
