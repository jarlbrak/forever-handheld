-- Contract checks for live icon mirroring, modifier banks, units and target hints.
local objects,timers={},{}
local secureSetupCalls=0
SlashCmdList={} -- Supplied by Blizzard before addons load.
local methods={}
function methods:IsForbidden()return false end
function methods:GetChildren()return unpack(self.children or {})end
function methods:IsDrawLayerEnabled(k)return not (self.disabledLayers and self.disabledLayers[k])end
function methods:DisableDrawLayer(k)self.disableWrites=(self.disableWrites or 0)+1;self.disabledLayers=self.disabledLayers or {};self.disabledLayers[k]=true end
function methods:EnableDrawLayer(k)self.disabledLayers=self.disabledLayers or {};self.disabledLayers[k]=nil end
function methods:GetOwner()return self.owner end
function methods:GetEffectiveAlpha()return self.alpha or 1 end
function methods:GetName()return self.name end
function methods:GetUnboundedStringWidth()
 self.measurements=(self.measurements or 0)+1
 return self.txt and #self.txt*6 or 0
end
function methods:GetStringHeight()return self.txt and math.ceil(#self.txt/(self.width or 216)*7)*16 or 0 end
function methods:GetTextColor()return 1,1,1,1 end
function methods:NumLines()return self.numLines or 0 end
function methods:GetPrimaryTooltipData()return self.data end
function methods:IsTooltipType(k)return self.data and self.data.type==k end
function methods:SetAttribute(k,v)self.attributes=self.attributes or {};self.attributes[k]=v end
function RegisterUnitWatch(f)secureSetupCalls=secureSetupCalls+1;f.unitWatch=true end
function RegisterStateDriver(f,k,v)secureSetupCalls=secureSetupCalls+1;f.driver=v end
function UnitClass()return 'Paladin','PALADIN' end
function UnitIsUnit(a,b)return a==b end
function UnitIsConnected()return true end
function UnitGroupRolesAssigned()return 'NONE' end
function IsInRaid()return false end
function IsInGroup()return false end
function methods:SetScript(k,f)self.scripts[k]=f end
function methods:RegisterEvent(k)self.events[k]=true end
function methods:CreateTexture()return self:new()end
function methods:CreateFontString()local font=self:new();font.parent=self;return font end
function methods:CreateMaskTexture()return self:new()end
function methods:SetTexture(t)self.texture=t;self.atlas=nil;self.textureWrites=(self.textureWrites or 0)+1 end
function methods:GetTexture()return self.texture end
function methods:GetAtlas()return self.atlas end
function methods:SetAtlas(t)self.atlas=t;self.texture=nil;self.coords={0,0,0,0};self.atlasWrites=(self.atlasWrites or 0)+1 end
function methods:GetTexCoord()return unpack(self.coords or {0,1,0,1})end
function methods:SetTexCoord(...)self.coords={...};self.coordWrites=(self.coordWrites or 0)+1 end
function methods:GetVertexColor()return unpack(self.vertex or {1,1,1,1})end
function methods:SetVertexColor(...)self.vertex={...};self.vertexWrites=(self.vertexWrites or 0)+1 end
function methods:SetBackdropBorderColor(...)self.border={...};self.borderWrites=(self.borderWrites or 0)+1 end
function methods:GetAlpha()return self.alpha or 1 end
function methods:SetAlpha(a)self.alpha=a;self.alphaWrites=(self.alphaWrites or 0)+1 end
function methods:IsDesaturated()return self.desaturated or false end
function methods:SetDesaturated(v)self.desaturated=v;self.desatWrites=(self.desatWrites or 0)+1 end
function methods:SetText(t)assert(t==nil or type(t)=='string' or type(t)=='number','invalid SetText type');self.txt=t;self.textWrites=(self.textWrites or 0)+1 end
function methods:SetFormattedText(fmt,...)self.txt=string.format(fmt,...)end
function methods:GetText()return self.txt end
function methods:Show()self.hidden=false end
function methods:Hide()self.hidden=true end
function methods:SetShown(v)self.hidden=not v end
function methods:IsShown()return not self.hidden end
function methods:SetHeight(v)self.height=v end
function methods:SetWidth(v)self.width=v;self.widthWrites=(self.widthWrites or 0)+1 end
function methods:SetSize(w,h)self.width=w;self.height=h end
function methods:ClearAllPoints()self.anchorWrites=(self.anchorWrites or 0)+1 end
function methods:SetPoint(...)self.anchorWrites=(self.anchorWrites or 0)+1 end
function methods:GetWidth()return self.width or 1280 end
function methods:GetHeight()return self.height or 800 end
function methods:GetFrameLevel()return 1 end
function methods:SetFrameStrata(v)self.strata=v end
function methods:SetCooldown(s,d)self.start=s*1000;self.duration=d*1000 end
function methods:GetCooldownTimes()return self.start or 0,self.duration or 0 end
function methods:Clear()self.start=0;self.duration=0 end
function methods:SetValue(v)self.value=v end
function methods:new(name)
 local o={scripts={},events={},hidden=false,name=name};setmetatable(o,{__index=function(_,k)if methods[k] then return methods[k] end;if k:match("^[A-Z]") then return function()end end end});objects[#objects+1]=o;if name then _G[name]=o end;return o
end
function CreateFrame(_,name,parent)local f=methods:new(name);f.parent=parent;return f end
UIParent=CreateFrame('Frame','UIParent')
function CreateColor(...)return {...}end
C_Timer={After=function(_,f)timers[#timers+1]=f end}
function hooksecurefunc()end
function InCombatLockdown()return false end
function GetTime()return 2 end
function date()return 'test' end
local errors={}
function geterrorhandler()return function(e)errors[#errors+1]=e end end
local cvars={GamepadShowAutoAuraTooltip='1',SoftTargetTooltipEnemy='1',SoftTargetTooltipFriend='1',SoftTargetTooltipInteract='1',SoftTargetTooltipLocked='1'}
C_CVar={GetCVar=function(k)return cvars[k]end,SetCVar=function(k,v)cvars[k]=v end}
WorldFrame=CreateFrame('Frame','WorldFrame');GameTooltip=CreateFrame('GameTooltip','GameTooltip')
BuffFrame=CreateFrame('Frame','BuffFrame')
function BuffFrame:ClearAuraTooltipQueue() error('HUD must not mutate the native aura queue') end
ObjectiveTrackerFrame=CreateFrame('Frame','ObjectiveTrackerFrame')
function ObjectiveTrackerFrame:SetCollapsed() error('HUD must not run native tracker layout') end
Enum={TooltipDataType={Unit=1,Spell=2,Item=3}}
local tipCallbacks={}
TooltipDataProcessor={AddTooltipPostCall=function(kind,cb)tipCallbacks[kind]=cb end}
local pad={buttons={}}
local padIndex={PADLTRIGGER=1,PADRTRIGGER=2,PADDUP=3,PAD1=4}
ControllerForeverDB={skins={minimap={},chat={}}}
ControllerForever={RuleBar={readPadState=function()return pad end,gamepadStateIndex=function(k)return padIndex[k] end,latched=function()end,gameActionOf=function(a)return a.game end},Layout={apply=function()end,placeGameWindows=function()end},Skins={apply=function()end},PadDisplay={redrawSoon=function()end},CastBar={apply=function()end}}
C_Spell={GetSpellName=function(id)return 'Spell '..id end,IsSpellUsable=function()return true end,IsSpellInRange=function()return true end}
local exists,hostile,casting=true,true,true
function UnitExists(u)return exists and (u=='player' or u=='target' or u=='focus' or u=='targettarget' or u=='party1') end
function UnitHealth(u)return u=='player' and 650 or 680 end
function UnitHealthMax()return 1000 end
function UnitPower()return 50 end
function UnitPowerMax()return 100 end
function UnitPowerType()return 0,'MANA' end
function UnitIsDeadOrGhost()return false end
function UnitName()return 'Enemy' end
function UnitCanAttack()return hostile end
function UnitIsFriend()return not hostile end
function UnitIsPlayer()return false end
function UnitLevel()return 13 end
function UnitClassification()return 'normal' end
function UnitCastingInfo()if casting then return 'Shadow Bolt',nil,nil,0,5000,nil,nil,false end end
function UnitChannelInfo()end
for g,set in ipairs({'top','left','right','bottom'})do
 for i=1,8 do
  local f=CreateFrame('Frame','ControllerForeverPad'..(set=='top' and '' or set)..i)
  f.icon=f:new();f.icon:SetTexture(g*100+i);f.cooldown=f:new();f.count=f:new();f.count:SetText('2');f.press=f:new();f.press:Hide();f.crDrawn={spellID=10+i}
 end
end
ControllerForeverPadright2.crDrawn.spellID=96231
ControllerForeverPad5.crDrawn={macroName='Interact',game={key='interact',name='Interact'}}
ControllerForeverPadleft8.crDrawn={macroName='Self heal',macroText='#showtooltip\n/cast Holy Light'}
RXPFrame=CreateFrame('Frame','RXPFrame')
RXPFrame.GuideName=false;RXPFrame.Footer=false
RXPFrame.CurrentStepFrame=CreateFrame('Frame')
local guideStep=CreateFrame('Frame');guideStep:SetFrameStrata('MEDIUM')
RXPFrame.CurrentStepFrame.framePool={guideStep}
RXPG_ARROW=CreateFrame('Frame','RXPG_ARROW');RXPTargetFrame=CreateFrame('Frame','RXPTargetFrame')
function RXPFrame:Hide()error('guide visibility must not fire its tracking lifecycle')end
-- Load real dependencies in production order; the progress rail is a module
-- since3.7.85 and omitting it turns startup failures into misleading HUD tests.
local moduleDir=arg[1]:match('^(.*[/])') or ''
dofile(moduleDir..'Progress.lua')
local chunk=assert(loadfile(arg[1]))
setfenv(chunk,setmetatable({},{__index=_G,__newindex=function(_,key,value)
 assert(key~='SlashCmdList','native command registry reassignment taints built-in commands')
 rawset(_G,key,value)
end}))
chunk()
GameTooltipTextLeft1=CreateFrame('Frame','GameTooltipTextLeft1');GameTooltipTextLeft1:SetText('Startup unit')
GameTooltip.owner=WorldFrame;GameTooltip.numLines=1;GameTooltip.data={type=1}
local realGetText=GameTooltipTextLeft1.GetText
if arg[2]=='startup_failure' then GameTooltipTextLeft1.GetText=function()error('startup read failure')end end
if arg[2]=='startup_combat' then InCombatLockdown=function()return true end end
for _,o in ipairs(objects)do if o.events.PLAYER_ENTERING_WORLD then o.scripts.OnEvent(o,'PLAYER_ENTERING_WORLD') end end
local startupDriver
for _,o in ipairs(objects)do if o.events.PLAYER_ENTERING_WORLD then startupDriver=o end end
assert(not ForeverHandheldDock and secureSetupCalls==0,'early inspection initialized secure HUD/controller setup')
if arg[2]=='startup_failure' then
 assert(ForeverHandheldDB.startupInspectionError and GameTooltip:IsDrawLayerEnabled('ARTWORK') and ForeverHandheldFieldNotes.hidden,'startup failure lost native fallback')
 assert(not startupDriver.scripts.OnUpdate,'failed startup driver kept running')
 GameTooltipTextLeft1.GetText=realGetText
else
 assert(ForeverHandheldFieldNotes and not ForeverHandheldFieldNotes.hidden,'field notes wait for delayed full HUD')
 assert(ForeverHandheldFieldNotes.lines[1].left:GetText()=='Startup unit' and not GameTooltip:IsDrawLayerEnabled('ARTWORK'),'first world frame lost native unit text')
 assert(startupDriver.scripts.OnUpdate,'early inspection render driver absent')
 GameTooltip.data={type=3};startupDriver.scripts.OnUpdate(startupDriver,1/60)
 assert(GameTooltip:IsDrawLayerEnabled('ARTWORK'),'early item inspection does not restore native tooltip')
 GameTooltip.data={type=1};startupDriver.scripts.OnUpdate(startupDriver,1/60)
 assert(not GameTooltip:IsDrawLayerEnabled('ARTWORK'),'early unit repaint leaked before text tick')
 assert(cvars.GamepadShowAutoAuraTooltip=='1','early inspection changed native configuration')
 if arg[2]=='startup_failure_late' then
  GameTooltipTextLeft1.GetText=function()error('later startup read failure')end
  startupDriver.scripts.OnUpdate(startupDriver,.2)
  assert(ForeverHandheldDB.startupInspectionError and GameTooltip:IsDrawLayerEnabled('ARTWORK') and ForeverHandheldFieldNotes.hidden,'failure after veiling did not restore native tooltip')
  assert(not startupDriver.scripts.OnUpdate,'failed startup driver kept running')
  GameTooltipTextLeft1.GetText=realGetText
 end
end
local earlyNotes=ForeverHandheldFieldNotes
while #timers>0 do table.remove(timers,1)()end
if arg[2]=='startup_combat' then
 assert(not ForeverHandheldDock and secureSetupCalls==0 and startupDriver.scripts.OnUpdate,'combat startup attempted secure HUD construction')
 InCombatLockdown=function()return false end
 startupDriver.scripts.OnEvent(startupDriver,'PLAYER_REGEN_ENABLED')
 while #timers>0 do table.remove(timers,1)()end
 print('PASS: secure HUD startup deferred through combat and resumed on combat exit')
end
assert(ForeverHandheldFieldNotes==earlyNotes and not startupDriver.scripts.OnUpdate,'full HUD duplicated reader or retained early driver')
assert(ForeverHandheldDB.inspectionStartup.handoffAt,'full HUD handoff unrecorded')
if arg[2]=='startup_failure' or arg[2]=='startup_failure_late' then
 ForeverHandheldDock.scripts.OnUpdate(ForeverHandheldDock,.2)
 assert(not ForeverHandheldFieldNotes.hidden and not GameTooltip:IsDrawLayerEnabled('ARTWORK'),'full HUD failed to recover inspection after early read failure')
 print('PASS: failed early inspection restores native tooltip, stops early driver, and full HUD recovers');return
end
print('PASS: immediate unit inspection before delayed secure setup, per-render item fallback, single reader and driver handoff')
assert(#errors==0,table.concat(errors,'\n'))
assert(guideStep.strata=='BACKGROUND' and RXPG_ARROW.strata=='BACKGROUND' and RXPTargetFrame.strata=='BACKGROUND','guide stays below even LOW-strata service windows')
local function tick()ForeverHandheldDock.scripts.OnUpdate(ForeverHandheldDock,.2);assert(#errors==0,table.concat(errors,'\n'))end
tick();assert(ForeverHandheldDB.mirroredSlots==32,'32 live slots')
local function textExists(s)for _,o in ipairs(objects)do if o.txt==s then return true end end end
assert(textExists('65%'),'live player health');assert(textExists('50%'),'live mana')
assert(textExists('RT + ↑ Interrupt'),'actual interrupt binding')
assert(not ForeverHandheldTarget.hidden,'target visible')
local function textureCount(t)local n=0;for _,o in ipairs(objects)do if o.texture==t then n=n+1 end end;return n end
local ownSlot
for _,o in ipairs(objects)do if o.nativeIndex==2 and o.icon and o.icon.texture==ControllerForeverPad2.icon.texture then ownSlot=o;break end end
assert(ownSlot,'own dock slot missing')
local borders,alphas=ownSlot.borderWrites,ownSlot.alphaWrites
tick();tick();assert(ownSlot.borderWrites==borders and ownSlot.alphaWrites==alphas,'unchanged dock decoration repainted')
ControllerForeverPad2.crProcOn=true;tick();assert(ownSlot.border[1]==1 and ownSlot.borderWrites==borders+1,'proc highlight failed')
tick();assert(ownSlot.borderWrites==borders+1,'stable proc repainted')
ControllerForeverPad2.crProcOn=false;tick();assert(ownSlot.border[1]==.68 and ownSlot.borderWrites==borders+2,'proc release did not restore border')
pad.buttons[1]=true;tick();assert(ownSlot.alpha==.90 and ownSlot.alphaWrites==alphas+1,'inactive bank alpha stale')
pad.buttons[1]=false;tick();assert(ownSlot.alpha==1 and ownSlot.alphaWrites==alphas+2,'active bank alpha not restored')
print('PASS: stable bank decoration skips writes; proc start/end and trigger-bank transitions repaint immediately.')
-- Rendering stability must not suppress native changes. Sample every owned
-- icon property across all 32 slots, then change each field independently.
local owned={}
for _,o in ipairs(objects)do if o.nativeIndex and o.icon then owned[#owned+1]=o end end
assert(#owned==32)
local function writes()
 local n=0
 for _,f in ipairs(owned)do
  local icon=f.icon
  n=n+(icon.textureWrites or 0)+(icon.atlasWrites or 0)+(icon.coordWrites or 0)+(icon.vertexWrites or 0)+(icon.desatWrites or 0)+(icon.alphaWrites or 0)+(f.count.textWrites or 0)
 end
 return n
end
local function imageCountWrites()
 local n=0
 for _,f in ipairs(owned)do n=n+(f.icon.textureWrites or 0)+(f.icon.atlasWrites or 0)+(f.count.textWrites or 0)end
 return n
end
local stable=writes();local stableImages=imageCountWrites()
for i=1,600 do tick()end
print('MEASURE: total icon paint writes over600ticks32slots='..(writes()-stable))
print('MEASURE: image/count writes over600ticks32slots='..(imageCountWrites()-stableImages))
assert(writes()-stable==76800,'expected only direct UV/color/desaturation/alpha copies on stable ticks')
assert(imageCountWrites()==stableImages,'stable image/count paint repeats')
local source=ControllerForeverPad2.icon
source:SetTexture(4242);tick();assert(ownSlot.icon.texture==4242,'changed texture stale')
local uv={.1,.2,.3,.4,.5,.6,.7,.8}
source:SetTexCoord(unpack(uv));tick()
for i=1,8 do assert(ownSlot.icon.coords[i]==uv[i],'eight-value UV lost')end
local coordWrites=ownSlot.icon.coordWrites
source:SetAtlas('NativeAtlas');source:SetTexCoord(unpack(uv));tick()
assert(ownSlot.icon.atlas=='NativeAtlas' and ownSlot.icon.coordWrites==coordWrites+1,'atlas change did not restore unchanged UVs')
for i=1,8 do assert(ownSlot.icon.coords[i]==uv[i],'atlas transition lost UV')end
coordWrites=ownSlot.icon.coordWrites
source:SetTexture(4242);tick()
assert(ownSlot.icon.texture==4242 and ownSlot.icon.atlas==nil and ownSlot.icon.coordWrites==coordWrites+1,'texture transition missed paint or UV restore')
source:SetVertexColor(.2,.3,.4,.5);source:SetDesaturated(true);source:SetAlpha(.4);ControllerForeverPad2.count:SetText('9');tick()
assert(ownSlot.icon.vertex[4]==.5 and ownSlot.icon.desaturated and ownSlot.icon.alpha==.4 and ownSlot.count.txt=='9','native visual state changes lost')
-- Replace the source object to prove cached rendering still reads native state.
local oldSource=source
source=CreateFrame('Texture');source:SetTexture(5151);source:SetTexCoord(unpack(uv));ControllerForeverPad2.icon=source;tick()
assert(ownSlot.icon.texture==5151 and ownSlot.icon.alpha==1 and not ownSlot.icon.desaturated,'replacement source not observed')
-- Test secrets as opaque public stand-ins. Equality on two distinct table
-- tokens throws; every secret write must invalidate its previous public cache.
local restricted=setmetatable({},{__eq=function()error('secret equality attempted')end})
local restricted2=setmetatable({},getmetatable(restricted))
local secretValues={[restricted]=true,[restricted2]=true}
issecretvalue=function(v)return secretValues[v] or false end
local function paintSecret(method,getter,field,publicValue)
 source[getter]=function()return restricted end
 tick();assert(ownSlot.icon[field]==restricted,'secret '..method..' not forwarded')
 local before=writes();local beforeImages=imageCountWrites();tick();assert(writes()>before,'repeated secret '..method..' was cached')
 if method=='texture' or method=='atlas' then assert(imageCountWrites()>beforeImages,'repeated secret image was cached')end
 source[getter]=function()return restricted2 end
 tick();assert(ownSlot.icon[field]==restricted2,'second secret '..method..' not forwarded')
 source[getter]=function()return publicValue end
 tick();assert(ownSlot.icon[field]==publicValue,'public '..method..' stale after secret')
 source[getter]=nil
end
paintSecret('texture','GetTexture','texture',5151)
paintSecret('atlas','GetAtlas','atlas','PublicAtlas')
source:SetTexture(5151);tick()
paintSecret('alpha','GetAlpha','alpha',1)
paintSecret('desaturated','IsDesaturated','desaturated',false)
source.GetVertexColor=function()return restricted,.3,.4,1 end;tick();assert(ownSlot.icon.vertex[1]==restricted,'secret color lost')
source.GetVertexColor=nil;tick();assert(ownSlot.icon.vertex[1]==1,'public color stale after secret')
source.GetTexCoord=function()return restricted,.2,.3,.4,.5,.6,.7,.8 end;tick();assert(ownSlot.icon.coords[1]==restricted,'secret UV lost')
source.GetTexCoord=nil;tick();assert(ownSlot.icon.coords[1]==uv[1],'public UV stale after secret')
-- SetText accepts strings/numbers, so mark a valid scalar as secret here.
secretValues['9']=true;tick();local secretCountWrites=ownSlot.count.textWrites;tick()
assert(ownSlot.count.textWrites==secretCountWrites+1,'secret count was cached')
secretValues['9']=nil;tick()
assert(ownSlot.count.textWrites==secretCountWrites+2,'public count did not recover after secret')
assert(ownSlot.count.txt=='9','count failed secret/public transition')
issecretvalue=nil
ControllerForeverPad2.icon=oldSource;tick()
print('PASS: stable32slot image/count paint skip; dynamic textures, atlas transitions, full UVs, color, alpha, desaturation, count, source replacement and secret recovery')

ControllerForeverPadleft8.icon:SetTexture(998877);tick();assert(textureCount(998877)==2,'dynamic macro native icon mirrored')
ControllerForeverPadright2.cooldown:SetCooldown(1,12);tick();assert(not textExists('RT + ↑ Interrupt'),'cooldown suppresses interrupt cue')
ControllerForeverPadright2.cooldown:Clear();C_Spell.IsSpellInRange=function()return false end;tick();assert(not textExists('RT + ↑ Interrupt'),'out-of-range interrupt suppressed')
casting=false;hostile=false;tick();assert(textExists('X Interact'),'friendly uses actual interact binding')
pad.buttons[1]=true;tick();local found=false;for _,o in ipairs(objects)do if type(o.txt)=='string' and o.txt:find('A Self heal',1,true) then found=true end end;assert(found,'modifier-specific action hint')
local function contains(s)for _,o in ipairs(objects)do if type(o.txt)=='string' and o.txt:find(s,1,true) then return true end end end
assert(contains('LT  ·  ') and contains('↑ Spell 12'),'LT D-pad labels include native spell')
pad.buttons[1]=false;pad.buttons[2]=true;tick();assert(contains('RT  ·  ') and contains('↑ Spell 96231'),'RT D-pad labels')
pad.buttons[1]=true;tick();assert(contains('LT + RT  ·  '),'combined trigger labels')
ControllerForeverPadbottom2.crDrawn=nil;tick();assert(contains('↑ Unassigned'),'empty D-pad slot is explicit')
ControllerForeverPadbottom2.crMode='slot'
GamepadMainActionBarFramePageUnitBottomCenteredAnchorBottomBarActionButton2={action=74}
function GetActionInfo(slot)assert(slot==74);return 'spell',123 end
tick();assert(contains('↑ Spell 123'),'native slot fallback resolves action label')
-- Native spell groups occupy slots even when PadDisplay has no spell or macro.
local labelAction=GetActionInfo
local flyoutID=264
GetActionInfo=function(slot)assert(slot==74);return 'flyout',flyoutID end
GetFlyoutInfo=function(id)assert(id==264);return 'Blessings','Native description' end
tick();assert(contains('↑ Blessings'),'assigned spell group displayed as empty')
local native=GamepadMainActionBarFramePageUnitBottomCenteredAnchorBottomBarActionButton2
native.isFlyoutAction=true;native.spellID=19740
tick();assert(contains('↑ Spell 19740'),'native single-spell override not reflected')
native.spellID=nil
local restricted={}
issecretvalue=function(v)return v==restricted end
flyoutID=restricted;tick();assert(contains('↑ Spell group'),'restricted flyout identity displayed as empty')
flyoutID=264;GetFlyoutInfo=function()return restricted end
tick();assert(contains('↑ Spell group'),'restricted flyout name used')
issecretvalue=nil;GetFlyoutInfo=nil
tick();assert(contains('↑ Spell group'),'missing flyout API displayed as empty')
ControllerForeverPadbottom2.crLookSrc={kind='flyout',id=273}
GetFlyoutInfo=function(id)assert(id==273);return 'Utility Blessings' end
tick();assert(contains('↑ Utility Blessings'),'resolved flyout action ignored')
ControllerForeverPadbottom2.crLookSrc=nil;GetFlyoutInfo=nil;GetActionInfo=labelAction
tick();assert(contains('↑ Spell 123'),'assigned slot swap left a stale flyout label')
print('PASS: native flyout label, one-spell display, unavailable and secret metadata, reassignment')
local notices={}
ForeverHandheldControls={kind='xbox',notify=function(m)notices[#notices+1]=m end}
pad.buttons[3]=true
ControllerForeverPadbottom2.press:Show();tick();tick();assert(#notices==1 and notices[1]:find('Spell 123',1,true),'one input cue per physical press')
assert(contains('Xbox · '),'active Xbox family shown')
pad.buttons[3]=false;tick();pad.buttons[3]=true;tick();assert(#notices==2,'released press can cue again even when the native overlay lags')
pad.buttons[3]=false;ControllerForeverPadbottom2.press:Hide()
ForeverHandheldControls.kind='deck';tick();assert(contains('Deck · '),'device switch reflected')
-- Native mouse mode must not display a dead controller dock or controller
-- interaction instructions. A cursor used within controller mode keeps it.
local enabled=true
ControllerForever.RuleBar.isGamepadOn=function()return enabled end
pad.buttons[1]=false;pad.buttons[2]=false;tick()
enabled=false;tick()
assert(ForeverHandheldDB.controllerDockVisible==false and ForeverHandheldDB.mirroredSlots==0,'mouse mode removes dead mirrored controller banks')
assert(not contains('Deck · ') and not contains('Xbox · ') and not contains('X Interact'),'mouse mode clears misleading controller hints')
assert(not ForeverHandheldDock.hidden and textExists('65%'),'health/mana remain available in mouse mode')
enabled=true;tick();assert(ForeverHandheldDB.controllerDockVisible and ForeverHandheldDB.mirroredSlots==32 and contains('Deck · '),'controller mode restores all native banks and labels')
local reads,restricted,denied=0,false,false
C_Secrets={ShouldAurasBeSecret=function()return restricted end}
C_UnitAuras={GetDebuffDataByIndex=function(_,index)
 reads=reads+1
 if denied then error('Auras cannot be accessed when secret while tainted') end
 if index==1 then return {icon=12345} end
end}
local auraIcon=ForeverHandheldFocus.auras[1]
tick();assert(auraIcon:IsShown() and auraIcon:GetTexture()==12345,'readable debuff missing')
restricted=true;reads=0;tick()
assert(reads==0 and not auraIcon:IsShown() and ForeverHandheldDock:IsShown(),'secret auras disabled the HUD or leaked a stale icon')
restricted=false;denied=true;tick()
assert(ForeverHandheldDB.lastError==nil and ForeverHandheldDock:IsShown() and not auraIcon:IsShown(),'denied aura read disabled the HUD')
denied=false;tick();assert(auraIcon:IsShown(),'readable debuff failed to return')
C_Secrets,C_UnitAuras=nil,nil
print('PASS: secret aura guard, rejected reads isolated, and readable debuffs recover without HUD fallback')
exists=false;tick();assert(ForeverHandheldTarget.hidden,'no target removes target frame')
assert(ForeverHandheldDB.lastError==nil,'no runtime error')
assert(cvars.GamepadShowAutoAuraTooltip=='0','automatic aura tooltip disabled')
assert(ForeverHandheldDB.tooltipSettingsBefore.GamepadShowAutoAuraTooltip=='1','previous tooltip setting retained')
assert(ForeverHandheldFocus.unitWatch and ForeverHandheldTargetOfTarget.unitWatch,'secure secondary unit visibility')
assert(ForeverHandheldParty1.attributes.unit=='party1' and ForeverHandheldParty1.attributes.type1=='target','secure party targeting')
assert(ForeverHandheldRaid40.unitWatch,'all 40 raid positions registered')
assert(not tipCallbacks[1] and not tipCallbacks[2],'no tooltip execution hooks taint native gamepad')
GameTooltipTextLeft1=CreateFrame('Frame','GameTooltipTextLeft1');GameTooltipTextLeft1:SetText('Field subject')
GameTooltipTextRight1=CreateFrame('Frame','GameTooltipTextRight1');GameTooltipTextRight1:Hide()
GameTooltip.numLines=1;GameTooltip.owner=WorldFrame;GameTooltip.data={type=1};GameTooltip:Show();tick()
assert(not ForeverHandheldFieldNotes.hidden and textExists('Field subject'),'world info mirrored into field notes')
assert(not GameTooltip.hidden and not GameTooltip:IsDrawLayerEnabled('ARTWORK'),'native tooltip remains logically present, paint layers replaced')
local noteRow=ForeverHandheldFieldNotes.lines[1]
local noteWidthWrites=noteRow.left.widthWrites
local noteAnchorWrites=noteRow.left.anchorWrites
local veilWrites=GameTooltip.disableWrites or 0
for i=1,600 do ForeverHandheldDock.scripts.OnUpdate(ForeverHandheldDock,1/60) end
print('MEASURE: stable tooltip draw-layer writes over600renders='..((GameTooltip.disableWrites or 0)-veilWrites))
assert((GameTooltip.disableWrites or 0)==veilWrites,'stable tooltip churns native draw layers')
assert(noteRow.left.widthWrites==noteWidthWrites,'stable reader reflows its column width')
assert(noteRow.left.anchorWrites==noteAnchorWrites,'stable reader resets its anchors')
GameTooltip:EnableDrawLayer('ARTWORK')
ForeverHandheldDock.scripts.OnUpdate(ForeverHandheldDock,1/1000)
assert(not GameTooltip:IsDrawLayerEnabled('ARTWORK') and GameTooltip.disableWrites==veilWrites+1,'native repaint not veiled immediately')
print('PASS: stable tooltip skips layer writes while native repaint is corrected on next render')
GameTooltip.owner=CreateFrame('Button','SpellBookButton');GameTooltip.data={type=2};tick()
assert(GameTooltip:IsDrawLayerEnabled('ARTWORK'),'deliberate spellbook tooltip restored')
PlayerSpellsFrame=CreateFrame('Frame','PlayerSpellsFrame')
function PlayerSpellsFrame:GetRight()return self.right or 900 end
function PlayerSpellsFrame:GetEffectiveScale()return 1 end
function UIParent:GetEffectiveScale()return 1 end
local spellOwner=CreateFrame('Button','NativeSpellButton')
function spellOwner:GetParent()return PlayerSpellsFrame end
local spellAction=function()error('native spell action invoked')end
spellOwner.scripts.OnClick=spellAction
GameTooltip.owner=spellOwner;GameTooltipTextLeft1:SetText('Complete spell description');tick()
assert(not GameTooltip:IsDrawLayerEnabled('ARTWORK') and not ForeverHandheldFieldNotes.hidden,'compact spell details not in rail')
assert(ForeverHandheldFieldNotes.heading:GetText()=='FIELD NOTES  /  SPELL' and textExists('Complete spell description'),'spell content or heading lost')
Enum.TooltipDataType.Flyout=22;GameTooltip.data={type=22};GameTooltipTextLeft1:SetText('Blessings');tick()
assert(not GameTooltip:IsDrawLayerEnabled('ARTWORK') and not ForeverHandheldFieldNotes.hidden and textExists('Blessings'),'typed spellbook flyout group left stale world inspection')
GameTooltip.data={type=2};GameTooltipTextLeft1:SetText('Complete spell description');tick()

assert(GameTooltip.owner==spellOwner and spellOwner.scripts.OnClick==spellAction,'native spell ownership/actions changed')
PlayerSpellsFrame.right=1250;tick()
assert(GameTooltip:IsDrawLayerEnabled('ARTWORK') and ForeverHandheldFieldNotes.hidden,'wide spellbook must keep native detail')
PlayerSpellsFrame.right=900;tick()
ForeverHandheldComms={active=true,visible=true};tick()
assert(GameTooltip:IsDrawLayerEnabled('ARTWORK'),'chat must not leave spell description veiled without rail')
ForeverHandheldComms.active=false;ForeverHandheldComms.visible=false;GameTooltip.numLines=25;tick()
assert(GameTooltip:IsDrawLayerEnabled('ARTWORK') and ForeverHandheldFieldNotes.hidden,'spell overflow must preserve complete native tooltip')
GameTooltip.numLines=1;PlayerSpellsFrame:Hide();GameTooltipTextLeft1:SetText('Field subject')
print('PASS: compact spell inspection rail, full text and native actions; wide-book/chat/overflow fallback')
-- The separate native action-binding tooltip must use its own text pool and
-- sit above the native modal shade, without touching input or action state.
GamepadActionBarEditFrame=CreateFrame('Frame','GamepadActionBarEditFrame')
local binding=GamepadActionBarEditFrame
binding.BindingInfoFrame=CreateFrame('Frame')
function binding.BindingInfoFrame:GetRight()return 900 end
function binding.BindingInfoFrame:GetEffectiveScale()return 1 end
binding.ActionTooltip=CreateFrame('GameTooltip','GamepadActionBarEditFrameActionTooltip')
local bt=binding.ActionTooltip;bt.owner=binding;bt.data={type=2};bt.numLines=1
GamepadActionBarEditFrameActionTooltipTextLeft1=CreateFrame('Frame');GamepadActionBarEditFrameActionTooltipTextLeft1:SetText('Binding spell complete text')
GamepadActionBarEditFrameActionTooltipTextRight1=CreateFrame('Frame');GamepadActionBarEditFrameActionTooltipTextRight1:Hide()
binding.AttemptBindDown=spellAction;binding.activeMode='BIND_ACTION'
tick();assert(not bt:IsDrawLayerEnabled('ARTWORK') and textExists('Binding spell complete text'),'separate binding tooltip text pool not mirrored')
assert(ForeverHandheldFieldNotes.strata=='DIALOG' and not ForeverHandheldFieldNotes.hidden,'binding rail must be above native modal shade')
assert(binding.activeMode=='BIND_ACTION' and binding.AttemptBindDown==spellAction,'native binding state changed')
bt.numLines=25;tick();assert(bt:IsDrawLayerEnabled('ARTWORK') and ForeverHandheldFieldNotes.hidden,'binding overflow must retain full native tooltip')
bt.numLines=1;binding:Hide();tick();assert(ForeverHandheldFieldNotes.strata=='MEDIUM','binding modal stratum leaked into world')
print('PASS: native binding spell tooltip source, modal layering, overflow fallback and unchanged action capture')

GameTooltip.owner=UIParent;GameTooltip.data={type=3};tick();assert(GameTooltip:IsDrawLayerEnabled('ARTWORK'),'full item comparison preserved');assert(ForeverHandheldFieldNotes.hidden,'native item detail must replace stale unit field notes')
GameTooltip.data={type=1};GameTooltipTextLeft1:SetText(string.rep('lengthy description ',100));tick()
assert(not GameTooltip:IsDrawLayerEnabled('ARTWORK') and not ForeverHandheldFieldNotes.hidden,'lengthy details stay in custom inspection')
assert(ForeverHandheldFieldNotes.maxScroll>0 and not ForeverHandheldFieldNotes.scrollButtons[1].hidden,'long descriptions expose scroll controls')
ForeverHandheldFieldNotes.scripts.OnMouseWheel(ForeverHandheldFieldNotes,-1);assert(ForeverHandheldFieldNotes.offset>0,'detail scrolling works')
GameTooltipTextLeft1:SetText('Field subject');tick();assert(not GameTooltip:IsDrawLayerEnabled('ARTWORK'))

BuffFrame=CreateFrame('Frame','BuffFrame');GameTooltip.owner=BuffFrame;GameTooltip.data={type=2};tick();assert(not GameTooltip:IsDrawLayerEnabled('ARTWORK'),'manual buff inspection shares field notes')
GameTooltipTextLeft1:SetText('Blessing of Might')
GameTooltipTextRight1:SetText('Magic');GameTooltipTextRight1:Show();tick()
assert(noteRow.left.width>=176 and noteRow.right.width==32,'short right label stole the title column')
local measured=noteRow.right.measurements
for _=1,30 do tick() end
assert(noteRow.right.measurements==measured,'stable right label measured again')
local restrictedRight='Restricted data'
issecretvalue=function(v)return v==restrictedRight end
GameTooltipTextRight1:SetText(restrictedRight);tick()
assert(noteRow.right.width==76 and noteRow.right.measurements==measured,'restricted text was measured')
issecretvalue=nil

GameTooltipTextRight1:SetText('A very long comparison value');tick()
assert(noteRow.right.width==76 and noteRow.left.width==134,'long right label escaped its column')
GameTooltipTextRight1:Hide();GameTooltipTextLeft1:SetText('Field subject');tick()
assert(noteRow.left.width==216,'single column did not get full width')
print('PASS: Field Notes lends title width to short right labels, wraps long values, and reuses text measurements')
GameTooltip.data={type=1}

-- Native fade opacity changes must not make any tooltip paint visible, even
-- between HUD ticks; includes the NineSlice child and cleared tooltip metadata.
local border=CreateFrame('Frame','TooltipBorder');border:DisableDrawLayer('HIGHLIGHT');GameTooltip.children={border};tick()
GameTooltip:SetAlpha(.9);assert(not GameTooltip:IsDrawLayerEnabled('ARTWORK') and not border:IsDrawLayerEnabled('BORDER'),'fade alpha cannot repaint hidden layers')
GameTooltip.owner=nil;GameTooltip.data=nil;GameTooltip.numLines=0;tick();assert(not GameTooltip:IsDrawLayerEnabled('ARTWORK'),'leave/cleared data retains veil through fade')
GameTooltip:Hide();tick();assert(not GameTooltip:IsDrawLayerEnabled('ARTWORK') and not border:IsDrawLayerEnabled('BORDER'),'hidden world tooltip retains veil between appearances')
assert(not ForeverHandheldFieldNotes.hidden and textExists('Field subject'),'last unit notes persist after native tooltip hides')
local editFocused=true
local nativeChatEdit={HasFocus=function()return editFocused end}
ChatEdit_GetActiveWindow=function()return nativeChatEdit end
ForeverHandheldDock.scripts.OnUpdate(ForeverHandheldDock,1/60)
assert(ForeverHandheldFieldNotes.hidden,'native chat focus did not clear the rail on the first render')
tick();assert(ForeverHandheldFieldNotes.hidden,'field note refresh covered active chat')
-- A visible rail owner should preserve native tooltip paint rather than
-- veiling both views. While covered the notes painter must stop doing work.
GameTooltip.owner=WorldFrame;GameTooltip.data={type=1};GameTooltip.numLines=1;GameTooltip:Show()
local writes=noteRow.left.textWrites;tick()
assert(GameTooltip:IsDrawLayerEnabled('ARTWORK'),'world tooltip veiled when chat owns the rail')
assert(noteRow.left.textWrites==writes,'covered notes still repainted')
GameTooltip:Hide()
editFocused=false;tick()
assert(not ForeverHandheldFieldNotes.hidden and textExists('Field subject'),'closing chat lost the last inspection')
ForeverHandheldComms={active=true,visible=false};tick()
assert(not ForeverHandheldFieldNotes.hidden,'hidden parked draft still owns the rail')
ForeverHandheldComms.visible=true;tick();assert(ForeverHandheldFieldNotes.hidden,'visible parked draft failed to reserve the rail')
ForeverHandheldComms=nil;tick()
ChatEdit_GetActiveWindow=nil
print('PASS: native chat immediately clears the field notes rail and restores the last inspection on close')
SocialUIFrame=CreateFrame('Frame','SocialUIFrame')
SocialUIFrame.IsVisible=SocialUIFrame.IsShown
local friendRow=CreateFrame('Button','FriendRow',SocialUIFrame)
GameTooltip:Show();GameTooltip.owner=friendRow;GameTooltip.numLines=1;GameTooltip.data=nil
ForeverHandheldDock.scripts.OnUpdate(ForeverHandheldDock,1/60)
assert(ForeverHandheldFieldNotes.hidden,'Social did not clear the rail on the first render')
tick();assert(ForeverHandheldFieldNotes.hidden and GameTooltip:IsDrawLayerEnabled('ARTWORK'),'Social detail must keep its native tooltip and the rail clear')
GameTooltip:Hide();SocialUIFrame:Hide();tick()
assert(not ForeverHandheldFieldNotes.hidden and textExists('Field subject'),'closing Social lost the previous world inspection')
print('PASS: Social yields to native row details and restores the previous world inspection')
-- A new world tooltip must be veiled on a 1/60-second render, before the
-- expensive 10 Hz text pass. Mouse/item inspection restores on the same cadence.
GameTooltip:Show();GameTooltip.owner=CreateFrame('Button','BagItem');GameTooltip.numLines=1;GameTooltip.data={type=3}
ForeverHandheldDock.scripts.OnUpdate(ForeverHandheldDock,1/60)
assert(GameTooltip:IsDrawLayerEnabled('ARTWORK') and border:IsDrawLayerEnabled('BORDER') and not border:IsDrawLayerEnabled('HIGHLIGHT'),'item inspection restores exact paint flags on its first render')
local lastContext=ForeverHandheldDB.contextDebug
GameTooltip.owner=WorldFrame;GameTooltip.data={type=1}
ForeverHandheldDock.scripts.OnUpdate(ForeverHandheldDock,1/60)
assert(not GameTooltip:IsDrawLayerEnabled('ARTWORK'),'new world tooltip does not wait for 10 Hz refresh')
assert(ForeverHandheldDB.contextDebug==lastContext,'paint-only render does not rebuild field-note text/layout')
local freshBorder=CreateFrame('Frame','NewTooltipBorder');GameTooltip.children={border,freshBorder}
GameTooltip:EnableDrawLayer('ARTWORK')
ForeverHandheldDock.scripts.OnUpdate(ForeverHandheldDock,1/60)
assert(not GameTooltip:IsDrawLayerEnabled('ARTWORK') and not freshBorder:IsDrawLayerEnabled('BORDER'),'native repaint and newly added children are veiled next render')
GameTooltip.numLines=25
ForeverHandheldDock.scripts.OnUpdate(ForeverHandheldDock,1/60)
assert(GameTooltip:IsDrawLayerEnabled('ARTWORK'),'overflow remains accessible without waiting for text tick')
GameTooltip.owner=UIParent;GameTooltip.numLines=1;GameTooltip.data={type=1};tick()

C_TooltipInfo={GetUnit=function(unit)return {lines={{leftText='Full unit name: '..unit},{leftText='Faction and role'}}}end}
ForeverHandheldParty1.scripts.OnEnter();tick();assert(textExists('Full unit name: party1'),'party hover shares field notes')
ForeverHandheldParty1.scripts.OnLeave();tick();assert(not textExists('Full unit name: party1'),'leaving party hover releases inspection')
GameTooltip.numLines=25;tick();assert(GameTooltip:IsDrawLayerEnabled('ARTWORK'),'pool overflow does not discard source lines');GameTooltip.numLines=1;tick()

local originalExists=UnitExists
local offline,dead,mouseover=false,false,false
UnitExists=function(u)return u=='raid1' or u=='softfriend' or u=='target' or (u=='mouseover' and mouseover) end
UnitIsConnected=function(u)return u~='raid1' or not offline end
UnitIsDeadOrGhost=function(u)return u=='raid1' and dead end
ForeverHandheldControls.gamepadActive=true;tick()
assert(textExists('Full unit name: softfriend') and ForeverHandheldFieldNotes.heading:GetText()=='FIELD NOTES  /  ALLY','controller ally must replace stale native unit tooltip')
ForeverHandheldParty1.scripts.OnEnter();tick();assert(textExists('Full unit name: party1'),'explicit hover takes priority over selected ally')
ForeverHandheldParty1.scripts.OnLeave();GameTooltip:Hide();mouseover=true;tick()
assert(textExists('Full unit name: mouseover'),'mouse hover takes priority over selected ally')
mouseover=false;ForeverHandheldControls.gamepadActive=false;tick()
assert(textExists('Full unit name: target'),'mouse mode must not be hijacked by cached softfriend')
local raid=ForeverHandheldRaid1
offline=true;tick();assert(not raid.mark.hidden and raid.mark:GetText()=='OFFLINE' and raid.health.alpha==0 and raid.power.alpha==0,'offline raid status must be visible without losing name')
assert(raid.name:GetText()=='Enemy' and raid.attributes.unit=='raid1' and raid.attributes.type1=='target','offline display changed member identity or secure target')
offline=false;dead=true;tick();assert(not raid.mark.hidden and raid.mark:GetText()=='DEAD','dead raid status missing')
dead=false;tick();assert(raid.mark.hidden and raid.health.alpha==1 and raid.power.alpha==1,'returning member did not restore bars')
local secretStatus={}
issecretvalue=function(v)return v==secretStatus end
UnitIsConnected=function()return secretStatus end;UnitIsDeadOrGhost=function()return secretStatus end;tick()
assert(raid.mark.hidden and raid.health.alpha==1,'unknown secret status must not invent dead/offline state')
issecretvalue=nil;UnitIsConnected=function()return true end;UnitIsDeadOrGhost=function()return false end
UnitExists=originalExists;GameTooltip:Show();tick()
print('PASS: controller ally inspection, explicit hover priority, mouse-mode target fallback, compact raid dead/offline status, secret-safe recovery and unchanged secure targeting.')
SlashCmdList.FOREVERROSTER('')
local preview=ForeverHandheldRosterPreview
assert(preview and #preview.cards==40 and not preview.hidden,'full roster preview did not open')
assert(preview.cards[2].mark:GetText()=='OFFLINE' and preview.cards[3].mark:GetText()=='DEAD','preview does not exercise shared status renderer')
for _,f in ipairs(preview.cards)do assert(f.unit==nil and f.attributes==nil and not f.scripts.OnEnter,'preview has a real unit or input handler')end
assert(ForeverHandheldRaid1.unitWatch and ForeverHandheldRaid1.attributes.unit=='raid1','preview changed real secure roster')
while #timers>0 do table.remove(timers,1)()end
assert(preview.hidden,'preview did not auto-close')
SlashCmdList.FOREVERROSTER('');preview.scripts.OnEvent(preview,'PLAYER_REGEN_DISABLED');assert(preview.hidden,'preview persists into combat')
IsInGroup=function()return true end;SlashCmdList.FOREVERROSTER('');assert(preview.hidden,'preview overlays a real group')
IsInGroup=function()return false end
print('PASS:40-card labelled preview shares rendering, owns no secure units/actions, auto-closes, and refuses real groups.')

-- Dedicated RareScanner hover uses the same scrollable rail without changing
-- its native item, actions, comparison data or owner. No fake rare DB entries.
GameTooltip:Hide()
RARESCANNER_BUTTON=CreateFrame('Button','RARESCANNER_BUTTON')
local rareTip=CreateFrame('GameTooltip','LootBarToolTip')
RARESCANNER_BUTTON.LootBar={LootBarToolTip=rareTip}
rareTip.owner=RARESCANNER_BUTTON;rareTip.data={type=3};rareTip.numLines=12
for i=1,12 do local l=CreateFrame('FontString','LootBarToolTipTextLeft'..i);l:SetText(i==1 and 'Rare native item' or 'Complete native item detail '..i)end
local right=CreateFrame('FontString','LootBarToolTipTextRight2');right:SetText('Mail')
local comparison=CreateFrame('GameTooltip','RareComparison');comparison:Hide();rareTip.shoppingTooltips={comparison}
tick()
assert(not rareTip:IsDrawLayerEnabled('ARTWORK'),'rare hover remains floating')
assert(ForeverHandheldFieldNotes.heading:GetText()=='FIELD NOTES  /  RARE LOOT' and (ForeverHandheldFieldNotes.lines[1].left:GetText()=='Rare native item') and (ForeverHandheldFieldNotes.lines[2].right:GetText()=='Mail'),'native rare columns not mirrored')
assert(ForeverHandheldFieldNotes.maxScroll>0 and not ForeverHandheldFieldNotes.hidden,'long rare item has no scroll access')
rareTip:Hide();tick();assert((ForeverHandheldFieldNotes.lines[1].left:GetText()=='Rare native item'),'leaving icon to scroll lost rare details')
RARESCANNER_BUTTON:Hide();tick();assert(not (ForeverHandheldFieldNotes.lines[1].left:GetText()=='Rare native item'),'dismissed alert retained stale loot')
RARESCANNER_BUTTON:Show();rareTip:Show();comparison:Show();tick()
assert(rareTip:IsDrawLayerEnabled('ARTWORK') and ForeverHandheldFieldNotes.hidden,'native comparison was hidden or duplicated')
comparison:Hide();rareTip.numLines=25;tick();assert(rareTip:IsDrawLayerEnabled('ARTWORK'),'overflow rare details discarded')
rareTip.numLines=12;ForeverHandheldComms={active=true,visible=true};tick();assert(rareTip:IsDrawLayerEnabled('ARTWORK'),'open chat hid both rare views')
ForeverHandheldComms.active=false;ForeverHandheldComms.visible=false;tick();assert(not rareTip:IsDrawLayerEnabled('ARTWORK'),'rare mirror failed to resume')
rareTip:Hide();GameTooltip:Show();GameTooltip.owner=WorldFrame;GameTooltip.data={type=1};GameTooltip.numLines=1;tick()
assert(not (ForeverHandheldFieldNotes.lines[1].left:GetText()=='Rare native item'),'new unit inspection did not replace loot snapshot')
GameTooltip:Hide();rareTip:Show();tick()
print('PASS: native rare tooltip columns, scroll persistence, dismissal/new-inspection release, native comparisons/overflow/chat fallback.')

-- A docked native tutorial keeps action previews visible, but owns the input.
-- Gameplay prompts must not conflict with the native tutorial's controls.
ForeverHandheldPanels={active=true,dockCovered=false}
local noticeCount=#notices
local rb=ControllerForever.RuleBar
rb.state={bindingHold=true}
ForeverHandheldControls.feedbackKind='input';ForeverHandheldControls.message='A  Jump';ForeverHandheldControls.untilTime=3
pad.buttons[4]=true;ControllerForeverPad8.press:Show()
ForeverHandheldDock:SetAlpha(1);tick()
local utility
for _,o in ipairs(objects)do if type(o.txt)=='string' and o.txt:find('LB Friend',1,true)then utility=o end end
assert(utility and utility.alpha==0,'world control hints conflict with modal controller ownership')
assert(ForeverHandheldDock:GetAlpha()==1,'modal hints hid the docked preview itself')
assert(#notices==noticeCount and ForeverHandheldControls.untilTime==0,'modal must consume its input cue and discard stale gameplay feedback')
ForeverHandheldPanels.active=false;ForeverHandheldDock:SetAlpha(.6);tick()
assert(utility.parent==ForeverHandheldDock and utility.alpha==1,'world hints must inherit dock opacity without double fading')
local stableHintWrites=utility.alphaWrites
for _=1,30 do tick() end
assert(utility.alphaWrites==stableHintWrites,'steady world hints rewrote opacity')

rb.state.bindingHold=false;pad.buttons[4]=false;tick()
assert(#notices==noticeCount,'closing a modal must not replay a stale native press as a world action')
pad.buttons[4]=true;tick()
assert(#notices==noticeCount+1,'next deliberate world press did not restore its cue')
pad.buttons[4]=false;ControllerForeverPad8.press:Hide();tick()
ForeverHandheldDock:SetAlpha(0)
assert(utility.parent:GetAlpha()*utility.alpha==0,'covered dock must suppress its hints before the next tick')
ForeverHandheldDock:SetAlpha(1);tick()
print('PASS: native modal owns hints while tutorial action preview stays visible; world hints restore on close')
ControllerForeverEditPanel=CreateFrame('Frame');ControllerForeverEditPanel:Show();tick()
assert(utility.alpha==0 and ForeverHandheldDock:GetAlpha()==1,'editor shows conflicting world hints or hides action preview')
ControllerForeverEditPanel:Hide();tick();assert(utility.alpha==1,'editor close did not restore world hints')
print('PASS: native layout editor owns hints and closure restores gameplay prompts')
local popupVisible=true
ForeverHandheldPanels.hasStaticPopup=function()return popupVisible end
pad.buttons[4]=true;ControllerForeverPad8.press:Show();tick()
assert(utility.alpha==0 and #notices==noticeCount+1,'compact native popup must own its controls without covering the dock')
popupVisible=false;pad.buttons[4]=false;ControllerForeverPad8.press:Hide();tick()
assert(utility.alpha==1 and #notices==noticeCount+1,'popup close must restore hints without a gameplay cue')
print('PASS: compact popup hides gameplay hints and consumes its raw press without hiding the dock')

-- Native chat controls take precedence immediately, before Comms' next paint.
-- Merely retaining a parked draft must leave gameplay instructions available.
local chatFocus,chatMenu=false,false
local nativeDraft={HasFocus=function()return chatFocus end,GetText=function()return 'Unsent draft' end}
ChatEdit_GetActiveWindow=function()return nativeDraft end
ChatFrame1={IsGamepadMenuOpen=function()return chatMenu end}
ForeverHandheldComms={active=true,focused=false,visible=true}
local chatNoticeCount=#notices
tick();assert(utility.alpha==1,'parked unfocused draft suppressed gameplay hints')
ForeverHandheldControls.feedbackKind='input';ForeverHandheldControls.message='A  Jump';ForeverHandheldControls.untilTime=3
chatFocus=true;pad.buttons[4]=true;ControllerForeverPad8.press:Show();tick()
assert(utility.alpha==0 and ForeverHandheldControls.untilTime==0,'focused native chat left world hints or stale input feedback visible')
assert(ForeverHandheldDock:GetAlpha()==1 and ForeverHandheldDB.mirroredSlots==32,'chat gate hid the action dock or stopped native icon updates')
assert(#notices==chatNoticeCount and nativeDraft:GetText()=='Unsent draft','chat face press emitted gameplay feedback or changed draft')
local pressedSlot
for _,o in ipairs(objects)do if o.nativeIndex==8 and o.icon and o.icon.texture==ControllerForeverPad8.icon.texture then pressedSlot=o;break end end
assert(pressedSlot and pressedSlot.press.hidden,'chat input painted a gameplay slot press')
-- Leaving chat while that physical press remains held must not replay it.
chatFocus=false;tick();assert(utility.alpha==1 and #notices==chatNoticeCount,'chat exit replayed held gameplay input or retained hidden hints')
pad.buttons[4]=false;tick();pad.buttons[4]=true;tick()
assert(#notices==chatNoticeCount+1,'fresh world press after chat failed to produce feedback')
pad.buttons[4]=false;ControllerForeverPad8.press:Hide();tick()
chatMenu=true;tick();assert(utility.alpha==0,'native chat menu left contradictory world hints')
chatMenu=false;tick();assert(utility.alpha==1,'closing chat menu did not restore world hints')
-- Other chat windows use the same native menu routing.
ChatFrame1=nil;ChatFrame2={IsGamepadMenuOpen=function()return true end};NUM_CHAT_WINDOWS=2
tick();assert(utility.alpha==0,'secondary chat menu left world hints')
ChatFrame2=nil;ChatEdit_GetActiveWindow=nil;NUM_CHAT_WINDOWS=nil;ForeverHandheldComms=nil
tick();assert(utility.alpha==1,'chat ownership cleanup left hints suppressed')
-- The native spell wheel is Core for bindings but owns selection while
-- open. Do not layer the ordinary dock and action prompts under its sectors.
GamepadSpellFlyout=CreateFrame('Frame','GamepadSpellFlyout')
local wheelLegend
for _,o in ipairs(objects)do if o.txt=='Right stick to choose  ·  Release to cast  ·  B Close' then wheelLegend=o end end
tick()
assert(utility.alpha==0 and wheelLegend and not wheelLegend.hidden,'spell wheel overlapped by gameplay hints')
assert(ownSlot.parent.hidden,'spell wheel overlapped by mirrored banks')
GamepadSpellFlyout:Hide();tick()
assert(utility.alpha==1 and wheelLegend.hidden and not ownSlot.parent.hidden,'spell wheel close failed to restore world dock')
print('PASS: native spell wheel owns the dock area and world hints return on close')
print('PASS: focused chat and native menus own hints; parked drafts keep gameplay controls; stale input feedback/presses suppressed, native icons stay live and exit resumes fresh presses')

ControllerForeverPad2.icon.GetTexCoord=function()error('simulated native read failure')end
ForeverHandheldDock.scripts.OnUpdate(ForeverHandheldDock,.2)
assert(ForeverHandheldDock.hidden,'failure hides incomplete custom HUD')
assert(GameTooltip:IsDrawLayerEnabled('ARTWORK'),'failure restores original tooltip')
assert(rareTip:IsDrawLayerEnabled('ARTWORK'),'failure restores rare tooltip')
assert(ForeverHandheldFocus.alpha==0 and ForeverHandheldParty1.alpha==0,'failure removes duplicate edge panels')
assert(not ControllerForeverDB.gameWindowsOff.PlayerFrame,'failure restores native health frame')
assert(not ControllerForeverDB.gameWindowsOff.ControllerForeverPadDisplay,'failure restores native action display')
print('PASS: 32 native slots, dynamic macro icon, health/mana, real interrupt binding, cooldown and range gates, friendly interaction, modifier hint, no-target state, native-UI fail-safe; render-cadence tooltip gate, exact inventory restoration, bounded text cadence, fade and last-unit snapshot retained')
