// Isolated proof only. No file IO and no dependency on any consumer or GIMP.
class AGIMP_MemoryLabEndpoint : AActor
{
    UPROPERTY(DefaultComponent, RootComponent) UTextRenderComponent Payload;
}
class UGIMP_MemoryLabPublisher : UGothicModExt_WidgetExtension
{
    default AddToWidgetOfClass=n"/Game/UI/CoreMenus/MainMenu/W_MainMenu.W_MainMenu_C";
    UPROPERTY() AGIMP_MemoryLabEndpoint Endpoint;
    float64 Started=0;
    int Phase=0;
    FString Generation;
    UFUNCTION(BlueprintOverride) void Construct()
    { Started=Gameplay::GetRealTimeSeconds(); Publish(1); }
    UFUNCTION(BlueprintOverride) bool RequiresTick() const { return true; }
    void Publish(int Revision)
    {
        if(!IsValid(Endpoint))
        {
            Endpoint=Cast<AGIMP_MemoryLabEndpoint>(SpawnActor(AGIMP_MemoryLabEndpoint));
            if(!IsValid(Endpoint)) return;
            Endpoint.SetActorHiddenInGame(true); Endpoint.SetActorEnableCollision(false); Endpoint.SetActorTickEnabled(false);
            Endpoint.Payload.SetHiddenInGame(true); Endpoint.Payload.SetComponentTickEnabled(false);
            Generation=Guid::Conv_GuidToString(Guid::NewGuid());
        }
        FJsonObject Root,Values;
        Root.SetStringField("protocol","GIMP"); Root.SetNumberField("protocolversion",1);
        Root.SetStringField("provider","gimp.lab.provider"); Root.SetStringField("generation",Generation);
        Root.SetNumberField("revision",Revision);
        Values.SetStringField("health.state","active"); Values.SetNumberField("health.ratePerSecond",Revision==1 ? 0.2:0.7);
        Values.SetBoolField("enabled",true); Root.SetObjectField("value",Values);
        Endpoint.Payload.SetText(FText::FromString(Root.SaveToString(false)));
        if(!Endpoint.ActorHasTag(n"GIMP.MemoryEndpoint.lab.v1")) Endpoint.Tags.Add(n"GIMP.MemoryEndpoint.lab.v1");
    }
    UFUNCTION(BlueprintOverride) void Tick(FGeometry Geometry,float32 Delta)
    {
        float64 Elapsed=Gameplay::GetRealTimeSeconds()-Started;
        if(Phase==0 && Elapsed>=2) { Publish(2); Phase=1; }
        if(Phase==1 && Elapsed>=4)
        {
            if(IsValid(Endpoint)) { Endpoint.Tags.Empty(); Endpoint.DestroyActor(); }
            Endpoint=nullptr; Phase=2;
        }
        if(Phase==2 && Elapsed>=6) { Publish(3); Phase=3; }
    }
    UFUNCTION(BlueprintOverride) void Destruct()
    { if(IsValid(Endpoint)) { Endpoint.Tags.Empty(); Endpoint.DestroyActor(); } Endpoint=nullptr; }
}
