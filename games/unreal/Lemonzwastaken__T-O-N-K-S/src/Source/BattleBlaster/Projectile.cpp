// Fill out your copyright notice in the Description page of Project Settings.


#include "Projectile.h"

#include "Kismet/GameplayStatics.h"
#include "BasePawn.h"


// Sets default values
AProjectile::AProjectile()
{
	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	ProjectileMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("ProjectileMesh"));
	SetRootComponent(ProjectileMesh);

	ProjectileMovementComp = CreateDefaultSubobject<UProjectileMovementComponent>(TEXT("ProjectileMovementComp"));
	ProjectileMovementComp->InitialSpeed = 1000.0f;
	ProjectileMovementComp->MaxSpeed = 1000.0f;

	TrailParticles = CreateDefaultSubobject<UNiagaraComponent>(TEXT("TrailParticles"));
	TrailParticles->SetupAttachment(RootComponent);

}

// Called when the game starts or when spawned
void AProjectile::BeginPlay()
{
	Super::BeginPlay();

	ProjectileMesh->OnComponentHit.AddDynamic(this, &AProjectile::OnHit);

	if (LaunchSound)
	{
		UGameplayStatics::PlaySoundAtLocation(GetWorld(), LaunchSound, GetActorLocation());
	}
}

// Called every frame
void AProjectile::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

void AProjectile::OnHit(UPrimitiveComponent* HitComponent, AActor* OtherActor, UPrimitiveComponent* OtherComp, FVector NormalImpulse, const FHitResult& Hit)
{
	AActor* MyOwner = GetOwner();
	if (MyOwner)
	{
		if (OtherActor && (OtherActor != MyOwner) && (OtherActor != this))
		{
			ABasePawn* OwnerPawn = Cast<ABasePawn>(MyOwner);
			ABasePawn* OtherPawn = Cast<ABasePawn>(OtherActor);

			bool bIsFriendlyFire = (OwnerPawn && OtherPawn && OwnerPawn->Team == OtherPawn->Team);

			if (!bIsFriendlyFire)
			{
				UGameplayStatics::ApplyDamage(OtherActor, Damage, MyOwner->GetInstigatorController(), this, UDamageType::StaticClass());

				if (HitParticles)
				{
					UNiagaraFunctionLibrary::SpawnSystemAtLocation(GetWorld(), HitParticles, GetActorLocation(), GetActorRotation());
				}

				if (HitSound)
				{
					UGameplayStatics::PlaySoundAtLocation(GetWorld(), HitSound, GetActorLocation());
				}

				if (HitCameraShakeClass)
				{
					APlayerController* PlayerController = UGameplayStatics::GetPlayerController(GetWorld(), 0);

					if (PlayerController)
					{
						PlayerController->ClientStartCameraShake(HitCameraShakeClass);
					}

				}

			}

		}
	}

	// Hide the mesh and stop movement/collision so the projectile "disappears"
	ProjectileMesh->SetVisibility(false);
	ProjectileMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	ProjectileMovementComp->StopMovementImmediately();

	if (TrailParticles && TrailParticles->GetAsset())
	{
		TrailParticles->Deactivate();
		TrailParticles->OnSystemFinished.AddDynamic(this, &AProjectile::OnTrailFinished);
	}
	else
	{
		Destroy();
	}
}

void AProjectile::OnTrailFinished(UNiagaraComponent* PSystem)
{
	Destroy();
}

