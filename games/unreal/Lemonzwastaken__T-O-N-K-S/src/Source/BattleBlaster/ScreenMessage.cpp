// Fill out your copyright notice in the Description page of Project Settings.


#include "ScreenMessage.h"

void UScreenMessage::SetMessageText(FString Message)
{
    if (MessageTextBlock)
    {
        MessageTextBlock->SetText(FText::FromString(Message));
        MessageTextBlock->SetVisibility(ESlateVisibility::Visible);
    }
}

void UScreenMessage::HideMessage()
{

    if (MessageTextBlock)
    {
        MessageTextBlock->SetVisibility(ESlateVisibility::Collapsed);
    }

}

void UScreenMessage::SetComboText(FString ComboMessage)
{
    if (ComboMessageBlock)
    {
        ComboMessageBlock->SetText(FText::FromString(ComboMessage));
        ComboMessageBlock->SetVisibility(ESlateVisibility::Visible);
    }

    if (ComboShake)
    {
        PlayAnimation(ComboShake);
    }
}

void UScreenMessage::HideCombo()
{
    if (ComboMessageBlock)
    {
        ComboMessageBlock->SetVisibility(ESlateVisibility::Collapsed);
    }
}
