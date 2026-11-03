// Fill out your copyright notice in the Description page of Project Settings.


#include "Demon.h"

#include "Door.h"
#include "StuckInsideCharacter.h"
#include "StuckInsideGameMode.h"
#include "WindowShutters.h"
#include "Animation/AnimInstance.h"
#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Components/AudioComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Net/UnrealNetwork.h"

// Sets default values
ADemon::ADemon()
{
 	// Set this character to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
	bReplicates = true;

	GetMovementComponent()->SetIsReplicated(true);

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

	ChaseSound = CreateDefaultSubobject<UAudioComponent>(TEXT("ChaseSound"));
	ChaseSound->SetupAttachment(FirstPersonCameraComponent);
	ChaseSound->SetIsReplicated(true);

	// Create a mesh component that will be used when being viewed from a '1st person' view (when controlling this pawn)
	GlobalMesh = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("CharacterMesh1P"));
	GlobalMesh->SetOnlyOwnerSee(true);
	GlobalMesh->SetupAttachment(RootComponent);
	GlobalMesh->SetOwnerNoSee(true);

	BiteHitbox = CreateDefaultSubobject<UBoxComponent>(TEXT("BiteHitbox"));
	BiteHitbox->SetupAttachment(RootComponent);
}

// Called when the game starts or when spawned
void ADemon::BeginPlay()
{
	if(HasAuthority())
	{
		SpawnLoc = GetActorLocation();
		cChaseTime = ChaseTime;
	}
	Super::BeginPlay();
	
}

void ADemon::SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent)
{
	// set up gameplay key bindings
	check(PlayerInputComponent);

	PlayerInputComponent->BindAction("Interact", IE_Pressed, this, &ADemon::Bite);

	// Bind movement events
	PlayerInputComponent->BindAxis("MoveForward", this, &ADemon::MoveForward);
	PlayerInputComponent->BindAxis("MoveRight", this, &ADemon::MoveRight);

	// We have 2 versions of the rotation bindings to handle different kinds of devices differently
	// "turn" handles devices that provide an absolute delta, such as a mouse.
	// "turnrate" is for devices that we choose to treat as a rate of change, such as an analog joystick
	PlayerInputComponent->BindAxis("Turn", this, &APawn::AddControllerYawInput);
	PlayerInputComponent->BindAxis("TurnRate", this, &ADemon::TurnAtRate);
	PlayerInputComponent->BindAxis("LookUp", this, &APawn::AddControllerPitchInput);
	PlayerInputComponent->BindAxis("LookUpRate", this, &ADemon::LookUpAtRate);
	
	Super::SetupPlayerInputComponent(PlayerInputComponent);
}

// Called every frame
void ADemon::Tick(float DeltaTime)
{
	if(HasAuthority())
	{
		BiteCD -= DeltaTime;

		if(EnteringBuilding)
		{
			GEngine->AddOnScreenDebugMessage(-1,0,FColor::Blue,"Enter Building @ " +
				FString::SanitizeFloat(FMath::RoundToZero((TimeEntering/EnterTime) * 100 )) + "%");
			GEngine->AddOnScreenDebugMessage(-1,0,FColor::Blue,"A: " + StartPos.ToString() + "\nB: " + EndPos.ToString());
			
			SetActorLocation(
				FMath::Lerp(StartPos,EndPos,TimeEntering/EnterTime)
			);
			setLocation(FMath::Lerp(StartPos,EndPos,TimeEntering/EnterTime));

			//Check If Window Is Closed
			if(WindowEntering && !WindowEntering->getIsOpened())
			{
				//Window Is Closed
				StopChase();
				for(ADoor* Door : DoorsChewed)
				{
					UStaticMeshComponent* DoorMesh = Door->GetDoor();
					DoorMesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
					DoorMesh->SetVisibility(true);
				}
				DoorsChewed = TArray<ADoor*>();
				onDemonDisapear();
				isOutside = true;
				onEnterExit(isOutside);
				PlayDoorClosedSFX();
				SetActorLocation(SpawnLoc);
				//setLocation(SpawnLoc);
				cChaseTime = ChaseTime;
				EnteringBuilding = false;
				GetMovementComponent()->Activate();
				bUseControllerRotationYaw = true;
			}

			if(TimeEntering/EnterTime >= 1)
			{
				//Has Entered The Building
				isOutside = false;
				onEnterExit(isOutside);
				EnteringBuilding = false;

				//Play Chase SFX
				GetMovementComponent()->Activate();
				SetActorLocation(EndPos);
				PlayChase();
				cChaseTime = ChaseTime;
				bUseControllerRotationYaw = true;
				BiteCount = 3;
			}

			TimeEntering = FMath::Clamp(TimeEntering + DeltaTime,0.f,EnterTime);
		}

		if(!isOutside)
		{
			cChaseTime -= DeltaTime;
			if(cChaseTime <= 0)
			{
				StopChase();
				for(ADoor* Door : DoorsChewed)
				{
					UStaticMeshComponent* DoorMesh = Door->GetDoor();
					DoorMesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
					DoorMesh->SetVisibility(true);
				}
				DoorsChewed = TArray<ADoor*>();
				onDemonDisapear();
				isOutside = true;
				onEnterExit(isOutside);
				SetActorLocation(SpawnLoc);
				cChaseTime = ChaseTime;
			}
		}
	}
	Super::Tick(DeltaTime);

}

void ADemon::PlayEnterSFX_Implementation()
{
	UGameplayStatics::PlaySoundAtLocation(GetWorld(),EnterSFX,GetActorLocation());
}

void ADemon::PlayDoorClosedSFX_Implementation()
{
	UGameplayStatics::PlaySoundAtLocation(GetWorld(),DoorCloseSFX,GetActorLocation());
}

void ADemon::PlayChase_Implementation()
{
	ChaseSound->Play();
}

void ADemon::StopChase_Implementation()
{
	ChaseSound->Stop();
}

void ADemon::PlayKillEffects_Implementation(FVector KillLoc)
{
	UNiagaraFunctionLibrary::SpawnSystemAtLocation(
		GetWorld(),
		HumanDeathVFX,
		KillLoc);
}

void ADemon::onDemonDisapear_Implementation()
{
	UNiagaraFunctionLibrary::SpawnSystemAtLocation(
	GetWorld(),
	DisapearVFX,
	GetActorLocation());
}

void ADemon::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	DOREPLIFETIME(ADemon,BiteCD);
	DOREPLIFETIME(ADemon,BiteCount);
	DOREPLIFETIME(ADemon,cChaseTime);
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
}

void ADemon::setRotation_Implementation(FRotator newRotation)
{
	SetActorRotation(newRotation);
}

void ADemon::setLocation_Implementation(FVector newLocaiton)
{
	SetActorLocation(newLocaiton);
}

void ADemon::BiteAnimationPlayAll_Implementation()
{
	PlayAnimMontage(BiteAnimation);
	UGameplayStatics::PlaySoundAtLocation(GetWorld(),BiteSFX,GetActorLocation());
}

void ADemon::Bite_Implementation()
{
	if(isOutside)
	{
		//Enter Building If Looking At Window
		FVector SPos = FirstPersonCameraComponent->GetComponentLocation();
		FVector EPos = (FirstPersonCameraComponent->GetForwardVector() * 250) + SPos;

		FCollisionQueryParams TraceParams(FName(TEXT("Interaction")),true,this);
		FHitResult Hit(ForceInit);
		GetWorld()->LineTraceSingleByChannel(Hit,SPos,EPos,ECC_GameTraceChannel1,TraceParams);
	
		AWindowShutters* WindowShutter = Cast<AWindowShutters>(Hit.GetActor());
		if(WindowShutter)
		{
			GEngine->AddOnScreenDebugMessage(-1,5,FColor::Blue,"ENTERING BUILDING!");
			WindowEntering = WindowShutter;
			StartPos = WindowShutter->Outside->GetComponentLocation();
			EndPos = WindowShutter->Inside->GetComponentLocation();
			TimeEntering = 0;
			PlayEnterSFX();
			EnteringBuilding = true;
			GetMovementComponent()->Deactivate();
			bUseControllerRotationYaw = false;
			SetActorRotation(WindowShutter->Outside->GetComponentRotation());
			setRotation(WindowShutter->Outside->GetComponentRotation());
		}
	}
	else if(BiteCD <= 0 && BiteCount > 0)
	{
		BiteCount -= 1;
		BiteCD = BiteCooldownPerBite;
		BiteAnimationPlayAll();
		
		//Bite With Animation Playing
		TArray<AActor*> ActorsHit;
		BiteHitbox->GetOverlappingActors(ActorsHit);

		for(AActor* Actor : ActorsHit)
		{
			ADoor* DoorObject = Cast<ADoor>(Actor);
			AStuckInsideCharacter* HumanObject = Cast<AStuckInsideCharacter>(Actor);

			if(DoorObject)
			{
				UStaticMeshComponent* DoorMesh = DoorObject->GetDoor();
				DoorMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
				DoorMesh->SetVisibility(false);
				DoorsChewed.Add(DoorObject);
				break;
			}

			if(HumanObject)
			{
				//Kill Human
				AStuckInsideGameMode* GM = Cast<AStuckInsideGameMode>(GetWorld()->GetAuthGameMode());
				if(GM)
				{
					GEngine->AddOnScreenDebugMessage(-1,12,FColor::Red,HumanObject->GetName() + " HAS DIED!");
					PlayKillEffects(HumanObject->GetActorLocation());
					GM->KillPlayer(HumanObject);
					
					//Disapear Back To Spawn
					SetActorLocation(SpawnLoc);
					StopChase();
					for(ADoor* Door : DoorsChewed)
					{
						UStaticMeshComponent* DoorMesh = Door->GetDoor();
						DoorMesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
						DoorMesh->SetVisibility(true);
					}
					onDemonDisapear();
					isOutside = true;
					onEnterExit(isOutside);
					SetActorLocation(SpawnLoc);
					cChaseTime = ChaseTime;
					break;
				}
			}
		}

		if(BiteCount <= 0) {
			StopChase();
			onDemonDisapear();
			isOutside = true;
			onEnterExit(isOutside);
			SetActorLocation(SpawnLoc);
			cChaseTime = ChaseTime;

		}
	}
}


void ADemon::MoveForward(float Value)
{
	if (Value != 0.0f)
	{
		// add movement in that direction
		AddMovementInput(GetActorForwardVector(), Value);
	}
}

void ADemon::MoveRight(float Value)
{
	if (Value != 0.0f)
	{
		// add movement in that direction
		AddMovementInput(GetActorRightVector(), Value);
	}
}

void ADemon::TurnAtRate(float Rate)
{
	// calculate delta for this frame from the rate information
	AddControllerYawInput(Rate * BaseTurnRate * GetWorld()->GetDeltaSeconds());
}

void ADemon::onEnterExit_Implementation(bool EnteredExited)
{
	EventEnterExit(EnteredExited);
}

void ADemon::LookUpAtRate(float Rate)
{
	// calculate delta for this frame from the rate information
	AddControllerPitchInput(Rate * BaseLookUpRate * GetWorld()->GetDeltaSeconds());
}
