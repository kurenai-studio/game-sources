// Fill out your copyright notice in the Description page of Project Settings.


#include "Door.h"
#include "StuckInsideCharacter.h"
#include "Kismet/KismetMathLibrary.h"

//Constructing The Object Here
ADoor::ADoor()
{
	bReplicates = true;

	RootComponent = InteractionHB;
	InteractionHB->SetRelativeLocation(FVector(60,0,120));
	InteractionHB->SetBoxExtent(FVector(70,15,115));
	
	Door = CreateDefaultSubobject<UStaticMeshComponent>("Door");
	Door->SetupAttachment(RootComponent);
	Door->SetSimulatePhysics(true);
	Door->SetIsReplicated(true);
	Door->SetAngularDamping(200);
	Door->SetCollisionResponseToChannel(ECC_GameTraceChannel1,ECollisionResponse::ECR_Block);
	Door->SetIsReplicated(true);

	Door->SetCollisionResponseToChannel(ECC_WorldDynamic,ECollisionResponse::ECR_Overlap);
	Door->SetCollisionResponseToChannel(ECC_WorldStatic,ECollisionResponse::ECR_Overlap);

	Hinge = CreateDefaultSubobject<UPhysicsConstraintComponent>("Hinge");
	Hinge->SetupAttachment(RootComponent);
	Hinge->SetComponentTickEnabled(false);
	Hinge->SetRelativeLocation(FVector(0,0,0));
	Hinge->SetIsReplicated(true);

	Hinge->SetAngularDriveMode(EAngularDriveMode::TwistAndSwing);
	Hinge->SetAngularVelocityDriveTwistAndSwing(false,true);
	Hinge->SetLinearPositionTarget(FVector(0,0,0));
	Hinge->SetAngularDriveParams(0.f,0.f,0.f);

	Hinge->SetAngularSwing1Limit(EAngularConstraintMotion::ACM_Limited,90);
	Hinge->SetAngularTwistLimit(EAngularConstraintMotion::ACM_Locked,1);
	Hinge->SetAngularSwing2Limit(EAngularConstraintMotion::ACM_Locked,1);
	Hinge->ComponentName1.ComponentName = "Door";

	Hinge->SetIsReplicated(true);
	Door->SetIsReplicated(true);
}

void ADoor::Interact(ACharacter* Char)
{
	if(!HasAuthority()) return;
	Hinge->SetAngularVelocityDriveTwistAndSwing(false,true);
	Hinge->SetOrientationDriveTwistAndSwing(false,true);
	
	isOpen = !isOpen;
	GEngine->AddOnScreenDebugMessage(-1,2,FColor::Green,("Door is now " + isOpen ? " open" : " closed"));
	
	if(isOpen) 
	{
		Hinge->SetAngularDriveParams(DoorSpeed,0.f,0.f);
		Door->SetMassScale(NAME_None,300);
		Door->SetAngularDamping(75);
		Tooltip = "Close Door";
		
		//Open Based On Player Location
		FVector LookVec = UKismetMathLibrary::InverseTransformLocation(Door->GetComponentTransform(),Char->GetActorLocation());
		if(LookVec.Y <= 0)
		{
			//In Front
			toRot = FRotator(0,MaxRotation,0);
			Hinge->SetAngularOrientationTarget(toRot);
		}
		else
		{
			//Behind
			toRot = FRotator(0,-MaxRotation,0);
			Hinge->SetAngularOrientationTarget(toRot);
		}
	}
	else
	{
		Hinge->SetAngularDriveParams(DoorSpeed,0.f,0.f);
		Door->SetMassScale(NAME_None,300);
		Door->SetAngularDamping(75);
		Hinge->SetAngularOrientationTarget(FRotator(0,0,0));
		Tooltip = "Open Door";
	} 

	Super::Interact(Char);
}

void ADoor::BeginPlay()
{
	Super::BeginPlay();
	
	if(!HasAuthority()) return;

	Hinge->SetAngularDriveParams(150.f,0.f,0.f);
	Door->SetMassScale(NAME_None,300);
	Tooltip = "Open Door";

	Door->SetSimulatePhysics(HasAuthority());
}

void ADoor::Tick(float DeltaSeconds)
{
	/*
	if(isOpen)
	{
		FRotator myRot = Door->GetComponentRotation();
		//GEngine->AddOnScreenDebugMessage(-1,1,FColor::Black,FString::SanitizeFloat(toRot.Yaw) + " / " + FString::SanitizeFloat(myRot.Yaw));
		if(toRot.Yaw - 1.5 <= myRot.Yaw && toRot.Yaw + 1.5 >= myRot.Yaw)
		{
			Hinge->SetAngularDriveParams(0.f,0.f,0.f);
			//GEngine->AddOnScreenDebugMessage(-1,1,FColor::Yellow,"Cooking In The Pot!");
		}
	}
	*/
	
	Super::Tick(DeltaSeconds);
}