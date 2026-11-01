#include "UI/SeagullTitleScreen.h"
#include "UI/SeagullEmailAuthForm.h"
#include "UI/SeagullWidgetStyles.h"
#include "Core/SeagullGameInstance.h"
#include "Core/SeagullStormGameMode.h"
#include "Core/SeagullTypes.h"
#include "Horizon/SeagullHorizonManager.h"
#include "HorizonSubsystem.h"
#include "Managers/HorizonAuthManager.h"
#include "HorizonSessionSave.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/EditableTextBox.h"
#include "Components/Image.h"
#include "Components/SizeBox.h"
#include "Components/ScaleBox.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Engine/Texture2D.h"
#include "ImageUtils.h"
#include "Kismet/GameplayStatics.h"
#include "Misc/Paths.h"
#include "SeagullStorm.h"

void USeagullTitleScreen::NativeOnInitialized()
{
	Super::NativeOnInitialized();

	// Build the whole widget tree in C++; this project uses no Blueprint widgets.
	UCanvasPanel* RootCanvas = WidgetTree->ConstructWidget<UCanvasPanel>(UCanvasPanel::StaticClass(), TEXT("RootCanvas"));
	WidgetTree->RootWidget = RootCanvas;

	// Full-screen dark background
	UBorder* Background = SeagullWidgetStyles::MakePanel(WidgetTree, SeagullColors::DarkBG, 0.f);
	if (UCanvasPanelSlot* BackgroundSlot = RootCanvas->AddChildToCanvas(Background))
	{
		BackgroundSlot->SetAnchors(FAnchors(0.f, 0.f, 1.f, 1.f));
		BackgroundSlot->SetOffsets(FMargin(0.f));
	}

	// Scale the centered title contents to the available window, including 720p.
	UScaleBox* ScreenFit = WidgetTree->ConstructWidget<UScaleBox>();
	ScreenFit->SetStretch(EStretch::ScaleToFit);
	if (UCanvasPanelSlot* FitSlot = RootCanvas->AddChildToCanvas(ScreenFit))
	{
		FitSlot->SetAnchors(FAnchors(0.04f, 0.03f, 0.96f, 0.97f));
		FitSlot->SetOffsets(FMargin(0.f));
	}
	USizeBox* ColumnSize = WidgetTree->ConstructWidget<USizeBox>(USizeBox::StaticClass());
	ColumnSize->SetWidthOverride(680.f);
	ScreenFit->AddChild(ColumnSize);

	UVerticalBox* Column = WidgetTree->ConstructWidget<UVerticalBox>(UVerticalBox::StaticClass());
	ColumnSize->AddChild(Column);

	// Seagull logo, imported from the shipped PNG at runtime, so no .uasset is needed
	USizeBox* LogoSize = WidgetTree->ConstructWidget<USizeBox>(USizeBox::StaticClass());
	LogoSize->SetWidthOverride(192.f);
	LogoSize->SetHeightOverride(192.f);
	LogoImage = WidgetTree->ConstructWidget<UImage>(UImage::StaticClass(), TEXT("LogoImage"));
	UTexture2D* LogoTexture = FImageUtils::ImportFileAsTexture2D(
		FPaths::ProjectContentDir() / TEXT("Textures/seagull_hero.png"));
	if (LogoTexture)
	{
		// Rebuild the sampler resource for the new cel-shaded artwork.
		LogoTexture->Filter = TextureFilter::TF_Bilinear;
		LogoTexture->UpdateResource();
		LogoImage->SetBrushFromTexture(LogoTexture, false);
	}
	else
	{
		LogoSize->SetVisibility(ESlateVisibility::Collapsed);
	}
	LogoSize->AddChild(LogoImage);
	if (UVerticalBoxSlot* LogoSlot = Column->AddChildToVerticalBox(LogoSize))
	{
		LogoSlot->SetHorizontalAlignment(HAlign_Center);
		LogoSlot->SetPadding(FMargin(0.f, 0.f, 0.f, 16.f));
	}

	// Title + subtitle
	TitleText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("SEAGULL STORM"),
		SeagullWidgetStyles::TitleFontSize, SeagullColors::Orange, TEXT("TitleText"));
	TitleText->SetJustification(ETextJustify::Center);
	SeagullWidgetStyles::AddRow(Column, TitleText, 6.f);

	SubtitleText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("Outlast the tide. Build your flock."),
		SeagullWidgetStyles::SmallFontSize, SeagullColors::LightText, TEXT("SubtitleText"));
	SubtitleText->SetJustification(ETextJustify::Center);
	SeagullWidgetStyles::AddRow(Column, SubtitleText, 6.f);

	// Name input
	NameInput = SeagullWidgetStyles::MakeTextInput(WidgetTree, TEXT("Enter your name..."), TEXT("NameInput"));
	SeagullWidgetStyles::AddRow(Column, NameInput, 14.f);

	PracticeButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Play offline practice"),
        SeagullColors::Orange, SeagullColors::DarkText, SeagullWidgetStyles::TextFontSize, TEXT("PracticeButton"));
    SeagullWidgetStyles::AddRow(Column, PracticeButton);

    // Auth buttons
	GuestButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Connect as guest"),
		SeagullColors::Orange, SeagullColors::DarkText, SeagullWidgetStyles::TextFontSize, TEXT("GuestButton"));
	SeagullWidgetStyles::AddRow(Column, GuestButton);

	GoogleButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Sign In with Google"),
		SeagullColors::Teal, SeagullColors::LightText, SeagullWidgetStyles::TextFontSize, TEXT("GoogleButton"));
	GoogleButton->SetVisibility(ESlateVisibility::Collapsed);

	AppleButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Sign In with Apple"),
		SeagullColors::Teal, SeagullColors::LightText, SeagullWidgetStyles::TextFontSize, TEXT("AppleButton"));
	#if PLATFORM_IOS
    SeagullWidgetStyles::AddRow(Column, AppleButton);
#else
    AppleButton->SetVisibility(ESlateVisibility::Collapsed);
#endif

	EmailButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Sign In with Email"),
		SeagullColors::Teal, SeagullColors::LightText, SeagullWidgetStyles::TextFontSize, TEXT("EmailButton"));
	SeagullWidgetStyles::AddRow(Column, EmailButton);

	RegisterButton = SeagullWidgetStyles::MakeTextButton(WidgetTree, TEXT("Create Account"),
		SeagullColors::Teal, SeagullColors::LightText, SeagullWidgetStyles::TextFontSize, TEXT("RegisterButton"));
	SeagullWidgetStyles::AddRow(Column, RegisterButton);

	// Status line (auth errors etc.)
	StatusText = SeagullWidgetStyles::MakeText(WidgetTree, TEXT(""),
		SeagullWidgetStyles::SmallFontSize, SeagullColors::Orange, TEXT("StatusText"));
	StatusText->SetJustification(ETextJustify::Center);
	StatusText->SetAutoWrapText(true);
	SeagullWidgetStyles::AddRow(Column, StatusText, 12.f);

	// Footer
	UTextBlock* Footer = SeagullWidgetStyles::MakeText(WidgetTree, TEXT("horizon.pm"),
		SeagullWidgetStyles::SmallFontSize, FLinearColor::FromSRGBColor(FColor(0x66, 0x66, 0x66)));
	Footer->SetJustification(ETextJustify::Center);
	SeagullWidgetStyles::AddRow(Column, Footer, 4.f);
}

void USeagullTitleScreen::NativeConstruct()
{
	Super::NativeConstruct();

	if (PracticeButton) PracticeButton->OnClicked.AddDynamic(this, &USeagullTitleScreen::OnPracticeClicked);
	if (GuestButton) GuestButton->OnClicked.AddDynamic(this, &USeagullTitleScreen::OnGuestClicked);
	if (GoogleButton) GoogleButton->OnClicked.AddDynamic(this, &USeagullTitleScreen::OnGoogleClicked);
	if (AppleButton) AppleButton->OnClicked.AddDynamic(this, &USeagullTitleScreen::OnAppleClicked);
	if (EmailButton) EmailButton->OnClicked.AddDynamic(this, &USeagullTitleScreen::OnEmailClicked);
	if (RegisterButton) RegisterButton->OnClicked.AddDynamic(this, &USeagullTitleScreen::OnRegisterClicked);
}

void USeagullTitleScreen::OnGuestClicked()
{
	FString Name = NameInput ? NameInput->GetText().ToString() : TEXT("Player");
	if (Name.IsEmpty()) Name = TEXT("Player");

	USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
	if (!GI) return;

	USeagullHorizonManager* HM = GI->GetHorizonManager();
	if (!HM) return;
	if (HM->IsAuthenticating())
	{
		if (StatusText) StatusText->SetText(FText::FromString(TEXT("Authentication is already in progress. Offline practice remains available.")));
		return;
	}

	// Weak self: the title screen can be removed and GC'd (e.g. a concurrent
	// session restore switching to the Hub) before the HTTP response lands.
	TWeakObjectPtr<USeagullTitleScreen> WeakThis(this);
    // A chosen guest login may leave a registered email account; its credentials
    // remain recoverable. Anonymous or corrupt saved identities must be restored.
    const bool bRestore = HM->HasProtectedGuestIdentity();
    auto Complete = [WeakThis, bRestore](bool bSuccess)
	{
		USeagullTitleScreen* Screen = WeakThis.Get();
		if (!Screen || !Screen->IsInViewport()) return;
		if (bSuccess) Screen->OnAuthSuccess(!bRestore);
		else Screen->OnAuthFailure();
	};
    if (bRestore) HM->RestoreSession(Complete,true);
    else HM->SignUpAnonymous(Name, Complete);
}

void USeagullTitleScreen::OnGoogleClicked()
{
	// The SDK's SignInGoogle(GoogleAuthCode, RedirectUri, ...) requires a pre-obtained
	// OAuth authorization code and provides no code-acquisition/browser flow, so a
	// desktop example cannot complete it. Surface the limitation directly instead of
	// firing a network call that is guaranteed to fail server-side.
	if (StatusText)
	{
		StatusText->SetText(FText::FromString(TEXT("Google sign-in is not available on this platform")));
	}
	UE_LOG(LogSeagullStorm, Warning, TEXT("Google sign-in not available on this platform"));
}

void USeagullTitleScreen::OnAppleClicked()
{
	USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
	if (!GI) return;

	USeagullHorizonManager* HM = GI->GetHorizonManager();
	if (HM && HM->IsAuthenticating())
	{
		if (StatusText) StatusText->SetText(FText::FromString(TEXT("Authentication is already in progress.")));
		return;
	}
	if (HM)
	{
		// Drop-in Apple flow -- native sheet on iOS, no-op fallback on other platforms.
		// On non-iOS the SDK logs a warning and reports failure, which we surface to the user.
		TWeakObjectPtr<USeagullTitleScreen> WeakThis(this);
		HM->SignInWithApple(
			[WeakThis](bool bSuccess)
			{
				USeagullTitleScreen* Screen = WeakThis.Get();
				if (!Screen || !Screen->IsInViewport()) return;
				if (bSuccess)
				{
					Screen->OnAuthSuccess();
				}
				else
				{
					if (Screen->StatusText)
					{
						Screen->StatusText->SetText(FText::FromString(TEXT("Apple sign-in is not available on this platform")));
					}
					else
					{
						UE_LOG(LogSeagullStorm, Warning, TEXT("Apple sign-in not available on this platform"));
					}
				}
			});
	}
	else
	{
		if (StatusText)
		{
			StatusText->SetText(FText::FromString(TEXT("Apple sign-in is not available on this platform")));
		}
		else
		{
			UE_LOG(LogSeagullStorm, Warning, TEXT("Apple sign-in not available on this platform"));
		}
	}
}

void USeagullTitleScreen::OnEmailClicked()
{
	APlayerController* PC = UGameplayStatics::GetPlayerController(GetWorld(), 0);
	if (!PC) return;

	USeagullEmailAuthForm* Form = CreateWidget<USeagullEmailAuthForm>(PC);
	if (Form)
	{
		Form->bRegisterMode = false;
		Form->AddToViewport(100);
	}
}

void USeagullTitleScreen::OnRegisterClicked()
{
	APlayerController* PC = UGameplayStatics::GetPlayerController(GetWorld(), 0);
	if (!PC) return;

	USeagullEmailAuthForm* Form = CreateWidget<USeagullEmailAuthForm>(PC);
	if (Form)
	{
		Form->bRegisterMode = true;
		Form->AddToViewport(100);
	}
}

void USeagullTitleScreen::OnAuthSuccess(bool bKnownNewPlayer)
{
    if (USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()))) GI->BeginOnlineSession(bKnownNewPlayer);
	UE_LOG(LogSeagullStorm, Log, TEXT("Authentication successful"));

	ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(UGameplayStatics::GetGameMode(GetWorld()));
	if (GM)
	{
		GM->SwitchToScreen(ESeagullGameScreen::Hub);
	}
}

void USeagullTitleScreen::OnAuthFailure()
{
	// Surface the failure on screen -- with the placeholder API key the guest
	// path is the first thing that fails, and a silent title screen looks dead.
	if (StatusText)
	{
		StatusText->SetText(FText::FromString(TEXT("Sign-in failed. Check your API key and connection.")));
	}
	UE_LOG(LogSeagullStorm, Warning, TEXT("Authentication failed"));
}

void USeagullTitleScreen::OnPracticeClicked()
{
    USeagullGameInstance* GI = Cast<USeagullGameInstance>(UGameplayStatics::GetGameInstance(GetWorld()));
    if (!GI) return;
    GI->BeginPractice();
    ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(UGameplayStatics::GetGameMode(GetWorld()));
    if (GM) GM->SwitchToScreen(ESeagullGameScreen::Hub);
}
