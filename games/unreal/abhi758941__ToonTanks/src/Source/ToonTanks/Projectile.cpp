// Fill out your copyright notice in the Description page of Project Settings.


#include "Projectile.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "GameFramework/DamageType.h"
#include "Kismet/GameplayStatics.h"
#include "Particles/ParticleSystemComponent.h"

// Sets default values
AProjectile::AProjectile()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = false;

	BulletComponent = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Bullet"));
	RootComponent = BulletComponent;
	ProjectileMovementComponent = CreateDefaultSubobject<UProjectileMovementComponent>(TEXT("Projectile Movement")); 
	SmokeTrail = CreateDefaultSubobject<UParticleSystemComponent>(TEXT("Smoke Trail"));
	SmokeTrail->SetupAttachment(BulletComponent);
}

// Called when the game starts or when spawned
void AProjectile::BeginPlay()
{
	Super::BeginPlay();
	BulletComponent->OnComponentHit.AddDynamic(this , &AProjectile::OnHit);
	if (LaunchSound)
	{
		UGameplayStatics::PlaySoundAtLocation(this , LaunchSound , GetActorLocation());
	}
}

// Called every frame
void AProjectile::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}
void AProjectile::OnHit(UPrimitiveComponent* HitComp , AActor* OtherActor , UPrimitiveComponent* OtherComp , FVector NormalImpulse , const FHitResult& Hit)
{
	auto MyOwner = GetOwner();
	if (MyOwner == nullptr) 
	{
		Destroy();
		return;
	};

	auto MyOwnerInstigator = MyOwner->GetInstigatorController();
	auto DamageTypeClass = UDamageType::StaticClass();

	if(OtherActor && OtherActor != this && OtherActor != MyOwner && HitParticles && HitSound && HitCameraShakeClass)
	{
		UGameplayStatics::ApplyDamage(OtherActor , Damage , MyOwnerInstigator , this, DamageTypeClass);
		UGameplayStatics::SpawnEmitterAtLocation(this , HitParticles , GetActorLocation() , GetActorRotation());
		UGameplayStatics::PlaySoundAtLocation(this , HitSound , GetActorLocation());
		GetWorld()->GetFirstPlayerController()->ClientStartCameraShake(HitCameraShakeClass);
	}
	Destroy();
}