-- Native chat owns editing and sending; local controls only focus, route or clear drafts.
-- No chat is sent by this addon. Clear only discards the current local draft.
local _, addon=...
ForeverHandheldComms={active=false,visible=false,unread=0}
local state=ForeverHandheldComms
local frame=CreateFrame('Frame',nil,UIParent)
local badge=CreateFrame('Frame','ForeverHandheldCommsBadge',UIParent,'BackdropTemplate')
badge:SetSize(242,36);badge:SetPoint('TOPRIGHT',-19,-286)
badge:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
badge:SetBackdropColor(.025,.03,.025,.86);badge:SetBackdropBorderColor(.45,.38,.25,.65)
badge:SetFrameStrata('LOW');badge:EnableMouse(false)
local label=badge:CreateFontString(nil,'OVERLAY')
label:SetFont('Fonts\\ARIALN.TTF',14,'OUTLINE');label:SetPoint('CENTER');label:SetTextColor(.84,.75,.56)
local chrome=CreateFrame('Frame','ForeverHandheldCommsChrome',UIParent)
chrome:SetAllPoints(UIParent);chrome:EnableMouse(false);chrome:SetFrameStrata('DIALOG')
local heading=chrome:CreateFontString(nil,'OVERLAY')
heading:SetFont('Fonts\\FRIZQT__.TTF',13,'OUTLINE');heading:SetTextColor(.84,.75,.56)
heading:SetPoint('TOPRIGHT',-30,-286);heading:SetText('COMMS');heading:Hide()
local hints=chrome:CreateFontString(nil,'OVERLAY')
hints:SetFont('Fonts\\ARIALN.TTF',14,'OUTLINE');hints:SetTextColor(.84,.75,.56)
hints:SetPoint('TOPRIGHT',-30,-572);hints:Hide()
local function active()
  local draft,menu
  for i=1,(NUM_CHAT_WINDOWS or 10) do
    local edit=_G['ChatFrame'..i..'EditBox']
    local chat=_G['ChatFrame'..i]
    if edit and edit:HasFocus() then return edit,true end
    if edit and edit:IsShown() and edit:GetText()~='' then draft=edit end
    if chat and chat.IsGamepadMenuOpen and chat:IsGamepadMenuOpen() then menu=edit end
  end
  return menu or draft,false,menu~=nil
end
local raised=setmetatable({},{__mode='k'})
local opacity=setmetatable({},{__mode='k'})
local chatPointer=setmetatable({},{__mode='k'})
local function setChatHitTest(chatFrame,visible)
  if not chatFrame.IsMouseClickEnabled or not chatFrame.SetMouseClickEnabled then return end
  if InCombatLockdown() and chatFrame:IsProtected() then return end
  local before=chatPointer[chatFrame]
  if visible and before==nil then return end
  local clicks=chatFrame:IsMouseClickEnabled()
  local motion=chatFrame.IsMouseMotionEnabled and chatFrame.SetMouseMotionEnabled and chatFrame:IsMouseMotionEnabled()
  if visible then
    if clicks~=before.clicks then chatFrame:SetMouseClickEnabled(before.clicks) end
    if motion~=before.motion then chatFrame:SetMouseMotionEnabled(before.motion) end
    chatPointer[chatFrame]=nil
  else
    -- Zero alpha alone leaves hidden chat tabs eligible for clicks and hover tips.
    if before==nil then chatPointer[chatFrame]={clicks=clicks,motion=motion} end
    if clicks then chatFrame:SetMouseClickEnabled(false) end
    if motion then chatFrame:SetMouseMotionEnabled(false) end
  end
end
local function conversation()
  for _,name in ipairs({'ControllerForeverTalkBox','ControllerForeverDialogueBand','ControllerForeverDialogueBanner'}) do
    local f=_G[name]
    if f and not f:IsForbidden() and f:IsShown() then return true end
  end
  return false
end
local function liftOpacity(on)
  if InCombatLockdown() then return end
  local function remember(f)
    if f and not f:IsForbidden() and f.IsIgnoringParentAlpha and f.SetIgnoreParentAlpha then
      if opacity[f]==nil then opacity[f]=f:IsIgnoringParentAlpha() end
    end
  end
  if on then
    remember(chrome)
    for i=1,(NUM_CHAT_WINDOWS or 10) do
      for _,suffix in ipairs({'','Tab','ButtonFrame','EditBox'}) do remember(_G['ChatFrame'..i..suffix]) end
    end
    for f in pairs(opacity) do
      if not f:IsIgnoringParentAlpha() then f:SetIgnoreParentAlpha(true) end
    end
  else
    for f,before in pairs(opacity) do
      if not f:IsForbidden() and f:IsIgnoringParentAlpha()~=before then f:SetIgnoreParentAlpha(before) end
      opacity[f]=nil
    end
  end
end
local function layers(overWorkspace)
  -- Change drawing order only; the native chat editor still owns its focus,
  -- bindings and send action. Defer frame mutations during combat lockdown.
  if InCombatLockdown() then return end
  if overWorkspace then
    for i=1,(NUM_CHAT_WINDOWS or 10) do
      for _,suffix in ipairs({'','Tab','ButtonFrame','EditBox'}) do
        local f=_G['ChatFrame'..i..suffix]
        if f and not f:IsForbidden() and f.GetFrameStrata and f.SetFrameStrata then
          if not raised[f] then raised[f]=f:GetFrameStrata() end
        end
      end
    end
    -- Snapshot all original layers before lifting any parent, otherwise a
    -- child could inherit TOOLTIP and incorrectly record it as its baseline.
    for f in pairs(raised) do
      if not f:IsForbidden() and f:GetFrameStrata()~='TOOLTIP' then f:SetFrameStrata('TOOLTIP') end
    end
  else
    for f,strata in pairs(raised) do
      if not f:IsForbidden() then f:SetFrameStrata(strata) end
      raised[f]=nil
    end
  end
  local layer=overWorkspace and 'TOOLTIP' or 'DIALOG'
  if chrome:GetFrameStrata()~=layer then chrome:SetFrameStrata(layer) end
end
local channelNames={SAY='Say',YELL='Yell',PARTY='Party',RAID='Raid',RAID_WARNING='Raid warning',GUILD='Guild',OFFICER='Officers',INSTANCE_CHAT='Instance',WHISPER='Whisper',BN_WHISPER='Whisper',CHANNEL='Channel'}
local function paint()
  local edit,focused,menuOpen=active()
  -- Steam Input often hides physical identity. Positional names remain accurate
  -- on both devices; only advertise Deck-specific labels when positively known.
  local positional=not ForeverHandheldControls or ForeverHandheldControls.kind~='deck'
  state.active=edit~=nil
  state.edit=edit
  state.focused=focused
  -- An intentionally opened draft remains usable over a workspace. A parked,
  -- unfocused draft stays tucked away until resumed with the rear chat key.
  local talking=conversation()
  local covered=talking or (ForeverHandheldPanels and ForeverHandheldPanels.active)
  local shown=state.active and (not covered or focused or menuOpen)
  state.visible=shown and true or false
  -- A parked draft can exist behind a workspace without being readable.
  -- Only a visible conversation consumes its incoming-message indicator.
  if state.visible then state.unread=0 end
  layers(covered and shown)
  -- Cinematic dialogue fades UIParent itself. Focused chat must remain visible
  -- while retaining its exact layout, native editor and send/cancel controls.
  liftOpacity(talking and shown)
  local alpha=shown and 1 or 0
  for i=1,(NUM_CHAT_WINDOWS or 10) do
    for _,suffix in ipairs({'','Tab','ButtonFrame','EditBox'}) do
      local f=_G['ChatFrame'..i..suffix]
      if f and not f:IsForbidden() then
        if f:GetAlpha()~=alpha then f:SetAlpha(alpha) end
        setChatHitTest(f,shown)
      end
    end
  end
  badge:SetShown(not state.active and not covered);heading:SetShown(shown);hints:SetShown(shown)
  if edit then
    local kind=edit:GetChatType() or 'SAY'
    local name=channelNames[kind] or kind
    if kind=='CHANNEL' then
      local id=edit:GetChannelTarget()
      local _,channel=GetChannelName(id)
      name=channel or ('Channel '..tostring(id))
    elseif kind=='WHISPER' then
      name='Whisper: '..(edit:GetAttribute('tellTarget') or 'choose recipient')
    end
    local color=ChatTypeInfo and ChatTypeInfo[kind]
    heading:SetText('DRAFT / '..name)
    if color then heading:SetTextColor(color.r,color.g,color.b) end
    if focused then
      hints:SetText(positional and 'Left rear: Upper Talk\nLower Channel / Hold Clear' or 'L5: Next channel   Hold L5: Clear   L4: Talk')
    else
      hints:SetText(positional and 'Left rear: Upper Talk\nLower Resume / Hold Clear' or 'L5: Resume draft   Hold L5: Clear   L4: Talk')
    end
  end
  label:SetText((positional and 'Left rear: Hold upper to talk\nLower: Chat / Hold to clear' or 'L4 Hold: Talk   L5: Open chat\nIn chat: L5 Channel / Hold to clear')..(state.unread>0 and ('  '..state.unread) or ''))
end
local lastRoute=-1
local function routeDraft()
  if GetTime()-lastRoute<.15 then return end
  lastRoute=GetTime()
  local edit,focused=active()
  edit=edit or ChatFrame1EditBox
  if not edit then return end
  if focused then
    local routes={{kind='SAY'}}
    if IsInGroup(LE_PARTY_CATEGORY_HOME) then routes[#routes+1]={kind='PARTY'} end
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then routes[#routes+1]={kind='RAID'} end
    if IsInGuild() then routes[#routes+1]={kind='GUILD'} end
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then routes[#routes+1]={kind='INSTANCE_CHAT'} end
    routes[#routes+1]={kind='YELL'}
    local channels={GetChannelList()}
    for i=1,#channels,3 do
      local id,name,disabled=channels[i],channels[i+1],channels[i+2]
      if type(id)=='number' and id>0 and not disabled then routes[#routes+1]={kind='CHANNEL',id=id} end
    end
    -- Whisper, officer and unavailable channels are outside this cycle.
    -- Re-enter at Say instead of skipping to its next (possibly public) route.
    local current=0
    for i,r in ipairs(routes) do
      if edit:GetChatType()==r.kind and (r.kind~='CHANNEL' or edit:GetChannelTarget()==r.id) then current=i;break end
    end
    local nextRoute=routes[current%#routes+1]
    edit:SetChatType(nextRoute.kind)
    edit:SetStickyType(nextRoute.kind)
    if nextRoute.id then edit:SetChannelTarget(nextRoute.id) end
    edit:UpdateHeader()
  end
  -- Native OPENCHAT owns focus; never assign ACTIVE_CHAT_EDIT_BOX from addon code.
end
local clearButton=CreateFrame('Button' ,'ForeverHandheldClearDraft',UIParent)
clearButton:RegisterForClicks('AnyDown')
local function clearDraft()
  local edit=active()
  if edit then
    edit:SetText('')
    -- Keep native focus so the next recording can replace the empty draft.
  end
end
clearButton:SetScript('OnClick',clearDraft)
local function configure()
  if InCombatLockdown() or not ControllerForeverDB then return end
  SetOverrideBinding(frame,false,'F8','OPENCHAT')
  SetOverrideBindingClick(frame,false,'F9','ForeverHandheldClearDraft','LeftButton')
  for i=1,(NUM_CHAT_WINDOWS or 10) do
    local edit=_G['ChatFrame'..i..'EditBox']
    if edit and not edit.foreverDraftKey then
      edit.foreverDraftKey=true
      edit:HookScript('OnKeyDown',function(_,key) if key=='F9' then clearDraft() elseif key=='F8' then routeDraft() end end)
    end
  end
  local d=ControllerForeverDB
  d.skins=d.skins or {};d.skins.chat=d.skins.chat or {}
  local s=d.skins.chat
  s.on=true;s.font='arialn';s.fontSize=16;s.outline='outline';s.background='solid'
  s.bgColor='black';s.bgOpacity=92;s.bgShows='always';s.border='thin';s.borderColor='gold'
  s.opacity=100;s.combatOpacity=100;s.idleFade='off';s.fade=0;s.tabs='game'
  s.buttons='hidden';s.editLook='dark';s.editPos='game'
  if ControllerForever and ControllerForever.Skins then ControllerForever.Skins.apply() end
  if ChatFrame1EditBox then ChatFrame1EditBox:SetFont('Fonts\\ARIALN.TTF',18,'OUTLINE') end
end
for _,e in ipairs({'CHAT_MSG_WHISPER','CHAT_MSG_BN_WHISPER','CHAT_MSG_PARTY','CHAT_MSG_PARTY_LEADER','CHAT_MSG_RAID','CHAT_MSG_RAID_LEADER','CHAT_MSG_INSTANCE_CHAT','CHAT_MSG_INSTANCE_CHAT_LEADER','CHAT_MSG_GUILD'}) do frame:RegisterEvent(e) end
frame:RegisterEvent('PLAYER_ENTERING_WORLD');frame:RegisterEvent('PLAYER_REGEN_ENABLED')
frame:RegisterEvent('ADDON_ACTION_BLOCKED');frame:RegisterEvent('ADDON_ACTION_FORBIDDEN')
frame:SetScript('OnEvent',function(_,event,addon,method)
  if event=='ADDON_ACTION_BLOCKED' or event=='ADDON_ACTION_FORBIDDEN' then
    ForeverHandheldDB=ForeverHandheldDB or {}
    ForeverHandheldDB.commsBlocked={addon=addon,method=method,time=GetTime()}
    local history=ForeverHandheldDB.blockedHistory or {}
    ForeverHandheldDB.blockedHistory=history
    history[#history+1]={addon=addon,method=method,event=event,time=GetTime(),
      date=date(),version=(C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata('ForeverHandheld','Version')) or '3.4.0',stack=debugstack(2,35,0)}
    if #history>10 then table.remove(history,1) end
  elseif event=='PLAYER_ENTERING_WORLD' then C_Timer.After(4,configure)
  elseif event=='PLAYER_REGEN_ENABLED' then configure()
  elseif not state.visible then state.unread=math.min(99,state.unread+1) end
end)
local elapsed=0
frame:SetScript('OnUpdate',function(_,dt)
  elapsed=elapsed+dt;if elapsed<.1 then return end;elapsed=0
  local wasVisible=state.visible
  local ok,err=pcall(paint)
  if not ok then
    frame:SetScript('OnUpdate',nil);badge:Hide();heading:Hide();hints:Hide();state.active=false;state.visible=false
    pcall(layers,false)
    pcall(liftOpacity,false)
    for chatFrame in pairs(chatPointer) do
      if not chatFrame:IsForbidden() then pcall(setChatHitTest,chatFrame,true) end
    end
    for i=1,(NUM_CHAT_WINDOWS or 10) do
      for _,suffix in ipairs({'','Tab','ButtonFrame','EditBox'}) do
        local f=_G['ChatFrame'..i..suffix];if f and not f:IsForbidden() then f:SetAlpha(1) end
      end
    end
    ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.commsError=tostring(err)
  end
  if state.visible~=wasVisible then addon.refreshFeeds() end
end)
