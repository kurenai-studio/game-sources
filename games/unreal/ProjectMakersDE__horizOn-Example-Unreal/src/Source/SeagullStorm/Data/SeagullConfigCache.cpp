#include "Data/SeagullConfigCache.h"
#include "Serialization/JsonSerializer.h"
#include "Dom/JsonObject.h"

void USeagullConfigCache::ParseFromConfigs(const TMap<FString, FString>& Configs)
{
	// Gameplay
	RunDurationSeconds = ParseInt(Configs, TEXT("run_duration_seconds"), 180);
	bBossWaveEnabled = ParseBool(Configs, TEXT("boss_wave_enabled"), true);
	CoinDivisor = ParseInt(Configs, TEXT("coin_divisor"), 10);
	XPPerKillBase = ParseInt(Configs, TEXT("xp_per_kill_base"), 10);
	XPLevelCurve = ParseFloat(Configs, TEXT("xp_level_curve"), 1.4f);

	// Validated Actions
	// Same keys as the Unity and Godot examples.
	bValidatedActionsEnabled = ParseBool(Configs, TEXT("validated_runs_enabled"), true);
	ValidatedCoinsKey = ParseBool(Configs, TEXT("validated_runs_send_coins"), false) ? FString(TEXT("coins")) : FString();
	const FString* Board = Configs.Find(TEXT("validated_runs_board"));
	ValidatedRunsBoard = (Board && !Board->TrimStartAndEnd().IsEmpty()) ? Board->TrimStartAndEnd() : FString(TEXT("default"));

	// Wave System
	WaveIntervalSeconds = ParseFloat(Configs, TEXT("wave_interval_seconds"), 15.f);
	WaveEnemyCountBase = ParseInt(Configs, TEXT("wave_enemy_count_base"), 5);
	WaveEnemyCountGrowth = ParseFloat(Configs, TEXT("wave_enemy_count_growth"), 1.3f);
	WaveBossHP = ParseInt(Configs, TEXT("wave_boss_hp"), 500);

	// Enemy Stats
	CrabStats.Speed = ParseFloat(Configs, TEXT("enemy_crab_speed"), 40.f);
	CrabStats.HP = ParseInt(Configs, TEXT("enemy_crab_hp"), 30);
	CrabStats.Damage = ParseInt(Configs, TEXT("enemy_crab_damage"), 10);
	CrabStats.XPDrop = ParseInt(Configs, TEXT("enemy_crab_xp"), 10);

	JellyfishStats.Speed = ParseFloat(Configs, TEXT("enemy_jellyfish_speed"), 60.f);
	JellyfishStats.HP = ParseInt(Configs, TEXT("enemy_jellyfish_hp"), 50);
	JellyfishStats.Damage = ParseInt(Configs, TEXT("enemy_jellyfish_damage"), 15);
	JellyfishStats.XPDrop = ParseInt(Configs, TEXT("enemy_jellyfish_xp"), 20);

	PirateStats.Speed = ParseFloat(Configs, TEXT("enemy_pirate_speed"), 100.f);
	PirateStats.HP = ParseInt(Configs, TEXT("enemy_pirate_hp"), 40);
	PirateStats.Damage = ParseInt(Configs, TEXT("enemy_pirate_damage"), 20);
	PirateStats.XPDrop = ParseInt(Configs, TEXT("enemy_pirate_xp"), 25);

	// Weapon Stats
	FeatherStats.Damage = ParseFloat(Configs, TEXT("weapon_feather_damage"), 20.f);
	FeatherStats.Cooldown = ParseFloat(Configs, TEXT("weapon_feather_cooldown"), 0.8f);
	FeatherStats.Projectiles = ParseInt(Configs, TEXT("weapon_feather_projectiles"), 1);

	ScreechStats.Damage = ParseFloat(Configs, TEXT("weapon_screech_damage"), 15.f);
	ScreechStats.Cooldown = ParseFloat(Configs, TEXT("weapon_screech_cooldown"), 2.0f);
	ScreechStats.Range = ParseFloat(Configs, TEXT("weapon_screech_radius"), 80.f);

	DiveStats.Damage = ParseFloat(Configs, TEXT("weapon_dive_damage"), 50.f);
	DiveStats.Cooldown = ParseFloat(Configs, TEXT("weapon_dive_cooldown"), 3.0f);
	DiveStats.Range = ParseFloat(Configs, TEXT("weapon_dive_range"), 120.f);

	GustStats.Damage = ParseFloat(Configs, TEXT("weapon_gust_damage"), 10.f);
	GustStats.Cooldown = ParseFloat(Configs, TEXT("weapon_gust_cooldown"), 2.5f);
	GustStats.Knockback = ParseFloat(Configs, TEXT("weapon_gust_knockback"), 60.f);

	// Upgrades
	const FString* Val;
	Val = Configs.Find(TEXT("upgrade_speed_costs"));
	UpgradeSpeedCosts = Val ? ParseIntArray(*Val) : TArray<int32>({100, 300, 600, 1000});
	Val = Configs.Find(TEXT("upgrade_speed_values"));
	UpgradeSpeedValues = Val ? ParseFloatArray(*Val) : TArray<float>({1.0f, 1.1f, 1.2f, 1.35f, 1.5f});
	UpgradeSpeedMax = ParseInt(Configs, TEXT("upgrade_speed_max"), 4);

	Val = Configs.Find(TEXT("upgrade_damage_costs"));
	UpgradeDamageCosts = Val ? ParseIntArray(*Val) : TArray<int32>({100, 300, 600, 1000});
	Val = Configs.Find(TEXT("upgrade_damage_values"));
	UpgradeDamageValues = Val ? ParseFloatArray(*Val) : TArray<float>({1.0f, 1.15f, 1.3f, 1.5f, 1.8f});
	UpgradeDamageMax = ParseInt(Configs, TEXT("upgrade_damage_max"), 4);

	Val = Configs.Find(TEXT("upgrade_hp_costs"));
	UpgradeHPCosts = Val ? ParseIntArray(*Val) : TArray<int32>({150, 400, 800});
	Val = Configs.Find(TEXT("upgrade_hp_values"));
	UpgradeHPValues = Val ? ParseIntArray(*Val) : TArray<int32>({100, 130, 170, 220});
	UpgradeHPMax = ParseInt(Configs, TEXT("upgrade_hp_max"), 3);

	Val = Configs.Find(TEXT("upgrade_magnet_costs"));
	UpgradeMagnetCosts = Val ? ParseIntArray(*Val) : TArray<int32>({200, 500});
	Val = Configs.Find(TEXT("upgrade_magnet_values"));
	UpgradeMagnetValues = Val ? ParseFloatArray(*Val) : TArray<float>({50.f, 80.f, 120.f});
	UpgradeMagnetMax = ParseInt(Configs, TEXT("upgrade_magnet_max"), 2);

	// Levelup Pool
	LevelUpChoices = ParseInt(Configs, TEXT("levelup_choices"), 3);
	Val = Configs.Find(TEXT("levelup_pool"));
	if (Val)
	{
		ParseLevelUpPool(*Val);
	}
	else
	{
		// Defaults
		LevelUpPool.Empty();
		auto AddChoice = [this](const FString& Id, const FString& Type, int32 Weight, const FString& Name, const FString& Desc)
		{
			FSeagullLevelUpChoice C;
			C.Id = Id; C.Type = Type; C.Weight = Weight; C.DisplayName = Name; C.Description = Desc;
			LevelUpPool.Add(C);
		};
		AddChoice(TEXT("feather_dmg"), TEXT("weapon_upgrade"), 3, TEXT("Feather+"), TEXT("DMG +15%"));
		AddChoice(TEXT("feather_speed"), TEXT("weapon_upgrade"), 2, TEXT("Feather Speed"), TEXT("Fire Rate +20%"));
		AddChoice(TEXT("screech_new"), TEXT("weapon_new"), 1, TEXT("Screech"), TEXT("NEW! AoE Ring"));
		AddChoice(TEXT("dive_new"), TEXT("weapon_new"), 1, TEXT("Dive Bomb"), TEXT("NEW! Dash Attack"));
		AddChoice(TEXT("gust_new"), TEXT("weapon_new"), 1, TEXT("Wind Gust"), TEXT("NEW! Knockback"));
		AddChoice(TEXT("move_speed"), TEXT("stat_boost"), 2, TEXT("Speed+"), TEXT("Move +10%"));
		AddChoice(TEXT("max_hp"), TEXT("stat_boost"), 2, TEXT("HP+"), TEXT("Max HP +20"));
		AddChoice(TEXT("xp_magnet"), TEXT("stat_boost"), 2, TEXT("Magnet+"), TEXT("Pickup Range +30%"));
	}
}

int32 USeagullConfigCache::GetUpgradeCost(const FString& UpgradeKey, int32 CurrentLevel) const
{
	const TArray<int32>* Costs = nullptr;
	if (UpgradeKey == TEXT("speed")) Costs = &UpgradeSpeedCosts;
	else if (UpgradeKey == TEXT("damage")) Costs = &UpgradeDamageCosts;
	else if (UpgradeKey == TEXT("hp")) Costs = &UpgradeHPCosts;
	else if (UpgradeKey == TEXT("magnet")) Costs = &UpgradeMagnetCosts;

	if (Costs && Costs->IsValidIndex(CurrentLevel))
	{
		return (*Costs)[CurrentLevel];
	}
	return 9999;
}

float USeagullConfigCache::GetUpgradeValue(const FString& UpgradeKey, int32 Level) const
{
	if (UpgradeKey == TEXT("speed") && UpgradeSpeedValues.IsValidIndex(Level))
		return UpgradeSpeedValues[Level];
	if (UpgradeKey == TEXT("damage") && UpgradeDamageValues.IsValidIndex(Level))
		return UpgradeDamageValues[Level];
	if (UpgradeKey == TEXT("hp") && UpgradeHPValues.IsValidIndex(Level))
		return static_cast<float>(UpgradeHPValues[Level]);
	if (UpgradeKey == TEXT("magnet") && UpgradeMagnetValues.IsValidIndex(Level))
		return UpgradeMagnetValues[Level];
	return 1.0f;
}

int32 USeagullConfigCache::GetUpgradeMax(const FString& UpgradeKey) const
{
	if (UpgradeKey == TEXT("speed")) return UpgradeSpeedMax;
	if (UpgradeKey == TEXT("damage")) return UpgradeDamageMax;
	if (UpgradeKey == TEXT("hp")) return UpgradeHPMax;
	if (UpgradeKey == TEXT("magnet")) return UpgradeMagnetMax;
	return 0;
}

int32 USeagullConfigCache::ParseInt(const TMap<FString, FString>& Configs, const FString& Key, int32 Default) const
{
	const FString* Val = Configs.Find(Key);
	return Val ? FCString::Atoi(**Val) : Default;
}

float USeagullConfigCache::ParseFloat(const TMap<FString, FString>& Configs, const FString& Key, float Default) const
{
	const FString* Val = Configs.Find(Key);
	return Val ? FCString::Atof(**Val) : Default;
}

bool USeagullConfigCache::ParseBool(const TMap<FString, FString>& Configs, const FString& Key, bool Default) const
{
	const FString* Val = Configs.Find(Key);
	if (!Val) return Default;
	return Val->ToBool();
}

TArray<int32> USeagullConfigCache::ParseIntArray(const FString& Value) const
{
	TArray<int32> Result;
	FString Cleaned = Value;
	Cleaned.ReplaceInline(TEXT("["), TEXT(""));
	Cleaned.ReplaceInline(TEXT("]"), TEXT(""));
	TArray<FString> Parts;
	Cleaned.ParseIntoArray(Parts, TEXT(","));
	for (const FString& P : Parts)
	{
		Result.Add(FCString::Atoi(*P.TrimStartAndEnd()));
	}
	return Result;
}

TArray<float> USeagullConfigCache::ParseFloatArray(const FString& Value) const
{
	TArray<float> Result;
	FString Cleaned = Value;
	Cleaned.ReplaceInline(TEXT("["), TEXT(""));
	Cleaned.ReplaceInline(TEXT("]"), TEXT(""));
	TArray<FString> Parts;
	Cleaned.ParseIntoArray(Parts, TEXT(","));
	for (const FString& P : Parts)
	{
		Result.Add(FCString::Atof(*P.TrimStartAndEnd()));
	}
	return Result;
}

void USeagullConfigCache::ParseLevelUpPool(const FString& Value)
{
	LevelUpPool.Empty();

	TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(Value);
	TArray<TSharedPtr<FJsonValue>> JsonArray;
	if (!FJsonSerializer::Deserialize(Reader, JsonArray))
	{
		return;
	}

	for (const auto& JsonVal : JsonArray)
	{
		const TSharedPtr<FJsonObject>& Obj = JsonVal->AsObject();
		if (!Obj.IsValid()) continue;

		FSeagullLevelUpChoice Choice;
		Choice.Id = Obj->GetStringField(TEXT("id"));
		Choice.Type = Obj->GetStringField(TEXT("type"));
		Choice.Weight = static_cast<int32>(Obj->GetNumberField(TEXT("weight")));

		// Generate display names from ID
		Choice.DisplayName = Choice.Id.Replace(TEXT("_"), TEXT(" "));
		Choice.DisplayName = Choice.DisplayName.Left(1).ToUpper() + Choice.DisplayName.Mid(1);

		if (Choice.Type == TEXT("weapon_new"))
			Choice.Description = TEXT("NEW! Weapon");
		else if (Choice.Type == TEXT("weapon_upgrade"))
			Choice.Description = TEXT("Upgrade");
		else
			Choice.Description = TEXT("Stat Boost");

		LevelUpPool.Add(Choice);
	}
}
