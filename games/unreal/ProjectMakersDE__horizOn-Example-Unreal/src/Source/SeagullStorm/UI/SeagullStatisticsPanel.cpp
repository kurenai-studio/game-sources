#include "UI/SeagullStatisticsPanel.h"
#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullTypes.h"
#include "Horizon/SeagullStatisticsSession.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/ScrollBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
void USeagullStatisticsPanel::NativeOnInitialized()
{
    Super::NativeOnInitialized(); auto* Root=WidgetTree->ConstructWidget<UCanvasPanel>(); WidgetTree->RootWidget=Root;
    auto* Dim=SeagullWidgetStyles::MakePanel(WidgetTree,SeagullColors::DarkBG,0); auto* Full=Root->AddChildToCanvas(Dim); Full->SetAnchors(FAnchors(0,0,1,1)); Full->SetOffsets(FMargin(0));
    auto* Panel=SeagullWidgetStyles::MakePanel(WidgetTree,SeagullColors::PanelBG,24); auto* Slot=Root->AddChildToCanvas(Panel); Slot->SetAnchors(FAnchors(.07f,.06f,.93f,.94f)); Slot->SetOffsets(FMargin(0));
    auto* Scroll=WidgetTree->ConstructWidget<UScrollBox>(); Panel->AddChild(Scroll); auto* Column=WidgetTree->ConstructWidget<UVerticalBox>(); Scroll->AddChild(Column);
    auto Text=[&](const FString& Label,FName Name) { auto* T=SeagullWidgetStyles::MakeText(WidgetTree,Label,18,SeagullColors::LightText,Name); T->SetAutoWrapText(true); SeagullWidgetStyles::AddRow(Column,T,6); return T; };
    Text(TEXT("STATISTICS / server session counters"),TEXT("StatisticsTitle"));
    Text(TEXT("One atomic online-round batch: kills (sum), rounds (sum), best_score (max), reset=none. Practice stays local. These client-reported counters are separate from validated scores and balances."),TEXT("StatisticsHelp"));
    Values=Text(TEXT("Refresh to load the signed-in player's authoritative snapshot."),TEXT("StatisticsValues")); Status=Text(TEXT(""),TEXT("StatisticsStatus"));
    auto Button=[&](const FString& Label,FName Name) { auto* B=SeagullWidgetStyles::MakeTextButton(WidgetTree,Label,SeagullColors::Teal,SeagullColors::LightText,18,Name); SeagullWidgetStyles::AddRow(Column,B,5); return B; };
    Button(TEXT("Refresh server snapshot"),TEXT("StatisticsRefresh"))->OnClicked.AddDynamic(this,&USeagullStatisticsPanel::OnRefresh);
    Button(TEXT("Retry saved original batch"),TEXT("StatisticsRetry"))->OnClicked.AddDynamic(this,&USeagullStatisticsPanel::OnRetry);
    // Hello exposes an explicit demo action; the game reports actual completed rounds instead.
    auto* Demo=Button(TEXT("Hello only: report 3 kills / 1 round / score 1200"),TEXT("StatisticsDemo")); Demo->OnClicked.AddDynamic(this,&USeagullStatisticsPanel::OnDemo);
    Demo->SetVisibility(bHelloDemo?ESlateVisibility::Visible:ESlateVisibility::Collapsed);
    Button(TEXT("Back to the flock"),TEXT("StatisticsClose"))->OnClicked.AddDynamic(this,&USeagullStatisticsPanel::OnClose); Render();
}
void USeagullStatisticsPanel::NativeTick(const FGeometry& Geometry,float Delta)
{ Super::NativeTick(Geometry,Delta); RenderAfter-=Delta; if (RenderAfter<=0) { RenderAfter=.2f; Render(); } }
void USeagullStatisticsPanel::Render()
{
    auto* GI=Cast<USeagullGameInstance>(GetGameInstance()); if (!GI || !Values || !Status) return;
    auto* Flow=GI->GetStatisticsSession(); const auto S=Flow->Snapshot(); FString Text=TEXT("No current authorized server snapshot.");
    if (S.bValid)
    {
        Text=FString::Printf(TEXT("Server revision %lld / definitions %lld\n"),S.Revision,S.DefinitionVersion);
        for (const auto& V:S.Values) Text+=V.bHasValue?FString::Printf(TEXT("%s: %lld%s%s\n"),*V.Key,V.Value,V.Period.IsEmpty()?TEXT(""):TEXT(" / "),*V.Period):V.Key+TEXT(": not reported\n");
        if (S.Values.IsEmpty()) Text+=TEXT("No definitions configured. The studio must configure the documented three keys.");
    }
    Values->SetText(FText::FromString(Text)); Status->SetText(FText::FromString(Flow->GetStatus()));
}
void USeagullStatisticsPanel::OnRefresh() { if (auto* GI=Cast<USeagullGameInstance>(GetGameInstance())) GI->GetStatisticsSession()->Refresh(); }
void USeagullStatisticsPanel::OnRetry() { if (auto* GI=Cast<USeagullGameInstance>(GetGameInstance())) GI->GetStatisticsSession()->RetryOriginal(); }
void USeagullStatisticsPanel::OnDemo() { if (bHelloDemo) if (auto* GI=Cast<USeagullGameInstance>(GetGameInstance())) GI->GetStatisticsSession()->RecordRound(3,1200); }
void USeagullStatisticsPanel::OnClose() { RemoveFromParent(); }

void USeagullStatisticsPanel::EnableHelloDemo()
{ bHelloDemo=true; if (auto* Button=GetWidgetFromName(TEXT("StatisticsDemo"))) Button->SetVisibility(ESlateVisibility::Visible); }
