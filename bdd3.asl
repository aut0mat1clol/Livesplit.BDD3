state("AVIAO3GAME", "1.1")
{
    string20 LevelName: 0x1F280D; // Level Name
    float IGT: 0xDE69C8; // In-Game Timer
    float Loading: 0xDFBDEC; // values: 0 (Loading), 22 (Playing)
    byte isFinished: 0x1DF0CC; // values: 0 (Not Finished), 1 (Finished)
}
state("AVIAO3GAME", "1.0")
{
    string20 LevelName: "AVIAO3GAME.EXE", 0x1F280D; // Level Name
    float IGT: "AVIAO3GAME.EXE", 0xA7CED4; // In-Game Timer
    float Loading: "AVIAO3GAME.EXE", 0xDE6CEC; // values: 0 (Loading), 22 (Playing)
    byte isFinished: "AVIAO3GAME.EXE", 0xDE7A30; // values: 0 (Not Finished), 1 (Finished)
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
    case 15306752:
        version = "Demo";
        print("Using Demo version");
        break;
    case 15847424:
        version = "1.0";
        print("Using 1.0 version");
        break;
	case 430080:
		version = "1.0";
        print("Using 1.0 version");
		break;
    default:
        throw new Exception("Unknown version: " + modules.First().ModuleMemorySize);
    }
}
update
{
    print(current.LevelName);
}

startup
{
}
start
{
    if (old.Loading > 0 && old.Loading != current.Loading && current.LevelName == "start.bsp")
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
    // Last split
    if(current.LevelName == "29FINALEPILOGUE.bsp" && current.isFinished == 1 && current.Loading == 0 && vars.LastSplit == 0)
    {
        vars.LastSplit++;
        return true;
    }
    // Last Demo split
    if(current.LevelName == "salga.bsp" && current.isFinished == 1 && current.Loading == 0 && vars.LastSplit == 0 && version == "Demo")
    {
        vars.LastSplit++;
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
onStart
{
    vars.LastSplit = 0;
}



