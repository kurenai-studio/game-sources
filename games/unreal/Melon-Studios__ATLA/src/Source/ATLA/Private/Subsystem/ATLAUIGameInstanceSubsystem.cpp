// Copyright Melon Studios.

#include "Subsystem/ATLAUIGameInstanceSubsystem.h"

#include "ATLA/ATLA.h"
#include "Engine/AssetManager.h"
#include "UI/Widget/ATLACommonActivatableWidget.h"
#include "UI/Widget/ATLACommonUserWidget.h"
#include "Widgets/CommonActivatableWidgetContainer.h"

UATLAUIGameInstanceSubsystem* UATLAUIGameInstanceSubsystem::Get(const UObject* WorldContextObject)
{
	if (GEngine)
	{
		const UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::Assert);

		return UGameInstance::GetSubsystem<UATLAUIGameInstanceSubsystem>(World->GetGameInstance());
	}

	return nullptr;
}

bool UATLAUIGameInstanceSubsystem::ShouldCreateSubsystem(UObject* Outer) const
{
	if (!CastChecked<UGameInstance>(Outer)->IsDedicatedServerInstance())
	{
		TArray<UClass*> FoundClasses;
		GetDerivedClasses(GetClass(), FoundClasses);

		return FoundClasses.IsEmpty();
	}

	return false;
}

void UATLAUIGameInstanceSubsystem::RegisterCreatedATLACommonUserWidget(UATLACommonUserWidget* InCreatedWidget)
{
	check(InCreatedWidget);

	CreatedATLACommonUserWidget = InCreatedWidget;
	ATLAPrint(TEXT("GG : Registered ATLA Common User Widget"));
}

void UATLAUIGameInstanceSubsystem::PushSoftWidgetToStackAsync(const FGameplayTag& InWidgetStackTag, TSoftClassPtr<UATLACommonActivatableWidget> InSoftWidgetClass,
                                                              TFunction<void(EPushSoftWidgetAsyncState, UATLACommonActivatableWidget*)> AsyncPushStateCallback)
{
	check(!InSoftWidgetClass.IsNull());

	UAssetManager::Get().GetStreamableManager().RequestAsyncLoad(InSoftWidgetClass.ToSoftObjectPath(), FStreamableDelegate::CreateLambda(
		                                                             [this, InSoftWidgetClass, InWidgetStackTag, AsyncPushStateCallback]
		                                                             {
			                                                             UClass* LoadedWidgetClass = InSoftWidgetClass.Get();
			                                                             check(LoadedWidgetClass && CreatedATLACommonUserWidget);
			                                                             UCommonActivatableWidgetContainerBase* FoundWidgetStack = CreatedATLACommonUserWidget->
				                                                             GetWidgetStackByTag(InWidgetStackTag);

			                                                             UATLACommonActivatableWidget* CreatedWidget = FoundWidgetStack->AddWidget<
				                                                             UATLACommonActivatableWidget>(
				                                                             LoadedWidgetClass, [AsyncPushStateCallback](UATLACommonActivatableWidget& CreatedWidgetInstance)
				                                                             {
					                                                             AsyncPushStateCallback(EPushSoftWidgetAsyncState::OnPushSoftWidgetStart,
					                                                                                    &CreatedWidgetInstance);
				                                                             });

			                                                             AsyncPushStateCallback(EPushSoftWidgetAsyncState::OnPushSoftWidgetEnd, CreatedWidget);
		                                                             }));
}
