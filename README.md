# Walke Bypass

It works off structure and behavior instead: whether a metamethod is the native engine function or a Lua hook, who the caller is when a value gets read, and how often a remote fires on its own.

## Load it

```lua
local Bypass = loadstring(game:HttpGet("https://raw.githubusercontent.com/SkinWalkeClub/Walke-Bypass/main/walkebypass.lua"))()
local b = Bypass.new()
```

## Fire past a namecall hook

A lot of anti-cheats hook `__namecall` and inspect `getnamecallmethod()` to catch your `FireServer`. `b:fire` calls the method function directly, so there is no namecall to inspect. The method is harvested once from a throwaway remote at load, never off a game instance.

```lua
b:fire(remote, amount, target)
local r = b:invoke(remoteFunction, payload)
```

## Show the game a clean value while you cheat

Reads coming from game scripts get the baseline you set, reads coming from your own code get the truth. This is how you keep an inflated WalkSpeed without the per frame check seeing it.

```lua
b:spoof("hum","WalkSpeed",16)
b.hum.WalkSpeed = 100
```

Pass the baseline explicitly, or omit it and Bypass captures whatever the value is at the moment you call `spoof`, so call it before you change the property. Works for the Humanoid (`"hum"`) and the HumanoidRootPart (`"root"`). `b:unspoof("hum","WalkSpeed")` or `b:unspoof("hum")` to drop it.

## Keep answering integrity pings

Some games expect the client to keep firing a remote on an interval and flag you if it goes quiet after you tamper. Bypass finds those by cadence, not by name, and keeps them firing with the last payload the game sent.

```lua
b:watch()
task.wait(20)
for _,h in ipairs(b:heartbeats()) do b:keepalive(h,nil,true) end
```

`keepalive` needs `confirm=true` as the third argument, because replaying a captured payload can repeat a purchase or a state change. When the payload has to change each send, pass a function as `entry.args` and it is called every tick for fresh values. The interval is jittered by about twenty percent so it does not read as a flat heartbeat.

`b:report()` prints the metatable hook state, your active spoofs, and the heartbeat candidates. `b:stop()` undoes every hook, spoof and keepalive. Spoofs re-apply themselves after you respawn, you do not re-add them.

## Being honest about the edges

- The read spoof needs `hookmetamethod` and a working `checkcaller` to tell your reads from the game's. On an executor missing either, `spoof` returns false and changes nothing.
- Live watching also needs `hookmetamethod`. The old `rawset` fallback was removed to stay stealthy, so on an executor without it, `watch` returns false and records nothing instead of degrading to a cruder hook.
- `:fire` dodges a `__namecall` hook. If a game also hooks `__index` to catch the method being fetched, harvesting the method off a throwaway remote sidesteps the common case, but it is not proven against every anti-cheat. Unverified there.
- Heartbeat detection is cadence based. A ping that is jittered or only fires on an event will not look periodic and will not show up.

## License

MIT. Author field is in the file.
