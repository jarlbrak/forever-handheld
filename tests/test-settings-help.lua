local driver,combat,ownerHook,showHooks
showHooks={}
local ownerHooks={}
function CreateFrame()driver={SetScript=function(s,k,v)s[k]=v end};return driver end
function InCombatLockdown()return combat end
function GetTime()return 100 end
function issecretvalue(v)return type(v)=='table' and v.secret end
function hooksecurefunc(t,k,fn)assert(t==GameTooltip or t==SettingsTooltip);if k=='SetOwner' then ownerHook=fn;ownerHooks[t]=fn elseif k=='Show' then showHooks[t]=fn else error('unexpected hook')end end
local function frame(parent)
 return {parent=parent,IsShown=function(s)return not s.hidden end,IsProtected=function(s)return s.protected end,
 IsForbidden=function(s)return s.forbidden end,GetParent=function(s)return s.parent end}
end
UIParent={GetWidth=function()return 1280 end,GetHeight=function()return 800 end,GetEffectiveScale=function()return 1 end}
SettingsPanel=frame();CooldownViewerSettings=frame();local owner=frame(SettingsPanel)
local tip=frame();GameTooltip=tip;tip.owner=owner;tip.alpha=1;tip.GetAlpha=function(s)return s.alpha end;tip.SetAlpha=function(s,v)s.alpha=v end;tip.scale=1;tip.w=240;tip.h=180;tip.writes=0
tip.GetOwner=function(s)return s.owner end;tip.GetScale=function(s)return s.scale end
tip.GetEffectiveScale=function(s)return s.scale end;tip.SetScale=function(s,v)s.scale=v;s.writes=s.writes+1 end
tip.GetWidth=function(s)return s.w end;tip.GetHeight=function(s)return s.h end
tip.IsClampedToScreen=function(s)return not not s.clamped end;tip.SetClampedToScreen=function(s,v)s.clamped=v;s.writes=s.writes+1 end
local region={size=12,text='Full native explanation',IsObjectType=function(_,t)return t=='FontString'end,
 IsShown=function()return true end,GetFont=function(s)return 'Native',s.size,''end,GetText=function(s)return s.text end}
tip.GetRegions=function()return region end
tip.anchor='native';tip.action=function()error('native action called')end;local action=tip.action
dofile(arg[1]);driver.OnUpdate(driver,.1)
assert(math.abs(tip.scale-4/3)<.001 and tip.clamped,'native help not enlarged/clamped')
assert(tip.owner==owner and tip.anchor=='native' and tip.action==action and region.text=='Full native explanation','content or native behavior changed')
local writes=tip.writes;driver.OnUpdate(driver,.1);assert(tip.writes==writes,'settled scale churn')
local other=frame();tip.owner=other;ownerHook(tip,other);assert(tip.scale==1 and not tip.clamped,'immediate owner handoff not restored')
driver.OnUpdate(driver,.1);assert(tip.scale==1,'ordinary tooltip affected')
tip.owner=owner;combat=true;driver.OnUpdate(driver,.1);assert(tip.scale==1,'combat acquired tooltip');combat=false
tip.protected=true;driver.OnUpdate(driver,.1);assert(tip.scale==1,'protected tooltip changed');tip.protected=false
tip.forbidden=true;driver.OnUpdate(driver,.1);assert(tip.scale==1,'forbidden tooltip changed');tip.forbidden=false
SettingsPanel.hidden=true;driver.OnUpdate(driver,.1);assert(tip.scale==1,'hidden root changed');SettingsPanel.hidden=false
local menu=frame();menu.GetOwnerRegion=function()return owner end;tip.owner=menu;driver.OnUpdate(driver,.1);assert(tip.scale>1,'native menu owner not recognized')
tip.hidden=true;driver.OnUpdate(driver,.1);assert(tip.scale==1 and not tip.clamped,'hidden tooltip not restored');tip.hidden=false
tip.owner=owner;tip.h=700;driver.OnUpdate(driver,.1);assert(tip.scale*700<=760.01 and tip.scale>=1,'height limit failed')
tip.h=900;driver.OnUpdate(driver,.1);assert(tip.scale==1,'oversized help shrunk');tip.h=180
tip.w=1200;driver.OnUpdate(driver,.1);assert(tip.scale*1200<=1248.01,'width limit failed')
tip.hidden=true;driver.OnUpdate(driver,.1);tip.hidden=false;tip.w=240
tip.clamped=true;region.size=18;driver.OnUpdate(driver,.1);assert(tip.scale==1 and tip.clamped,'already readable font enlarged')
region.size=12;owner.parent=CooldownViewerSettings;driver.OnUpdate(driver,.1);assert(tip.scale>1,'cooldown help not included')
tip.scale=1.7;tip.owner=other;ownerHook(tip,other);assert(tip.scale==1.7 and tip.clamped,'external scale change overwritten')
assert(not ForeverHandheldDB.settingsHelpError)
print('PASS: scoped native help scaling, full content/owner/anchors/actions preserved, viewport limits, immediate owner restoration, external-change ownership and combat/protected/hidden guards')

local settingsTip={} for k,v in pairs(tip)do settingsTip[k]=v end
settingsTip.owner=owner;settingsTip.scale=1;settingsTip.clamped=false;settingsTip.hidden=false
SettingsTooltip=settingsTip;tip.hidden=true
driver.OnUpdate(driver,.1)
assert(settingsTip.scale>1 and tip.scale==1.7,'separate SettingsTooltip not handled independently')
settingsTip.hidden=true;driver.OnUpdate(driver,.1);assert(settingsTip.scale==1,'SettingsTooltip scale not restored')
print('PASS: separate native SettingsTooltip targets and restores independently of GameTooltip')

local function texture(color)
 return {color=color,writes=0,GetVertexColor=function(s)return unpack(s.color)end,
 SetVertexColor=function(s,...)s.color={...};s.writes=s.writes+1 end}
end
local center=texture({.1,.1,.2,1});local edge=texture({.8,.7,.5,1})
settingsTip.NineSlice=frame();settingsTip.NineSlice.Center=center;settingsTip.NineSlice.TopEdge=edge
settingsTip.hidden=false;region.size=18;driver.OnUpdate(driver,.1)
assert(settingsTip.scale==1 and center.color[1]==.025 and edge.color[1]==.68,'readable help palette missing')
local cw,ew=center.writes,edge.writes;driver.OnUpdate(driver,.1)
assert(center.writes==cw and edge.writes==ew,'settled palette churn')
edge:SetVertexColor(.2,.3,.4,1);settingsTip.hidden=true;driver.OnUpdate(driver,.1)
assert(center.color[1]==.1 and center.color[3]==.2,'native center color not restored')
assert(edge.color[1]==.2,'external border change overwritten')
settingsTip.hidden=false;settingsTip.NineSlice.protected=true;driver.OnUpdate(driver,.1)
assert(center.color[1]==.1,'protected backdrop changed')
assert(not ForeverHandheldDB.settingsHelpError)
print('PASS: scoped charcoal/gold palette, original per-piece restoration, external changes retained, protected guards and no settled writes')

settingsTip.hidden=true;driver.OnUpdate(driver,.1)
ProfessionsFrame=frame();ProfessionsFrame.protected=true
local spell=frame(ProfessionsFrame);spell.protected=true
spell.SetScale=function()error('protected spell button changed')end
spell.SetScript=function()error('protected spell action changed')end
local nativeAction=function()end;spell.action=nativeAction
tip.hidden=false;tip.scale=1;tip.owner=spell;tip.clamped=false;region.size=12
driver.OnUpdate(driver,.1)
assert(tip.scale>1 and spell.action==nativeAction,'secure profession ancestry not read-only')
assert(ForeverHandheldDB.settingsHelp.context=='professions','profession context not recorded')
local pw=tip.writes;driver.OnUpdate(driver,.1);assert(tip.writes==pw,'profession help churn')
ProfessionsFrame.hidden=true;driver.OnUpdate(driver,.1)
assert(tip.scale==1 and not tip.clamped,'hidden profession help not restored')
ProfessionsFrame.hidden=false;spell.forbidden=true;driver.OnUpdate(driver,.1)
assert(tip.scale==1,'forbidden profession owner inspected');spell.forbidden=false
spell.parent=SettingsPanel;driver.OnUpdate(driver,.1)
assert(tip.scale==1,'protected Settings owner guard weakened')
spell.parent=frame();driver.OnUpdate(driver,.1)
assert(tip.scale==1,'unrelated secure tooltip changed')
spell.parent=ProfessionsFrame;combat=true;driver.OnUpdate(driver,.1)
assert(tip.scale==1,'profession help acquired in combat');combat=false
assert(not ForeverHandheldDB.settingsHelpError)
print('PASS: readable profession help with read-only secure ancestry; native actions retained, stable writes, hidden/forbidden/combat guards and unrelated protected owners excluded')

CollectionsJournal=frame();CollectionsJournal.protected=true
spell.parent=CollectionsJournal;tip.owner=spell;driver.OnUpdate(driver,.1)
assert(tip.scale>1 and ForeverHandheldDB.settingsHelp.context=='collections','collection help missing')
CollectionsJournal.hidden=true;driver.OnUpdate(driver,.1);assert(tip.scale==1,'collection help not restored')
assert(not ForeverHandheldDB.settingsHelpError)
print('PASS: collection appearance help scales through read-only secure ancestry and restores on closure')

function tip:CreateTexture(_,layer,_,sublevel)
 assert(layer=='BACKGROUND' and sublevel==-8)
 local f={IsShown=function(s)return s.shown end,SetAllPoints=function(s,t)s.anchor=t end,SetColorTexture=function(s,...)s.color={...}end,Show=function(s)s.shown=true end,Hide=function(s)s.shown=false end}
 self.fill=f;return f
end
SocialUIFrame=frame();AddFriendFrame=frame();AddFriendFrame.hidden=true
local card=frame(SocialUIFrame);tip.owner=card;tip.scale=1;tip.alpha=.8;tip.hidden=false
settingsTip.hidden=true;driver.OnUpdate(driver,.1)
assert(tip.scale>1 and ForeverHandheldDB.settingsHelp.context=='social','social help not readable')
assert(tip.fill.shown and tip.fill.anchor==tip and tip.fill.color[4]==.98,'social backdrop still translucent')
AddFriendFrame.hidden=false;driver.OnUpdate(driver,.1);assert(tip.alpha==0 and not tip.hidden,'underlying social help bleeds over dialog')
tip.alpha=1;showHooks[tip]();assert(tip.alpha==0,'newly shown social tooltip flashes over modal')
AddFriendFrame.hidden=true;driver.OnUpdate(driver,.1);assert(tip.alpha==.8,'native alpha not restored after modal')
AddFriendFrame.hidden=false;driver.OnUpdate(driver,.1);tip.alpha=.4;AddFriendFrame.hidden=true;driver.OnUpdate(driver,.1);assert(tip.alpha==.4,'external alpha overwritten')
AddFriendFrame.hidden=false;driver.OnUpdate(driver,.1);tip.owner=other;ownerHooks[tip](tip,other);assert(tip.alpha==.4,'non-social owner still invisible')
assert(not tip.fill.shown,'social backdrop leaked to another owner')
assert(tip.owner==other and tip.action==action and region.text=='Full native explanation','native content or action modified')
assert(not ForeverHandheldDB.settingsHelpError)
print('PASS: Social readability, modal-only occlusion before Show, alpha/owner restoration and external changes; no native Hide/content/action changes')
