// Independent provider: only native Blackboard objects cross the mod boundary.
class UGIMP_TypedProvider : UGothicModExt_WorldSubsystem
{
    UPROPERTY() AAIController Endpoint;
    UPROPERTY() AAIController ValuesOwner;
    UPROPERTY() UBlackboardComponent Envelope;
    UPROPERTY() UBlackboardComponent Values;
    UPROPERTY() USceneComponent RandomChanged;
    UPROPERTY() USceneComponent StateChanged;
    int Updates=0;
    UFUNCTION(BlueprintOverride) void HandleReadyForPlay()
    {
        if(IsValid(Endpoint)) return;
        Endpoint=AAIController::Spawn(); ValuesOwner=AAIController::Spawn();
        if(!IsValid(Endpoint) || !IsValid(ValuesOwner)) return;
        Endpoint.SetActorHiddenInGame(true); Endpoint.SetActorEnableCollision(false); Endpoint.SetActorTickEnabled(false);
        ValuesOwner.SetActorHiddenInGame(true); ValuesOwner.SetActorEnableCollision(false); ValuesOwner.SetActorTickEnabled(false);
        auto Header=Cast<UBlackboardData>(NewObject(Endpoint,UBlackboardData));
        AddKey(Header,n"protocol",UBlackboardKeyType_String);
        AddKey(Header,n"protocolversion",UBlackboardKeyType_Int);
        AddKey(Header,n"provider",UBlackboardKeyType_String);
        AddKey(Header,n"generation",UBlackboardKeyType_String);
        AddKey(Header,n"value",UBlackboardKeyType_Object);
        auto Data=Cast<UBlackboardData>(NewObject(ValuesOwner,UBlackboardData));
        AddKey(Data,n"random",UBlackboardKeyType_Float);
        AddKey(Data,n"state",UBlackboardKeyType_String);
        if(!Endpoint.UseBlackboard(Header,Envelope) || !ValuesOwner.UseBlackboard(Data,Values)) return;
        Envelope.SetValueAsString(n"protocol","GIMP"); Envelope.SetValueAsInt(n"protocolversion",1);
        Envelope.SetValueAsString(n"provider","gimp.test.random");
        Envelope.SetValueAsString(n"generation",Guid::Conv_GuidToString(Guid::NewGuid()));
        Envelope.SetValueAsObject(n"value",Values);
        RandomChanged=USceneComponent::Create(ValuesOwner,n"random");
        StateChanged=USceneComponent::Create(ValuesOwner,n"state");
        PublishRandom(); Endpoint.Tags.Add(n"GIMP");
        System::SetTimer(this,n"PublishRandom",1.0f,true);
        System::SetTimer(this,n"PublishState",0.4f,true);
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
