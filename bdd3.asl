state("AVIAO3GAME", "EA")
{
    string20 LevelName: "AVIAO3GAME.EXE", 0x1EA2BD; // Level Name
    float IGT: "AVIAO3GAME.EXE", 0xA6BCF8; // In-Game Timer
    float Loading: "AVIAO3GAME.EXE", 0xDDD70C; // values: 0 (Loading), 22 (Playing)
    byte isFinished: "AVIAO3GAME.EXE", 0xDDE850; // values: 0 (Not Finished), 1 (Finished)
}
state("AVIAO3", "Demo")
{
    string20 LevelName: "AVIAO3.exe", 0x1AC37D; // Level Name
    float IGT: "AVIAO3.exe", 0xA2C458; // In-Game Timer
    float Loading: "AVIAO3.exe", 0xD9DB6C; // values: 0 (Loading), 22 (Playing)
    byte isFinished: "AVIAO3.exe", 0xD9ECB0; // values: 0 (Not Finished), 1 (Finished)
}


init
{
    vars.doneMaps = new List<string>();

    switch (modules.First().ModuleMemorySize) {
    case 15806464:
        version = "EA";
        print("Using EA version");
        break;
    case 15306752:
        version = "Demo";
        print("Using Demo version");
        break;
    default:
        throw new Exception("Unknown version: " + modules.First().ModuleMemorySize);
    }
}
update
{
}

startup
{
    settings.Add("NGP", true, "Timer start after loading NG+ save");
    settings.Add("2MAPA2.bsp", true, "MAPA2");
    settings.Add("3MAPAtreze.bsp", true, "MAPATREZE");
    settings.Add("4CARRETA.bsp", true, "CARRETA");
    settings.Add("5salga.bsp", true, "SALGA");
    settings.Add("chavinha19.bsp", true, "CHAVINHA");
    settings.Add("pierniteroi.bsp", true, "PIERNITEROI");  
    settings.Add("praca16.bsp", true, "PRACA");
    settings.Add("5aniversarioguanaSAOGONCALO.bsp", true, "ANIVERSARIO");
    settings.Add("surfamazonia.bsp", true, "SURFMAZONIA");
    settings.Add("zegaroto.bsp", true, "ZEGAROTO");
    settings.Add("RODOPRACAMARISACAMELO.bsp", true, "RODOPRACAMARISACAMELO");
    settings.Add("partaginrocket.bsp", true, "PARTAGINROCKET");
    settings.Add("myhouse.bsp", true, "MYHOUSE");    
    settings.Add("6GLOBE.bsp", true, "GLOBE");
    settings.Add("7niteroi.bsp", true, "NITEROI");
    settings.Add("8varginhao.bsp", true, "VARGINHAO");
    settings.Add("9cristopaodeacucar.bsp", true, "CRISTOPAODEACUCAR");
    settings.Add("10cristopaodeacucar2.bsp", true, "CRISTOPAODEACUCAR2");
    settings.Add("11EDINHO.bsp", true, "EDINHO");
    settings.Add("12copaloco.bsp", true, "COPALOCO");
    settings.Add("13Sambodromo.bsp", true, "SAMBODROMO");
    settings.Add("14metrorio.bsp", true, "METRORIO");
    settings.Add("15AMANHA.bsp", true, "AMANHA");
    settings.Add("16ULTIMAFASE.bsp", true, "ULTIMAFASE");
    settings.Add("17FINAL.bsp", true, "FINAL");
    settings.Add("18FINALEPILOGUE.bsp", true, "FINALEPILOGUE");
}
start
{
    if (current.IGT <= 1.5 && current.LevelName == "start.bsp" && settings["NGP"] == false)
    {
        vars.doneMaps.Add("");
        vars.doneMaps.Add(current.LevelName);
        return true;
    }
    if (current.IGT <= 1.5 && current.LevelName == "1MAPA1.bsp" && settings["NGP"] == true)
    {
        vars.doneMaps.Add("");
        vars.doneMaps.Add(current.LevelName);
        return true;
    }
}
split
{
    // Split on level change
	if(current.LevelName != old.LevelName && !vars.doneMaps.Contains(current.LevelName)) {
		if(current.Loading == 0)
		{
            vars.doneMaps.Add(current.LevelName);
			return true;
		}
	}
    // Last EA split
    if(current.LevelName == "18FINALEPILOGUE.bsp" && current.isFinished == 1 && current.Loading == 0 && version == "EA")
    {
        return true;
    }
    // Last Demo split
    if(current.LevelName == "salga.bsp" && current.isFinished == 1 && current.Loading == 0 && version == "Demo")
    {
        return true;
    }
}
isLoading
{
    if(current.Loading == 0)
    {
        return true;
    }
    if(current.Loading > 0)
    {
        return false;
    }
}
reset
{
    if(current.IGT <= 1.5 && current.LevelName == "start.bsp")
    {  
        return true;
    }
    if(current.IGT <= 1.5 && current.LevelName == "1MAPA1.bsp")
    {  
        return true;
    }
}
onReset
{
	vars.doneMaps.Clear();    
}
