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

	ProjectileMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Projectile Mesh"));
	RootComponent = ProjectileMesh;
	
	ProjectileMovementComponent = CreateDefaultSubobject<UProjectileMovementComponent>("Projectile Movement");
	ProjectileMovementComponent->MaxSpeed = 1300.f;
	ProjectileMovementComponent->InitialSpeed = 1300.f;
	
	TrailParticles = CreateDefaultSubobject<UParticleSystemComponent>("Smoke Trail");
	TrailParticles->SetupAttachment(RootComponent);
}

// Called when the game starts or when spawned
void AProjectile::BeginPlay()
{
	Super::BeginPlay();

	// This binds "OnComponentHit" event to "OnHit()" function, so OnHit is called any time this component is hit.
	// AddDynamic() is a helper macro that binds the event to the object and method we want to call.
	ProjectileMesh->OnComponentHit.AddDynamic(this, &AProjectile::OnHit);

	if(LaunchSound)
	{
		UGameplayStatics::SpawnSoundAtLocation(this, LaunchSound, GetActorLocation());
	}
}

// Called every frame
void AProjectile::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

/*
 * ctrl-click OnComponentHit and scroll up to the first time it’s mentioned, to see where these delegate parameters
 * are declared so that we know which ones to grab if we’re making our own delegate for OnComponentHit.
 * you find this mess with no explanations. So here’s some:

	* Delegate for notification of blocking collision against a specific component.
	* NormalImpulse will be filled in for physics-simulating bodies, but will be zero for swept-component blocking collisions.
	
DECLARE_DYNAMIC_MULTICAST_SPARSE_DELEGATE_FiveParams(
	FComponentHitSignature,					// (Don't need) The type this event fires off from behind the scenes (I think).
	UPrimitiveComponent,					// (Don't need) The class this event is attached to behind the scenes (I think), which is why we can access it from a StaticMesh component.
	OnComponentHit,							// (Don't need) The event name! This is how we know what it is.
	UPrimitiveComponent*, HitComponent,		// First parameter we'll actually get from the event. Our component that was hit (our ProjectileMesh in this case).
	AActor*, OtherActor,					// Second parameter. The other actor hit by our ProjectileMesh.
	UPrimitiveComponent*, OtherComp,		// Third. The other specific component hit on that actor, if needed (like if we could specifically damage an arm, rather than a player).
	FVector, NormalImpulse,					// Fourth. The impulse of the hit.
	const FHitResult&, Hit					// Fifth. The info in the hit result of a trace, like point of impact, etc.
	);
 */

/// Our method. Will be a Dynamic Delegate. Used to handle our OnComponentHit Event info for damage, destruction, etc. \n
/// Parameters determined by parameters accessible from OnComponentHit event.
void AProjectile::OnHit(UPrimitiveComponent* HitComp, AActor* OtherActor, UPrimitiveComponent* OtherComp,
	FVector NormalImpulse, const FHitResult& Hit)
{
	//UE_LOG(LogTemp, Warning, TEXT("OnHit"));
	auto MyOwner = GetOwner();
	if(MyOwner == nullptr)
	{
		Destroy();
		return;
	}

	if(OtherActor && OtherActor != this && OtherActor != MyOwner)
	{
		UGameplayStatics::ApplyDamage(OtherActor, Damage, MyOwner->GetInstigatorController(), this, UDamageType::StaticClass());
		if(HitParticles)
		{
			UGameplayStatics::SpawnEmitterAtLocation(this, HitParticles, GetActorLocation(), GetActorRotation());
		}
		if(HitParticles)
		{
			UGameplayStatics::SpawnSoundAtLocation(this, HitSound, GetActorLocation());
		}
		if(HitCameraShakeClass)
		{
			GetWorld()->GetFirstPlayerController()->ClientStartCameraShake(HitCameraShakeClass);
		}
		
	}
	Destroy();
}