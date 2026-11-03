// Copyright Epic Games, Inc. All Rights Reserved.

#include "StuckInsideCharacter.h"
#include "Animation/AnimInstance.h"
#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Net/UnrealNetwork.h"

DEFINE_LOG_CATEGORY_STATIC(LogFPChar, Warning, All);

//////////////////////////////////////////////////////////////////////////
// AStuckInsideCharacter

AStuckInsideCharacter::AStuckInsideCharacter()
{
	// Set size for collision capsule
	GetCapsuleComponent()->InitCapsuleSize(55.f, 96.0f);

	// set our turn rates for input
	BaseTurnRate = 45.f;
	BaseLookUpRate = 45.f;

	// Create a CameraComponent	
	FirstPersonCameraComponent = CreateDefaultSubobject<UCameraComponent>(TEXT("FirstPersonCamera"));
	FirstPersonCameraComponent->SetupAttachment(GetCapsuleComponent());
	FirstPersonCameraComponent->SetRelativeLocation(FVector(-39.56f, 1.75f, 64.f)); // Position the camera
	FirstPersonCameraComponent->bUsePawnControlRotation = true;
	FirstPersonCameraComponent->SetIsReplicated(true);

	// Create a mesh component that will be used when being viewed from a '1st person' view (when controlling this pawn)
	GlobalMesh = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("CharacterMesh1P"));
	GlobalMesh->SetOnlyOwnerSee(true);
	GlobalMesh->SetupAttachment(RootComponent);
	GlobalMesh->SetOwnerNoSee(true);

	Flashlight = CreateDefaultSubobject<USpotLightComponent>(TEXT("Flashlight"));
	Flashlight->Activate();
	Flashlight->SetIsReplicated(true);
	Flashlight->SetupAttachment(FirstPersonCameraComponent);
}

void AStuckInsideCharacter::BeginPlay()
{
	// Call the base class  
	Super::BeginPlay();
}

//////////////////////////////////////////////////////////////////////////
// Input

void AStuckInsideCharacter::onFlashlightToggle_Implementation()
{
	onFlashlightToggleBP();
}

void AStuckInsideCharacter::SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent)
{
	// set up gameplay key bindings
	check(PlayerInputComponent);

	// Bind jump events
	PlayerInputComponent->BindAction("Jump", IE_Pressed, this, &ACharacter::Jump);
	PlayerInputComponent->BindAction("Jump", IE_Released, this, &ACharacter::StopJumping);

	// Bind Other Events
	PlayerInputComponent->BindAction("Flashlight", IE_Pressed, this, &AStuckInsideCharacter::ToggleFlashlight);
	PlayerInputComponent->BindAction("Interact", IE_Pressed, this, &AStuckInsideCharacter::Interact);

	PlayerInputComponent->BindAction("Sprint", IE_Pressed, this, &AStuckInsideCharacter::startSprint);
	PlayerInputComponent->BindAction("Sprint", IE_Released, this, &AStuckInsideCharacter::endSprint);

	// Bind movement events
	PlayerInputComponent->BindAxis("MoveForward", this, &AStuckInsideCharacter::MoveForward);
	PlayerInputComponent->BindAxis("MoveRight", this, &AStuckInsideCharacter::MoveRight);

	// We have 2 versions of the rotation bindings to handle different kinds of devices differently
	// "turn" handles devices that provide an absolute delta, such as a mouse.
	// "turnrate" is for devices that we choose to treat as a rate of change, such as an analog joystick
	PlayerInputComponent->BindAxis("Turn", this, &APawn::AddControllerYawInput);
	PlayerInputComponent->BindAxis("TurnRate", this, &AStuckInsideCharacter::TurnAtRate);
	PlayerInputComponent->BindAxis("LookUp", this, &APawn::AddControllerPitchInput);
	PlayerInputComponent->BindAxis("LookUpRate", this, &AStuckInsideCharacter::LookUpAtRate);
}

void AStuckInsideCharacter::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	if(HasAuthority())
	{
		FVector StartPos = FirstPersonCameraComponent->GetComponentLocation();
		FVector EndPos = (FirstPersonCameraComponent->GetForwardVector() * InteractionRange) + StartPos;

		FCollisionQueryParams TraceParams(FName(TEXT("Interaction")),true,this);
		FHitResult Hit(ForceInit);
		GetWorld()->LineTraceSingleByChannel(Hit,StartPos,EndPos,ECC_GameTraceChannel1,TraceParams);
	
		Interactable = Cast<AInteractable>(Hit.GetActor());

		if(Interactable) InteractableText = Interactable->getToolTip();
		else InteractableText = "";

		//Sprinting
		if(Sprinting && canSprint)
		{
			GEngine->AddOnScreenDebugMessage(-1,0,FColor::Yellow,"Sprinting!");
			SprintCharge -= SprintChargeReduction * DeltaSeconds;
			if(SprintCharge <= 0) canSprint = false;
			GetCharacterMovement()->MaxWalkSpeed = SprintSpeed;
		}
		else
		{
			GEngine->AddOnScreenDebugMessage(-1,0,FColor::Red,"NOT Sprinting!");
			SprintCharge += SprintRecharge * DeltaSeconds;
			if(SprintCharge > 0.25) canSprint = true;
			GetCharacterMovement()->MaxWalkSpeed = WalkSpeed;
		}

		SprintCharge = FMath::Clamp(SprintCharge,0.f,1.f);
	}
}

//Commenting this section out to be consistent with FPS BP template.
//This allows the user to turn without using the right virtual joystick

//void AStuckInsideCharacter::TouchUpdate(const ETouchIndex::Type FingerIndex, const FVector Location)
//{
//	if ((TouchItem.bIsPressed == true) && (TouchItem.FingerIndex == FingerIndex))
//	{
//		if (TouchItem.bIsPressed)
//		{
//			if (GetWorld() != nullptr)
//			{
//				UGameViewportClient* ViewportClient = GetWorld()->GetGameViewport();
//				if (ViewportClient != nullptr)
//				{
//					FVector MoveDelta = Location - TouchItem.Location;
//					FVector2D ScreenSize;
//					ViewportClient->GetViewportSize(ScreenSize);
//					FVector2D ScaledDelta = FVector2D(MoveDelta.X, MoveDelta.Y) / ScreenSize;
//					if (FMath::Abs(ScaledDelta.X) >= 4.0 / ScreenSize.X)
//					{
//						TouchItem.bMoved = true;
//						float Value = ScaledDelta.X * BaseTurnRate;
//						AddControllerYawInput(Value);
//					}
//					if (FMath::Abs(ScaledDelta.Y) >= 4.0 / ScreenSize.Y)
//					{
//						TouchItem.bMoved = true;
//						float Value = ScaledDelta.Y * BaseTurnRate;
//						AddControllerPitchInput(Value);
//					}
//					TouchItem.Location = Location;
//				}
//				TouchItem.Location = Location;
//			}
//		}
//	}
//}

void AStuckInsideCharacter::MoveForward(float Value)
{
	if (Value != 0.0f)
	{
		// add movement in that direction
		AddMovementInput(GetActorForwardVector(), Value);
	}
}

void AStuckInsideCharacter::MoveRight(float Value)
{
	if (Value != 0.0f)
	{
		// add movement in that direction
		AddMovementInput(GetActorRightVector(), Value);
	}
}

void AStuckInsideCharacter::startSprint_Implementation()
{
	Sprinting = true;
}

void AStuckInsideCharacter::endSprint_Implementation()
{
	Sprinting = false;
}

void AStuckInsideCharacter::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	DOREPLIFETIME(AStuckInsideCharacter,SprintCharge);
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
}

void AStuckInsideCharacter::TurnAtRate(float Rate)
{
	// calculate delta for this frame from the rate information
	AddControllerYawInput(Rate * BaseTurnRate * GetWorld()->GetDeltaSeconds());
}

void AStuckInsideCharacter::LookUpAtRate(float Rate)
{
	// calculate delta for this frame from the rate information
	AddControllerPitchInput(Rate * BaseLookUpRate * GetWorld()->GetDeltaSeconds());
}

void AStuckInsideCharacter::Interact_Implementation()
{
	if(Interactable != nullptr)
	{
		Interactable->Interact(this);
	}
}

void AStuckInsideCharacter::ToggleFlashlight_Implementation()
{
	GEngine->AddOnScreenDebugMessage(-1,1,FColor::Red,"Toggling Flashlight!");
	Flashlight->SetVisibility(!Flashlight->IsVisible());
	onFlashlightToggle();
}
