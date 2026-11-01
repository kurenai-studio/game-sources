#include "Core/SeagullTypes.h"
#include "Misc/PackageName.h"
#include "PaperFlipbook.h"

UPaperFlipbook* SeagullAssets::LoadFlipbookCached(const TCHAR* Path)
{
	// Weak entries: a flipbook GC'd between spawns is transparently re-loaded.
	static TMap<FString, TWeakObjectPtr<UPaperFlipbook>> Cache;
	// Paths whose full LoadObject already failed once this session. They are
	// retried with a cheap in-memory FindObject (no disk probe, no warning), so
	// flipbooks created in the editor mid-session are still picked up.
	static TSet<FString> FailedLoads;

	TWeakObjectPtr<UPaperFlipbook>& Cached = Cache.FindOrAdd(Path);
	if (!Cached.IsValid())
	{
		if (!FailedLoads.Contains(Path))
		{
			UPaperFlipbook* Loaded = LoadObject<UPaperFlipbook>(nullptr, Path);
			if (!Loaded)
			{
				FailedLoads.Add(Path);
			}
			Cached = Loaded;
		}
		else
		{
			// FindObject needs the full Package.Asset form
			const FString ObjectPath = FString::Printf(TEXT("%s.%s"), Path, *FPackageName::GetShortName(Path));
			Cached = FindObject<UPaperFlipbook>(nullptr, *ObjectPath);
			if (Cached.IsValid())
			{
				FailedLoads.Remove(Path);
			}
		}
	}
	return Cached.Get();
}
