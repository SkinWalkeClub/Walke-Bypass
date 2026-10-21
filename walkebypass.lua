local M={}
M._VERSION="1.0.0"
M._AUTHOR="tankm3n / Skin Walke Team"
local Plrs=game:GetService("Players")
local RunS=game:GetService("RunService")
local LP=Plrs.LocalPlayer
local function have(f) return type(f)=="function" end
local getrawmt=getrawmetatable or (debug and debug.getmetatable)
local setread=setreadonly
local isread=isreadonly or function() return false end
local iscc=iscclosure or function() return false end
local checkc=checkcaller or function() return false end
local getnc=getnamecallmethod or function() return nil end
local newcc=newcclosure or function(f) return f end
local hookmm=hookmetamethod
local req=rawequal
local clock=os.clock
local fs,invk
do local re=Instance.new("RemoteEvent") fs=re.FireServer re:Destroy() local rf=Instance.new("RemoteFunction") invk=rf.InvokeServer rf:Destroy() end
local B={}
B.__index=B
function M.new()
 local s=setmetatable({},B)
 s.spoofHum={} s.spoofRoot={} s.base={} s.hum=nil s.root=nil
 s.idxOrig=nil s.idxOn=false
 s.traffic={} s.rate={} s.watching=false s.ncOrig=nil
 s.keep={} s.conns={}
 s:_bind(LP.Character)
 s.conns[#s.conns+1]=LP.CharacterAdded:Connect(function(c) s:_bind(c) end)
 return s
end
function B:_bind(c)
 if not c then return end
 self.char=c
 self.hum=c:FindFirstChildOfClass("Humanoid")
 self.root=c:FindFirstChild("HumanoidRootPart")
 for k in pairs(self.spoofHum) do if self.hum then local ok,v=pcall(function() return self.hum[k] end) if ok then self.base["H"..k]=v end end end
 for k in pairs(self.spoofRoot) do if self.root then local ok,v=pcall(function() return self.root[k] end) if ok then self.base["R"..k]=v end end end
 if not self.idxOn and (next(self.spoofHum) or next(self.spoofRoot)) then self:_ensureIdx() end
end
function M.fire(r,...) return fs(r,...) end
function M.invoke(r,...) return invk(r,...) end
function B:fire(r,...) return fs(r,...) end
function B:invoke(r,...) return invk(r,...) end
function B:scanHooks()
 local out={}
 if not have(getrawmt) then return out,"no getrawmetatable" end
 local ok,mt=pcall(getrawmt,game)
 if not ok or type(mt)~="table" then return out,"game metatable unreachable" end
 local ro=isread(mt)
 if ro and have(setread) then pcall(setread,mt,false) end
 for _,mm in ipairs({"__namecall","__index","__newindex"}) do
  local f=rawget(mt,mm)
  if type(f)=="function" then out[#out+1]={mm=mm,hooked=not iscc(f)} end
 end
 if ro and have(setread) then pcall(setread,mt,true) end
 return out
end
function B:_ensureIdx()
 if self.idxOn then return true end
 if not have(hookmm) then return false end
 local s=self
 local ok,orig=pcall(hookmm,game,"__index",newcc(function(o,k)
  if not checkc() then
   if req(o,s.hum) then local sv=s.spoofHum[k] if sv~=nil then if sv==true then return s.base["H"..k] end return sv end end
   if req(o,s.root) then local sv=s.spoofRoot[k] if sv~=nil then if sv==true then return s.base["R"..k] end return sv end end
  end
  return s.idxOrig(o,k)
 end))
 if not ok then return false end
 self.idxOrig=orig self.idxOn=true
 return true
end
function B:spoof(part,k,v)
 local tgt=part=="root" and self.spoofRoot or self.spoofHum
 local cur=part=="root" and self.root or self.hum
 if v==nil then v=true end
 tgt[k]=v
 if cur then local ok,cv=pcall(function() return cur[k] end) if ok then self.base[(part=="root" and "R" or "H")..k]=cv end end
 return self:_ensureIdx()
end
function B:unspoof(part,k)
 local tgt=part=="root" and self.spoofRoot or self.spoofHum
 if k then tgt[k]=nil else for key in pairs(tgt) do tgt[key]=nil end end
end
function B:_rec(r,fromGame,args)
 local p=r:GetFullName()
 self.traffic[#self.traffic+1]={t=clock(),p=p,game=fromGame}
 if #self.traffic>2000 then table.remove(self.traffic,1) end
 local e=self.rate[p]
 if not e then e={n=0,last=nil,gaps={},game=fromGame,r=r,args=args} self.rate[p]=e end
 e.n+=1 e.game=e.game or fromGame e.r=r
 if fromGame then e.args=args end
 if e.last then local g=clock()-e.last e.gaps[#e.gaps+1]=g if #e.gaps>24 then table.remove(e.gaps,1) end end
 e.last=clock()
end
function B:watch()
 if self.watching then return true end
 if not have(hookmm) then return false,"needs hookmetamethod, the rawset fallback was removed to stay stealthy" end
 local s=self
 local function tap(o,m,...)
  if m~="FireServer" and m~="InvokeServer" then return end
  local a={...}
  local okc,c=pcall(function() return o.ClassName end)
  if okc and (c=="RemoteEvent" or c=="RemoteFunction" or c=="UnreliableRemoteEvent") then
   pcall(function() s:_rec(o,not checkc(),a) end)
  end
 end
 local orig
 local ok2,res=pcall(hookmm,game,"__namecall",newcc(function(o,...)
  local m=getnc() if m then tap(o,m,...) end
  return orig(o,...)
 end))
 if not ok2 then return false,"hookmetamethod failed" end
 orig=res self.ncOrig=res self.watching=true
 return true
end
function B:heartbeats()
 local out={}
 for p,e in pairs(self.rate) do
  if e.game and e.n>=3 and #e.gaps>=2 then
   local sum=0 for _,g in ipairs(e.gaps) do sum+=g end
   local a=sum/#e.gaps
   if a>0 and a<=30 then
    local dev=0 for _,g in ipairs(e.gaps) do dev+=math.abs(g-a) end
    dev=dev/#e.gaps
    if dev<=a*0.5 then out[#out+1]={p=p,every=a,n=e.n,r=e.r,args=e.args} end
   end
  end
 end
 table.sort(out,function(x,y) return x.every<y.every end)
 return out
end
function B:keepalive(entry,every,confirm)
 if not entry or not entry.r then return false,"no remote" end
 if confirm~=true then return false,"this replays a captured payload and can repeat a purchase or state change, pass confirm=true to accept" end
 local r=entry.r
 local gap=every or entry.every or 5
 local args=entry.args or {}
 local dyn=type(args)=="function"
 local tok={} self.keep[r]=tok
 task.spawn(function()
  while self.keep[r]==tok and r.Parent do
   local p=dyn and table.pack(args()) or args
   pcall(function() fs(r,table.unpack(p,1,p.n or #p)) end)
   task.wait(gap*(0.8+math.random()*0.4))
  end
 end)
 return true
end
function B:stopKeepalive(r)
 if r then self.keep[r]=nil else self.keep={} end
end
function B:stop()
 if self.stopped then return end
 self.stopped=true
 self:stopKeepalive()
 self:unspoof("hum") self:unspoof("root")
 if self.idxOn and have(hookmm) and self.idxOrig then pcall(hookmm,game,"__index",self.idxOrig) end
 self.idxOn=false self.idxOrig=nil
 if self.watching then
  if have(hookmm) and self.ncOrig then pcall(hookmm,game,"__namecall",self.ncOrig) end
  self.watching=false self.ncOrig=nil
 end
 for _,c in ipairs(self.conns) do pcall(function() c:Disconnect() end) end
 self.conns={} self.traffic={} self.rate={} self.base={}
end
function B:report()
 local o={}
 o[#o+1]="== Walke Bypass =="
 o[#o+1]="client side only, the server deciding from replicated movement is out of reach"
 local h=self:scanHooks()
 o[#o+1]="metatable:"
 if #h==0 then o[#o+1]="  unreadable" else for _,m in ipairs(h) do o[#o+1]="  "..m.mm.." "..(m.hooked and "hooked (Lua)" or "native") end end
 o[#o+1]="spoofed reads:"
 local any=false
 for k,v in pairs(self.spoofHum) do any=true o[#o+1]="  Humanoid."..k.." -> "..(v==true and "baseline "..tostring(self.base["H"..k]) or tostring(v)) end
 for k,v in pairs(self.spoofRoot) do any=true o[#o+1]="  Root."..k.." -> "..(v==true and "baseline "..tostring(self.base["R"..k]) or tostring(v)) end
 if not any then o[#o+1]="  none" end
 o[#o+1]="heartbeat candidates:"
 local hb=self:heartbeats()
 if #hb==0 then o[#o+1]="  none seen, call :watch() and wait" else for _,b in ipairs(hb) do o[#o+1]=string.format("  every %.1fs x%d  %s",b.every,b.n,b.p) end end
 return table.concat(o,"\n")
end
M.Bypass=B
return M
