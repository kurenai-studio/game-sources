#include "Core/SeagullPlayerController.h"
#include "Core/SeagullStormGameMode.h"
#include "UI/SeagullTitleScreen.h"
#include "UI/SeagullMainHub.h"
#include "UI/SeagullHUD.h"
#include "UI/SeagullGameOverScreen.h"
#include "UI/SeagullPauseMenu.h"
#include "UI/SeagullLevelUpOverlay.h"
#include "Blueprint/WidgetLayoutLibrary.h"
#include "EnhancedInputComponent.h"
#include "EnhancedInputSubsystems.h"
#include "InputMappingContext.h"
#include "InputAction.h"
#include "InputModifiers.h"
#include "InputActionValue.h"
#include "SeagullStorm.h"

ASeagullPlayerController::ASeagullPlayerController()
{
	bShowMouseCursor = true;
	bEnableClickEvents = true;
	bEnableMouseOverEvents = true;
}

void ASeagullPlayerController::BeginPlay()
{
	Super::BeginPlay();

	// Create input actions programmatically
	MoveAction = NewObject<UInputAction>(this);
	MoveAction->ValueType = EInputActionValueType::Axis2D;
	MoveAction->AccumulationBehavior = EInputActionAccumulationBehavior::Cumulative;

	PauseAction = NewObject<UInputAction>(this);
	PauseAction->ValueType = EInputActionValueType::Boolean;

	// Create and register mapping context
	InputMappingContext = NewObject<UInputMappingContext>(this);

	// WASD bindings
	FEnhancedActionKeyMapping& MoveUpMap = InputMappingContext->MapKey(MoveAction, EKeys::W);
	UInputModifierSwizzleAxis* SwizzleUp = NewObject<UInputModifierSwizzleAxis>(this);
	SwizzleUp->Order = EInputAxisSwizzle::YXZ;
	MoveUpMap.Modifiers.Add(SwizzleUp);

	FEnhancedActionKeyMapping& MoveDownMap = InputMappingContext->MapKey(MoveAction, EKeys::S);
	UInputModifierSwizzleAxis* SwizzleDown = NewObject<UInputModifierSwizzleAxis>(this);
	SwizzleDown->Order = EInputAxisSwizzle::YXZ;
	MoveDownMap.Modifiers.Add(SwizzleDown);
	UInputModifierNegate* NegateDown = NewObject<UInputModifierNegate>(this);
	MoveDownMap.Modifiers.Add(NegateDown);

	InputMappingContext->MapKey(MoveAction, EKeys::D);

	FEnhancedActionKeyMapping& MoveLeftMap = InputMappingContext->MapKey(MoveAction, EKeys::A);
	UInputModifierNegate* NegateLeft = NewObject<UInputModifierNegate>(this);
	MoveLeftMap.Modifiers.Add(NegateLeft);

	FEnhancedActionKeyMapping& ArrowUp = InputMappingContext->MapKey(MoveAction, EKeys::Up);
    ArrowUp.Modifiers.Add(SwizzleUp);
    FEnhancedActionKeyMapping& ArrowDown = InputMappingContext->MapKey(MoveAction, EKeys::Down);
    ArrowDown.Modifiers.Add(SwizzleDown);
    ArrowDown.Modifiers.Add(NegateDown);
    InputMappingContext->MapKey(MoveAction, EKeys::Right);
    FEnhancedActionKeyMapping& ArrowLeft = InputMappingContext->MapKey(MoveAction, EKeys::Left);
    ArrowLeft.Modifiers.Add(NegateLeft);

    // Escape for pause
	InputMappingContext->MapKey(PauseAction, EKeys::Escape);

	// Gamepad left-stick binding
	InputMappingContext->MapKey(MoveAction, EKeys::Gamepad_LeftX);

	FEnhancedActionKeyMapping& StickYMap = InputMappingContext->MapKey(MoveAction, EKeys::Gamepad_LeftY);
	UInputModifierSwizzleAxis* SwizzleStickY = NewObject<UInputModifierSwizzleAxis>(this);
	SwizzleStickY->Order = EInputAxisSwizzle::YXZ;
	StickYMap.Modifiers.Add(SwizzleStickY);

	// Gamepad Start button for pause
	InputMappingContext->MapKey(PauseAction, EKeys::Gamepad_Special_Right);

	// Register
	UEnhancedInputLocalPlayerSubsystem* EIS = ULocalPlayer::GetSubsystem<UEnhancedInputLocalPlayerSubsystem>(GetLocalPlayer());
	if (EIS)
	{
		EIS->AddMappingContext(InputMappingContext, 0);
	}

	// Bind here, NOT in SetupInputComponent(): for the initial player controller
	// SetupInputComponent() runs during login (before World BeginPlay dispatches
	// actor BeginPlay), i.e. before the actions above exist. InputComponent is
	// already valid at this point.
	UEnhancedInputComponent* EIC = Cast<UEnhancedInputComponent>(InputComponent);
	if (EIC)
	{
		EIC->BindAction(MoveAction, ETriggerEvent::Triggered, this, &ASeagullPlayerController::OnMoveInput);
		EIC->BindAction(MoveAction, ETriggerEvent::Completed, this, &ASeagullPlayerController::OnMoveInput);
		EIC->BindAction(MoveAction, ETriggerEvent::Canceled, this, &ASeagullPlayerController::OnMoveInput);
		EIC->BindAction(PauseAction, ETriggerEvent::Started, this, &ASeagullPlayerController::OnPauseInput);
	}
}

void ASeagullPlayerController::OnMoveInput(const FInputActionValue& Value)
{
	CachedMoveInput = Value.Get<FVector2D>();
}

void ASeagullPlayerController::OnPauseInput()
{
	ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(GetWorld()->GetAuthGameMode());
	if (GM && GM->GetCurrentScreen() == ESeagullGameScreen::Run)
	{
		TogglePause();
	}
}

void ASeagullPlayerController::OnScreenChanged(ESeagullGameScreen NewScreen)
{
	SetPause(false);
	CachedMoveInput = FVector2D::ZeroVector;
	ClearAllWidgets();

	switch (NewScreen)
	{
		case ESeagullGameScreen::Title:
			TitleWidget = CreateWidget<USeagullTitleScreen>(this);
			if (TitleWidget) TitleWidget->AddToViewport();
			SetInputMode(FInputModeUIOnly());
			break;

		case ESeagullGameScreen::Hub:
			HubWidget = CreateWidget<USeagullMainHub>(this);
			if (HubWidget) HubWidget->AddToViewport();
			SetInputMode(FInputModeUIOnly());
			break;

		case ESeagullGameScreen::Run:
			HUDWidget = CreateWidget<USeagullHUD>(this);
			if (HUDWidget) HUDWidget->AddToViewport();
			SetInputMode(FInputModeGameAndUI().SetHideCursorDuringCapture(false));
			break;

		case ESeagullGameScreen::GameOver:
			GameOverWidget = CreateWidget<USeagullGameOverScreen>(this);
			if (GameOverWidget)
			{
				GameOverWidget->AddToViewport();
				// Cache on GameMode for async rank update
				ASeagullStormGameMode* GM = Cast<ASeagullStormGameMode>(GetWorld()->GetAuthGameMode());
				if (GM) GM->CachedGameOverWidget = GameOverWidget;
			}
			SetInputMode(FInputModeUIOnly());
			break;
	}
}

void ASeagullPlayerController::ShowLevelUpOverlay(const TArray<FSeagullLevelUpChoice>& Choices)
{
	if (!LevelUpWidget)
	{
		LevelUpWidget = CreateWidget<USeagullLevelUpOverlay>(this);
	}
	if (LevelUpWidget)
	{
		LevelUpWidget->SetChoices(Choices);
		LevelUpWidget->AddToViewport(100);
		SetPause(true);
		SetInputMode(FInputModeUIOnly());
	}
}

void ASeagullPlayerController::HideLevelUpOverlay()
{
	if (LevelUpWidget)
	{
		LevelUpWidget->RemoveFromParent();
	}
	SetPause(false);
	CachedMoveInput = FVector2D::ZeroVector;
	SetInputMode(FInputModeGameAndUI());
}

void ASeagullPlayerController::TogglePause()
{
	bIsPaused = !bIsPaused;

	if (bIsPaused)
	{
		PauseWidget = CreateWidget<USeagullPauseMenu>(this);
		if (PauseWidget) PauseWidget->AddToViewport(100);
		SetPause(true);
		SetInputMode(FInputModeUIOnly());
	}
	else
	{
		if (PauseWidget)
		{
			PauseWidget->RemoveFromParent();
			PauseWidget = nullptr;
		}
		SetPause(false);
		CachedMoveInput = FVector2D::ZeroVector;
		SetInputMode(FInputModeGameAndUI());
	}
}

void ASeagullPlayerController::RefreshHubDisplay()
{
	if (HubWidget)
	{
		HubWidget->RefreshDisplay();
	}
}

void ASeagullPlayerController::ClearAllWidgets()
{
	// Removes every viewport widget: the six tracked screen widgets AND the
	// ad-hoc modals (Settings/GiftCode/Feedback/EmailAuth/News) that are added
	// directly via AddToViewport and would otherwise survive a screen switch
	// (e.g. quitting a run with the news panel open).
	UWidgetLayoutLibrary::RemoveAllWidgets(this);
	TitleWidget = nullptr;
	HubWidget = nullptr;
	HUDWidget = nullptr;
	GameOverWidget = nullptr;
	PauseWidget = nullptr;
	LevelUpWidget = nullptr;
	bIsPaused = false;
}
