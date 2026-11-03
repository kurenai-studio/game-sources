#include "Tank.h"
#include "Camera/CameraComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "Kismet/GameplayStatics.h"

ATank::ATank()
{
    SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("Spring Arm"));
    SpringArm->SetupAttachment(RootComponent);
    Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
    Camera-> SetupAttachment(SpringArm); 
}

void ATank::BeginPlay()
{
    Super::BeginPlay();
    TankPlayerController = Cast<APlayerController>(GetController());
}

void ATank::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
    Rotate();
}

void ATank::HandleDestruction()
{
    Super::HandleDestruction();
    SetActorHiddenInGame(true);
    SetActorTickEnabled(false);
    bAlive = false;
}

void ATank::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);
    PlayerInputComponent->BindAxis(TEXT("MoveForward") , this , &ATank::Move);
    PlayerInputComponent->BindAxis(TEXT("Turn") , this , &ATank::Turn);
    PlayerInputComponent->BindAction(TEXT("Fire") , IE_Pressed , this , &ATank::Fire);
}

void ATank::Move(float Value)
{
    
    DeltaLocation = FVector::ZeroVector;
    DeltaLocation.X = Value*MovementSpeed*(UGameplayStatics::GetWorldDeltaSeconds(this));
    AddActorLocalOffset(DeltaLocation , true);
    
    // DeltaLocation = DeltaLocation*MovementSpeed*(UGameplayStatics::GetWorldDeltaSeconds(this));
    // AddActorLocalOffset(DeltaLocation , true);
}

void ATank::Turn(float Value)
{
    DeltaRotation = FRotator::ZeroRotator;
    DeltaRotation.Yaw = Value*RotationSpeed*(UGameplayStatics::GetWorldDeltaSeconds(this));
    AddActorLocalRotation(DeltaRotation , true);

    // DeltaRotation = DeltaRotation*RotationSpeed*(UGameplayStatics::GetWorldDeltaSeconds(this));
    // AddActorLocalRotation(DeltaRotation , true);
}

void ATank::Rotate()
{
    if(TankPlayerController)
    {
        FHitResult HitResult;
        TankPlayerController->GetHitResultUnderCursor(ECollisionChannel::ECC_Visibility , false , HitResult);
        RotateTurret(HitResult.ImpactPoint);
    }
}

