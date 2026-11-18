-- Input presentation must never change secure bindings or leak secret action data.
local frames={}
function CreateFrame()local f={scripts={}};function f:RegisterEvent()end;function f:SetScript(k,v)self.scripts[k]=v end;frames[#frames+1]=f;return f end
local time=20
function GetTime()return time end
local secret={}
function issecretvalue(x)return x==secret end
local id=1
local devices={{name='Steam Deck',vendorID=0x28de,productID=0x1205},{name='Xbox One Elite 2',vendorID=0x045e,productID=0x0b22},{name='Xbox 360 Controller',vendorID=0x045e,productID=0x028e}}
C_GamePad={GetActiveDeviceID=function()return id end,GetDeviceMappedState=function(i)return devices[i]end,GetDeviceRawState=function(i)return devices[i]end}
C_CVar={GetCVar=function(k)assert(not k:find('InputFunctionBindingButton_',1,true),'native buttons are frames, not CVars');return k end}
function SetBinding()error('must never change bindings')end
function GetBindingAction(k)return 'native:'..k end
ControllerForever={RuleBar={layerKeyPrefix=function(layer)return ({bare='',lt='SHIFT-',rt='CTRL-',ltrt='CTRL-SHIFT-'})[layer]end}}
ControllerForeverPad1={crDrawn={spellID=secret,macroName='My macro',macroText='do not persist this'},crLookSrc={kind='spell',id=secret}}
C_Spell={GetSpellName=function(i)return i==999 and secret or 'Holy Light' end}
assert(loadfile(arg[1]))()
local s=ForeverHandheldControls;local driver=frames[1]
local function event(...)driver.scripts.OnEvent(driver,...)end
local function tick(dt)time=time+dt;driver.scripts.OnUpdate(driver,dt)end
tick(.5);assert(s.kind=='deck');assert(s.rearLabels()=='L4')
C_GamePad.GetDeviceMappedState=function(i)return devices[i] and {name='Xbox 360 Virtual'} end
event('GAME_PAD_CONNECTED');assert(s.kind=='deck','raw physical name wins over virtual mapping name')
id=2;event('GAME_PAD_CONNECTED');assert(s.kind=='xbox');assert(s.rearLabels()=='Upper-left rear')
id=3;event('GAME_PAD_ACTIVE_CHANGED',false);assert(s.kind=='controller' and not s.gamepadActive,'virtual controller must not be mislabelled Xbox')
id=1;event('GAME_PAD_ACTIVE_CHANGED',true);assert(s.gamepadActive and s.kind=='deck')
local snap=s.snapshot();assert(snap.actions.top[1].spell==nil and snap.actions.top[1].resolvedID==nil and snap.actions.top[1].macroText==nil)
C_GamePad.GetAllDeviceIDs=function()return {1,2,3,secret}end
C_GamePad.GetCombinedDeviceID=function()return 5 end
local inventory=s.snapshot()
assert(#inventory.devices==3 and inventory.combinedDeviceID==5)
assert(inventory.devices[1].vendor==0x28de and inventory.devices[2].rawName=='Xbox One Elite 2')
assert(snap.bindings.left.PADDUP.command=='native:SHIFT-PADDUP');assert(snap.bindings.bottom.PADDRIGHT.command=='native:CTRL-SHIFT-PADDRIGHT')
event('UNIT_SPELLCAST_START','player','cast',1);assert(s.message=='Casting: Holy Light')
event('UI_ERROR_MESSAGE',1,'Out of range');event('UNIT_SPELLCAST_FAILED','player','cast',1);assert(s.message=='Out of range','use specific game error')
s.notify('RT + Up  Holy Light','input',.8);assert(s.message=='Out of range','late press sample must not erase the cast error')
event('UNIT_SPELLCAST_SUCCEEDED','player','cast',1);assert(s.message=='Holy Light' and s.feedbackKind=='success')
s.notify('RT + Up  Holy Light','input',.8);assert(s.feedbackKind=='success','late input does not erase success')
event('UNIT_SPELLCAST_START','target','cast',1);assert(s.message=='Holy Light')
event('UI_ERROR_MESSAGE',1,secret);event('UNIT_SPELLCAST_START','player','cast',999);assert(s.message=='Holy Light','secret values ignored')
tick(2);s.notify('LT + Up  Blacksmithing','input',.8);assert(s.feedbackKind=='input','input acknowledgement returns after result expires')
event('UNIT_SPELLCAST_START','player','cast',1);s.notify('LT + A  Holy Light','input',.8);assert(s.feedbackKind=='casting','input does not erase casting')
id=99;event('GAME_PAD_DISCONNECTED');assert(not s.connected)
tick(15);assert(ForeverHandheldDB.controls and not ForeverHandheldDB.controlsError)
-- The real client exposes an aggregate active ID even while physical devices
-- are individually readable. Presence alone must not let Xbox steal Deck hints.
id=5
local present={1,5}
local input={[1]={false,false,0},[2]={false,false,0}}
C_GamePad.GetAllDeviceIDs=function()return present end
C_GamePad.GetDeviceRawState=function(i)return devices[i]end
C_GamePad.GetDeviceMappedState=function(i)
 if i==5 then return {name='Xbox One Elite 2'} end
 local v=input[i];if not v then return nil end
 return {name=devices[i].name,buttons={v[1],v[2]},axes={v[3]}}
end
event('GAME_PAD_CONNECTED');assert(s.kind=='controller' and not s.physicalDeviceID,'sole cached device is not proof of input ownership')
input[1][1]=true;tick(.1);assert(s.kind=='deck' and s.physicalDeviceID==1,'fresh Deck input resolves aggregate identity')
input[1][1]=false;tick(.1)
present={1,2,5};event('GAME_PAD_CONNECTED');assert(s.kind=='deck','connecting an idle Xbox must not steal hints')
input[2][1]=true;tick(.1);assert(s.kind=='xbox' and s.physicalDeviceID==2,'Xbox press selects Xbox labels through aggregate input')
input[2][1]=false;tick(.1);assert(s.kind=='xbox','release retains last input owner')
input[1][1]=true;tick(.1);assert(s.kind=='deck','Deck press restores Deck hints')
input[2][3]=.02;tick(.1);assert(s.kind=='deck','neutral stick noise must not steal hints')
input[2][3]=.7;tick(.1);assert(s.kind=='xbox','intentional stick movement switches owner')
input[1][2]=true;input[2][2]=true;tick(.1);assert(s.kind=='controller','simultaneous physical activity remains explicitly ambiguous')
present={1,5};event('GAME_PAD_DISCONNECTED');assert(s.kind=='controller','remaining idle device must not replace ambiguous owner')
input[1][1]=false;tick(.1);input[1][1]=true;tick(.1);assert(s.kind=='deck','fresh input restores remaining device identity')
present={5};event('GAME_PAD_DISCONNECTED');assert(s.kind=='controller' and not s.physicalDeviceID,'stale aggregate Xbox name must not invent a physical Xbox owner')
present={2,5};event('GAME_PAD_CONNECTED');assert(s.kind=='controller','cached Elite alone after reconnect/reload must not be advertised as active')
tick(2.5);assert(s.kind=='controller','idle cached Elite must stay unconfirmed across inventory refresh')
input[2][1]=true;tick(.1);assert(s.kind=='xbox','fresh Elite input confirms its physical ownership')
input[2][1]=false;tick(.1);assert(s.kind=='xbox','confirmed owner survives button release')
event('GAME_PAD_DISCONNECTED');assert(s.kind=='controller' and not s.physicalDeviceID,'disconnect invalidates owner even when Wine retains the device entry')
local attrs={['held-count']=2,['held-state']='10',['held-key-1']='PADDUP',['held-index-1']=9,
 ['held-00-1']='CLICK Base:LeftButton',['held-10-1']='CLICK Left:LeftButton',
 ['held-01-1']='CLICK Right:LeftButton',['held-11-1']='CLICK Both:LeftButton',
 ['held-key-2']='PAD1',['held-10-2']='not recorded'}
ControllerForeverHeldTriggerKeys={GetAttribute=function(_,k)return attrs[k]end}
local routing=s.snapshot().routing
assert(routing.state=='10' and #routing.keys==1 and routing.keys[1].states['01']=='CLICK Right:LeftButton','read native RT route even without a keyboard modifier')
attrs['held-state']=secret;assert(s.snapshot().routing.state==nil,'secret routing values excluded')
local baseBar={GetName=function()return 'NativeBaseBar'end}
local leftBar={GetName=function()return 'NativeLeftBar'end}
local selected=leftBar
GamepadMainActionBarFrame={PageUnit={actionBars={topBar=baseBar,leftBar=leftBar},GetActiveBar=function()return selected end}}
GamepadMode={IsLeftModifierDown=function()return true end,IsRightModifierDown=function()return false end,FrameControlsManager={isUIFocused=false,fallThroughCatcherActive=true}}
local blocker={name='NativeFallthrough',treatBindsAsCore=false,GetBinding=function(_,key)if key=='SHIFT-PADDLEFT' then return {isActive=true,type='InputButtonBinding',boundFunction='must not copy'} end end}
GamepadSharedUtility={InputBindingManager={bindingSetStack={blocker},IsOnlyCoreBindingSetActive=function()return false end}}
local n=s.snapshot().native
assert(n.leftModifier and not n.rightModifier and n.activeBank=='leftBar' and n.activeBar=='NativeLeftBar','native modifier and active action-bank agreement visible')
assert(n.fallthrough and not n.core and n.stack[1].keys['SHIFT-PADDLEFT'].active,'native blocker ownership distinguishes window routing')
assert(n.stack[1].keys['SHIFT-PADDLEFT'].boundFunction==nil,'no callback bodies persisted')
local manager=GamepadSharedUtility.InputBindingManager
manager.IsOnlyCoreBindingSetActive=function()return true end
manager.bindingSetStack={};GamepadMode.FrameControlsManager.isUIFocused=false
function GetCurrentKeyBoardFocus()return nil end
local world=s.snapshot();assert(ForeverHandheldDB.controlsWorld==world,'unobstructed world route retained')
GamepadMode.FrameControlsManager.isUIFocused=true;s.snapshot();assert(ForeverHandheldDB.controlsWorld==world,'menu snapshot cannot replace world route')
GamepadMode.FrameControlsManager.isUIFocused=false
GetCurrentKeyBoardFocus=function()return {} end;s.snapshot();assert(ForeverHandheldDB.controlsWorld==world,'keyboard draft cannot replace world route')
GamepadMode.IsLeftModifierDown=function()return secret end
blocker.name=secret;blocker.treatBindsAsCore=secret
GamepadSharedUtility.InputBindingManager.bindingSetStack={};for i=1,20 do GamepadSharedUtility.InputBindingManager.bindingSetStack[i]=blocker end
n=s.snapshot().native;assert(n.leftModifier==nil and #n.stack==16 and n.stack[1].name==nil and n.stack[1].core==nil,'native diagnostic values remain bounded and secret safe')
assert(not ForeverHandheldDB.controlsError)
ControllerForeverTapPadLeft={GetAttribute=function(_,k)return ({['cr-lt-index']=10,['cr-rt-index']=11,['cr-slot-lt']=101,action=101})[k]end}
local nativeSlot={GetID=function()return 101 end,GetAttribute=function(_,k)if k=='actionpage' then return 1 end end}
ControllerForever.Stances={nativeButton=function(layer,key)if layer=='lt' and key=='Left' then return nativeSlot end end}
ControllerForever.Shoulders={nativeButtonAction=function(n)assert(n==nativeSlot);return 101 end}
GetActionInfo=function(slot)assert(slot==101);return 'spell',635 end
local audit=s.snapshot().dpad
assert(audit.Left.leftIndex==10 and audit.Left.rightIndex==11 and audit.Left.lastAction==101,'proxy indices/action missing')
assert(audit.Left.layers.lt.fallback==101 and audit.Left.layers.lt.nativeSlot==101 and audit.Left.layers.lt.nativeID==101 and audit.Left.layers.lt.page==1 and audit.Left.layers.lt.id==635,'native/proxy route comparison incomplete')
GetActionInfo=function()return secret,secret end
audit=s.snapshot().dpad;assert(audit.Left.layers.lt.kind==nil and audit.Left.layers.lt.id==nil,'secret action identity persisted')
print('PASS: bounded native/proxy D-pad slot audit, trigger indices, native page and secret-safe action identity.')
print('PASS: Deck/Xbox/virtual/disconnect identity, input-mode change, 32 binding diagnostics, secret-safe records, native cast/error feedback, no binding changes')
