-- Bounded, passive evidence from real combat. No input, names, chat or audio.
-- No update handler exists while idle. At most two samples per group context
-- are collected per login, for at most sixty seconds each.
local VERSION='3.7.88'
local driver=CreateFrame('Frame')
local current,store
local counts={solo=0,party=0,raid=0}
local function context()
 if IsInRaid() then return 'raid' end
 return IsInGroup() and 'party' or 'solo'
end
local function finish(reason)
 driver:SetScript('OnUpdate',nil)
 if not current then return end
 local p=current;current=nil
 p.reason=reason;p.finishedAt=GetTime()
 p.averageFPS=p.seconds>0 and p.frames/p.seconds or 0
 -- Fixed frame-time bins retain useful distribution evidence without a
 -- growing stream of timings. A short fight remains explicitly short.
 p.fullMinute=p.seconds>=60
 store.samples[#store.samples+1]=p
 while #store.samples>12 do table.remove(store.samples,1) end
 store.active=false;store.lastReason=reason
end
local function tick(_,dt)
 if type(dt)~='number' or dt~=dt or dt<=0 or dt==math.huge then return end
 local p=current;if not p then return end
 p.seconds=p.seconds+dt;p.frames=p.frames+1
 local ms=dt*1000;p.maxMs=math.max(p.maxMs,ms)
 local bin=ms<=16.67 and 1 or ms<=33.34 and 2 or ms<=50 and 3 or ms<=100 and 4 or 5
 p.frameBins[bin]=p.frameBins[bin]+1
 if ms>33.34 then p.over33ms=p.over33ms+1 end
 if ms>50 then p.over50ms=p.over50ms+1 end
 if p.seconds>=60 then finish('duration-limit') end
end
local function start()
 if current or not store then return end
 local kind=context();if counts[kind]>=2 then return end
 counts[kind]=counts[kind]+1
 current={version=VERSION,context=kind,startedAt=GetTime(),seconds=0,
  frames=0,maxMs=0,over33ms=0,over50ms=0,frameBins={0,0,0,0,0}}
 store.active=true;store.context=kind;store.sessionCounts=counts
 driver:SetScript('OnUpdate',tick)
end
local function initialize()
 ForeverHandheldDB=ForeverHandheldDB or {}
 local previous=ForeverHandheldDB.combatSample
 store=type(previous)=='table' and previous.version==VERSION and previous or {samples={}}
 if type(store.samples)~='table' then store.samples={} end
 while #store.samples>12 do table.remove(store.samples,1) end
 store.version=VERSION;store.active=false;store.sessionCounts=counts
 store.limits={secondsPerSample=60,samplesPerContextPerLogin=2,retainedSamples=12}
 store.environment='Not inferred: correlate Desktop/Gaming Mode separately'
 ForeverHandheldDB.combatSample=store
end
driver:SetScript('OnEvent',function(_,event)
 if event=='PLAYER_LOGIN' then initialize()
 elseif event=='PLAYER_REGEN_DISABLED' then start()
 elseif event=='PLAYER_REGEN_ENABLED' then finish('combat-ended')
 elseif event=='GROUP_ROSTER_UPDATE' then
  if current and current.context~=context() then
   finish('group-context-changed')
   if InCombatLockdown() then start() end
  end
 elseif event=='PLAYER_LEAVING_WORLD' then finish('leaving-world')
 elseif event=='PLAYER_ENTERING_WORLD' then
  if not store then initialize() end
  if InCombatLockdown() then start() end
 elseif event=='PLAYER_LOGOUT' then finish('logout') end
end)
for _,event in ipairs({'PLAYER_LOGIN','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED',
 'GROUP_ROSTER_UPDATE','PLAYER_LEAVING_WORLD','PLAYER_ENTERING_WORLD','PLAYER_LOGOUT'})do
 driver:RegisterEvent(event)
end
