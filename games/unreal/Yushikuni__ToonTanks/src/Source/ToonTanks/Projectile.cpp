// Fill out your copyright notice in the Description page of Project Settings.


#include "Projectile.h"

#include "Components/CapsuleComponent.h"

#include "Kismet/GameplayStatics.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "Particles/ParticleSystemComponent.h"

// Sets default values
AProjectile::AProjectile()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = false; //Not need to tick

	// Projectile Components:
	//Capsule:
	CapsuleComp = CreateDefaultSubobject<UCapsuleComponent>(TEXT("Capsule Collider"));
	RootComponent = CapsuleComp;

	CapsuleComp->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	CapsuleComp->SetCollisionObjectType(ECC_PhysicsBody);
	CapsuleComp->SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

	//Adding meshes and attachet them
	ProjectileMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Projectile Mesh"));
	ProjectileMesh->SetupAttachment(RootComponent);

	ProjectileMovementComp = CreateDefaultSubobject<UProjectileMovementComponent>(TEXT("Projectile Movement Component"));

	//Add smoke trail
	SmokeTrail = CreateDefaultSubobject< UParticleSystemComponent>(TEXT("Smoke Trail"));
	SmokeTrail->SetupAttachment(RootComponent);

	ProjectileMovementComp->MaxSpeed = 1500.f;
	ProjectileMovementComp->InitialSpeed = 1500.f;
}

// Called when the game starts or when spawned
void AProjectile::BeginPlay()
{
	Super::BeginPlay();

	UE_LOG(LogTemp, Warning, TEXT("Begin Play - Projectile spawned at location: %s"), *GetActorLocation().ToString());


	CapsuleComp->OnComponentBeginOverlap.AddDynamic(this, &AProjectile::OnOverlapBegin);
	CapsuleComp->OnComponentEndOverlap.AddDynamic(this, &AProjectile::OnOverlapEnd);

	InstigatorController = GetOwner() ? GetOwner()->GetInstigatorController() : nullptr;
	// Uložení vlastníka støely (instigatora)
	OwnerActor = GetOwner();

	DrawDebugSphere(GetWorld(), GetActorLocation(), 50.f, 12, FColor::Black, false, 2.0f);


	if (LaunchSound)
	{
		UGameplayStatics::PlaySoundAtLocation(this, LaunchSound, GetActorLocation());
	}
}

// Called every frame
void AProjectile::Tick(float DeltaTime)
{
	UE_LOG(LogTemp, Warning, TEXT("TICK - Projectile spawned at location: %s"), *GetActorLocation().ToString());

	Super::Tick(DeltaTime);
}

void AProjectile::OnOverlapBegin(class UPrimitiveComponent* OverlappedComp, class AActor* OtherActor, class UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep, const FHitResult& SweepResult)
{
	UE_LOG(LogTemp, Warning, TEXT("OnOverlapBegin - Projectile spawned at location: %s"), *GetActorLocation().ToString());

	DrawDebugSphere(GetWorld(), GetActorLocation(), 50.f, 12, FColor::Red, false, 2.0f);

	if (InstigatorController) UE_LOG(LogTemp, Error, TEXT("Get owner is nullptr!!!!"));
	// Kontrola, zda OtherActor není vlastníkem støely
	if (OtherActor && OtherActor != this && OtherActor != OwnerActor && OtherComp)
	{
		UE_LOG(LogTemp, Warning, TEXT("HITING something"));
		UGameplayStatics::ApplyDamage(OtherActor, Damage, InstigatorController, this, UDamageType::StaticClass());
		Destroy();
	}
}
void AProjectile::OnOverlapEnd(class UPrimitiveComponent* OverlappedComp, class AActor* OtherActor, class UPrimitiveComponent* OtherComp, int32 OtherBodyIndex)
{
	UE_LOG(LogTemp, Warning, TEXT("OnOverlapEnd - Projectile spawned at location: %s"), *GetActorLocation().ToString());

	DrawDebugSphere(GetWorld(), GetActorLocation(), 50.f, 12, FColor::Yellow, false, 2.0f);

	UE_LOG(LogTemp, Warning, TEXT("END overlap"));
	Destroy();
}
