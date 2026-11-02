// Copyright Melon Studios.

#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"

#include "ATLABlueprintFunctionLibrary.generated.h"

class UDataTable;
class UATLAGameInstance;

/**
 *	ATLA Blueprint Function Library Class.
 */
UCLASS()
class ATLA_API UATLABlueprintFunctionLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintPure, Category = "ATLA", meta = (WorldContext = "WorldContextObject"))
	static UATLAGameInstance* GetATLAGameInstance(const UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category = "ATLA")
	static FString GetGameInfoDetails();

	template <typename T>
	static T* GetDataTableRowByName(UDataTable* DataTable, const FName& RowName);
};

template <typename T>
T* UATLABlueprintFunctionLibrary::GetDataTableRowByName(UDataTable* DataTable, const FName& RowName)
{
	return DataTable->FindRow<T>(RowName, TEXT(""));
}
