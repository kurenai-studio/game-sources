#include "UnrealEngineLearning/Player/PlayerCharater.h"

#include "Camera/CameraComponent.h"
#include "UnrealEngineLearning/Guns/Gun.h"

// Sets default values
APlayerCharater::APlayerCharater()
{
 	// Set this character to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	// Camera
	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(RootComponent);
	Camera->bUsePawnControlRotation = false;

	// Weapon socket attaches to camera
	WeaponSocket = CreateDefaultSubobject<USceneComponent>(TEXT("WeaponSocket"));
	WeaponSocket->SetupAttachment(Camera);
}

// Called when the game starts or when spawned
void APlayerCharater::BeginPlay()
{
	Super::BeginPlay();

	EquipWeapon(0); //try's to equip the first weapon in the array
}

void APlayerCharater::ScrollWeapon(float Input)
{
	if (FMath::IsNearlyZero(Input)) return;

	int32 Direction = (Input > 0) ? 1 : -1;
	int32 WeaponCount = WeaponClasses.Num();

	if (WeaponCount == 0) return;

	int32 NextIndex = (CurrentWeaponIndex + Direction + WeaponCount) % WeaponCount;
	EquipWeapon(NextIndex);
}

void APlayerCharater::EquipWeapon(int32 Index)
{
	if (CurrentWeapon)
	{
		CurrentWeapon->Destroy();
		CurrentWeapon = nullptr;
	}

	if (!WeaponClasses.IsValidIndex(Index)) return;

	CurrentWeapon = GetWorld()->SpawnActor<AGun>(WeaponClasses[Index]);
	if (CurrentWeapon)
	{
		CurrentWeapon->AttachToComponent(WeaponSocket, FAttachmentTransformRules::SnapToTargetNotIncludingScale);
		CurrentWeapon->SetOwner(this);
		CurrentWeaponIndex = Index;
	}
}

// Called every frame
void APlayerCharater::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	IsMoving = InputVector.Length() > 0;

	// Compute target roll
	float TargetRoll = FMath::Clamp(InputVector.X * CameraTiltAmount, -CameraTiltAmount, CameraTiltSmoothTiming);

	// Interpolate roll manually
	float SmoothedRoll = FMath::FInterpTo(CurrentRoll, TargetRoll, DeltaTime, CameraTiltSmoothTiming);
	CurrentRoll = SmoothedRoll;

	// Build a full rotation from controller + roll
	FRotator ControlRotation = GetControlRotation();
	FRotator FinalRotation(ControlRotation.Pitch, ControlRotation.Yaw, SmoothedRoll);

	Camera->SetWorldRotation(FinalRotation);
}

void APlayerCharater::BeginFiring() 
{
	CurrentWeapon->BeginFiring();
}

void APlayerCharater::EndFiring()
{
	CurrentWeapon->EndFiring();
}

// Called to bind functionality to input
void APlayerCharater::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	PlayerInputComponent->BindAction("Jump", IE_Pressed, this, &ACharacter::Jump);
	PlayerInputComponent->BindAxis("MoveForward", this, &APlayerCharater::MoveForward);
	PlayerInputComponent->BindAxis("MoveRight", this, &APlayerCharater::MoveRight);
	PlayerInputComponent->BindAxis("LookUp", this, &APlayerCharater::LookUp);
	PlayerInputComponent->BindAxis("LookRight", this, &APlayerCharater::LookRight);

	PlayerInputComponent->BindAction("Fire", IE_Pressed, this, &APlayerCharater::BeginFiring);
	PlayerInputComponent->BindAction("Fire", IE_Released, this, &APlayerCharater::EndFiring);
	PlayerInputComponent->BindAxis("ScrollWeapon", this, &APlayerCharater::ScrollWeapon);

}

void APlayerCharater::ApplyDamage(float DamageAmount)
{
	Health -= DamageAmount;
	if (Health <= 0.0f)
	{
		UE_LOG(LogTemp, Log, TEXT("Player is dead"));
		//Destroy();
	}
}

float APlayerCharater::GetHealth() const
{
	return Health;
}

void APlayerCharater::SetHealth(float NewHealth)
{
	Health = NewHealth;
}

void APlayerCharater::MoveForward(float Input)
{
	FVector ForwardDirection = GetActorForwardVector();
	AddMovementInput(ForwardDirection, Input);

	InputVector.Y = Input;
}

void APlayerCharater::MoveRight(float Input)
{
	FVector RightDirection = GetActorRightVector();
	AddMovementInput(RightDirection, Input);

	InputVector.X = Input;
}

void APlayerCharater::LookUp(float Input)
{
	AddControllerPitchInput(Input);
}

void APlayerCharater::LookRight(float Input)
{
	AddControllerYawInput(Input);
}