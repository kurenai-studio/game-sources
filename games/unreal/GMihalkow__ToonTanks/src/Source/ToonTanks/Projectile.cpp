// Fill out your copyright notice in the Description page of Project Settings.

#include "Projectile.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Particles/ParticleSystemComponent.h"

// Sets default values
AProjectile::AProjectile()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = false;

	this->_mesh = this->CreateDefaultSubobject<UStaticMeshComponent>("MESH");
	this->RootComponent = this->_mesh;

	this->_trail = this->CreateDefaultSubobject<UParticleSystemComponent>("TRAIL");
	this->_trail->AttachToComponent(this->_mesh, FAttachmentTransformRules::SnapToTargetIncludingScale);

	this->_movement = this->CreateDefaultSubobject<UProjectileMovementComponent>("MOVEMENT");
}

// Called when the game starts or when spawned
void AProjectile::BeginPlay()
{
	Super::BeginPlay();

	UGameplayStatics::PlaySoundAtLocation(this, this->_launchSound, this->GetActorLocation());
	this->_mesh->OnComponentHit.AddDynamic(this, &AProjectile::OnHit);
}

// Called every frame
void AProjectile::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

void AProjectile::OnHit(UPrimitiveComponent* hitComponent, AActor* otherActor, UPrimitiveComponent* other, FVector impulse, const FHitResult& hit)
{
	if (this->GetOwner() == nullptr)
	{
		if (this->_hitCameraShake != nullptr) 
		{
			this->GetWorld()->GetFirstPlayerController()->ClientStartCameraShake(this->_hitCameraShake);
		}

		UGameplayStatics::PlaySoundAtLocation(this, this->_hitSound, hit.ImpactPoint);
		Destroy();
		return;
	}

	if (otherActor == nullptr || otherActor == this || otherActor == this->GetOwner())
	{
		return;
	}

	if (this->_hitCameraShake != nullptr)
	{
		this->GetWorld()->GetFirstPlayerController()->ClientStartCameraShake(this->_hitCameraShake);
	}

	UGameplayStatics::PlaySoundAtLocation(this, this->_hitSound, hit.ImpactPoint);
	AController* instigator = otherActor->GetInstigatorController();
	UClass* dmgType = UDamageType::StaticClass();

	UGameplayStatics::ApplyDamage(otherActor, this->_damage, instigator, this, dmgType);
	UGameplayStatics::SpawnEmitterAtLocation(this->GetWorld(), this->_hitEffectBlueprint, this->GetActorLocation(), this->GetActorRotation());
	Destroy();
}