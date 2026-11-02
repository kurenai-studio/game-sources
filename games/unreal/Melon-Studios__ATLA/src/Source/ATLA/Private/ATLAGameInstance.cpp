// Copyright Melon Studios.

#include "ATLAGameInstance.h"

void UATLAGameInstance::FinishDestroy()
{
	if (FSlateApplication::IsInitialized())
	{
		const TSharedPtr<FSlateUser> SlateUser = FSlateApplication::Get().GetUser(FSlateApplication::Get().GetCursorUser()->GetUserIndex());
		if (SlateUser)
		{
			SlateUser->SetCursorVisibility(true);
		}
	}
	
	Super::FinishDestroy();
}
