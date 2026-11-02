// Copyright Melon Studios.

#include "UI/PushSoftWidgetAsyncActionBase.h"

#include "Subsystem/ATLAUIGameInstanceSubsystem.h"
#include "UI/Widget/ATLACommonActivatableWidget.h"

UPushSoftWidgetAsyncActionBase* UPushSoftWidgetAsyncActionBase::PushSoftWidget(const UObject* WorldContextObject, APlayerController* OwningPlayerController,
                                                                               TSoftClassPtr<UATLACommonActivatableWidget> InSoftWidgetClass, FGameplayTag InWidgetStackTag,
                                                                               bool bFocusOnNewlyPushedWidget)
{
	checkf(!InSoftWidgetClass.IsNull(), TEXT("GG : PushSoftWidgetToStack was passed with a null soft widget class"));

	if (GEngine)
	{
		if (UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull))
		{
			UPushSoftWidgetAsyncActionBase* PushSoftWidget = NewObject<UPushSoftWidgetAsyncActionBase>();
			PushSoftWidget->CachedOwningWorld = World;
			PushSoftWidget->CachedOwningPC = OwningPlayerController;
			PushSoftWidget->CachedSoftWidgetClass = InSoftWidgetClass;
			PushSoftWidget->CachedWidgetStackTag = InWidgetStackTag;
			PushSoftWidget->bCachedFocusOnNewlyPushedWidget = bFocusOnNewlyPushedWidget;

			PushSoftWidget->RegisterWithGameInstance(World);
			return PushSoftWidget;
		}
	}

	return nullptr;
}

void UPushSoftWidgetAsyncActionBase::Activate()
{
	UATLAUIGameInstanceSubsystem* ATLAUISubsystem = UATLAUIGameInstanceSubsystem::Get(CachedOwningWorld.Get());
	ATLAUISubsystem->PushSoftWidgetToStackAsync(CachedWidgetStackTag, CachedSoftWidgetClass,
	                                            [this](EPushSoftWidgetAsyncState InPushState, UATLACommonActivatableWidget* PushedWidget)
	                                            {
		                                            switch (InPushState)
		                                            {
		                                            case EPushSoftWidgetAsyncState::OnPushSoftWidgetStart:
			                                            PushedWidget->SetOwningPlayer(CachedOwningPC.Get());
			                                            OnPushSoftWidgetStart.Broadcast(PushedWidget);
			                                            break;
		                                            case EPushSoftWidgetAsyncState::OnPushSoftWidgetEnd:
			                                            OnPushSoftWidgetEnd.Broadcast(PushedWidget);

			                                            if (bCachedFocusOnNewlyPushedWidget)
			                                            {
				                                            if (UWidget* WidgetToFocus = PushedWidget->GetDesiredFocusTarget())
				                                            {
					                                            WidgetToFocus->SetFocus();
				                                            }
			                                            }

			                                            SetReadyToDestroy();
			                                            break;
		                                            }
	                                            });
}
