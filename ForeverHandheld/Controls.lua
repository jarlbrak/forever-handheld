-- Presentation and read-only diagnostics. Native secure bindings own all actions.
ForeverHandheldControls={kind='controller',gamepadActive=true}
local S=ForeverHandheldControls
local driver=CreateFrame('Frame')
local function readable(v)return not (issecretvalue and issecretvalue(v))end
local function public(v)if readable(v) then return v end end
local function get(fn,...)
 if type(fn)~='function' then return nil end
 local ok,v=pcall(fn,...);if ok and readable(v) then return v end
end
function S.classify(name,vendor,product)
 name,vendor,product=public(name),public(vendor),public(product)
 name=type(name)=='string' and name:lower() or ''
 if name:find('steam deck',1,true) or name:find('neptune',1,true) or (vendor==0x28de and product==0x1205) then return 'deck' end
 if name:find('elite',1,true) then return 'xbox' end
 if name:find('virtual',1,true) or name:find('360',1,true) or (vendor==0x045e and product==0x028e) then return 'controller' end
 if name:find('xbox',1,true) or vendor==0x045e then return 'xbox' end
 return 'controller'
end
function S.rearLabels()
 if S.kind=='deck' then return 'L4','L5','R4','R5' end
 return 'Upper-left rear','Lower-left rear','Upper-right rear','Lower-right rear'
end
function S.notify(message,kind,duration)
 if type(message)~='string' or not readable(message) or message=='' then return end
 -- An input edge is only an acknowledgement, not the result of that action.
 -- The HUD may sample it after the game has already reported a cast/error.
 if kind=='input' and (S.untilTime or 0)>GetTime() and
  (S.feedbackKind=='error' or S.feedbackKind=='casting' or S.feedbackKind=='success') then return end
 S.message=message;S.feedbackKind=kind or 'info';S.untilTime=GetTime()+(duration or 2.5)
end
local physical,lastPhysical,inventoryAt={},nil,-10
local function refreshPhysical(pad)
 local now=GetTime();if now-inventoryAt<2 then return end;inventoryAt=now
 local combined=get(pad.GetCombinedDeviceID)
 local ids=get(pad.GetAllDeviceIDs)
 if type(ids)~='table' then return end
 local nextPhysical={}
 for n,id in ipairs(ids)do
  if n>16 then break end
  if readable(id) and type(id)=='number' and id~=combined then
   local raw=get(pad.GetDeviceRawState,id)
   if type(raw)=='table' then
    local kind=S.classify(raw.name,raw.vendorID,raw.productID)
    if kind~='controller' then
     local old=physical[id]
     nextPhysical[id]={kind=kind,name=public(raw.name),previous=old and old.kind==kind and old.previous or nil}
    end
   end
  end
 end
 physical=nextPhysical
 if lastPhysical and not physical[lastPhysical] then lastPhysical=nil end
end
local function intentionalInput(now,previous)
 if type(now)~='table' or type(previous)~='table' then return false end
 local buttons,before=now.buttons,previous.buttons
 if type(buttons)=='table' and type(before)=='table' then
  for i=1,math.min(#buttons,32)do
   local a,b=public(buttons[i]),public(before[i])
   if a==true and b==false then return true end
  end
 end
 local axes,old=now.axes,previous.axes
 if type(axes)=='table' and type(old)=='table' then
  for i=1,math.min(#axes,16)do
   local a,b=public(axes[i]),public(old[i])
   -- Ignore neutral jitter and releases; a held stick retains its last owner.
   if type(a)=='number' and type(b)=='number' and math.abs(a)>.25 and math.abs(a-b)>.15 then return true end
  end
 end
 return false
end
local function physicalOwner(pad)
 refreshPhysical(pad)
 local candidate,ambiguous,count=nil,false,0
 for id,entry in pairs(physical)do
  local state=get(pad.GetDeviceMappedState,id)
  if type(state)=='table' then
   count=count+1
   if intentionalInput(state,entry.previous) then
    if candidate then ambiguous=true else candidate=id end
   end
   entry.previous=state
  end
 end
 if ambiguous then lastPhysical=nil
 elseif candidate then lastPhysical=candidate end
 -- Wine may retain one disconnected physical device indefinitely. A sole
 -- enumerated name is not proof of current ownership; require a fresh edge.
 if count==0 then lastPhysical=nil end
 local entry=lastPhysical and physical[lastPhysical]
 return entry and entry.kind,lastPhysical,entry and entry.name
end
local function updateDevice()
 if not C_GamePad then return end
 local id=get(C_GamePad.GetActiveDeviceID)
 local mapped=get(C_GamePad.GetDeviceMappedState,id)
 local raw=id and get(C_GamePad.GetDeviceRawState,id)
 local name=raw and raw.name or mapped and mapped.name or ''
 if not readable(name) then name='' end
 S.deviceID=id;S.deviceName=name
 S.kind=S.classify(name,raw and raw.vendorID,raw and raw.productID)
 -- Steam Input exposes the built-in pad as a virtual Xbox 360 device.
 -- Do not guess physical identity from that generic name or its numeric ID.
 S.connected=mapped~=nil
 local kind,physicalID,physicalName=physicalOwner(C_GamePad)
 local combined=get(C_GamePad.GetCombinedDeviceID)
 -- The aggregate can inherit the last device's friendly name (including
 -- "Xbox One Elite 2"). That name is not evidence of the current input owner.
 if type(C_GamePad.GetAllDeviceIDs)=='function' then
  S.kind=kind or 'controller';S.physicalDeviceID=physicalID;S.physicalDeviceName=physicalName
 elseif id==combined or S.kind=='controller' then
  S.kind=kind or 'controller';S.physicalDeviceID=physicalID;S.physicalDeviceName=physicalName
 else S.physicalDeviceID=nil;S.physicalDeviceName=nil end
end
local keys={'PADDUP','PADDLEFT','PADDDOWN','PADDRIGHT','PAD1','PAD2','PAD3','PAD4'}
local sets={'top','left','right','bottom'}
function S.snapshot()
 local d={version='3.7.23',at=GetTime(),device=S.deviceName,deviceID=S.deviceID,kind=S.kind,
  gamepadActive=S.gamepadActive,cvars={},bindings={},actions={},devices={}}
 d.physicalDeviceID=S.physicalDeviceID;d.physicalDeviceName=S.physicalDeviceName
 local pad=C_GamePad or {}
 d.combinedDeviceID=get(pad.GetCombinedDeviceID)
 -- Read native selection and binding ownership without entering its callbacks.
 -- A keyboard modifier's blocker is not proof that a physical trigger failed:
 -- the client can consume triggers internally and route the plain pad key.
 local mode=GamepadMode or {}
 local manager=GamepadSharedUtility and GamepadSharedUtility.InputBindingManager
 local focus=mode.FrameControlsManager
 local page=GamepadMainActionBarFrame and GamepadMainActionBarFrame.PageUnit
 local active=page and get(page.GetActiveBar,page)
 d.native={leftModifier=get(mode.IsLeftModifierDown),rightModifier=get(mode.IsRightModifierDown),
  activeBar=active and get(active.GetName,active),
  core=manager and get(manager.IsOnlyCoreBindingSetActive,manager),
  focus=public(focus and focus.isUIFocused),fallthrough=public(focus and focus.fallThroughCatcherActive),stack={}}
 if page and type(page.actionBars)=='table' then
  for _,name in ipairs({'topBar','leftBar','rightBar','bottomBar'}) do
   if active and active==page.actionBars[name] then d.native.activeBank=name;break end
  end
 end
 local stack=manager and manager.bindingSetStack
 if type(stack)=='table' then
  for i=1,math.min(#stack,16) do
   local set=stack[i]
   if type(set)=='table' then
    local entry={name=public(set.name),core=public(set.treatBindsAsCore),keys={}}
    for _,key in ipairs({'PADDUP','PADDLEFT','PADDDOWN','PADDRIGHT','SHIFT-PADDUP','SHIFT-PADDLEFT','SHIFT-PADDDOWN','SHIFT-PADDRIGHT','PADLTRIGGER','PADRTRIGGER'}) do
     local binding=get(set.GetBinding,set,key)
     if type(binding)=='table' then entry.keys[key]={active=public(binding.isActive),type=public(binding.type)} end
    end
    d.native.stack[#d.native.stack+1]=entry
   end
  end
 end
 -- Bounded identity inventory explains combined/virtual devices without
 -- recording audio, chat, or a stream of controller input.
 local ids=get(pad.GetAllDeviceIDs)
 if type(ids)=='table' then
  for n,id in ipairs(ids)do
   if n>16 then break end
   if readable(id) and type(id)=='number' then
    local raw=get(pad.GetDeviceRawState,id)
    local mapped=get(pad.GetDeviceMappedState,id)
    d.devices[#d.devices+1]={id=id,rawName=public(raw and raw.name),mappedName=public(mapped and mapped.name),
     vendor=public(raw and raw.vendorID),product=public(raw and raw.productID),
     buttons=public(mapped and mapped.buttonCount),axes=public(mapped and mapped.axisCount)}
   end
  end
 end
 for _,k in ipairs({'GamePadEmulateShift','GamePadEmulateCtrl','GamePadEmulateAlt','GamePadEnable','InputDeviceInterfaceStyle'}) do
  d.cvars[k]=get(C_CVar and C_CVar.GetCVar or GetCVar,k)
 end
 local rb=ControllerForever and ControllerForever.RuleBar
 -- Read the actual native trigger router as well as ordinary key bindings:
 -- RT is not necessarily an emulated keyboard modifier. Never change these
 -- protected attributes, and never record macro bodies or input histories.
 local h=_G.ControllerForeverHeldTriggerKeys
 local function attr(k)return h and get(h.GetAttribute,h,k)end
 d.routing={state=attr('held-state'),last=attr('held-last'),calls=attr('held-calls'),
  count=attr('held-count'),bindingHold=public(rb and rb.state and rb.state.bindingHold),
  paused=public(rb and rb.state and rb.state.paused),keys={}}
 local count=d.routing.count
 if type(count)=='number' then
  for i=1,math.min(count,64)do
   local key=attr('held-key-'..i)
   if type(key)=='string' and key:find('PADD',1,true) then
    local entry={key=key,index=attr('held-index-'..i),gameOwns=attr('held-game-'..i),states={}}
    for _,state in ipairs({'00','10','01','11'})do entry.states[state]=attr('held-'..state..'-'..i)end
    d.routing.keys[#d.routing.keys+1]=entry
   end
  end
 end
 local layers={top='bare',left='lt',right='rt',bottom='ltrt'}
 d.dpad={}
 local cf=ControllerForever or {}
 for _,direction in ipairs({'Up','Left','Down','Right'})do
  local proxy=_G['ControllerForeverTapPad'..direction]
  local function read(k)return proxy and get(proxy.GetAttribute,proxy,k)end
  local entry={leftIndex=read('cr-lt-index'),rightIndex=read('cr-rt-index'),lastAction=read('action'),layers={}}
  for _,layer in ipairs({'bare','lt','rt','ltrt'})do
   local native=cf.Stances and get(cf.Stances.nativeButton,layer,direction,false)
   local slot=native and cf.Shoulders and get(cf.Shoulders.nativeButtonAction,native)
   local item={fallback=read('cr-slot-'..layer),nativeSlot=slot,
    nativeID=native and get(native.GetID,native),page=native and get(native.GetAttribute,native,'actionpage')}
   if type(slot)=='number' and type(GetActionInfo)=='function' then
    local info=get(function()local kind,id=GetActionInfo(slot);return {kind=public(kind),id=public(id)}end)
    if info then item.kind=info.kind;item.id=info.id end
   end
   entry.layers[layer]=item
  end
  d.dpad[direction]=entry
 end
 for _,set in ipairs(sets)do
  local prefix=rb and get(rb.layerKeyPrefix,layers[set])
  d.bindings[set]={};d.actions[set]={}
  for _,key in ipairs(keys)do
   local native=_G['InputFunctionBindingButton_'..key]
   d.bindings[set][key]={command=prefix and get(GetBindingAction,prefix..key,true) or nil,
    native=native~=nil,shown=native and get(native.IsShown,native),
    action=native and get(native.GetAttribute,native,'action')}

  end
  for i=1,8 do
   local f=_G['ControllerForeverPad'..(set=='top' and '' or set)..i]
   local a=f and f.crDrawn;local look=f and f.crLookSrc
   d.actions[set][i]={spell=public(a and a.spellID),macro=public(a and a.macroName),
    resolvedKind=public(look and look.kind),resolvedID=public(look and look.id),mode=public(f and f.crMode)}
  end
 end
 ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.controls=d
 -- Opening chat to request or flush a report must not erase the last actual
 -- world route. Keep one bounded snapshot, not a history of user input.
 if d.native.core==true and d.native.focus~=true and not get(GetCurrentKeyBoardFocus) then
  ForeverHandheldDB.controlsWorld=d
 end
 return d
end
local function onEvent(_,event,...)
 if event=='GAME_PAD_ACTIVE_CHANGED' then S.gamepadActive=public((...))==true;updateDevice()
 elseif event=='GAME_PAD_CONNECTED' or event=='GAME_PAD_DISCONNECTED' then
  if event=='GAME_PAD_DISCONNECTED' then lastPhysical=nil end
  inventoryAt=-10;updateDevice()
 elseif event=='UI_ERROR_MESSAGE' then local _,message=...;S.notify(message,'error',3)
 elseif event:find('UNIT_SPELLCAST',1,true) then
  local unit,_,spellID=...;if unit~='player' or not readable(spellID) then return end
  local name=get(C_Spell and C_Spell.GetSpellName,spellID)
  if not name then return end
  if event=='UNIT_SPELLCAST_SUCCEEDED' then S.notify(name,'success',1.2)
  elseif event=='UNIT_SPELLCAST_START' or event=='UNIT_SPELLCAST_CHANNEL_START' then S.notify('Casting: '..name,'casting',2)
  elseif event=='UNIT_SPELLCAST_INTERRUPTED' then S.notify('Interrupted: '..name,'error',2)
  elseif event=='UNIT_SPELLCAST_FAILED' and not (S.feedbackKind=='error' and (S.untilTime or 0)>GetTime()) then S.notify('Could not cast '..name,'error',2) end
 end
end
for _,event in ipairs({'GAME_PAD_ACTIVE_CHANGED','GAME_PAD_CONNECTED','GAME_PAD_DISCONNECTED','UI_ERROR_MESSAGE',
 'UNIT_SPELLCAST_START','UNIT_SPELLCAST_CHANNEL_START','UNIT_SPELLCAST_SUCCEEDED','UNIT_SPELLCAST_FAILED','UNIT_SPELLCAST_INTERRUPTED'})do driver:RegisterEvent(event)end
driver:SetScript('OnEvent',function(...)
 local ok,err=pcall(onEvent,...)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.controlsError=tostring(err)end
end)
local elapsed,diagnostics=0,0
-- One bounded, passive sample after load. These are actual UI frame intervals,
-- not a benchmark claim: scene, Desktop/Gaming Mode and capture affect results.
local frameSample={warmup=5,seconds=0,frames=0,over33ms=0,over50ms=0,maxMs=0}
driver:SetScript('OnUpdate',function(_,dt)
 if frameSample then
  local p=frameSample
  if p.warmup>0 then p.warmup=p.warmup-dt
  else
   p.seconds=p.seconds+dt;p.frames=p.frames+1
   local ms=dt*1000;p.maxMs=math.max(p.maxMs,ms)
   if ms>33.34 then p.over33ms=p.over33ms+1 end
   if ms>50 then p.over50ms=p.over50ms+1 end
   if p.seconds>=60 then
    p.averageFPS=p.frames/p.seconds;p.completedAt=GetTime();p.warmup=nil
    ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.frameSample=p
    frameSample=nil
   end
  end
 end
 elapsed=elapsed+dt;diagnostics=diagnostics+dt;if elapsed<.1 then return end;elapsed=0
 local ok,err=pcall(function()updateDevice();if diagnostics>=15 then diagnostics=0;S.snapshot()end end)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.controlsError=tostring(err)end
end)
