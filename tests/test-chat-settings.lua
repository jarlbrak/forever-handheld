local driver,combat
local function font(size)
 return {size=size,writes=0,GetFont=function(s)return 'NativeFont',s.size,''end,
  SetFont=function(s,face,size,flags)assert(face=='NativeFont' and flags=='');s.size=size;s.writes=s.writes+1 end,
  IsObjectType=function(_,kind)return kind=='FontString'end}
end
local function frame()
 return {regions={},children={},w=70,h=16,writes=0,
  IsShown=function(s)return not s.hidden end,IsForbidden=function(s)return s.forbidden end,
  IsProtected=function(s)return s.protected end,GetRegions=function(s)return unpack(s.regions)end,
  GetChildren=function(s)return unpack(s.children)end,GetWidth=function(s)return s.w end,GetHeight=function(s)return s.h end,
  SetHeight=function(s,n)s.h=n;s.writes=s.writes+1 end,SetWidth=function(s,n)s.w=n;s.writes=s.writes+1 end,
  GetTextWidth=function()return 110 end}
end
local focusChanged
EventRegistry={RegisterCallback=function(_,event,callback)
 assert(event=='Gamepad.RefreshFrameFocus');focusChanged=callback
end}
function CreateFrame(_,name)
 if name then
  local hint={SetPoint=function()end,SetText=function()end,Show=function()end,Hide=function()end}
  return {EnableMouse=function()end,SetSize=function()end,SetPoint=function()end,
   SetFrameLevel=function()end,CreateFontString=function()return hint end}
 end
 driver={SetScript=function(s,k,v)s[k]=v end,RegisterEvent=function()end}
 return driver
end
function InCombatLockdown()return combat end
function issecretvalue(v)return type(v)=='table'end
function GetTime()return 10 end
ChatConfigFrame=frame();ChatConfigFrame.w=745;ChatConfigFrame.h=605
local manager=frame();ChatConfigFrame.ChatTabManager=manager
local tab=frame();tab.Text=font(10);tab.regions={tab.Text};manager.children={tab}
local measures=0;manager.UpdateWidth=function()measures=measures+1 end
local row=frame();row.regions={font(12)};row.checked=true;row.color={.2,.3,.4};row.OnClick=function()error('native action invoked')end
ChatConfigCategoryFrameButton1=frame();local category=ChatConfigCategoryFrameButton1;category.regions={font(12)}
ChatConfigFrameRedockButton=frame();local redock=ChatConfigFrameRedockButton;redock.regions={font(10)};redock.OnClick=row.OnClick
ChatConfigFrame.children={manager,row,category,redock}
local activeChat=font(10)
ChatFrame1={font=activeChat,text='unsent draft',channel='PARTY'}
local swatch=frame();swatch.x=178.00001525879;swatch.OnClick=row.OnClick
swatch.GetPoint=function(s)return 'LEFT',row,'LEFT',s.x,0 end
swatch.SetPoint=function(s,p,r,rp,x,y)assert(p=='LEFT' and r==row and rp=='LEFT' and y==0);s.x=x;s.writes=s.writes+1 end
row.ColorSwatch=swatch
CombatConfigTab1=frame();CombatConfigTab1.Text=font(10)
local combatMeasures=0
function PanelTemplates_TabResize(tab,padding)assert(tab==CombatConfigTab1 and padding==0);combatMeasures=combatMeasures+1 end
local compact=frame();compact.x=60.0000038147
compact.GetName=function()return 'CombatConfigMessageTypesRightCheck1Sub2'end
compact.GetPoint=function(s)return 'LEFT',row,'RIGHT',s.x,0 end
compact.SetPoint=function(s,p,r,rp,x,y)assert(p=='LEFT' and r==row and rp=='RIGHT' and y==0);s.x=x;s.writes=s.writes+1 end
ChatConfigFrame.children[#ChatConfigFrame.children+1]=compact
local fallback=frame();fallback.GetName=function()return 'ChatConfigOtherSettingsPVPCheck1'end
local fallbackSwatch=frame();fallbackSwatch.x=178.00001525879
fallbackSwatch.GetPoint=function(s)return 'LEFT',nil,nil,s.x,0 end
fallbackSwatch.SetPoint=function(s,p,r,rp,x,y)assert(r==fallback);s.x=x;s.writes=s.writes+1 end
_G.ChatConfigOtherSettingsPVPCheck1ColorSwatch=fallbackSwatch
ChatConfigFrame.children[#ChatConfigFrame.children+1]=fallback
local nativeAction=row.OnClick
dofile(arg[1])
local function tick()driver.OnUpdate(driver,.3)end
ChatConfigFrame.hidden=true;tick();assert(row.regions[1].size==12)
ChatConfigFrame.hidden=false;combat=true;tick();assert(row.regions[1].size==12)
combat=false;tick()
assert(compact.x==80 and fallbackSwatch.x==220,'legacy named swatches/compound row spacing not repaired')
assert(combatMeasures==1,'combat tabs not remeasured')
assert(swatch.x==220 and swatch.writes==1 and swatch.OnClick==nativeAction,'narrow swatch overlap not repaired safely')
assert(row.regions[1].size==16 and category.h==24 and redock.w==134)
assert(tab.Text.size==16 and measures==1,'native tabs not remeasured after typography change')
assert(ChatConfigFrame.w==745 and ChatConfigFrame.h==605,'native root geometry changed')
assert(row.checked and row.color[2]==.3 and row.OnClick==nativeAction and redock.OnClick==nativeAction)
assert(activeChat.size==10 and ChatFrame1.text=='unsent draft' and ChatFrame1.channel=='PARTY','intentional chat changed')
local writes=row.regions[1].writes+category.writes+redock.writes
for i=1,20 do tick()end
assert(writes==row.regions[1].writes+category.writes+redock.writes and measures==1,'stable presentation repeatedly mutated')
assert(combatMeasures==1,'stable combat tabs repeatedly remeasured')
assert(swatch.writes==1,'stable swatch repeatedly mutated')
-- Native pooled tabs can reset their text font when reacquired.
tab.Text.size=10;tick();assert(tab.Text.size==16 and measures==2)
local hidden=frame();hidden.hidden=true;hidden.regions={font(10)}
local forbidden=frame();forbidden.forbidden=true;forbidden.GetRegions=function()error('forbidden read')end
local secured=frame();secured.protected=true;secured.regions={font(10)}
local secret=frame();secret.regions={font({})}
ChatConfigFrame.children={hidden,forbidden,secured,secret};tick()
assert(hidden.regions[1].size==10 and secured.regions[1].size==10 and secret.regions[1].writes==0)
assert(not ForeverHandheldDB.chatSettingsError and ForeverHandheldDB.chatSettings.visited<=350)
assert(ChatConfigFrameRedockButton.OnClick==nativeAction)
print('PASS: readable native chat settings, pooled tab remeasurement, category/footer fit, stable writes, hidden/combat/protected/secret guards; native values/actions and intentional chat preserved')

local activeFrame, binding
local root=ChatConfigFrame
root.hidden=false
root.IsVisible=root.IsShown
root.GetFrameLevel=function()return 1 end
root.HookScript=function(_,event,callback)assert(event=='OnHide');root.hideHook=callback end
local function exitButton(name,hidden)
 local button=frame()
 button.hidden=hidden
 button.IsVisible=button.IsShown
 button.IsEnabled=function()return true end
 button.GetName=function()return name end
 return button
end
ChatConfigFrameOkayButton=exitButton('ChatConfigFrameOkayButton',false)
ChatConfigFrameCancelButton=exitButton('ChatConfigFrameCancelButton',true)
InputUtil={IsGamepadUIEnabled=function()return true end}
GamepadMode={FrameControlsManager={GetActiveFrame=function()return activeFrame end}}
ControllerForever={Binds={PRIORITY={gamewindow=80},claimant=function(_,_,_,options)
 assert(options.overGame and options.outOfFight)
 return {set=function(key,value)assert(key=='PAD2');binding=value end,
  clear=function()binding=nil end,commit=function()end}
end}}
activeFrame=root;focusChanged()
assert(binding=='CLICK ChatConfigFrameOkayButton:LeftButton')
activeFrame={};focusChanged()
assert(binding==nil,'nested color picker lost its own Back action')
activeFrame=root;ChatConfigFrameCancelButton.hidden=false;focusChanged()
assert(binding=='CLICK ChatConfigFrameCancelButton:LeftButton')
root.hidden=true;root.hideHook()
assert(binding==nil and not ForeverHandheldDB.chatSettingsControllerError)
print('PASS: Chat Settings Back follows the visible exit action and leaves nested focus alone')
