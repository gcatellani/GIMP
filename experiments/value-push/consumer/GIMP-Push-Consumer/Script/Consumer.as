// Independent consumer: no reference to the provider's custom classes.
class UGIMP_PushReadout : UUserWidget
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
// These records are consumer-owned copies; this type never crosses the mod boundary.
struct FGIMP_PushRecord
{
    FString Key,Type,Text,Provider,Generation;
    float32 Number=0;
    int Sequence=0;
    float64 ReceivedAt=0;
}
class UGIMP_PushConsumer : UGothicModExt_WorldSubsystem
{
    UPROPERTY() UGIMP_PushReadout View;
    UPROPERTY() USceneComponent NumberSignal;
    UPROPERTY() USceneComponent StringSignal;
    TArray<FGIMP_PushRecord> Queue;
    FString Generation,Latest,Delayed;
    int Notifications=0,Processed=0,Invalid=0;
    UFUNCTION(BlueprintOverride) void HandleReadyForPlay()
    {
        System::SetTimer(this,n"Discover",0.2f,false);
        System::SetTimer(this,n"DiscoverAgain",10.0f,false);
        System::SetTimer(this,n"ProcessQueue",0.1f,true);
    }
    UFUNCTION() void DiscoverAgain() { Discover(); }
    UFUNCTION() void Discover()
    {
        if(IsValid(NumberSignal) && IsValid(StringSignal)) return;
        TArray<AActor> Actors; Gameplay::GetAllActorsWithTag(n"GIMP",Actors);
        for(auto Actor:Actors)
        {
            if(!IsValid(Actor)) continue;
            auto Header=Cast<UBlackboardComponent>(Actor.GetComponentByClass(UBlackboardComponent));
            if(!IsValid(Header) || Header.GetValueAsString(n"protocol")!="GIMP" || Header.GetValueAsInt(n"protocolversion")!=1 ||
                Header.GetValueAsString(n"provider")!="gimp.test.push") continue;
            auto Values=Cast<UBlackboardComponent>(Header.GetValueAsObject(n"value")); if(!IsValid(Values)) continue;
            Generation=Header.GetValueAsString(n"generation");
            NumberSignal=USceneComponent::Get(Values.GetOwner(),n"random");
            StringSignal=USceneComponent::Get(Values.GetOwner(),n"state");
            if(!IsValid(NumberSignal) || !IsValid(StringSignal)) continue;
            NumberSignal.OnComponentActivated.AddUFunction(this,n"OnPushedValue");
            StringSignal.OnComponentActivated.AddUFunction(this,n"OnPushedValue");
            // Values is not cached or read: updates come only from event snapshots.
            EnsureView(); return;
        }
    }
    void EnsureView()
    {
        if(IsValid(View)) return;
        auto Player=Gameplay::GetPlayerController(0); if(!IsValid(Player)) return;
        View=Cast<UGIMP_PushReadout>(WidgetBlueprint::CreateWidget(UGIMP_PushReadout,Player));
        if(IsValid(View)) View.AddToViewport(10000);
    }
    FString Describe(FGIMP_PushRecord Record)
    {
        FString Value=Record.Type=="number" ? ""+Record.Number:Record.Text;
        return "#"+Record.Sequence+"  key: "+Record.Key+"  type: "+Record.Type+"  value: "+Value;
    }
    UFUNCTION() void OnPushedValue(UActorComponent Component,bool Reset)
    {
        auto Snapshot=Cast<UBlackboardComponent>(Component);
        if(!IsValid(Snapshot)) { Invalid++; return; }
        FGIMP_PushRecord Record;
        Record.Provider=Snapshot.GetValueAsString(n"provider"); Record.Generation=Snapshot.GetValueAsString(n"generation");
        Record.Key=Snapshot.GetValueAsString(n"key"); Record.Type=Snapshot.GetValueAsString(n"type");
        Record.Sequence=Snapshot.GetValueAsInt(n"sequence"); Record.ReceivedAt=Gameplay::GetRealTimeSeconds();
        if(Record.Provider!="gimp.test.push" || Record.Generation!=Generation ||
           (Record.Type!="number" && Record.Type!="string")) { Invalid++; return; }
        if(Record.Type=="number") Record.Number=Snapshot.GetValueAsFloat(n"value"); else Record.Text=Snapshot.GetValueAsString(n"value");
        Notifications++; Queue.Add(Record); Latest=Describe(Record); RefreshDisplay();
    }
    UFUNCTION() void ProcessQueue()
    {
        while(Queue.Num()>0 && Gameplay::GetRealTimeSeconds()-Queue[0].ReceivedAt>=3)
        {
            FGIMP_PushRecord Record=Queue[0]; Queue.RemoveAt(0); Processed++; Delayed=Describe(Record);
            FJsonObject Evidence;
            Evidence.SetNumberField("notifications",Notifications); Evidence.SetNumberField("processedAfterDelay",Processed);
            Evidence.SetNumberField("queued",Queue.Num()); Evidence.SetNumberField("invalid",Invalid);
            Evidence.SetStringField("latest",Latest); Evidence.SetStringField("delayedCopy",Delayed);
            Evidence.SetStringField("key",Record.Key); Evidence.SetStringField("type",Record.Type);
            if(Record.Type=="number") Evidence.SetNumberField("value",Record.Number); else Evidence.SetStringField("value",Record.Text);
            Evidence.SetNumberField("sequence",Record.Sequence); Evidence.SetNumberField("ageSeconds",Gameplay::GetRealTimeSeconds()-Record.ReceivedAt);
            Evidence.SetStringField("generation",Generation);
            FFileHelper::SaveStringToFile(Evidence.SaveToString(false),System::GetProjectSavedDirectory()+"gimp-push-evidence.json",FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM);
        }
        RefreshDisplay();
    }
    void RefreshDisplay()
    {
        EnsureView();
        if(IsValid(View) && IsValid(View.Label)) View.Label.SetText(FText::FromString("GIMP pushed values\nReceived: "+Latest+"\nQueued copy (3s later): "+Delayed+"\nEvents: "+Notifications+" | processed: "+Processed+" | queued: "+Queue.Num()));
    }
}
