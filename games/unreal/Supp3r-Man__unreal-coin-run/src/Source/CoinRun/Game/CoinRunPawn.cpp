#include "Game/CoinRunPawn.h"

#include "Camera/CameraComponent.h"
#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/SpringArmComponent.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "Rules/Tuning.h"
#include "UObject/ConstructorHelpers.h"

ACoinRunPawn::ACoinRunPawn()
{
	PrimaryActorTick.bCanEverTick = false;

	Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	RootComponent = Root;

	// The engine's basic sphere is 100 cm across, so scaling by diameter / 100 gives the rules' radius.
	Body = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Body"));
	Body->SetupAttachment(Root);
	Body->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Body->SetRelativeScale3D(FVector(coinrun::tuning::kPlayerRadius * 2.0f / 100.0f));

	static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
	if (SphereMesh.Succeeded())
	{
		Body->SetStaticMesh(SphereMesh.Object);
	}

	static ConstructorHelpers::FObjectFinder<UMaterialInterface> BasicMaterial(TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
	if (BasicMaterial.Succeeded())
	{
		BaseMaterial = BasicMaterial.Object;
	}

	// Fixed overhead camera: absolute rotation so it does not turn with the pawn, attached to the unscaled root.
	Arm = CreateDefaultSubobject<USpringArmComponent>(TEXT("Arm"));
	Arm->SetupAttachment(Root);
	Arm->SetUsingAbsoluteRotation(true);
	Arm->SetRelativeRotation(FRotator(-65.0f, 0.0f, 0.0f));
	Arm->TargetArmLength = 2400.0f;
	Arm->bDoCollisionTest = false;

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(Arm, USpringArmComponent::SocketName);
}

void ACoinRunPawn::BeginPlay()
{
	Super::BeginPlay();

	if (BaseMaterial)
	{
		BodyMaterial = UMaterialInstanceDynamic::Create(BaseMaterial, this);
		BodyMaterial->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.25f, 0.9f, 1.0f));
		Body->SetMaterial(0, BodyMaterial);
	}
}

void ACoinRunPawn::SetBodyVisible(bool bVisible)
{
	Body->SetVisibility(bVisible);
}
