// Fill out your copyright notice in the Description page of Project Settings.


#include "SuperSoldier/Characters/SuperSoldierCharacter.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "Components/CapsuleComponent.h"
#include "SuperSoldier/Weapons/GunBase.h"
#include "SuperSoldier/SuperSoldierGameModeBase.h"

// Sets default values
ASuperSoldierCharacter::ASuperSoldierCharacter()
{
 	// Set this character to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = false;
	InitializeComponents();
}

// Called when the game starts or when spawned
void ASuperSoldierCharacter::BeginPlay()
{
	Super::BeginPlay();
	InitializeGuns();
	InitializeCharacterStats();
	if (DefaultGunIndex == 2) SwitchWeapon3();
	else if(DefaultGunIndex == 1) SwitchWeapon2();
	else SwitchWeapon1();
}

// Called every frame
void ASuperSoldierCharacter::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

// Called to bind functionality to input
void ASuperSoldierCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	if (!PlayerInputComponent)
	{
		UE_LOG(LogTemp, Error, TEXT("Player Input Component Is Missing On %s"), *(GetOwner()->GetName()));
		return;
	}

	// Movement
	PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &ASuperSoldierCharacter::MoveForward);
	PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &ASuperSoldierCharacter::MoveRight);
	PlayerInputComponent->BindAxis(TEXT("LookUp"), this, &APawn::AddControllerPitchInput);
	PlayerInputComponent->BindAxis(TEXT("LookRight"), this, &APawn::AddControllerYawInput);

	// Action
	PlayerInputComponent->BindAction(TEXT("Jump"), EInputEvent::IE_Pressed, this, &ACharacter::Jump);
	PlayerInputComponent->BindAction(TEXT("Shoot"), EInputEvent::IE_Pressed, this, &ASuperSoldierCharacter::Shoot);
	PlayerInputComponent->BindAction(TEXT("SwitchWeapon1"), EInputEvent::IE_Pressed, this, &ASuperSoldierCharacter::SwitchWeapon1);
	PlayerInputComponent->BindAction(TEXT("SwitchWeapon2"), EInputEvent::IE_Pressed, this, &ASuperSoldierCharacter::SwitchWeapon2);
	PlayerInputComponent->BindAction(TEXT("SwitchWeapon3"), EInputEvent::IE_Pressed, this, &ASuperSoldierCharacter::SwitchWeapon3);
	
}

void ASuperSoldierCharacter::Shoot() 
{
	Guns[IndexOfCurrentGun]->PullTrigger();
}

float ASuperSoldierCharacter::TakeDamage(float DamageAmount, struct FDamageEvent const & DamageEvent, class AController* EventInstigator, AActor* DamageCauser) 
{
	float DamageToApply = FMath::Max(DamageAmount - Armor, 1.f); 
	DamageToApply = Super::TakeDamage(DamageToApply, DamageEvent, EventInstigator, DamageCauser);
	Health = FMath::Clamp(Health - DamageToApply, 0.f, MaxHealth);
	Armor = FMath::Clamp(Armor - 1.f, 0.f, MaxArmor);
	if (IsDead())
	{
		ASuperSoldierGameModeBase* CurrentGameMode = GetWorld()->GetAuthGameMode<ASuperSoldierGameModeBase>();
		if (CurrentGameMode)
		{
			CurrentGameMode->PawnKilled(this);
		}
		DetachFromControllerPendingDestroy();
		if (GetCapsuleComponent())
		{
			GetCapsuleComponent()->SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
	}
	return DamageToApply;
}

bool ASuperSoldierCharacter::IsDead() const
{
	return Health <= 0.f;
}

float ASuperSoldierCharacter::GetHealthPercent() const
{
	return Health / MaxHealth;
}

float ASuperSoldierCharacter::GetArmorPercent() const
{
	return Armor / MaxArmor;
}

float ASuperSoldierCharacter::GetArmor() const
{
	return Armor;
}

void ASuperSoldierCharacter::InitializeComponents() 
{
	SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("Spring Arm"));
	SpringArm->SetupAttachment(RootComponent);
	SpringArm->bUsePawnControlRotation = true;

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(SpringArm);
}


void ASuperSoldierCharacter::InitializeGuns() 
{
	if (GunClasses.Num() > 0)
	{
		int32 Len = FMath::Min(GunClasses.Num(), 3);
		for (int32 Index = 0; Index < Len; Index++)
		{
			AGunBase* Gun = GetWorld()->SpawnActor<AGunBase>(GunClasses[Index]);
			Gun->SetActualMesh(this);
			AttachGunToPlayer(Gun);
			HideOrShowGun(Index, true);
		}
	}
	IndexOfCurrentGun = DefaultGunIndex;
}

void ASuperSoldierCharacter::InitializeCharacterStats() 
{
	Health = MaxHealth;
	Armor = MaxArmor;
}

void ASuperSoldierCharacter::MoveForward(float AxisValue) 
{
	AddMovementInput(GetActorForwardVector() * AxisValue);
}

void ASuperSoldierCharacter::MoveRight(float AxisValue) 
{
	AddMovementInput(GetActorRightVector() * AxisValue);
}

void ASuperSoldierCharacter::SwitchWeapon1() 
{
	if (IndexOfCurrentGun == 0) return;
	HideOrShowGun(IndexOfCurrentGun, true);
	IndexOfCurrentGun = 0;
	ShowOriginGunMesh();
}

void ASuperSoldierCharacter::SwitchWeapon2() 
{
	if (IndexOfCurrentGun == 1) return;
	if (IndexOfCurrentGun == 0)
	{
		HideOriginGunMesh();
	}
	else 
	{
		HideOrShowGun(IndexOfCurrentGun, true);
	}
	IndexOfCurrentGun = 1;
	HideOrShowGun(IndexOfCurrentGun, false);
}

void ASuperSoldierCharacter::SwitchWeapon3() 
{
	if (IndexOfCurrentGun == 2) return;
	if (IndexOfCurrentGun == 0)
	{
		HideOriginGunMesh();
	}
	else 
	{
		HideOrShowGun(IndexOfCurrentGun, true);
	}
	IndexOfCurrentGun = 2;
	HideOrShowGun(IndexOfCurrentGun, false);
}

void ASuperSoldierCharacter::AttachGunToPlayer(class AGunBase* Gun) 
{
	Gun->AttachToComponent(GetMesh(), FAttachmentTransformRules::KeepRelativeTransform, FName(*GunAttachedBoneName));
	Gun->SetOwner(this);
	Guns.Add(Gun);
}

void ASuperSoldierCharacter::HideOriginGunMesh() 
{
	GetMesh()->HideBoneByName(FName(*GunAttachedBoneName), EPhysBodyOp::PBO_None);
}

void ASuperSoldierCharacter::ShowOriginGunMesh() 
{
	GetMesh()->UnHideBoneByName(FName(*GunAttachedBoneName));
}

void ASuperSoldierCharacter::HideOrShowGun(int32 IndexOfGun, bool ToHide) 
{
	Guns[IndexOfGun]->SetActorHiddenInGame(ToHide);
}
