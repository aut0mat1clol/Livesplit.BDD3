state("AVIAO3GAME") {}
state("FLESHCANCER") {}

startup
{
    settings.Add("split_level_end", true, "Split on level screen (isFinished)");
    
    vars.realMapWatcher = null; 
    vars.candidateWatchers = new List<StringWatcher>(); 
    
    vars.timerWatcher = null;
    vars.isFinishedWatcher = null;
    
    vars.initFailed = true;
    vars.scanAttempts = 0;

    vars.totalGameTime = 0f;    
    vars.hasSplitThisLevel = false;
    vars.completedLevels = new List<string>();
}

init
{
    vars.module = modules.First();
    vars.initFailed = true;
    vars.scanAttempts = 0;
    
    vars.isFleshcancer = game.ProcessName.ToLower().Contains("fleshcancer");
    
    if (vars.isFleshcancer) {
        print("[BDD Engine] Detected Fleshcancer.");
    } else {
        print("[BDD Engine] Detected BDD3.");
    }
}

update
{
    if (vars.initFailed)
    {
        vars.scanAttempts++;
        if (vars.scanAttempts % 100 != 0) return false;

        print("[BDD Engine] Attempting memory scan (Engine warmup)...");

        var scanner = new SignatureScanner(game, vars.module.BaseAddress, vars.module.ModuleMemorySize);

        var finishedTarget = new SigScanTarget(2, "39 1D ?? ?? ?? ?? 75 ?? 0F 2F");
        finishedTarget.OnFound = (proc, s, ptr) => {
            int offset = proc.ReadValue<int>(ptr);
            return ptr + 4 + offset; 
        };
        IntPtr finishedPtr = scanner.Scan(finishedTarget);

        var mapTarget = new SigScanTarget(8, "00 00 00 00 00 00 00 00 6D 61 70 73 2F");
        
        IntPtr ptrMap = scanner.Scan(mapTarget);
        int mapCount = 0;
        long endOfModule = vars.module.BaseAddress.ToInt64() + vars.module.ModuleMemorySize;
        
        vars.candidateWatchers.Clear(); 

        while (ptrMap != IntPtr.Zero)
        {
            vars.candidateWatchers.Add(new StringWatcher(ptrMap, ReadStringType.ASCII, 64));
            mapCount++;
            
            IntPtr nextStart = ptrMap + 1;
            long remainingSize = endOfModule - nextStart.ToInt64();
            if (remainingSize <= 0) break;
            
            var nextScanner = new SignatureScanner(game, nextStart, (int)remainingSize);
            ptrMap = nextScanner.Scan(mapTarget);
            
            if (mapCount > 100) break; 
        }

        if (finishedPtr != IntPtr.Zero && mapCount > 0)
        {
            print("[BDD Engine] WARMUP SUCCESSFUL!");
            print("[BDD Engine] isFinished found at: 0x" + finishedPtr.ToString("X"));
            
            IntPtr timerPtr = finishedPtr - 0x1188;
            print("[BDD Engine] Timer calculated at: 0x" + timerPtr.ToString("X"));
            
            vars.isFinishedWatcher = new MemoryWatcher<int>(finishedPtr);
            vars.timerWatcher = new MemoryWatcher<float>(timerPtr);
            
            print("[BDD Engine] Found " + mapCount + " potential map addresses.");
            
            vars.initFailed = false; 
        }
        else
        {
            print("[BDD Engine] Warmup failed. Retrying later...");
            return false; 
        }
    }

    vars.timerWatcher.Update(game);
    vars.isFinishedWatcher.Update(game);

    if (vars.realMapWatcher != null)
    {
        vars.realMapWatcher.Update(game);
    }
    else
    {
        foreach (var watcher in vars.candidateWatchers)
        {
            watcher.Update(game);
            
            if (watcher.Changed)
            {
                string newVal = watcher.Current;
                
                if (!string.IsNullOrEmpty(newVal) && newVal.StartsWith("maps/") && newVal.EndsWith(".bsp") && newVal.Length > 9)
                {
                    if (!newVal.Contains("b_bh"))
                    {
                        // УБРАНО ОБРАЩЕНИЕ К .Address
                        print("[BDD Engine] BINGO! Found the real map variable!");
                        print("[BDD Engine] Map value is: " + newVal);
                        
                        vars.realMapWatcher = watcher;
                        vars.candidateWatchers.Clear(); 
                        break;
                    }
                    else
                    {
                        print("[BDD Engine] Ignored background map cache: " + newVal);
                    }
                }
            }
        }
    }

    if (vars.timerWatcher == null || vars.isFinishedWatcher == null) return false;

    float currentTimer = vars.timerWatcher.Current;
    float oldTimer = vars.timerWatcher.Old;
    int currentFinished = vars.isFinishedWatcher.Current;
    int oldFinished = vars.isFinishedWatcher.Old;

    print("[BDD Engine] Map value is: " + vars.realMapWatcher.Current);

    if (oldFinished > 0 && currentFinished == 0)
    {
        vars.hasSplitThisLevel = false;
    }

    if (oldTimer > 0 && currentTimer > 0 && currentFinished == 0)
    {
        bool isHubMap = false;
        if (vars.realMapWatcher != null) {
            isHubMap = (vars.realMapWatcher.Current == "maps/start.bsp");
        }

        bool blockTimer = (vars.isFleshcancer && isHubMap);

        if (!blockTimer)
        {
            float delta = currentTimer - oldTimer;
            if (delta > 0 && delta < 1.0f)
            {
                vars.totalGameTime += delta;
            }
        }
    }
}

start
{
    if (vars.realMapWatcher == null) return false;
    
    string curMap = vars.realMapWatcher.Current;
    
    if (curMap == "maps/start.bsp" && vars.timerWatcher.Current < 1)
    {
        vars.totalGameTime = 0f;
        vars.hasSplitThisLevel = false;
        vars.completedLevels.Clear();
        print("[BDD Engine] Run started! IGT and completed levels reset.");
        return true;
    }
}

split
{
    if (vars.realMapWatcher == null || vars.isFinishedWatcher == null) return false;

    int currentFinished = vars.isFinishedWatcher.Current;
    int oldFinished = vars.isFinishedWatcher.Old;

    if (settings["split_level_end"] && oldFinished == 0 && currentFinished > 0)
    {
        string currentLevel = vars.realMapWatcher.Current;

        if (!vars.hasSplitThisLevel && currentLevel != "maps/menu.bsp" && currentLevel != "")
        {
            if (!vars.completedLevels.Contains(currentLevel))
            {
                print("[BDD Engine] Splitting! Level finished: " + currentLevel);
                vars.completedLevels.Add(currentLevel);
                vars.hasSplitThisLevel = true; 
                return true;
            }
            else
            {
                print("[BDD Engine] Ignored split for " + currentLevel + " (Already completed)");
            }
        }
    }
}

isLoading
{
    return true;
}

gameTime
{
    return TimeSpan.FromSeconds(vars.totalGameTime);
}

reset
{
    if (vars.realMapWatcher != null)
    {
        if (vars.realMapWatcher.Current == "maps/menu.bsp")
        {
            vars.completedLevels.Clear();
        }
    }
}