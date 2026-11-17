// References native types only: no publisher class, GIMP class or dependency.
class UGIMP_MemoryLabReader : UGothicModExt_WidgetExtension
{
    default AddToWidgetOfClass=n"/Game/UI/CoreMenus/MainMenu/W_MainMenu.W_MainMenu_C";
    float64 NextRead=0;
    int Last=-1;
    bool ReadFirst=false,ReadUpdate=false,ObservedRemoval=false,ReadReplacement=false,InvalidPayload=false;
    FString FirstGeneration,LastGeneration;
    UFUNCTION(BlueprintOverride) bool RequiresTick() const { return true; }
    UFUNCTION(BlueprintOverride) void Tick(FGeometry Geometry,float32 Delta)
    {
        float64 Now=Gameplay::GetRealTimeSeconds(); if(Now<NextRead) return; NextRead=Now+0.25;
        TArray<AActor> Endpoints; Gameplay::GetAllActorsWithTag(n"GIMP.MemoryEndpoint.lab.v1",Endpoints);
        int Revision=0;
        if(Endpoints.Num()==1 && IsValid(Endpoints[0]))
        {
            auto Payload=Cast<UTextRenderComponent>(Endpoints[0].GetComponentByClass(UTextRenderComponent));
            if(IsValid(Payload))
            {
                FString Text=Payload.GetText().ToString();
                FJsonObject Root,Values;
                if(Text.Len()<16384 && Root.LoadFromString(Text) && Root.GetStringField("protocol")=="GIMP" &&
                   Root.GetNumberField("protocolversion")==1 && Root.TryGetObjectField("value",Values))
                {
                    Revision=int(Root.GetNumberField("revision"));
                    LastGeneration=Root.GetStringField("generation");
                    float64 Rate=Values.GetNumberField("health.ratePerSecond");
                    bool Valid=Values.GetStringField("health.state")=="active" && Values.GetBoolField("enabled") &&
                        Math::Abs(Rate-(Revision==1 ? 0.2:0.7))<0.00001;
                    InvalidPayload=InvalidPayload || !Valid;
                    if(Revision==1 && Valid) { ReadFirst=true; FirstGeneration=LastGeneration; }
                    if(Revision==2 && Valid && LastGeneration==FirstGeneration) ReadUpdate=true;
                    if(Revision==3 && Valid && LastGeneration!=FirstGeneration) ReadReplacement=true;
                }
                else InvalidPayload=true;
            }
        }
        if(Revision==0 && ReadUpdate) ObservedRemoval=true;
        if(Revision==Last) return; Last=Revision;
        FJsonObject Evidence;
        Evidence.SetNumberField("revision",Revision); Evidence.SetBoolField("readInitialTypedValues",ReadFirst);
        Evidence.SetBoolField("readUpdatedValues",ReadUpdate); Evidence.SetBoolField("observedRemoval",ObservedRemoval);
        Evidence.SetBoolField("readReplacement",ReadReplacement); Evidence.SetBoolField("invalidPayload",InvalidPayload);
        Evidence.SetBoolField("providerModEnabled",Plugin::GetEnabledPluginNames().Contains("GIMP-Memory-Provider-Lab"));
        Evidence.SetStringField("firstGeneration",FirstGeneration); Evidence.SetStringField("lastGeneration",LastGeneration);
        // This is a test result, not the transport. The provider never reads/writes files.
        FString File=System::GetProjectSavedDirectory()+"GIMP-Lab/memory-transport-evidence.json";
        FFileHelper::SaveStringToFile(Evidence.SaveToString(false),File,FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM);
    }
}
