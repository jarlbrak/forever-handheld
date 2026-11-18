-- Visibility ownership and restoration, including combat and late-loaded UI.
local driver,combat,secret
function CreateFrame() driver={SetScript=function(self,k,v)self[k]=v end};return driver end
function InCombatLockdown()return combat end
function issecretvalue(v)return v==secret end
local function frame(shown)
 return {shown=shown,alpha=1,hides=0,shows=0,
  IsForbidden=function(s)return s.forbidden end,
  IsProtected=function(s)return s.protected end,
  IsShown=function(s)return s.shown end,
  GetAlpha=function(s)return s.alpha end,
  Hide=function(s)assert(not s.protected);s.hides=s.hides+1;s.shown=false end,
  Show=function(s)assert(not s.protected);s.shows=s.shows+1;s.shown=true end}
end
UIParent=frame(true)
dofile(arg[1])
local function tick()driver.OnUpdate(driver,.1)end
tick() -- unavailable map and conversation roots are harmless
Minimap=frame(true);ControllerForeverDialogueBand=frame(false)
tick();assert(Minimap.hides==0)
ControllerForeverDialogueBand.shown=true;UIParent.alpha=.5
tick();assert(Minimap.hides==0,'do not truncate the native fade')
UIParent.alpha=0;tick();assert(not Minimap.shown and Minimap.hides==1)
for i=1,100 do tick()end
assert(Minimap.hides==1 and Minimap.shows==0,'steady dialog must not rewrite visibility')
combat=true;ControllerForeverDialogueBand.shown=false
tick();assert(Minimap.shown and Minimap.shows==1,'restore unprotected map even if combat starts')
ControllerForeverDialogueBand.shown=true;tick();assert(Minimap.hides==1,'do not initiate combat hide')
combat=false;Minimap.shown=false;tick()
ControllerForeverDialogueBand.shown=false;tick();assert(Minimap.shows==1,'never show another owner\'s hidden map')
Minimap.shown=true;ControllerForeverDialogueBand.shown=true
Minimap.protected=true;tick();assert(Minimap.hides==1)
Minimap.protected=false;Minimap.forbidden=true;tick();assert(Minimap.hides==1)
Minimap.forbidden=false;secret=0;tick();assert(Minimap.hides==1,'ignore secret alpha')
secret=nil;tick();assert(Minimap.hides==2)
local old=Minimap;Minimap=frame(true);tick()
assert(old.shown and not Minimap.shown,'restore old map before acquiring a replacement')
ControllerForeverDialogueBand.shown=false;tick();assert(Minimap.shown)
ControllerForeverTalkBox=frame(true);tick();assert(not Minimap.shown)
UIParent.alpha=.2;tick();assert(Minimap.shown,'restore when cinematic fade lifts')
UIParent.alpha=0;tick();assert(not Minimap.shown)
Minimap.protected=true;ControllerForeverTalkBox.shown=false;tick()
assert(not Minimap.shown,'do not touch newly protected frame')
Minimap.protected=false;tick();assert(Minimap.shown,'retain restoration until safe')
ControllerForeverTalkBox.shown=true
Minimap.Hide=function(s)s.shown=false;error('simulated hide failure')end
tick();assert(Minimap.shown and not driver.OnUpdate and ForeverHandheldDB.minimapVisibilityError,'fail safe restores and stops')
print('PASS minimap cinematic visibility: ownership, fade, combat restoration, secret/protected/forbidden guards, late roots, replacement, stable writes, failure cleanup')
