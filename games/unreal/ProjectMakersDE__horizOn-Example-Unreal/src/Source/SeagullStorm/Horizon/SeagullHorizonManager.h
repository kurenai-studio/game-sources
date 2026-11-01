#pragma once

#include "CoreMinimal.h"
#include "HorizonSubsystem.h"
#include "Models/HorizonLeaderboardEntry.h"
#include "Models/HorizonLeaderboardBoard.h"
#include "Models/HorizonValidatedActions.h"
#include "Models/HorizonPlayerProfile.h"
#include "Models/HorizonNewsEntry.h"
#include "SeagullHorizonManager.generated.h"

class UHorizonExampleIdentity;

UCLASS()
class USeagullHorizonManager : public UObject
{
	GENERATED_BODY()

public:
	void Initialize(UHorizonSubsystem* InSubsystem);

	// --- Connection ---
	void ConnectToServer();
	bool IsConnected() const;

	// --- Auth ---
	void SignUpAnonymous(const FString& Name, TFunction<void(bool)> Callback);
	void SignInEmail(const FString& Email, const FString& Password, TFunction<void(bool)> Callback);
	void SignUpEmail(const FString& Email, const FString& Password, const FString& Name, TFunction<void(bool)> Callback);
	void RestoreSession(TFunction<void(bool)> Callback,bool GuestOnly=false);
	void SignInWithApple(TFunction<void(bool)> Callback);
	bool IsAuthenticating() const { return bAuthRequestInFlight; }
	void SignOut();
	bool IsSignedIn() const;
    bool HasProtectedGuestIdentity() const;
	FString GetDisplayName() const;
	FString GetUserId() const;

	// --- Remote Config ---
	void LoadAllConfigs(TFunction<void(bool, const TMap<FString, FString>&)> Callback);

	// --- Cloud Save ---
	void SaveData(const FString& JsonData, TFunction<void(bool)> Callback);
	void LoadData(TFunction<void(bool, const FString&)> Callback);

	// --- Leaderboard ---
	void SubmitScore(int64 Score, TFunction<void(bool)> Callback);
	void GetTop(int32 Limit, TFunction<void(bool, const TArray<FHorizonLeaderboardEntry>&)> Callback);
	void GetRank(TFunction<void(bool, const FHorizonLeaderboardEntry&)> Callback);
    void ListBoards(TFunction<void(bool, const TArray<FHorizonLeaderboardBoard>&)> Callback);
    void GetAround(int32 Range, TFunction<void(bool, const TArray<FHorizonLeaderboardEntry>&)> Callback);
    void GetValidatedState(TFunction<void(bool, const FHorizonPlayerState&, const FString&)> Callback);
    void LoadLocalization(const FString& Lang, TFunction<void(bool, const TMap<FString, FString>&)> Callback);
    void GetPlayerProfile(TFunction<void(bool, const FHorizonPlayerProfileResult&, const FString&)> Callback);
    void SetPlayerAvatar(const FString& AvatarId, TFunction<void(bool, const FHorizonPlayerProfileResult&, const FString&)> Callback);
    void SendOwnAccountEmail(const FString& TemplateSlug, TFunction<void(bool, const FString&)> Callback);
    const FString& GetEvidenceStatus() const { return EvidenceStatus; }

	// --- News ---
	void LoadNews(int32 Limit, const FString& Lang, TFunction<void(bool, const TArray<FHorizonNewsEntry>&)> Callback);

	// --- Gift Codes ---
	void ValidateGiftCode(const FString& Code, TFunction<void(bool, bool)> Callback);
	void RedeemGiftCode(const FString& Code, TFunction<void(bool, const FString&, const FString&)> Callback);

	// --- Feedback ---
	void SubmitFeedback(const FString& Title, const FString& Message, const FString& Category, TFunction<void(bool)> Callback);

	// --- User Logs ---
	void LogInfo(const FString& Message);
	void LogWarn(const FString& Message);

	// --- Crash Reporting ---
	void StartCrashCapture();
	void RecordBreadcrumb(const FString& Type, const FString& Message);
	void SetCrashCustomKey(const FString& Key, const FString& Value);
	void RecordException(const FString& Error, const FString& StackTrace);

	// --- Validated Actions ---
	// Official SDK plugin: ticket, server-owned state and evidence.
	// An unavailable ticket leaves the run in practice without score submission.
	static bool IsValidatedActionsCompiledIn();

	/** Asks the server for a run ticket bound to LeaderboardKey. Callback(bSuccess, Seed, ErrorCode). */
	void StartValidatedRun(const FString& LeaderboardKey, TFunction<void(bool, int32, const FString&)> Callback);

	/** True while a started ticket waits for its submit. */
	bool HasValidatedRun() const;

	/** Drops the current ticket without submitting it. */
	void DiscardValidatedRun();

	/**
	 * Submits the run with its input log. CoinsKey empty sends no earned values; otherwise
	 * Coins is sent as earned value CoinsKey (the rules of the API key must define it).
	 * Callback(bSuccess, Rank, ErrorCode); Rank is 0 when unknown.
	 */
	void SubmitValidatedScore(int64 Score, const TArray<uint8>& InputLog, const FString& Stage,
		const FString& CoinsKey, int64 Coins, TFunction<void(bool, int64, const FString&)> Callback);

	/** Error code of the last failed SubmitScore (for example VALIDATED_SUBMIT_REQUIRED), empty if unknown. */
	FString GetLastSubmitErrorCode() const;

	/** Player facing text for a Validated Actions or leaderboard error code. */
	static FString DescribeScoreError(const FString& ErrorCode);

private:
    UPROPERTY() UHorizonExampleIdentity* AuthOriginal=nullptr;
    FString AuthProject;
    bool bGuestSignupSent=false,bRestoringIdentity=false;
	UPROPERTY()
	UHorizonSubsystem* Subsystem = nullptr;
	FString EvidenceStatus = TEXT("No evidence requested");
	FString EvidenceRunId;
	uint64 EvidenceGeneration = 0;
	bool bEvidenceResolved = false;
	bool bAuthRequestInFlight = false;
	bool bSignOutAfterAuth = false;
	bool bTicketRequestInFlight = false;
	bool bCloudSaveInFlight = false;
	struct FPendingCloudSave
	{
		FString Json;
		FString Owner;
		uint64 Generation = 0;
		TFunction<void(bool)> Callback;
	};
	TArray<FPendingCloudSave> PendingCloudSaves;
	bool BeginAuthRequest(uint64& Generation, const TFunction<void(bool)>& Callback);
	void CompleteAuthRequest(uint64 Generation, bool bSuccess, const TFunction<void(bool)>& Callback);
	bool IsCurrentSession(uint64 Generation, const FString& Owner) const;
	void DrainCloudSaves();
	FString GetLeaderboardKey() const;

	UFUNCTION()
	void HandleEvidenceUploaded(const FString& RunId, int32 Bytes);

	UFUNCTION()
	void HandleEvidenceUploadFailed(const FString& RunId, const FString& ErrorCode, const FString& ErrorMessage);
};
