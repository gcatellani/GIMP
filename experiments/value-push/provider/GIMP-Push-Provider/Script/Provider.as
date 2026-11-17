// Independent provider: only native Blackboard objects cross the mod boundary.
class UGIMP_PushProvider : UGothicModExt_WorldSubsystem
{
    UPROPERTY() AAIController Endpoint;
    UPROPERTY() AAIController ValuesOwner;
    UPROPERTY() UBlackboardComponent Envelope;
    UPROPERTY() UBlackboardComponent Values;
    UPROPERTY() USceneComponent RandomChanged;
    UPROPERTY() USceneComponent StateChanged;
    int Updates=0;
    int Sequence=0;
    FString Generation;
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
        Envelope.SetValueAsString(n"provider","gimp.test.push");
        Generation=Guid::Conv_GuidToString(Guid::NewGuid()); Envelope.SetValueAsString(n"generation",Generation);
        Envelope.SetValueAsObject(n"value",Values);
        RandomChanged=USceneComponent::Create(ValuesOwner,n"random");
        StateChanged=USceneComponent::Create(ValuesOwner,n"state");
        PublishRandom(); Endpoint.Tags.Add(n"GIMP");
        System::SetTimer(this,n"PublishRandom",1.0f,true);
        System::SetTimer(this,n"PublishState",1.3f,true);
    }
    void AddKey(UBlackboardData Data,FName KeyName,UClass Type)
    {
        FBlackboardEntry Entry; Entry.EntryName=KeyName;
        Entry.KeyType=Cast<UBlackboardKeyType>(NewObject(Data,Type)); Data.Keys.Add(Entry);
    }
    UFUNCTION() void PublishRandom()
    {
        if(!IsValid(Values) || !IsValid(RandomChanged)) return;
        Updates++; float32 Number=Math::RandRange(0.0f,1000.0f);
        Values.SetValueAsFloat(n"random",Number); Push(RandomChanged,"random","number",Number,"");
    }
    UFUNCTION() void PublishState()
    {
        if(!IsValid(Values) || !IsValid(StateChanged)) return;
        FString Text=Updates%2==0 ? "idle":"active";
        Values.SetValueAsString(n"state",Text); Push(StateChanged,"state","string",0,Text);
    }
    void Push(USceneComponent Signal,FString Key,FString Type,float32 Number,FString Text)
    {
        auto Owner=AAIController::Spawn(); if(!IsValid(Owner)) return;
        Owner.SetActorHiddenInGame(true); Owner.SetActorEnableCollision(false); Owner.SetActorTickEnabled(false);
        auto Schema=Cast<UBlackboardData>(NewObject(Owner,UBlackboardData));
        AddKey(Schema,n"key",UBlackboardKeyType_String); AddKey(Schema,n"type",UBlackboardKeyType_String);
        AddKey(Schema,n"provider",UBlackboardKeyType_String); AddKey(Schema,n"generation",UBlackboardKeyType_String);
        AddKey(Schema,n"sequence",UBlackboardKeyType_Int);
        if(Type=="number") AddKey(Schema,n"value",UBlackboardKeyType_Float);
        else AddKey(Schema,n"value",UBlackboardKeyType_String);
        UBlackboardComponent Snapshot;
        if(!Owner.UseBlackboard(Schema,Snapshot)) { Owner.DestroyActor(); return; }
        Sequence++; Snapshot.SetValueAsString(n"key",Key); Snapshot.SetValueAsString(n"type",Type);
        Snapshot.SetValueAsString(n"provider","gimp.test.push"); Snapshot.SetValueAsString(n"generation",Generation);
        Snapshot.SetValueAsInt(n"sequence",Sequence);
        if(Type=="number") Snapshot.SetValueAsFloat(n"value",Number); else Snapshot.SetValueAsString(n"value",Text);
        // This separate native snapshot is borrowed for the synchronous callback.
        // Consumers copy the typed fields before returning; they do not retain it.
        Signal.OnComponentActivated.Broadcast(Snapshot,false);
        Owner.DestroyActor();
    }
}
