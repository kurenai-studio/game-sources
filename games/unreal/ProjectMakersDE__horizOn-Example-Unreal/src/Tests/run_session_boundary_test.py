#!/usr/bin/env python3
"""Exercise actual facade methods with delayed SDK callbacks, without an engine.

Compiles selected production method definitions and the actual facade declaration
against small value/delegate/SDK boundaries. This checks application state guards,
not Unreal reflection, Slate, transport or native module compilation.
"""
from pathlib import Path
import os
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
FACADE = ROOT / "Source/SeagullStorm/Horizon/SeagullHorizonManager.cpp"
HEADER = FACADE.with_suffix(".h")
GI = ROOT / "Source/SeagullStorm/Core/SeagullGameInstance.cpp"


def method(source: str, owner: str, name: str) -> str:
    match = re.search(rf"^(?:bool|void|FString) {owner}::{name}\(", source, re.M)
    if not match:
        raise ValueError(f"Missing production method {owner}::{name}")
    end = source.index("\n}", match.end()) + 2
    return source[match.start():end]


SHIM = r"""
#include <cassert>
#include <cstdint>
#include <cstdarg>
#include <cstdio>
#include <functional>
#include <iostream>
#include <map>
#include <string>
#include <utility>
#include <vector>
using uint64 = uint64_t; using int64 = int64_t; using int32 = int32_t; using uint8 = uint8_t;
#define TEXT(S) S
#define UCLASS(...)
#define GENERATED_BODY(...)
#define UPROPERTY(...)
#define UFUNCTION(...)
#define UE_LOG(...)
#define HORIZON_WITH_VALIDATED_ACTIONS 1
#define MoveTemp(S) std::move(S)
struct FString : std::string {
 using std::string::string;
 FString(const std::string& V) : std::string(V) {}
 bool IsEmpty() const { return empty(); }
 void Empty() { clear(); }
 const char* operator*() const { return c_str(); }
 static FString Printf(const char* Format, ...) {
  char B[1024]; va_list Args; va_start(Args, Format); vsnprintf(B,sizeof(B),Format,Args); va_end(Args); return B;
 }
};
template<class T> struct TArray : std::vector<T> {
 using std::vector<T>::vector;
 void Add(T V) { this->push_back(std::move(V)); }
 void RemoveAt(int32 I) { this->erase(this->begin()+I); }
 bool IsEmpty() const { return this->empty(); }
};
template<class K,class V> using TMap = std::map<K,V>;
template<class T> using TFunction = std::function<T>;
template<class T> struct TWeakObjectPtr {
 T* P; TWeakObjectPtr(T* Value) : P(Value) {} T* Get() const { return P; }
};
struct UObject {
 void* Outer = nullptr;
 template<class T> T* GetTypedOuter() const { return static_cast<T*>(Outer); }
};
template<class... Args> struct Delegate {
 template<class F> static std::function<void(Args...)> CreateLambda(F Callback) { return Callback; }
};
struct FHorizonUserData {};
struct FOnAnonymousIdentityIssued { template<class F> static int CreateLambda(F) { return 0; } };
using FOnAuthComplete = Delegate<bool>;
using FOnRequestComplete = Delegate<bool,const FString&>;
using FOnStringComplete = Delegate<bool,const FString&>;
using FOnAllConfigsComplete = Delegate<bool,const TMap<FString,FString>&>;
struct FHorizonCloudSaveSnapshot { bool bSuccess = false; bool bFound = false; FString Data; };
using FOnCloudSaveSnapshotComplete = Delegate<const FHorizonCloudSaveSnapshot&>;
struct FHorizonLeaderboardEntry {}; struct FHorizonLeaderboardBoard {}; struct FHorizonPlayerState {};
struct FHorizonPlayerProfileResult {}; struct FHorizonNewsEntry {};
struct FHorizonValidatedRun { FString RunId; int32 Seed = 0; };
struct FHorizonEarnedValue { FHorizonEarnedValue(const FString&,int64) {} };
struct FHorizonValidatedSubmitResult {
 bool bAccepted = true; int64 Rank = 7; struct { bool bRequired = true; } Evidence;
};
using FOnValidatedRunStarted = Delegate<bool,const FHorizonValidatedRun&,const FString&,const FString&>;
using FOnValidatedSubmitComplete = Delegate<bool,const FHorizonValidatedSubmitResult&,const FString&,const FString&>;
struct FakeAuth {
 struct User { FString UserId; FString DisplayName; } Current;
 std::vector<std::function<void(bool)>> Pending;
 void SignUpAnonymous(const FString&,std::function<void(bool)> C,const FString& = "",int = 0) { Pending.push_back(C); }
 void SignInEmail(const FString&,const FString&,std::function<void(bool)> C) { Pending.push_back(C); }
 void SignUpEmail(const FString&,const FString&,const FString&,std::function<void(bool)> C) { Pending.push_back(C); }
 void RestoreAnonymousSession(std::function<void(bool)> C) { Pending.push_back(C); }
 void SignInWithApple(std::function<void(bool)> C) { Pending.push_back(C); }
 void SignOut() { Current.UserId.Empty(); }
 bool IsSignedIn() const { return !Current.UserId.IsEmpty(); }
 const User& GetCurrentUser() const { return Current; }
 void Complete(const FString& UserId,bool Ok=true) {
  assert(!Pending.empty()); auto C=Pending.front(); Pending.erase(Pending.begin());
  if(Ok) Current.UserId=UserId; // The real SDK mutates shared state before returning.
  C(Ok);
 }
};
struct FakeCloud {
 FakeAuth* Auth;
 struct Request { FString Json; FString Owner; std::function<void(bool,const FString&)> Callback; };
 std::vector<Request> Pending, Sent;
 std::vector<std::function<void(bool,const FString&)>> Reads;
 void Save(const FString& Json,std::function<void(bool,const FString&)> C) {
  Request R{Json,Auth->Current.UserId,C}; Sent.push_back(R); Pending.push_back(R);
 }
 void Load(std::function<void(bool,const FString&)> C) { Reads.push_back(C); }
 // Reads complete as (reached server, slot data); an empty slot is a successful read without data.
 void LoadSnapshot(std::function<void(const FHorizonCloudSaveSnapshot&)> C) {
  Reads.push_back([C](bool Ok,const FString& Data){ FHorizonCloudSaveSnapshot S; S.bSuccess=Ok; S.bFound=Ok && !Data.IsEmpty(); S.Data=Data; C(S); });
 }
 void Complete(bool Ok=true) { assert(!Pending.empty()); auto C=Pending.front().Callback; Pending.erase(Pending.begin()); C(Ok,""); }
};
struct FakeConfig {
 std::vector<std::function<void(bool,const TMap<FString,FString>&)>> Reads;
 void GetAllConfigs(bool,std::function<void(bool,const TMap<FString,FString>&)> C) { Reads.push_back(C); }
};
struct FakeValidated {
 bool bAutoUploadEvidence = false;
 struct Event { template<class... T> void AddUniqueDynamic(T...) {} } OnEvidenceUploaded, OnEvidenceUploadFailed;
 using StartCallback=std::function<void(bool,const FHorizonValidatedRun&,const FString&,const FString&)>;
 using SubmitCallback=std::function<void(bool,const FHorizonValidatedSubmitResult&,const FString&,const FString&)>;
 std::vector<StartCallback> Starts; std::vector<SubmitCallback> Submits;
 bool Active=false; std::function<void()> EarlyEvidence;
 void StartRun(const FString&,StartCallback C) { Starts.push_back(C); }
 void DiscardRun() { Active=false; }
 bool HasActiveRun() const { return Active; }
 void SubmitValidated(int64,const TArray<uint8>&,const FString&,const FString&,const TArray<FHorizonEarnedValue>&,SubmitCallback C) {
  if(EarlyEvidence) EarlyEvidence(); Submits.push_back(C);
 }
 void CompleteStart(const FString& Id) { assert(!Starts.empty()); auto C=Starts.front(); Starts.erase(Starts.begin()); Active=true; C(true,{Id,123},"",""); }
 void CompleteSubmit() { assert(!Submits.empty()); auto C=Submits.front(); Submits.erase(Submits.begin()); C(true,{},"",""); }
};
using UHorizonValidatedActionsManager = FakeValidated;
struct UHorizonSubsystem { FakeAuth* Auth; FakeCloud* CloudSave; FakeConfig* RemoteConfig; FakeValidated* ValidatedActions; };
struct UHorizonExampleIdentity {
 static FString ProjectKey(UHorizonSubsystem*) { return "fixture-project"; }
 static bool CaptureBeforeAuth(UHorizonSubsystem*,UHorizonExampleIdentity*& Out) { Out=nullptr; return true; }
 static bool BeforeSignup(UHorizonSubsystem*,const FString&) { return true; }
 static bool RecordIssuedSignup(const FString&,const FHorizonUserData&) { return true; }
 static bool BeforeRestore(UHorizonSubsystem*,const FString&,bool,UHorizonExampleIdentity*&) { return true; }
 static bool AfterAuth(UHorizonSubsystem*,const FString&,UHorizonExampleIdentity*,bool,bool,bool Success) { return Success; }
};
class USeagullHorizonManager;
struct USeagullGameInstance {
 uint64 SessionGeneration=0;
 bool bPracticeMode=false,bSaveLoaded=false,bCloudSaveReady=false;
 FString SaveOwnerId;
 USeagullHorizonManager* Manager;
 USeagullHorizonManager* GetHorizonManager() { return Manager; }
 bool CanMutateProgress();
};
"""

TEST = r"""
int main() {
 FakeAuth Auth; FakeCloud Cloud{&Auth}; FakeConfig Config; FakeValidated Validated;
 UHorizonSubsystem Subsystem{&Auth,&Cloud,&Config,&Validated};
 USeagullGameInstance GI; USeagullHorizonManager Manager; GI.Manager=&Manager; Manager.Outer=&GI; Manager.Initialize(&Subsystem);
 int AuthResult=0,BusyResult=0;
 Manager.SignInEmail("a","pw",[&](bool Ok){ AuthResult=Ok?1:-1; });
 assert(Manager.IsAuthenticating() && Auth.Pending.size()==1);
 ++GI.SessionGeneration; GI.bPracticeMode=true; GI.SaveOwnerId="practice";
 Manager.SignInEmail("b","pw",[&](bool Ok){ BusyResult=Ok?1:-1; });
 assert(Auth.Pending.size()==1 && BusyResult==-1);
 Auth.Complete("a"); assert(AuthResult==-1 && GI.bPracticeMode && !Manager.IsAuthenticating());
 Manager.SignInEmail("logout race","pw",[&](bool Ok){ AuthResult=Ok?1:-1; });
 Manager.SignOut(); Auth.Complete("late login");
 assert(AuthResult==-1 && !Manager.IsSignedIn() && !Manager.IsAuthenticating());
 Manager.SignInEmail("b","pw",[&](bool Ok){ AuthResult=Ok?1:-1; }); Auth.Complete("b"); assert(AuthResult==1);
 GI.bPracticeMode=false; GI.SaveOwnerId="b"; ++GI.SessionGeneration;
 assert(!GI.CanMutateProgress());
 bool SaveRejected=false;
 Manager.SaveData("unsafe",[&](bool Ok){ SaveRejected=!Ok; }); assert(SaveRejected && Cloud.Sent.empty());
 bool StaleReadAccepted=true,StaleConfigAccepted=true;
 Manager.LoadData([&](bool Ok,const FString& Data){ StaleReadAccepted=Ok || !Data.IsEmpty(); });
 Manager.LoadAllConfigs([&](bool Ok,const TMap<FString,FString>& Data){ StaleConfigAccepted=Ok || !Data.empty(); });
 ++GI.SessionGeneration; GI.bPracticeMode=true; GI.SaveOwnerId="practice";
 Cloud.Reads.front()(true,"old save"); Config.Reads.front()(true,{{"board","old"}});
 assert(!StaleReadAccepted && !StaleConfigAccepted);
 GI.bPracticeMode=false; GI.SaveOwnerId="b"; GI.bSaveLoaded=true; GI.bCloudSaveReady=true;
 bool EmptySlotOk=false,EmptySlotData=true,FailedReadOk=true;
 Manager.LoadData([&](bool Ok,const FString& Data){ EmptySlotOk=Ok; EmptySlotData=!Data.IsEmpty(); });
 Manager.LoadData([&](bool Ok,const FString&){ FailedReadOk=Ok; });
 Cloud.Reads[1](true,""); Cloud.Reads[2](false,"");
 assert(EmptySlotOk && !EmptySlotData && !FailedReadOk); // A guest without a save may save; a failed read keeps saving off.
 bool FirstSaved=false,SecondSaved=false,ThirdSaved=false;
 Manager.SaveData("purchase",[&](bool Ok){ FirstSaved=Ok; });
 Manager.SaveData("gift",[&](bool Ok){ SecondSaved=Ok; });
 Manager.SaveData("run",[&](bool Ok){ ThirdSaved=Ok; });
 assert(Cloud.Sent.size()==1 && Cloud.Sent[0].Json=="purchase");
 Cloud.Complete(); assert(FirstSaved && Cloud.Sent.size()==2 && Cloud.Sent[1].Json=="gift");
 Cloud.Complete(); Cloud.Complete(); assert(SecondSaved && ThirdSaved && Cloud.Sent[2].Json=="run");
 bool OldWriteAccepted=true,QueuedOldAccepted=true;
 Manager.SaveData("old in flight",[&](bool Ok){ OldWriteAccepted=Ok; });
 Manager.SaveData("old queued",[&](bool Ok){ QueuedOldAccepted=Ok; });
 ++GI.SessionGeneration; GI.SaveOwnerId="c"; Auth.Current.UserId="c";
 bool NewSaved=false; Manager.SaveData("new owner",[&](bool Ok){ NewSaved=Ok; });
 const auto Before=Cloud.Sent.size(); Cloud.Complete();
 assert(!OldWriteAccepted && !QueuedOldAccepted && Cloud.Sent.size()==Before+1 && Cloud.Sent.back().Owner=="c");
 Cloud.Complete(); assert(NewSaved);
 int OldTicket=0,BusyTicket=0;
 Manager.StartValidatedRun("default",[&](bool Ok,int32,const FString&){ OldTicket=Ok?1:-1; });
 ++GI.SessionGeneration; GI.bPracticeMode=true; GI.SaveOwnerId="practice"; Manager.DiscardValidatedRun();
 GI.bPracticeMode=false; GI.SaveOwnerId="c";
 Manager.StartValidatedRun("default",[&](bool Ok,int32,const FString&){ BusyTicket=Ok?1:-1; });
 assert(Validated.Starts.size()==1 && BusyTicket==-1);
 Validated.CompleteStart("old ticket"); assert(OldTicket==-1 && !Validated.Active);
 Manager.StartValidatedRun("default",[](bool Ok,int32 Seed,const FString&){ assert(Ok && Seed==123); });
 Validated.CompleteStart("new ticket");
 assert(Manager.EvidenceRunId=="new ticket");
 Validated.EarlyEvidence=[&] { Manager.HandleEvidenceUploadFailed("new ticket","EVIDENCE_TOO_LARGE","limit"); };
 bool ScoreAccepted=false;
 Manager.SubmitValidatedScore(120,{},"wave_2","",0,[&](bool Ok,int64 Rank,const FString&){ ScoreAccepted=Ok && Rank==7; });
 Validated.CompleteSubmit();
 assert(ScoreAccepted && Manager.GetEvidenceStatus().find("EVIDENCE_TOO_LARGE")!=std::string::npos);
 auto Status=Manager.GetEvidenceStatus(); Manager.HandleEvidenceUploaded("old ticket",10); assert(Status==Manager.GetEvidenceStatus());
 Manager.DiscardValidatedRun(); Manager.HandleEvidenceUploaded("new ticket",10); assert(Manager.GetEvidenceStatus()=="No evidence requested");
 std::cout << "PASS: actual facade delayed auth/practice, stale config/save loads, preload lock, ordered owner-bound writes, ticket serialization and early/stale evidence\n";
}
"""

source = FACADE.read_text()
names = ["Initialize", "BeginAuthRequest", "CompleteAuthRequest", "SignUpAnonymous", "SignInEmail", "SignUpEmail",
         "RestoreSession", "SignInWithApple", "SignOut", "IsSignedIn", "GetUserId", "IsCurrentSession",
         "SaveData", "DrainCloudSaves", "LoadData", "LoadAllConfigs", "StartValidatedRun", "DiscardValidatedRun",
         "SubmitValidatedScore", "HandleEvidenceUploaded", "HandleEvidenceUploadFailed"]
declaration = HEADER.read_text().split("UCLASS()", 1)[1].replace("private:", "public:")
production = "\n\n".join(method(source, "USeagullHorizonManager", name) for name in names)
production += "\n" + method(GI.read_text(), "USeagullGameInstance", "CanMutateProgress")
with tempfile.TemporaryDirectory(prefix="seagull-session-boundary-") as temporary:
    folder = Path(temporary)
    cpp = folder / "SessionBoundaryTest.cpp"
    cpp.write_text(SHIM + declaration + production + TEST)
    binary = folder / "session-boundary-test"
    subprocess.run([os.environ.get("CXX", "c++"), "-std=c++17", str(cpp), "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
