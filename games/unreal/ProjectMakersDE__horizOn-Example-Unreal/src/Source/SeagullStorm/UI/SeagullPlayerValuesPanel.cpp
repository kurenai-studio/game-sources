#include "UI/SeagullPlayerValuesPanel.h"
#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullTypes.h"
#include "Data/SeagullValueIntent.h"
#include "HorizonSubsystem.h"
#include "Http/HorizonHttpClient.h"
#include "Managers/HorizonAuthManager.h"
#include "Managers/HorizonPlayerValuesManager.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/EditableTextBox.h"
#include "Components/ScrollBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Kismet/GameplayStatics.h"

void USeagullPlayerValuesPanel::NativeOnInitialized()
{
    Super::NativeOnInitialized();
    UCanvasPanel* Root = WidgetTree->ConstructWidget<UCanvasPanel>(); WidgetTree->RootWidget = Root;
    FLinearColor DimColor = SeagullColors::DarkBG; DimColor.A = .95f;
    UBorder* Dim = SeagullWidgetStyles::MakePanel(WidgetTree,DimColor,0.f);
    UCanvasPanelSlot* DimSlot = Root->AddChildToCanvas(Dim); DimSlot->SetAnchors(FAnchors(0,0,1,1)); DimSlot->SetOffsets(FMargin(0));
    UBorder* Panel = SeagullWidgetStyles::MakePanel(WidgetTree, SeagullColors::PanelBG, 24.f);
    UCanvasPanelSlot* Slot = Root->AddChildToCanvas(Panel); Slot->SetAnchors(FAnchors(.06f,.05f,.94f,.95f)); Slot->SetOffsets(FMargin(0));
    UScrollBox* Scroll = WidgetTree->ConstructWidget<UScrollBox>(); Panel->AddChild(Scroll);
    UVerticalBox* Column = WidgetTree->ConstructWidget<UVerticalBox>(); Scroll->AddChild(Column);
    auto Text = [&](const FString& Value) { UTextBlock* T = SeagullWidgetStyles::MakeText(WidgetTree, Value, 16, SeagullColors::LightText); T->SetAutoWrapText(true); SeagullWidgetStyles::AddRow(Column,T); return T; };
    Text(TEXT("PLAYER VALUES / server balances"));
    Text(TEXT("Practice coins stay local. Server offers choose all prices and rewards. Retry preserves the original saved operation."));
    Balances = Text(TEXT("Refresh balances to load the current player snapshot."));
    Catalog = Text(TEXT("Load offers, choose a key and confirm its current price."));
    Status = Text(TEXT("Online player session required."));
    auto Button = [&](const FString& Label, FName Name) { UButton* B = SeagullWidgetStyles::MakeTextButton(WidgetTree, Label, SeagullColors::Teal, SeagullColors::LightText,16,Name); SeagullWidgetStyles::AddRow(Column,B); return B; };
    Button(TEXT("Refresh balances"), TEXT("ValuesRefresh"))->OnClicked.AddDynamic(this,&USeagullPlayerValuesPanel::OnState);
    Button(TEXT("Load current offers"), TEXT("ValuesOffers"))->OnClicked.AddDynamic(this,&USeagullPlayerValuesPanel::OnOffers);
    OfferInput = SeagullWidgetStyles::MakeTextInput(WidgetTree,TEXT("Offer key from catalog"),TEXT("ValuesOfferKey")); SeagullWidgetStyles::AddRow(Column,OfferInput);
    Button(TEXT("Confirm purchase"), TEXT("ValuesPurchase"))->OnClicked.AddDynamic(this,&USeagullPlayerValuesPanel::OnPurchase);
    KeyInput = SeagullWidgetStyles::MakeTextInput(WidgetTree,TEXT("Configured value key"),TEXT("ValuesAdjustKey")); SeagullWidgetStyles::AddRow(Column,KeyInput);
    AmountInput = SeagullWidgetStyles::MakeTextInput(WidgetTree,TEXT("Signed whole adjustment, e.g. -1"),TEXT("ValuesAdjustAmount")); SeagullWidgetStyles::AddRow(Column,AmountInput);
    Button(TEXT("Send demo adjustment"), TEXT("ValuesAdjust"))->OnClicked.AddDynamic(this,&USeagullPlayerValuesPanel::OnAdjust);
    Button(TEXT("Retry saved original operation"), TEXT("ValuesRetry"))->OnClicked.AddDynamic(this,&USeagullPlayerValuesPanel::OnRetry);
    Button(TEXT("Back to the flock"), TEXT("ValuesClose"))->OnClicked.AddDynamic(this,&USeagullPlayerValuesPanel::OnClose);
    Context = CurrentContext();
}
FString USeagullPlayerValuesPanel::CurrentContext() const
{
    const USeagullGameInstance* GI = Cast<USeagullGameInstance>(GetGameInstance());
    UHorizonSubsystem* SDK = GI ? GI->GetHorizonSubsystem() : nullptr;
    if (!GI || GI->bPracticeMode || !SDK || !SDK->Auth || !SDK->GetHttpClient()) return TEXT("practice");
    return FString::Printf(TEXT("%llu|"), GI->SessionGeneration) + SDK->GetHttpClient()->GetActiveHost() + TEXT("|") + SDK->GetHttpClient()->GetApiKey()
        + TEXT("|") + SDK->GetHttpClient()->GetSessionToken() + TEXT("|") + SDK->Auth->GetCurrentUser().UserId;
}
bool USeagullPlayerValuesPanel::IsCurrent(const FString& Expected, int64 SentGeneration) const
{ return IsInViewport() && Context == Expected && CurrentContext() == Expected && Generation == SentGeneration; }
void USeagullPlayerValuesPanel::NativeTick(const FGeometry& Geometry, float DeltaTime)
{
    Super::NativeTick(Geometry,DeltaTime);
    if (Context != CurrentContext())
    { Context = CurrentContext(); Generation++; Pending = nullptr; Offers = {}; bBusy = false; Balances->SetText(FText::FromString(TEXT("Player changed. Refresh balances."))); Catalog->SetText(FText::FromString(TEXT("Reload offers."))); Message(TEXT("Session changed. Saved original operations remain protected.")); }
}
UHorizonSubsystem* USeagullPlayerValuesPanel::Begin()
{
    if (bBusy) return nullptr;
    USeagullGameInstance* GI = Cast<USeagullGameInstance>(GetGameInstance());
    UHorizonSubsystem* SDK = GI ? GI->GetHorizonSubsystem() : nullptr;
    if (!GI || GI->bPracticeMode || !SDK || !SDK->Auth->IsSignedIn()) { Message(TEXT("Practice is local. Connect a player first.")); return nullptr; }
    if (Context != CurrentContext()) { Message(TEXT("Session changed. Reopen this panel.")); return nullptr; }
    return SDK;
}
bool USeagullPlayerValuesPanel::LoadPending(UHorizonSubsystem* SDK)
{
    bool Blocked; Pending = USeagullValueIntent::Load(SDK->GetHttpClient()->GetApiKey(),SDK->Auth->GetCurrentUser().UserId,Blocked);
    if (Blocked) Message(TEXT("Saved operation needs recovery. Original file retained."));
    return !Blocked;
}
void USeagullPlayerValuesPanel::Message(const FString& Text, bool Success)
{ if (Status) { Status->SetText(FText::FromString(Text)); Status->SetColorAndOpacity(Success ? SeagullColors::LightText : SeagullColors::CrabRed); } }
void USeagullPlayerValuesPanel::DisplayState(bool Success, const FHorizonPlayerValuesState& State, const FString& Code)
{
    bBusy = false;
    if (State.bPresent)
    {
        FString Text = TEXT("Server balances\n");
        for (const auto& V : State.Values) Text += FString::Printf(TEXT("%s: %lld / earned today %lld\n"),*V.Key,V.Balance,V.EarnedToday);
        if (State.Values.IsEmpty()) Text += TEXT("No values configured."); Balances->SetText(FText::FromString(Text));
    }
    Message(Success ? TEXT("Authoritative server snapshot loaded.") : Code + TEXT(". Saved original operation retained for reconciliation/retry."), Success);
}
void USeagullPlayerValuesPanel::DisplayOffers(const FHorizonPlayerValuesOffers& Snapshot)
{
    Offers = Snapshot; FString Text = TEXT("Current offers\n");
    for (const auto& Offer : Offers.Offers)
    {
        Text += Offer.Key + (Offer.bActive ? TEXT(" / costs ") : TEXT(" / inactive "));
        for (const auto& V : Offer.Costs) Text += FString::Printf(TEXT("%s=%lld "),*V.Key,V.Amount);
        Text += TEXT(" / rewards "); for (const auto& V : Offer.Rewards) Text += FString::Printf(TEXT("%s=%lld "),*V.Key,V.Amount); Text += TEXT("\n");
    }
    if (Offers.Offers.IsEmpty()) Text += TEXT("No offers configured."); Catalog->SetText(FText::FromString(Text));
}
void USeagullPlayerValuesPanel::OnState()
{
    UHorizonSubsystem* SDK = Begin(); if (!SDK) return;
    bBusy = true; FString Sent = Context; int64 Epoch = Generation; TWeakObjectPtr<USeagullPlayerValuesPanel> Weak(this);
    SDK->PlayerValues->GetState(SDK->Auth->GetCurrentUser().UserId,FOnPlayerValuesComplete::CreateLambda([Weak,Sent,Epoch](bool Ok,const FHorizonPlayerValuesState& State,const FString& Code,const FString&)
    { if (auto* P = Weak.Get(); P && P->IsCurrent(Sent,Epoch)) P->DisplayState(Ok,State,Code); }));
}
void USeagullPlayerValuesPanel::OnOffers()
{
    UHorizonSubsystem* SDK = Begin(); if (!SDK) return;
    bBusy = true; FString Sent = Context; int64 Epoch = Generation; TWeakObjectPtr<USeagullPlayerValuesPanel> Weak(this);
    SDK->PlayerValues->GetOffers(SDK->Auth->GetCurrentUser().UserId,FOnPlayerValuesOffersComplete::CreateLambda([Weak,Sent,Epoch](bool Ok,const FHorizonPlayerValuesOffers& Data,const FString& Code,const FString&)
    { if (auto* P = Weak.Get(); P && P->IsCurrent(Sent,Epoch)) { P->bBusy = false; if (Ok) P->DisplayOffers(Data); P->Message(Ok ? TEXT("Choose an offer and confirm its displayed price.") : Code,Ok); } }));
}
void USeagullPlayerValuesPanel::OnPurchase()
{
    UHorizonSubsystem* SDK = Begin(); if (!SDK || !LoadPending(SDK)) return;
    if (Pending) { Message(TEXT("An original operation is pending. Use Retry saved original operation.")); return; }
    if (!Offers.bPresent || !SDK->PlayerValues->HasServerClock()) { Message(TEXT("Refresh balances and current offers before purchase.")); return; }
    FString Key = OfferInput->GetText().ToString().TrimStartAndEnd(); int64 Quoted = Offers.DefinitionVersion;
    bBusy = true; FString Sent = Context; int64 Epoch = Generation; TWeakObjectPtr<USeagullPlayerValuesPanel> Weak(this);
    SDK->PlayerValues->GetOffers(SDK->Auth->GetCurrentUser().UserId,FOnPlayerValuesOffersComplete::CreateLambda([Weak,Sent,Epoch,Key,Quoted,SDK](bool Ok,const FHorizonPlayerValuesOffers& Data,const FString& Code,const FString&)
    {
        auto* P = Weak.Get(); if (!P || !P->IsCurrent(Sent,Epoch)) return; P->bBusy = false;
        if (!Ok) { P->Message(Code); return; } P->DisplayOffers(Data);
        if (Quoted != Data.DefinitionVersion) { P->Message(TEXT("Offer catalog changed. Review the new price and confirm again.")); return; }
        const auto* Offer = Data.Offers.FindByPredicate([&](const auto& V) { return V.Key == Key && V.bActive; });
        if (!Offer) { P->Message(TEXT("Choose an active offer key from the current catalog.")); return; }
        P->Pending = NewObject<USeagullValueIntent>(P); P->Pending->ProjectHash = USeagullValueIntent::Project(SDK->GetHttpClient()->GetApiKey()); P->Pending->UserId = SDK->Auth->GetCurrentUser().UserId;
        P->Pending->Kind = TEXT("purchase"); P->Pending->OfferDefinitionVersion = Data.DefinitionVersion; P->Pending->OfferKey = Key; P->Pending->OperationId = SDK->PlayerValues->CreateOperationId(); P->SendPending(SDK);
    }));
}
void USeagullPlayerValuesPanel::OnAdjust()
{
    UHorizonSubsystem* SDK = Begin(); if (!SDK || !LoadPending(SDK)) return;
    if (Pending) { Message(TEXT("Retry the saved original operation first.")); return; }
    FString Raw = AmountInput->GetText().ToString().TrimStartAndEnd(), Key = KeyInput->GetText().ToString().TrimStartAndEnd(); int64 Amount = 0;
    bool Digits = !Raw.IsEmpty(); for (int32 I = Raw.StartsWith(TEXT("-")) ? 1 : 0; I < Raw.Len(); I++) Digits &= Raw[I] >= '0' && Raw[I] <= '9';
    if (!Digits || !LexTryParseString(Amount,*Raw) || Amount == 0 || Amount < -9007199254740991LL || Amount > 9007199254740991LL || Key.IsEmpty() || !SDK->PlayerValues->HasServerClock()) { Message(TEXT("Refresh balances, then enter a safe whole adjustment and configured key.")); return; }
    if (!SDK->PlayerValues->GetCurrentState().Values.ContainsByPredicate([&](const auto& V) { return V.Key == Key; }))
    { Message(TEXT("Unknown value key. Refresh balances and choose an existing server key.")); return; }
    Pending = NewObject<USeagullValueIntent>(this); Pending->ProjectHash = USeagullValueIntent::Project(SDK->GetHttpClient()->GetApiKey()); Pending->UserId = SDK->Auth->GetCurrentUser().UserId;
    Pending->Kind = TEXT("adjust"); Pending->ValueKey = Key; Pending->Amount = Amount; Pending->Reason = TEXT("demo"); Pending->OperationId = SDK->PlayerValues->CreateOperationId(); SendPending(SDK);
}
void USeagullPlayerValuesPanel::OnRetry()
{
    UHorizonSubsystem* SDK = Begin(); if (!SDK || !LoadPending(SDK)) return;
    if (!Pending) { Message(TEXT("No saved operation for this project/player.")); return; }
    if (Pending->Kind != TEXT("purchase")) { SendPending(SDK); return; }
    bBusy = true; FString Sent = Context; int64 Epoch = Generation; TWeakObjectPtr<USeagullPlayerValuesPanel> Weak(this);
    SDK->PlayerValues->GetOffers(Pending->UserId,FOnPlayerValuesOffersComplete::CreateLambda([Weak,Sent,Epoch,SDK](bool Ok,const FHorizonPlayerValuesOffers& Data,const FString& Code,const FString&)
    {
        auto* P = Weak.Get(); if (!P || !P->IsCurrent(Sent,Epoch)) return; P->bBusy = false;
        if (!Ok) { P->Message(Code + TEXT(". Original retained.")); return; }
        P->DisplayOffers(Data);
        if (!Data.Offers.ContainsByPredicate([&](const auto& V) { return V.Key == P->Pending->OfferKey && V.bActive; }))
        { P->Message(TEXT("Original offer is unavailable. Reconcile the saved operation before another purchase.")); return; }
        if (Data.DefinitionVersion != P->Pending->OfferDefinitionVersion &&
            (P->RetryQuotedVersion != Data.DefinitionVersion || P->RetryQuotedOperation != P->Pending->OperationId))
        {
            P->RetryQuotedVersion = Data.DefinitionVersion; P->RetryQuotedOperation = P->Pending->OperationId;
            P->Message(TEXT("Retry price/catalog changed. Review current terms, then click Retry original again to confirm. The original ID is preserved.")); return;
        }
        P->RetryQuotedVersion = -1; P->RetryQuotedOperation.Empty(); P->SendPending(SDK);
    }));
}
void USeagullPlayerValuesPanel::SendPending(UHorizonSubsystem* SDK)
{
    FString Project = SDK->GetHttpClient()->GetApiKey();
    if (!Pending || Pending->SendCount == MAX_int32) { Message(TEXT("Saved operation needs reconciliation.")); return; }
    Pending->SendCount++;
    if (!Pending->Persist(Project)) { Message(TEXT("Could not safely persist the original operation. No request sent.")); return; }
    bBusy = true; FString Sent = Context; int64 Epoch = Generation; TWeakObjectPtr<USeagullPlayerValuesPanel> Weak(this); USeagullValueIntent* Intent = Pending;
    auto Complete = FOnPlayerValuesComplete::CreateLambda([Weak,Sent,Epoch,Project,Intent](bool Ok,const FHorizonPlayerValuesState& State,const FString& Code,const FString&)
    { if (auto* P = Weak.Get(); P && P->IsCurrent(Sent,Epoch)) { if (Ok && Intent->Confirm(Project)) P->Pending = nullptr; P->DisplayState(Ok,State,Code); } });
    if (Intent->Kind == TEXT("purchase")) SDK->PlayerValues->Purchase(Intent->UserId,Intent->OfferKey,Intent->OperationId,Complete);
    else SDK->PlayerValues->Adjust(Intent->UserId,Intent->ValueKey,Intent->Amount,Intent->Reason,Intent->OperationId,Complete);
}
void USeagullPlayerValuesPanel::OnClose() { Generation++; RemoveFromParent(); }
