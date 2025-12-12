# Bolt's Journal ⚡

## 2024-05-22 - Universal Loop Hygiene
- **Discovery**: `UpdateSpeed` and `UpdateJump` in `Universal.lua` accessed `LocalPlayer.Character` and called `FindFirstChild` multiple times per frame.
- **Optimization**: Cached `Character` and `Humanoid` in local variables inside the loop.
- **Why**: Reduces Lua bridge overhead and property indexing cost in critical `Heartbeat` loops (60+ FPS).

## 2024-05-22 - Memory Leak Discovery (Pending)
- **Discovery**: `Utils.ESP:Add` in `main/modules/Utils.lua` inserts a connection into `Utils.Connections` but `Utils.ESP:Remove` does not remove it.
- **Impact**: Toggling ESP repeatedly creates accumulated connections on the character that are only cleared on `DeepClean` or script unload.
- **Action Required**: Refactor `Utils.ESP` to manage its own connections map to allow precise disconnection.
