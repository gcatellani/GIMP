// Independent consumer: no reference to the provider's custom classes.
class UGIMP_DiscoveryReadout : UUserWidget
{
    UPROPERTY() UTextBlock Label;
    UFUNCTION(BlueprintOverride) void OnInitialized()
    {
        auto Canvas=Cast<UCanvasPanel>(ConstructWidget(UCanvasPanel)); SetRootWidget(Canvas);
        auto Panel=Cast<UBorder>(ConstructWidget(UBorder));
        FSlateBrush Brush; Brush.DrawAs=ESlateBrushDrawType::Image; Brush.TintColor=FSlateColor(FLinearColor(1,1,1,1));
        Panel.SetBrush(Brush); Panel.SetBrushColor(FLinearColor(0,0,0,1)); Panel.SetPadding(FMargin(10));
        auto Placement=Canvas.AddChildToCanvas(Panel); Placement.SetPosition(FVector2D(30,180)); Placement.SetAutoSize(true);
        Label=Cast<UTextBlock>(ConstructWidget(UTextBlock)); Label.SetText(FText::FromString("GIMP: waiting for provider"));
        Label.SetColorAndOpacity(FSlateColor(FLinearColor(1,1,1,1)));
        FSlateFontInfo Font=Label.GetFont(); Font.Size=16; Label.SetFont(Font);
        Panel.SetContent(Label); SetVisibility(ESlateVisibility::HitTestInvisible);
    }
}
class UGIMP_DiscoveryConsumer : UGothicModExt_WorldSubsystem
{
    UPROPERTY() UGIMP_DiscoveryReadout View;
    UPROPERTY() UBlackboardComponent Values;
    UPROPERTY() USceneComponent Signal;
    FString Generation;
    int Notifications=0;
    bool EnvelopeValid=false;
    FString Trace;
    void Probe(FString Event)
    {
        TArray<AActor> Candidates; Gameplay::GetAllActorsWithTag(n"GIMP",Candidates);
        FString IDs; int Valid=0;
        for(auto Candidate:Candidates)
        {
            if(!IsValid(Candidate)) continue;
            auto Header=Cast<UBlackboardComponent>(Candidate.GetComponentByClass(UBlackboardComponent));
            if(IsValid(Header) && Header.GetValueAsString(n"protocol")=="GIMP" && Header.GetValueAsInt(n"protocolversion")==1 &&
               IsValid(Header.GetValueAsObject(n"value"))) { Valid++; IDs+=Header.GetValueAsString(n"provider")+","; }
        }
        Trace+="time="+Gameplay::GetRealTimeSeconds()+" world="+GetWorld().GetPathName()+" event="+Event+" valid="+Valid+" providers="+IDs+"\n";
        FFileHelper::SaveStringToFile(Trace,System::GetProjectSavedDirectory()+"gimp-discovery-consumer.txt",FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM);
    }
    UFUNCTION(BlueprintOverride) void HandleSaveGameLoaded() { Probe("SaveGameLoaded"); }
    UFUNCTION(BlueprintOverride) void HandlePlayerCharacterBeginPlay(AGothicCharacter Character) { Probe("PlayerBeginPlay"); }
    UFUNCTION() void ProbeNextFrame() { Probe("Deferred-next-tick"); }
    UFUNCTION() void Probe50ms() { Probe("Deferred-50ms"); }
    UFUNCTION() void Probe1s() { Probe("Deferred-1s"); }
    UFUNCTION() void Probe4s() { Probe("Deferred-4s"); }
    UFUNCTION() void Probe13s() { Probe("Deferred-13s"); }

    UFUNCTION(BlueprintOverride) void HandleReadyForPlay()
    {
        Probe("ReadyForPlay");
        System::SetTimer(this,n"ProbeNextFrame",0.001f,false);
        System::SetTimer(this,n"Probe50ms",0.05f,false);
        System::SetTimer(this,n"Probe1s",1.0f,false);
        System::SetTimer(this,n"Probe4s",4.0f,false);
        System::SetTimer(this,n"Probe13s",13.0f,false);
        System::SetTimer(this,n"Discover",0.2f,false);
        System::SetTimer(this,n"DiscoverAgain",10.0f,false);
        // This timer checks only widget/endpoint lifetime, never reads a data value.
        System::SetTimer(this,n"MaintainView",0.5f,true);
    }
    UFUNCTION() void MaintainView()
    {
        if(!IsValid(View))
        {
            auto Player=Gameplay::GetPlayerController(0); if(!IsValid(Player)) return;
            View=Cast<UGIMP_DiscoveryReadout>(WidgetBlueprint::CreateWidget(UGIMP_DiscoveryReadout,Player));
            if(IsValid(View)) { View.AddToViewport(10000); if(IsValid(Values)) ReadValue(false); }
        }
        if(IsValid(Signal) && !IsValid(Values)) { Signal.OnComponentActivated.Unbind(this,n"OnRandomChanged"); Signal=nullptr; }
    }
    UFUNCTION() void DiscoverAgain() { Probe("Deferred-10s"); Discover(); }
    UFUNCTION() void Discover()
    {
        Probe("Discover-200ms-or-10s");
        if(IsValid(Values) && IsValid(Signal)) return;
        TArray<AActor> Actors; Gameplay::GetAllActorsWithTag(n"GIMP",Actors);
        for(auto Actor:Actors)
        {
            if(!IsValid(Actor)) continue;
            auto Header=Cast<UBlackboardComponent>(Actor.GetComponentByClass(UBlackboardComponent));
            if(!IsValid(Header) || Header.GetValueAsString(n"protocol")!="GIMP" || Header.GetValueAsInt(n"protocolversion")!=1 ||
                Header.GetValueAsString(n"provider")!="gimp.test.random") continue;
            Values=Cast<UBlackboardComponent>(Header.GetValueAsObject(n"value"));
            if(!IsValid(Values)) continue;
            Signal=USceneComponent::Get(Values.GetOwner(),n"random"); if(!IsValid(Signal)) continue;
            Generation=Header.GetValueAsString(n"generation"); EnvelopeValid=Generation.Len()>0;
            Signal.OnComponentActivated.AddUFunction(this,n"OnRandomChanged");
            MaintainView(); ReadValue(false); return;
        }
    }
    UFUNCTION() void OnRandomChanged(UActorComponent Component,bool Reset)
    {
        if(Component!=Signal || !IsValid(Values)) return;
        Notifications++; ReadValue(true);
    }
    void ReadValue(bool FromEvent)
    {
        float32 Number=Values.GetValueAsFloat(n"random");
        FString State=Values.GetValueAsString(n"state");
        if(IsValid(View) && IsValid(View.Label)) View.Label.SetText(FText::FromString("GIMP random: "+Number+" | events: "+Notifications));
        // Diagnostic evidence only; neither provider nor consumer reads this file.
        FJsonObject Evidence; Evidence.SetBoolField("envelopeValid",EnvelopeValid);
        Evidence.SetNumberField("random",Number); Evidence.SetStringField("state",State);
        Evidence.SetNumberField("notifications",Notifications); Evidence.SetBoolField("fromEvent",FromEvent);
        Evidence.SetStringField("generation",Generation);
        FFileHelper::SaveStringToFile(Evidence.SaveToString(false),System::GetProjectSavedDirectory()+"gimp-discovery-events.json",FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM);
    }
}

// Independent native world lifecycle observer: this class only logs discovery timing.
class UGIMP_DiscoveryWorldObserver : UScriptWorldSubsystem
{
    default bCreateForGameWorlds=true;
    FString Trace;
    void Probe(FString Event)
    {
        TArray<AActor> Candidates; Gameplay::GetAllActorsWithTag(n"GIMP",Candidates);
        Trace+="time="+Gameplay::GetRealTimeSeconds()+" world="+GetWorld().GetPathName()+" event="+Event+" candidates="+Candidates.Num()+"\n";
        FFileHelper::SaveStringToFile(Trace,System::GetProjectSavedDirectory()+"gimp-discovery-world.txt",FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM);
    }
    UFUNCTION(BlueprintOverride) void Initialize() { Probe("Initialize"); }
    UFUNCTION(BlueprintOverride) void PostInitialize() { Probe("PostInitialize"); }
    UFUNCTION(BlueprintOverride) void OnWorldBeginPlay() { Probe("WorldBeginPlay"); }
}
