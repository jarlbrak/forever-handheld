local driver,hook,combat
function CreateFrame()driver={SetScript=function(s,k,v)s[k]=v end};return driver end
function InCombatLockdown()return combat end
function GetTime()return 100 end
function issecretvalue(v)return type(v)=='table' and v.secret end
function CreateFont()return {SetFont=function(s,f,n,flags)s.face=f;s.size=n;s.flags=flags end}end
local nativeMenu={PopulateDescription=function()end}
Menu=nativeMenu;if arg[2]=='late_menu' then Menu=nil end
function hooksecurefunc(t,k,fn)assert(t==Menu and k=='PopulateDescription');hook=fn end
local function frame(parent)
 return {parent=parent,IsShown=function(s)return not s.hidden end,IsProtected=function(s)return s.protected end,
 IsForbidden=function(s)return s.forbidden end,GetParent=function(s)return s.parent end}
end
local function font()
 local r=frame();r.size=12;r.w=120;r.h=20;r.writes=0
 r.fontObject={face='Native',size=12,flags='OUTLINE'}
 r.GetFont=function(s)return s.fontObject.face,s.size,s.fontObject.flags end
 r.SetFont=function()error('Menu compositor prohibits direct FontString:SetFont')end
 r.GetFontObject=function(s)return s.fontObject end
 r.SetFontObject=function(s,f)s.fontObject=f;s.size=f.size;s.writes=s.writes+1 end
 r.GetWidth=function(s)return s.w end;r.GetHeight=function(s)return s.h end
 r.SetWidth=function(s,v)s.w=v;s.writes=s.writes+1 end;r.SetHeight=function(s,v)s.h=v;s.writes=s.writes+1 end
 return r
end
local function description(children)
 return {children=children or {},initializers={},EnumerateElementDescriptions=function(s)return ipairs(s.children)end,
 AddInitializer=function(s,f)table.insert(s.initializers,f)end,
 AddMenuReleasedCallback=function(s,f)s.release=f end}
end
SettingsPanel=frame();CooldownViewerSettings=frame()
local owner=frame(SettingsPanel);local menu=frame();menu.GetOwnerRegion=function()return owner end
local button=frame(menu);button.fontString=font()
local originalAction=function()error('native action invoked')end
button.OnClick=originalAction;button.checked=true;button.navigation='native'
local child=description();child.responder=originalAction;child.finalInitializer=originalAction
local root=description({child});local nested=description();child.children={nested}
dofile(arg[1]);assert(driver.OnUpdate,'menu discovery driver not started')
if arg[2]=='late_menu' then
 for i=1,20 do driver.OnUpdate(driver,.25)end
 assert(not hook and driver.OnUpdate,'missing native Menu stopped discovery')
 Menu=nativeMenu
end
driver.OnUpdate(driver,.25);assert(hook)
local idleCallbacks=0
for i=1,600 do if driver.OnUpdate then idleCallbacks=idleCallbacks+1;driver.OnUpdate(driver,1/60)end end
print('Idle native-menu callbacks over600 frames: '..idleCallbacks)
if arg[2]=='baseline' then return end
assert(idleCallbacks==0 and not driver.OnUpdate,'discovered idle menu kept render callback')
hook(nil,owner,root);assert(#child.initializers==1 and #nested.initializers==1 and root.release)
hook(nil,owner,root);assert(#child.initializers==1,'duplicate initializer')
local init=child.initializers[1];init(button,child,menu)
assert(driver.OnUpdate,'menu initialization did not resume observation driver')
assert(button.fontString.size==16 and button.fontString.w==160 and button.fontString.h==26,'readable native row not sized before layout')
assert(button.OnClick==originalAction and button.checked and button.navigation=='native' and child.responder==originalAction and child.finalInitializer==originalAction,'native actions or state changed')
local n=button.fontString.writes;init(button,child,menu);assert(button.fontString.writes==n,'settled font churn')
driver.OnUpdate(driver,.25);assert(ForeverHandheldDB.nativeMenus.observedFont==16,'actual composed font not observed')
assert(button.fontString.writes==n,'settled observation mutated typography')
root.release(menu);assert(button.fontString.size==12 and button.fontString.w==120 and button.fontString.h==20,'pool geometry/font not restored')
assert(not driver.OnUpdate,'last pooled release kept render callback')
combat=true;init(button,child,menu);assert(button.fontString.size==12,'combat mutation');combat=false
button.protected=true;init(button,child,menu);assert(button.fontString.size==12,'protected mutation');button.protected=false
button.forbidden=true;init(button,child,menu);assert(button.fontString.size==12,'forbidden mutation');button.forbidden=false
SettingsPanel.hidden=true;init(button,child,menu);assert(button.fontString.size==12,'hidden owner mutation');SettingsPanel.hidden=false
button.fontString.hidden=true;init(button,child,menu);assert(button.fontString.size==12,'hidden language placeholder exposed');button.fontString.hidden=false
local other=frame();owner.parent=other;init(button,description(),menu);assert(button.fontString.size==12,'unrelated owner affected');owner.parent=SettingsPanel
local unrelated=description({description()});hook(nil,other,unrelated);assert(#unrelated.children[1].initializers==0,'unrelated description modified')
assert(not driver.OnUpdate,'irrelevant/protected/hidden/combat init restarted driver')
local parentMenu=menu;local submenu=frame();submenu.GetOwnerRegion=function()return parentMenu end
nested.initializers[1](button,nested,submenu);assert(button.fontString.size==16,'submenu owner chain not recognized');root.release(submenu)
owner.parent=CooldownViewerSettings;init(button,child,menu);assert(button.fontString.size==16,'cooldown menu not included')
combat=true;root.release(menu);assert(button.fontString.size==16,'combat restore not deferred')
assert(driver.OnUpdate,'combat-deferred restoration lost its driver');driver.OnUpdate(driver,.25)
assert(button.fontString.size==16 and driver.OnUpdate,'active combat restored or discarded pending pool')
combat=false;driver.OnUpdate(driver,.25);assert(button.fontString.size==12,'deferred pool restoration failed')
assert(not driver.OnUpdate,'completed deferred restore kept render callback')
button.fontString.size=20;button.fontString.h=30;init(button,child,menu);assert(button.fontString.size==20 and button.fontString.h==30,'larger native typography shrunk')
assert(not ForeverHandheldDB.nativeMenuError)
print('PASS: scoped native menu initialization, proportional readable text/row extent, unchanged actions/checks/final initializer/navigation, submenus, pooled restoration, combat/protected/hidden guards and no settled writes')

root.release(menu);button.fontString=font();ProfessionsFrame=frame();ProfessionsFrame.protected=true;owner.parent=ProfessionsFrame
local professionRoot=description({description()});hook(nil,owner,professionRoot);assert(#professionRoot.children[1].initializers==0,'protected profession menu was modified')
init(button,child,menu);assert(button.fontString.size==12,'protected profession menu initialized')
print('PASS: protected profession menus remain entirely native after live focus-handoff regression')

assert(not driver.OnUpdate,'protected profession menu restarted polling')
owner.parent=SettingsPanel;button.fontString=font();init(button,child,menu)
local second=frame();second.GetOwnerRegion=function()return owner end
local secondButton=frame(second);secondButton.fontString=font()
init(secondButton,child,second)
root.release(menu)
assert(driver.OnUpdate and button.fontString.size==12 and secondButton.fontString.size==16,'one release stopped another active styled menu')
root.release(second)
assert(not driver.OnUpdate and secondButton.fontString.size==12,'final simultaneous menu release kept driver')
-- A fresh active period starts its own observation interval.
button.fontString=font();init(button,child,menu);ForeverHandheldDB.nativeMenus.observedFont=nil
driver.OnUpdate(driver,.20);root.release(menu)
init(button,child,menu);ForeverHandheldDB.nativeMenus.observedFont=nil
driver.OnUpdate(driver,.10)
assert(ForeverHandheldDB.nativeMenus.observedFont==nil,'elapsed observation carried across idle lifecycle')
driver.OnUpdate(driver,.15)
assert(ForeverHandheldDB.nativeMenus.observedFont==16,'reactivated menu was not observed')
root.release(menu)
assert(not driver.OnUpdate and not ForeverHandheldDB.nativeMenuError,'final menu cleanup failed')
print('PASS: discovery/idle/active/release lifecycle, late Menu availability, simultaneous menus, combat-deferred restore and elapsed reset; no idle callback.')
