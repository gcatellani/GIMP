// Independent provider: only native Blackboard objects cross the mod boundary.
class UGIMP_DiscoveryProvider : UGothicModExt_WorldSubsystem
{
    UPROPERTY() AAIController Endpoint;
    UPROPERTY() AAIController ValuesOwner;
    UPROPERTY() UBlackboardComponent Envelope;
    UPROPERTY() UBlackboardComponent Values;
    UPROPERTY() USceneComponent RandomChanged;
    UPROPERTY() USceneComponent StateChanged;
    int Updates=0;
    FString Trace;
    UPROPERTY() TArray<AAIController> DelayedEndpoints;
    void Record(FString Event)
    {
        Trace+="time="+Gameplay::GetRealTimeSeconds()+" world="+GetWorld().GetPathName()+" event="+Event+"\n";
        FFileHelper::SaveStringToFile(Trace,System::GetProjectSavedDirectory()+"gimp-discovery-provider.txt",FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM);
    }
    UFUNCTION(BlueprintOverride) void HandleSaveGameLoaded() { Record("SaveGameLoaded"); }
    UFUNCTION(BlueprintOverride) void HandlePlayerCharacterBeginPlay(AGothicCharacter Character) { Record("PlayerBeginPlay"); }

    UFUNCTION(BlueprintOverride) void HandleReadyForPlay()
    {
        Record("ReadyForPlay-enter");
        if(IsValid(Endpoint)) return;
        Endpoint=AAIController::Spawn(); ValuesOwner=AAIController::Spawn();
        if(!IsValid(Endpoint) || !IsValid(ValuesOwner)) return;
        Endpoint.SetActorHiddenInGame(true); Endpoint.SetActorEnableCollision(false); Endpoint.SetActorTickEnabled(false);
        ValuesOwner.SetActorHiddenInGame(true); ValuesOwner.SetActorEnableCollision(false); ValuesOwner.SetActorTickEnabled(false);
        auto Header=Cast<UBlackboardData>(NewObject(Endpoint,UBlackboardData));
        AddKey(Header,n"protocol",UBlackboardKeyType_String);
        AddKey(Header,n"protocolversion",UBlackboardKeyType_Int); AddKey(Header,n"moddataversion",UBlackboardKeyType_Int);
        AddKey(Header,n"modid",UBlackboardKeyType_String);
        AddKey(Header,n"generation",UBlackboardKeyType_String);
        AddKey(Header,n"values",UBlackboardKeyType_Object);
        auto Data=Cast<UBlackboardData>(NewObject(ValuesOwner,UBlackboardData));
        AddKey(Data,n"random",UBlackboardKeyType_Float);
        AddKey(Data,n"state",UBlackboardKeyType_String);
        if(!Endpoint.UseBlackboard(Header,Envelope) || !ValuesOwner.UseBlackboard(Data,Values)) return;
        Envelope.SetValueAsString(n"protocol","GIMP"); Envelope.SetValueAsInt(n"protocolversion",2); Envelope.SetValueAsInt(n"moddataversion",1);
        Envelope.SetValueAsString(n"modid","gimp.test.random");
        Envelope.SetValueAsString(n"generation",Guid::Conv_GuidToString(Guid::NewGuid()));
        Envelope.SetValueAsObject(n"values",Values);
        RandomChanged=USceneComponent::Create(ValuesOwner,n"random");
        StateChanged=USceneComponent::Create(ValuesOwner,n"state");
        PublishRandom(); Endpoint.Tags.Add(n"GIMP"); Record("early-endpoint-published");
        System::SetTimer(this,n"PublishDelayed3",3.0f,false);
        System::SetTimer(this,n"PublishDelayed12",12.0f,false);
        System::SetTimer(this,n"PublishRandom",1.0f,true);
        System::SetTimer(this,n"PublishState",0.4f,true);
    }
    UFUNCTION() void PublishDelayed3() { PublishDelayed("gimp.test.delay3"); }
    UFUNCTION() void PublishDelayed12() { PublishDelayed("gimp.test.delay12"); }
    void PublishDelayed(FString ProviderID)
    {
        auto Actor=AAIController::Spawn(); if(!IsValid(Actor)) return;
        Actor.SetActorHiddenInGame(true); Actor.SetActorEnableCollision(false); Actor.SetActorTickEnabled(false);
        auto Data=Cast<UBlackboardData>(NewObject(Actor,UBlackboardData));
        AddKey(Data,n"protocol",UBlackboardKeyType_String); AddKey(Data,n"protocolversion",UBlackboardKeyType_Int); AddKey(Data,n"moddataversion",UBlackboardKeyType_Int);
        AddKey(Data,n"modid",UBlackboardKeyType_String); AddKey(Data,n"generation",UBlackboardKeyType_String);
        AddKey(Data,n"values",UBlackboardKeyType_Object);
        UBlackboardComponent Header;
        if(!Actor.UseBlackboard(Data,Header)) { Record("delayed-initialize-failed"); return; }
        Header.SetValueAsString(n"protocol","GIMP"); Header.SetValueAsInt(n"protocolversion",2); Header.SetValueAsInt(n"moddataversion",1);
        Header.SetValueAsString(n"modid",ProviderID); Header.SetValueAsString(n"generation",Guid::Conv_GuidToString(Guid::NewGuid()));
        Header.SetValueAsObject(n"values",Values); Actor.Tags.Add(n"GIMP"); DelayedEndpoints.Add(Actor); Record(ProviderID+"-published");
    }
    void AddKey(UBlackboardData Data,FName KeyName,UClass Type)
    {
        FBlackboardEntry Entry; Entry.EntryName=KeyName;
        Entry.KeyType=Cast<UBlackboardKeyType>(NewObject(Data,Type)); Data.Keys.Add(Entry);
    }
    UFUNCTION() void PublishRandom()
    {
        if(!IsValid(Values) || !IsValid(RandomChanged)) return;
        Updates++; Values.SetValueAsFloat(n"random",Math::RandRange(0.0f,1000.0f));
        // Native delegate used as an explicit per-key signal, not automatic Blackboard observation.
        RandomChanged.OnComponentActivated.Broadcast(RandomChanged,false);
    }
    UFUNCTION() void PublishState()
    {
        if(!IsValid(Values) || !IsValid(StateChanged)) return;
        Values.SetValueAsString(n"state","running");
        StateChanged.OnComponentActivated.Broadcast(StateChanged,false);
    }
}
