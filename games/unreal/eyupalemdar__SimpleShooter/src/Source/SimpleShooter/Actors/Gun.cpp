#include "Gun.h"
#include "Components/SkeletalMeshComponent.h"
#include "Kismet/GameplayStatics.h"

AGun::AGun()
{
	PrimaryActorTick.bCanEverTick = true;

	Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	RootComponent = Root;

	Mesh = CreateDefaultSubobject<USkeletalMeshComponent>("Mesh");
	Mesh->SetupAttachment(Root);
}

void AGun::BeginPlay()
{
	Super::BeginPlay();
	
}

void AGun::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

void AGun::PullTrigger()
{
	// Silah namlusuna efekt yerleþtir
	UGameplayStatics::SpawnEmitterAttached(MuzzleFlash, Mesh, TEXT("MuzzleFlashSocket"));
	UGameplayStatics::SpawnSoundAttached(MuzzleSound, Mesh, TEXT("MuzzleFlashSocket"));

	FHitResult Hit;
	FVector ShotDirection;
	bool bSuccessfulHit = GunTrace(Hit, ShotDirection);

	if (bSuccessfulHit)
	{
		// Merminin çarptýðý noktada efekt oluþtur.
		UGameplayStatics::SpawnEmitterAtLocation(GetWorld(), ImpactEffect, Hit.Location, ShotDirection.Rotation());
		UGameplayStatics::SpawnSoundAtLocation(GetWorld(), ImpactSound, Hit.Location, ShotDirection.Rotation());
		
		// Merminin çarptýðý þey bir Aktör mü?
		AActor* HitActor = Hit.GetActor();
		if (HitActor)
		{
			// Aktörse ona Damage uygula
			FPointDamageEvent DamageEvent(Damage, Hit, ShotDirection, nullptr);
			AController* OwnerController = GetOwnerController();
			HitActor->TakeDamage(Damage, DamageEvent, OwnerController, this);
		}
	}
}

/// <summary>
/// Baþlangýç ve Bitiþ noktasý arasýnda bir LineTrace oluþtur ve 
/// bak bakalým verilen Channel'a uygun olarak herhangi birþeye çarpýyor mu?
/// </summary>
/// <param name="Hit"></param>
/// <param name="ShotDirection"></param>
/// <returns></returns>
bool AGun::GunTrace(FHitResult& Hit, FVector& ShotDirection)
{
	AController* OwnerController = GetOwnerController();
	if (OwnerController == nullptr)
	{
		return false;
	}

	// Kullanýcýnýn ViewPoint bilgisini ubl. (Ekrana bakýþ noktasý)
	FVector Location;
	FRotator Rotation;
	OwnerController->GetPlayerViewPoint(Location, Rotation);

	// Atýþ yönünü bul
	ShotDirection = -Rotation.Vector();

	// Merminin gidebileceði son noktayý hesapla
	FVector EndLocation = Location + Rotation.Vector() * MaxBulletRange;

	FCollisionQueryParams CollisionQueryParams;
	CollisionQueryParams.AddIgnoredActor(this); // ignore gun's itself
	CollisionQueryParams.AddIgnoredActor(GetOwner()); // ignore the user or AI who carry the gun

	return GetWorld()->LineTraceSingleByChannel(
		Hit, Location, EndLocation, ECollisionChannel::ECC_GameTraceChannel1, CollisionQueryParams);
}

AController* AGun::GetOwnerController() const
{
	// Bu silahý kullanan Pawn (Kullanýcý) ve onun Controller'ýný bul
	APawn* OwnerPawn = Cast<APawn>(GetOwner());
	if (OwnerPawn == nullptr) 
		return nullptr;
	return OwnerPawn->GetController();
}
