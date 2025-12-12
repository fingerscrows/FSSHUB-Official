# Bolt's Journal ⚡

## 2024-05-22 - Universal Loop Hygiene
- **Discovery**: `UpdateSpeed` and `UpdateJump` in `Universal.lua` accessed `LocalPlayer.Character` and called `FindFirstChild` multiple times per frame.
- **Optimization**: Cached `Character` and `Humanoid` in local variables inside the loop.
- **Why**: Reduces Lua bridge overhead and property indexing cost in critical `Heartbeat` loops (60+ FPS).

## 2024-05-22 - Memory Leak Fix: Utils ESP
- **Discovery**: `Utils.ESP:Add` in `main/modules/Utils.lua` inserted a connection into `Utils.Connections` but `Utils.ESP:Remove` never removed it. Repeated toggling caused connection accumulation.
- **Optimization**: Refactored `Utils.ESP` to store connections in a local `Cache` table (struct: `{Highlight, Connection}`) and explicitly disconnect them in `ESP:Remove`.
- **Why**: Prevents event listener leaks that degrade server performance and memory over time.

## 2024-05-22 - SurviveWaveZ Cache Optimization
- **Discovery**: AutoFarm and Aimbot were calling `workspace.ServerZombies:GetChildren()` every frame, an O(n) operation that scales poorly with zombie count.
- **Optimization**: Implemented a `ZombieCache` table maintained via `ChildAdded`/`ChildRemoved` events. Refactored loops to iterate this cache.
- **Why**: Eliminates expensive Instance API calls in tight loops, significantly stabilizing FPS during high-wave rounds.
