// Fill out your copyright notice in the Description page of Project Settings.

#include "GGJ2017.h"
#include "PlayerPawn.h"


// Sets default values
APlayerPawn::APlayerPawn()
{
 	// Set this pawn to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	static ConstructorHelpers::FObjectFinder<UClass> PlayerProjectileClassFinder(TEXT("Blueprint'/Game/Blueprints/APlayerProjectile_BP.APlayerProjectile_BP_C'"));
	Projectile = PlayerProjectileClassFinder.Object;
}

// Called when the game starts or when spawned
void APlayerPawn::BeginPlay()
{
	Super::BeginPlay();
	
}

// Called every frame
void APlayerPawn::Tick( float DeltaTime )
{
	Super::Tick( DeltaTime );

	if (CurrentShootWindowTime < 0) {
		CurrentShootWindowTime = 0;
		CanShoot = false;
	}
	else if (CurrentShootWindowTime > 0) {
		CurrentShootWindowTime -= DeltaTime;
	}
}

void APlayerPawn::Shoot() {
	if (!CanShoot || Shielded)
		return;
	UE_LOG(LogTemp, Warning, TEXT("SHOOT"));
	this->SpawnProjectile();
	CanShoot = false;
}

void APlayerPawn::Shield() {
	Shielded = true;
	CanShoot = false;
	UE_LOG(LogTemp, Warning, TEXT("SHIELD"));
}

void APlayerPawn::ReleaseShield() {
	Shielded = false;
	CanShoot = true;
}

void APlayerPawn::SpawnProjectile() {
	
	FVector ProjectilePosition = ShootingOffset;
	APlayerCameraManager* camera = Cast<APlayerCameraManager>(UGameplayStatics::GetPlayerCameraManager(GetWorld(), 0));
	FRotator CameraRotator = camera->GetCameraRotation();
	FRotator ProjectileRotation = CameraRotator;
	FActorSpawnParameters SpawnInfo;
	if (Projectile != NULL)
		APlayerProjectile* projectile = GetWorld()->SpawnActor<APlayerProjectile>(Projectile, ProjectilePosition, ProjectileRotation, SpawnInfo);
	else
		UE_LOG(LogTemp, Warning, TEXT("Projectile not found"));

}

void APlayerPawn::OnLoseLife()
{
	if (LifePoints >= 0 && !Shielded)
		LifePoints--;
	else
		GameOver();
}

void APlayerPawn::GameOver() {
	UE_LOG(LogTemp, Warning, TEXT("GAME OVER"));
}

// Called to bind functionality to input
void APlayerPawn::SetupPlayerInputComponent(class UInputComponent* InputComponent)
{
	Super::SetupPlayerInputComponent(InputComponent);
}

void APlayerPawn::OnBeat() {
	UE_LOG(LogTemp, Warning, TEXT("BEAT"));
	CanShoot = true;
	CurrentShootWindowTime = ShootWindowTime;
}