// Copyright Melon Studios.

#include "UI/Component/ATLACommonButtonBase.h"

#include "CommonTextBlock.h"
#include "Subsystem/ATLAUIGameInstanceSubsystem.h"

void UATLACommonButtonBase::NativePreConstruct()
{
	Super::NativeConstruct();

	SetButtonText(ButtonDisplayText);
}

void UATLACommonButtonBase::NativeOnHovered()
{
	Super::NativeOnHovered();
	
	if (!ButtonDescriptionText.IsEmpty())
	{
		UATLAUIGameInstanceSubsystem::Get(this)->OnButtonDescriptionTextUpdated.Broadcast(this, ButtonDescriptionText);
	}
}

void UATLACommonButtonBase::NativeOnUnhovered()
{
	Super::NativeOnUnhovered();
	
	if (!ButtonDescriptionText.IsEmpty())
	{
		UATLAUIGameInstanceSubsystem::Get(this)->OnButtonDescriptionTextUpdated.Broadcast(this, FText::GetEmpty());
	}
}

void UATLACommonButtonBase::NativeOnCurrentTextStyleChanged()
{
	Super::NativeOnCurrentTextStyleChanged();
	
	if (CommonText_ButtonText && GetCurrentTextStyleClass())
	{
		CommonText_ButtonText->SetStyle(GetCurrentTextStyleClass());
	}
}

void UATLACommonButtonBase::SetButtonText(FText InText)
{
	if (!CommonText_ButtonText || InText.IsEmpty()) return;

	CommonText_ButtonText->SetText(bUseUpperCaseForButtonText ? InText.ToUpper() : InText);
}
