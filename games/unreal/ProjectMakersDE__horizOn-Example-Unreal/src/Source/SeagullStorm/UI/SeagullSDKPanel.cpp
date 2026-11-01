#include "UI/SeagullSDKPanel.h"
#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullTypes.h"
#include "Data/SeagullConfigCache.h"
#include "Horizon/SeagullHorizonManager.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/EditableTextBox.h"
#include "Components/ScrollBox.h"
#include "Components/WrapBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Kismet/GameplayStatics.h"

void USeagullSDKPanel::NativeOnInitialized()
{
    Super::NativeOnInitialized();
    UCanvasPanel* Root = WidgetTree->ConstructWidget<UCanvasPanel>();
    WidgetTree->RootWidget = Root;
    FLinearColor DimColor = SeagullColors::DarkBG;
    DimColor.A = 0.95f;
    UBorder* Dim = SeagullWidgetStyles::MakePanel(WidgetTree, DimColor, 0.f);
    UCanvasPanelSlot* DimSlot = Root->AddChildToCanvas(Dim);
    DimSlot->SetAnchors(FAnchors(0.f, 0.f, 1.f, 1.f));
    DimSlot->SetOffsets(FMargin(0.f));

    UBorder* Panel = SeagullWidgetStyles::MakePanel(WidgetTree, SeagullColors::PanelBG, 24.f);
    UCanvasPanelSlot* PanelSlot = Root->AddChildToCanvas(Panel);
    PanelSlot->SetAnchors(FAnchors(0.06f, 0.08f, 0.94f, 0.92f));
    PanelSlot->SetOffsets(FMargin(0.f));
    UScrollBox* Scroll = WidgetTree->ConstructWidget<UScrollBox>();
    Panel->AddChild(Scroll);
    UVerticalBox* Column = WidgetTree->ConstructWidget<UVerticalBox>();
    Scroll->AddChild(Column);
    SeagullWidgetStyles::AddRow(Column, SeagullWidgetStyles::MakeText(WidgetTree,
        TEXT("horizOn SDK"), 24, SeagullColors::Orange));
    UTextBlock* Intro = SeagullWidgetStyles::MakeText(WidgetTree,
        TEXT("Run tickets and evidence are used during online play. Explore board queries, server-owned balances and localization here. Gift codes, news and feedback are in the hub."),
        16, SeagullColors::LightText);
    Intro->SetAutoWrapText(true);
    SeagullWidgetStyles::AddRow(Column, Intro);
    BoardInput = SeagullWidgetStyles::MakeTextInput(WidgetTree, TEXT("Leaderboard board key"));
    USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
    BoardInput->SetText(FText::FromString(GI ? GI->GetConfigCache()->ValidatedRunsBoard : FString(TEXT("default"))));
    SeagullWidgetStyles::AddRow(Column, BoardInput);

    UWrapBox* QueryRow = WidgetTree->ConstructWidget<UWrapBox>();
    QueryRow->SetExplicitWrapSize(false);
    QueryRow->SetInnerSlotPadding(FVector2D(6.f, 6.f));
    UButton* Boards = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("List boards"), SeagullColors::Teal, SeagullColors::LightText, 16);
    Boards->OnClicked.AddDynamic(this, &USeagullSDKPanel::OnBoards);
    UButton* Top = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Top 10"), SeagullColors::Teal, SeagullColors::LightText, 16);
    Top->OnClicked.AddDynamic(this, &USeagullSDKPanel::OnTop);
    UButton* Around = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Around me"), SeagullColors::Teal, SeagullColors::LightText, 16);
    Around->OnClicked.AddDynamic(this, &USeagullSDKPanel::OnAround);
    UButton* Rank = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("My rank"), SeagullColors::Teal, SeagullColors::LightText, 16);
    Rank->OnClicked.AddDynamic(this, &USeagullSDKPanel::OnRank);
    for (UButton* Button : {Boards, Top, Around, Rank})
    {
        QueryRow->AddChildToWrapBox(Button);
    }
    SeagullWidgetStyles::AddRow(Column, QueryRow);
    UWrapBox* FeatureRow = WidgetTree->ConstructWidget<UWrapBox>();
    FeatureRow->SetExplicitWrapSize(false);
    FeatureRow->SetInnerSlotPadding(FVector2D(6.f, 6.f));
    UButton* State = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Balances"), SeagullColors::Teal, SeagullColors::LightText, 16);
    State->OnClicked.AddDynamic(this, &USeagullSDKPanel::OnState);
    UButton* English = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("English"), SeagullColors::Teal, SeagullColors::LightText, 16);
    English->OnClicked.AddDynamic(this, &USeagullSDKPanel::OnEnglish);
    UButton* German = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Deutsch"), SeagullColors::Teal, SeagullColors::LightText, 16);
    German->OnClicked.AddDynamic(this, &USeagullSDKPanel::OnGerman);
    UButton* Save = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Save progress"), SeagullColors::Teal, SeagullColors::LightText, 16);
    Save->OnClicked.AddDynamic(this, &USeagullSDKPanel::OnCloudSave);
    for (UButton* Button : {State, English, German, Save})
    {
        FeatureRow->AddChildToWrapBox(Button);
    }
    SeagullWidgetStyles::AddRow(Column, FeatureRow);
    UButton* Profile = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Read player profile"), SeagullColors::Teal, SeagullColors::LightText, 16);
    Profile->OnClicked.AddDynamic(this, &USeagullSDKPanel::OnProfile);
    SeagullWidgetStyles::AddRow(Column, Profile);
    AvatarInput = SeagullWidgetStyles::MakeTextInput(WidgetTree, TEXT("Available avatar id from catalog"));
    SeagullWidgetStyles::AddRow(Column, AvatarInput);
    UButton* ApplyAvatar = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Set avatar"), SeagullColors::Teal, SeagullColors::LightText, 16);
    ApplyAvatar->OnClicked.AddDynamic(this, &USeagullSDKPanel::OnApplyAvatar);
    SeagullWidgetStyles::AddRow(Column, ApplyAvatar);
    EmailTemplateInput = SeagullWidgetStyles::MakeTextInput(WidgetTree, TEXT("Email template slug configured in your app"));
    SeagullWidgetStyles::AddRow(Column, EmailTemplateInput);
    UButton* SendEmail = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Send template to my account"), SeagullColors::Teal, SeagullColors::LightText, 16);
    SendEmail->OnClicked.AddDynamic(this, &USeagullSDKPanel::OnSendEmail);
    SeagullWidgetStyles::AddRow(Column, SendEmail);
    ResultText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("Choose an operation. Online features need a configured app and a player session."), 16, SeagullColors::LightText);
    ResultText->SetAutoWrapText(true);
    SeagullWidgetStyles::AddRow(Column, ResultText);
    EvidenceText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT(""), 16, SeagullColors::Sand);
    EvidenceText->SetAutoWrapText(true);
    SeagullWidgetStyles::AddRow(Column, EvidenceText);
    UButton* Close = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Back to the flock"), SeagullColors::Orange, SeagullColors::DarkText, 20);
    Close->OnClicked.AddDynamic(this, &USeagullSDKPanel::OnClose);
    SeagullWidgetStyles::AddRow(Column, Close);
}

void USeagullSDKPanel::NativeTick(const FGeometry& Geometry, float DeltaTime)
{
    Super::NativeTick(Geometry, DeltaTime);
    USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
    if (GI && EvidenceText) EvidenceText->SetText(FText::FromString(GI->GetHorizonManager()->GetEvidenceStatus()));
}

USeagullHorizonManager* USeagullSDKPanel::BeginRequest(const FString& Action)
{
    if (bBusy) return nullptr;
    USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
    if (!GI || GI->bPracticeMode || !GI->GetHorizonManager()->IsSignedIn())
    {
        ShowResult(TEXT("Practice is local. Return to the title and connect a player to use online features."), false);
        return nullptr;
    }
    FString Key = BoardInput->GetText().ToString().TrimStartAndEnd();
    GI->GetConfigCache()->ValidatedRunsBoard = Key.IsEmpty() ? FString(TEXT("default")) : Key;
    ShowResult(Action + TEXT(" / waiting for server..."), true);
    bBusy = true;
    return GI->GetHorizonManager();
}

void USeagullSDKPanel::ShowResult(const FString& Text, bool bSuccess)
{
    bBusy = false;
    if (!ResultText) return;
    ResultText->SetText(FText::FromString(Text));
    ResultText->SetColorAndOpacity(FSlateColor(bSuccess ? SeagullColors::LightText : SeagullColors::CrabRed));
}

void USeagullSDKPanel::OnBoards()
{
    USeagullHorizonManager* HM = BeginRequest(TEXT("Boards"));
    if (!HM) return;
    TWeakObjectPtr<USeagullSDKPanel> Weak(this);
    HM->ListBoards([Weak](bool Ok, const TArray<FHorizonLeaderboardBoard>& Boards)
    {
        USeagullSDKPanel* Panel = Weak.Get(); if (!Panel || !Panel->IsInViewport()) return;
        FString Text = Ok ? TEXT("Available boards\n") : TEXT("Boards unavailable / check connection and app configuration.");
        for (const auto& Board : Boards) Text += FString::Printf(TEXT("%s / %s / %s / %lld entries\n"), *Board.Key, *Board.Name, Board.bValidatedOnly ? TEXT("validated only") : TEXT("ordinary"), Board.ScoreCount);
        if (Ok && Boards.IsEmpty()) Text += TEXT("No boards configured.");
        Panel->ShowResult(Text, Ok);
    });
}

void USeagullSDKPanel::OnTop()
{
    USeagullHorizonManager* HM = BeginRequest(TEXT("Top 10")); if (!HM) return;
    TWeakObjectPtr<USeagullSDKPanel> Weak(this);
    HM->GetTop(10, [Weak](bool Ok, const TArray<FHorizonLeaderboardEntry>& Entries)
    {
        USeagullSDKPanel* Panel = Weak.Get(); if (!Panel || !Panel->IsInViewport()) return;
        FString Text = Ok ? TEXT("Top 10 / fresh server query\n") : TEXT("Leaderboard unavailable.");
        for (const auto& E : Entries) Text += FString::Printf(TEXT("#%d  %s  %lld\n"), E.Position, *E.Username, E.Score);
        if (Ok && Entries.IsEmpty()) Text += TEXT("No scores yet.");
        Panel->ShowResult(Text, Ok);
    });
}

void USeagullSDKPanel::OnAround()
{
    USeagullHorizonManager* HM = BeginRequest(TEXT("Around me")); if (!HM) return;
    TWeakObjectPtr<USeagullSDKPanel> Weak(this);
    HM->GetAround(3, [Weak](bool Ok, const TArray<FHorizonLeaderboardEntry>& Entries)
    {
        USeagullSDKPanel* Panel = Weak.Get(); if (!Panel || !Panel->IsInViewport()) return;
        FString Text = Ok ? TEXT("Three neighbors above and below\n") : TEXT("Surrounding entries unavailable / finish an online run first.");
        for (const auto& E : Entries) Text += FString::Printf(TEXT("#%d  %s  %lld\n"), E.Position, *E.Username, E.Score);
        if (Ok && Entries.IsEmpty()) Text += TEXT("No ranked entry yet.");
        Panel->ShowResult(Text, Ok);
    });
}

void USeagullSDKPanel::OnRank()
{
    USeagullHorizonManager* HM = BeginRequest(TEXT("My rank")); if (!HM) return;
    TWeakObjectPtr<USeagullSDKPanel> Weak(this);
    HM->GetRank([Weak](bool Ok, const FHorizonLeaderboardEntry& E)
    {
        USeagullSDKPanel* Panel = Weak.Get(); if (!Panel || !Panel->IsInViewport()) return;
        Panel->ShowResult(Ok && E.Position > 0 ? FString::Printf(TEXT("My rank #%d / best score %lld"), E.Position, E.Score) : FString(TEXT("No ranked entry / finish an online run first.")), Ok);
    });
}

void USeagullSDKPanel::OnState()
{
    USeagullHorizonManager* HM = BeginRequest(TEXT("Server-owned balances")); if (!HM) return;
    TWeakObjectPtr<USeagullSDKPanel> Weak(this);
    HM->GetValidatedState([Weak](bool Ok, const FHorizonPlayerState& State, const FString& Code)
    {
        USeagullSDKPanel* Panel = Weak.Get(); if (!Panel || !Panel->IsInViewport()) return;
        FString Text = Ok ? TEXT("Server-owned balances / read only\n") : USeagullHorizonManager::DescribeScoreError(Code);
        for (const auto& V : State.Values) Text += FString::Printf(TEXT("%s: %lld / earned today %lld / daily cap %lld\n"), *V.Key, V.Balance, V.EarnedToday, V.DailyCap);
        if (Ok && State.Values.IsEmpty()) Text += TEXT("No value rules configured for this app.");
        Panel->ShowResult(Text, Ok);
    });
}

void USeagullSDKPanel::OnEnglish() { LoadLanguage(TEXT("en")); }
void USeagullSDKPanel::OnGerman() { LoadLanguage(TEXT("de")); }
void USeagullSDKPanel::LoadLanguage(const FString& Language)
{
    USeagullHorizonManager* HM = BeginRequest(TEXT("Localization")); if (!HM) return;
    TWeakObjectPtr<USeagullSDKPanel> Weak(this);
    HM->LoadLocalization(Language, [Weak, Language](bool Ok, const TMap<FString, FString>& Values)
    {
        USeagullSDKPanel* Panel = Weak.Get(); if (!Panel || !Panel->IsInViewport()) return;
        FString Text = Ok ? FString::Printf(TEXT("Localization: %s / %d keys\n"), *Language, Values.Num()) : FString(TEXT("Localization unavailable."));
        int32 Count = 0;
        for (const auto& V : Values) { if (Count++ >= 6) break; Text += V.Key + TEXT(": ") + V.Value + TEXT("\n"); }
        if (Ok && Values.IsEmpty()) Text += TEXT("No localization keys configured.");
        Panel->ShowResult(Text, Ok);
    });
}

void USeagullSDKPanel::OnCloudSave()
{
    USeagullHorizonManager* HM = BeginRequest(TEXT("Cloud Save")); if (!HM) return;
    USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
    if (!GI || !GI->bCloudSaveReady) { ShowResult(TEXT("Cloud save has not loaded successfully. Saving is disabled to protect existing progress."), false); return; }
    TWeakObjectPtr<USeagullSDKPanel> Weak(this);
    HM->SaveData(GI->SaveData.ToJsonString(), [Weak](bool Ok)
    {
        USeagullSDKPanel* Panel = Weak.Get(); if (!Panel || !Panel->IsInViewport()) return;
        Panel->ShowResult(Ok ? TEXT("Cloud Save / progress saved for the signed-in player") : TEXT("Cloud Save failed / progress remains in memory"), Ok);
    });
}

void USeagullSDKPanel::OnClose() { RemoveFromParent(); }

void USeagullSDKPanel::OnProfile()
{
    USeagullHorizonManager* HM = BeginRequest(TEXT("Player profile")); if (!HM) return;
    TWeakObjectPtr<USeagullSDKPanel> Weak(this);
    HM->GetPlayerProfile([Weak](bool Ok, const FHorizonPlayerProfileResult& Profile, const FString& Code)
    {
        USeagullSDKPanel* Panel = Weak.Get(); if (!Panel || !Panel->IsInViewport()) return;
        FString Text = Ok ? FString::Printf(TEXT("Avatar: %s / frame: %s / catalog:\n"), *Profile.Profile.AvatarId, *Profile.Profile.FrameId) : TEXT("Profile unavailable: ") + Code;
        for (const auto& Item : Profile.Cosmetics) Text += FString::Printf(TEXT("%s / %s / %s\n"), *Item.Id, *Item.Type, Item.bAvailable ? TEXT("available") : TEXT("locked"));
        if (Ok && Profile.Cosmetics.IsEmpty()) Text += TEXT("No cosmetics configured for this app.");
        if (Ok) Panel->AvatarInput->SetText(FText::FromString(Profile.Profile.AvatarId));
        Panel->ShowResult(Text, Ok);
    });
}

void USeagullSDKPanel::OnApplyAvatar()
{
    USeagullHorizonManager* HM = BeginRequest(TEXT("Set player avatar")); if (!HM) return;
    TWeakObjectPtr<USeagullSDKPanel> Weak(this);
    HM->SetPlayerAvatar(AvatarInput->GetText().ToString().TrimStartAndEnd(),
        [Weak](bool Ok, const FHorizonPlayerProfileResult& Profile, const FString& Code)
        {
            USeagullSDKPanel* Panel = Weak.Get(); if (!Panel || !Panel->IsInViewport()) return;
            Panel->ShowResult(Ok ? TEXT("Player avatar selected: ") + Profile.Profile.AvatarId : TEXT("Avatar not selected: ") + Code, Ok);
        });
}

void USeagullSDKPanel::OnSendEmail()
{
    const FString Slug = EmailTemplateInput->GetText().ToString().TrimStartAndEnd();
    if (Slug.IsEmpty()) { ShowResult(TEXT("Enter a template slug from your own app. This sends a real email to your account."), false); return; }
    USeagullHorizonManager* HM = BeginRequest(TEXT("Send template to my account")); if (!HM) return;
    TWeakObjectPtr<USeagullSDKPanel> Weak(this);
    HM->SendOwnAccountEmail(Slug, [Weak](bool Ok, const FString& Status)
    {
        USeagullSDKPanel* Panel = Weak.Get(); if (!Panel || !Panel->IsInViewport()) return;
        Panel->ShowResult(Status, Ok);
    });
}
