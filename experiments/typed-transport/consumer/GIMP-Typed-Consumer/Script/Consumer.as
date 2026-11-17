// Independent consumer: no reference to the provider's custom classes.
class UGIMP_TypedReadout : UUserWidget
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
class UGIMP_TypedConsumer : UGothicModExt_WorldSubsystem
{
    UPROPERTY() UGIMP_TypedReadout View;
    UPROPERTY() UBlackboardComponent Values;
    UPROPERTY() USceneComponent Signal;
    FString Generation;
    int Notifications=0;
    bool EnvelopeValid=false;
    UFUNCTION(BlueprintOverride) void HandleReadyForPlay()
    {
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
            View=Cast<UGIMP_TypedReadout>(WidgetBlueprint::CreateWidget(UGIMP_TypedReadout,Player));
            if(IsValid(View)) { View.AddToViewport(10000); if(IsValid(Values)) ReadValue(false); }
        }
        if(IsValid(Signal) && !IsValid(Values)) { Signal.OnComponentActivated.Unbind(this,n"OnRandomChanged"); Signal=nullptr; }
    }
    UFUNCTION() void DiscoverAgain() { Discover(); }
    UFUNCTION() void Discover()
    {
        if(IsValid(Values) && IsValid(Signal)) return;
        TArray<AActor> Actors; Gameplay::GetAllActorsWithTag(n"GIMP",Actors);
        for(auto Actor:Actors)
        {
            if(!IsValid(Actor)) continue;
            auto Header=Cast<UBlackboardComponent>(Actor.GetComponentByClass(UBlackboardComponent));
            if(!IsValid(Header) || Header.GetValueAsString(n"protocol")!="GIMP" || Header.GetValueAsInt(n"protocolversion")!=2 || Header.GetValueAsInt(n"moddataversion")!=1 ||
                Header.GetValueAsString(n"modid")!="gimp.test.random") continue;
            Values=Cast<UBlackboardComponent>(Header.GetValueAsObject(n"values"));
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
        FFileHelper::SaveStringToFile(Evidence.SaveToString(false),System::GetProjectSavedDirectory()+"gimp-typed-evidence.json",FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM);
    }
}
