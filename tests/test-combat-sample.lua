local frame,now,kind,combat=nil,0,'solo',false
function CreateFrame()
 frame={events={}}
 function frame:SetScript(k,v)self[k]=v end
 function frame:RegisterEvent(k)self.events[k]=true end
 return frame
end
function GetTime()return now end
function IsInRaid()return kind=='raid' end
function IsInGroup()return kind~='solo' end
function InCombatLockdown()return combat end
local function event(e)frame.OnEvent(frame,e)end
local function tick(dt)now=now+dt;if frame.OnUpdate then frame.OnUpdate(frame,dt)end end
local function begin()combat=true;event('PLAYER_REGEN_DISABLED')end
local function stop()combat=false;event('PLAYER_REGEN_ENABLED')end
local function db()return ForeverHandheldDB.combatSample end
dofile(arg[1]);event('PLAYER_LOGIN')
assert(not frame.OnUpdate and not db().active and #db().samples==0,'idle must not sample')
begin();event('PLAYER_REGEN_DISABLED');assert(db().sessionCounts.solo==1,'duplicate event spent quota')
for _,dt in ipairs({.01,.02,.04,.08,.2})do tick(dt)end
stop();local p=db().samples[1]
assert(p.frames==5 and math.abs(p.seconds-.35)<.000001 and p.maxMs==200)
assert(p.over33ms==3 and p.over50ms==2 and math.abs(p.averageFPS-5/.35)<.000001)
for _,n in ipairs(p.frameBins)do assert(n==1,'frame distribution incorrect')end
assert(p.reason=='combat-ended' and not p.fullMinute and not frame.OnUpdate)
local n=p.frames;tick(50);assert(p.frames==n,'idle changed finished sample')
begin();frame.OnUpdate(frame,0/0);frame.OnUpdate(frame,0);frame.OnUpdate(frame,-1);frame.OnUpdate(frame,math.huge)
for i=1,120 do tick(.5)end
p=db().samples[2];assert(p.frames==120 and p.seconds==60 and p.fullMinute and p.reason=='duration-limit')
assert(not frame.OnUpdate and not db().active,'duration cap must detach')
stop();begin();assert(not frame.OnUpdate and #db().samples==2,'solo quota exceeded')
stop();kind='party';begin();tick(.04)
kind='raid';event('GROUP_ROSTER_UPDATE');tick(.02);stop()
assert(db().samples[3].context=='party' and db().samples[3].reason=='group-context-changed')
assert(db().samples[4].context=='raid' and db().samples[4].seconds==.02)
begin();tick(.1);event('PLAYER_LEAVING_WORLD');assert(not frame.OnUpdate and db().samples[5].reason=='leaving-world')
event('PLAYER_ENTERING_WORLD');assert(not frame.OnUpdate,'raid quota bypassed on loading')
stop();kind='party';begin();tick(.05);event('PLAYER_LOGOUT')
assert(not frame.OnUpdate and #db().samples==6 and db().samples[6].reason=='logout')
-- Reload into combat starts a fresh bounded session, preserving only12records.
local saved=ForeverHandheldDB
for i=7,20 do saved.combatSample.samples[i]={marker=i} end
dofile(arg[1]);event('PLAYER_LOGIN');assert(#db().samples==12 and not db().active)
combat=true;event('PLAYER_ENTERING_WORLD');assert(frame.OnUpdate and db().sessionCounts.party==1)
tick(.01);stop();assert(#db().samples==12 and db().samples[12].reason=='combat-ended')
-- Sampler must be incapable of mutating native UI or taking game actions:
-- the harness supplies only a private frame, clocks, group/combat flags and DB.
print('PASS: idle zero polling; real interval math/bins; short fight; duplicate event; invalid timing;60s stop; per-context quota; group transition; loading/logout; reload-in-combat;12sample retention')
