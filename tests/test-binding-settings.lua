local driver,combat
local function font(size)
 return {size=size,writes=0,GetFont=function(s)return 'Native',s.size,''end,
 SetFont=function(s,face,n,flags)assert(face=='Native' and flags=='');s.size=n;s.writes=s.writes+1 end,
 IsObjectType=function(_,t)return t=='FontString'end,GetPoint=function(s)return unpack(s.point or {'LEFT',nil,'LEFT',0,-15})end,
 ClearAllPoints=function(s)s.point=nil end,SetPoint=function(s,...)s.point={...};s.writes=s.writes+1 end}
end
local function frame()
 return {regions={},children={},writes=0,IsShown=function(s)return not s.hidden end,IsForbidden=function(s)return s.forbidden end,
 IsProtected=function(s)return s.protected end,GetRegions=function(s)return unpack(s.regions)end,GetChildren=function(s)return unpack(s.children)end,
 GetPoint=function(s)return unpack(s.point or {'TOPLEFT',nil,'TOPLEFT',300,0})end,ClearAllPoints=function(s)s.point=nil end,
 SetPoint=function(s,...)s.point={...};s.writes=s.writes+1 end}
end
function CreateFrame()driver={SetScript=function(s,k,v)s[k]=v end};return driver end
function InCombatLockdown()return combat end
function issecretvalue(v)return type(v)=='table'end
function GetTime()return 10 end
ClickBindingFrame=frame();local root=ClickBindingFrame
local row=frame();row.Name=font(12);row.BindingText=font(10);row.regions={row.Name,row.BindingText}
local action=function()error('native action invoked')end
row.OnClick=action;row.binding='BUTTON1';row.pendingChanges=false
local help=frame();help.regions={font(12)};root.TutorialFrame=help;root.children={row,help}
local helpPaint={}
function help:CreateTexture()
 local r={}
 for _,k in ipairs({'SetAllPoints','SetPoint','SetWidth','SetHeight'})do r[k]=function()end end
 r.SetColorTexture=function(o,...)o.color={...}end;r.SetAtlas=function(o,a)o.atlas=a end
 helpPaint[#helpPaint+1]=r;return r
end

local helpButton=frame();root.TutorialButton=helpButton;helpButton.w=48;helpButton.h=48
helpButton.GetWidth=function(s)return s.w end;helpButton.GetHeight=function(s)return s.h end
helpButton.SetSize=function(s,w,h)s.w=w;s.h=h;s.writes=s.writes+1 end
helpButton.OnClick=action
dofile(arg[1])
local function tick()driver.OnUpdate(driver,.3)end
root.hidden=true;tick();assert(row.Name.size==12)
root.hidden=false;combat=true;tick();assert(row.Name.size==12)
combat=false;tick()
assert(helpButton.point[4]==8 and helpButton.point[5]==-24 and helpButton.w==36 and helpButton.OnClick==action,'native help button obscured or replaced')
assert(row.Name.size==16 and row.BindingText.size==14)
assert(row.BindingText.point[1]=='TOPLEFT' and row.BindingText.point[2]==row.Name and row.BindingText.point[5]==-3)
assert(help.point[1]=='TOPRIGHT' and help.point[2]==root and help.point[3]=='TOPLEFT' and help.point[4]==-16)
assert(row.OnClick==action and row.binding=='BUTTON1' and not row.pendingChanges)
local writes=row.Name.writes+row.BindingText.writes+help.writes
for i=1,20 do tick()end
assert(writes==row.Name.writes+row.BindingText.writes+help.writes,'stable geometry churn')
local forbidden=frame();forbidden.forbidden=true;forbidden.GetRegions=function()error('forbidden access')end
local secured=frame();secured.protected=true;secured.regions={font(10)}
local hidden=frame();hidden.hidden=true;hidden.regions={font(10)}
root.children={forbidden,secured,hidden};help.protected=true;help.point={'TOPLEFT',root,'TOPLEFT',300,0};tick()
assert(secured.regions[1].size==10 and hidden.regions[1].size==10 and help.point[1]=='TOPLEFT')
assert(not ForeverHandheldDB.bindingSettingsError and ForeverHandheldDB.bindingSettings.visited<=180)
print('PASS: click-binding typography, separated row labels and companion help layout; stable writes, hidden/combat/protected/forbidden guards; native bindings and callbacks unchanged')

root.hidden=true;CooldownViewerSettings=frame();local cooldown=CooldownViewerSettings
local category=frame();category.regions={font(10)};category.OnClick=action;category.icon=12345;cooldown.children={category}
combat=true;tick();assert(category.regions[1].size==10)
combat=false;tick();assert(category.regions[1].size==16 and category.OnClick==action and category.icon==12345)
assert(ForeverHandheldDB.cooldownSettings.visited==2 and not ForeverHandheldDB.bindingSettingsError)
local n=category.regions[1].writes;tick();assert(category.regions[1].writes==n)
print('PASS: cooldown settings native categories readable without changing spell icons, actions or combat state; settled writes remain stable')

-- Gamepad edit/bind dialog painting must not alter native state or actions.
local function region()
 local r={}
 for _,k in ipairs({'SetPoint','SetColorTexture','SetWidth','SetHeight','SetFont','SetTextColor','SetJustifyH'})do r[k]=function()end end
 r.SetText=function(o,v)o.text=v end
 return r
end
local function box(title)
 local f=frame();f.CreateTexture=region;f.CreateFontString=region
 local function decoration()return {alpha=1,GetAlpha=function(o)return o.alpha end,SetAlpha=function(o,v)o.alpha=v end}end
 f.Border=decoration();f.HighlightFrame=decoration();f.TitleBox=decoration();f.TitleBox.TitleText={GetText=function()return title end}
 return f
end
GamepadActionBarEditFrame=frame();local editor=GamepadActionBarEditFrame
editor.BindingInfoFrame=box('Bind to Action Bar');editor.EditActionBarsInfoFrame=box('Edit Action Bars')
editor.protected=true;editor.BindingInfoFrame.protected=true
editor.AttemptBindDown=action;editor.activeMode='BIND_ACTION';editor.BindingInfoFrame.ActionIcon=12345
combat=true;tick();assert(editor.BindingInfoFrame.Border.alpha==1)
combat=false;tick();assert(not ForeverHandheldDB.bindingSettingsError,ForeverHandheldDB.bindingSettingsError)
assert(editor.BindingInfoFrame.Border.alpha==0 and editor.EditActionBarsInfoFrame.TitleBox.alpha==0)
assert(editor.AttemptBindDown==action and editor.activeMode=='BIND_ACTION' and editor.BindingInfoFrame.ActionIcon==12345)
assert(ForeverHandheldDB.actionBindingStyle.version=='3.7.91')
print('PASS: native binding/editor dialog paint; combat guard; action capture, mode and icon unchanged')

assert(#helpPaint==6 and helpPaint[1].color[4]==1 and helpPaint[6].atlas=='clickcast-background-tutorial','opaque tutorial paint or native illustration missing')
print('PASS: tutorial has opaque backdrop and native illustration; paint created once')
