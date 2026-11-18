-- Tone the native paper grid without changing dates, navigation, event art,
-- selection highlights or the calendar's month and event scripts.
local function safe(region)
 return region and not (region.IsForbidden and region:IsForbidden())
end
local function readable(region,size)
 if not safe(region) then return end
 local font,n,flags=region:GetFont()
 if font and n and n<size then region:SetFont(font,size,flags)end
end
local gridHint
local moveHint='D-pad  Move    A  Select    B  Back'
local function paint(root)
 local function tint(region,r,g,b)
  if not safe(region) then return end
  region:SetDesaturated(true);region:SetVertexColor(r,g,b)
 end
 for i=1,7 do
  local key='CalendarWeekday'..i
  tint(_G[key..'Background'],.35,.33,.27)
  readable(_G[key..'Name'],14)
 end
 for i=1,42 do
  local key='CalendarDayButton'..i
  local button=_G[key]
  if button and not (button.IsForbidden and button:IsForbidden()) then
   tint(button:GetNormalTexture(),.24,.25,.22)
   tint(_G[key..'DarkFrameTop'],.28,.29,.26)
   tint(_G[key..'DarkFrameBottom'],.28,.29,.26)
   readable(_G[key..'DateFrameDate'],14)
  end
 end
 local footer=CreateFrame('Frame','ForeverHandheldCalendarFooter',root)
 footer:EnableMouse(false);footer:SetFrameLevel(root:GetFrameLevel()+3)
 footer:SetSize(340,25);footer:SetPoint('TOP',root,'BOTTOM',0,-7)
 gridHint=footer:CreateFontString(nil,'OVERLAY')
 gridHint:SetPoint('CENTER')
 gridHint:SetFont(STANDARD_TEXT_FONT,15,'OUTLINE')
 gridHint:SetTextColor(.88,.75,.52)
 gridHint:SetText(moveHint)
end

local driver=CreateFrame('Frame')
local applied=false
local detailFont
local closeClaim,closeTarget,dayTarget
local closeButtons={
 CalendarViewHolidayFrame='CalendarViewHolidayCloseButton',
 CalendarViewRaidFrame='CalendarViewRaidCloseButton',
 CalendarViewEventFrame='CalendarViewEventCloseButton',
 CalendarCreateEventFrame='CalendarCreateEventCloseButton',
}
local function calendarMenu(active)
 local root=_G.CalendarFrame
 if not safe(root) or not root:IsShown() or not active or not active.GetOwnerRegion then return false end
 local owner=active:GetOwnerRegion()
 for _=1,16 do
  if not safe(owner) then return false end
  if owner==root then return true end
  if owner.GetOwnerRegion then owner=owner:GetOwnerRegion()
  else owner=owner.GetParent and owner:GetParent()end
 end
 return false
end
local function syncClose()
 local manager=GamepadMode and GamepadMode.FrameControlsManager
 local active=manager and manager:GetActiveFrame()
 local target,day
 local editor=_G.CalendarCreateEventFrame
 local viewer=_G.CalendarViewEventFrame
 local formVisible=(safe(editor) and editor:IsVisible()) or (safe(viewer) and viewer:IsVisible())
 if active and InputUtil and InputUtil.IsGamepadUIEnabled() and not InCombatLockdown() then
  if calendarMenu(active) then
   -- Stand down the whole-window shortcut and let the native menu consume B.
   target='native-menu'
  else
   local kit=ControllerForever and ControllerForever.Kit
   if not (kit and kit.typing and kit.typing()) then
    for name,button in pairs(closeButtons) do
     if active==_G[name] and safe(active) and active:IsVisible() then
      target=button
      break
     end
    end
    if active==_G.CalendarFrame and not formVisible and SmartNavigation and
       SmartNavigation:GetActiveFrame()==active then
     local selected=SmartNavigation:GetCurrentButton()
     local name=safe(selected) and selected.GetName and selected:GetName()
     if name and type(name)=='string' and not (issecretvalue and issecretvalue(name)) and
        name:match('^CalendarDayButton%d+$') and _G[name]==selected then day=name end
    end
   end
  end
 end
 if gridHint and gridHint:IsShown()==not not formVisible then gridHint:SetShown(not formVisible)end
 if target==closeTarget and day==dayTarget then return end
 if not closeClaim then
  local binds=ControllerForever and ControllerForever.Binds
  if not binds or not binds.claimant or not binds.PRIORITY then return end
  closeClaim=binds:claimant('foreverCalendarCard',binds.PRIORITY.gamewindow+1,{overGame=true,outOfFight=true})
 end
 if gridHint and day~=dayTarget then
  gridHint:SetText(day and 'D-pad  Move    A  Select    X  Date options    B  Back' or moveHint)
 end
 closeTarget,dayTarget=target,day
 -- Controller Forever normally gives Calendar B a whole-window close.
 -- Only while a native detail card owns focus, use its existing close click.
 closeClaim.clear()
 if target=='native-menu' then closeClaim.set('PAD2',false)
 elseif target then closeClaim.set('PAD2','CLICK '..target..':LeftButton')end
 -- Bind to the named native day button. Its own RightButton action runs
 -- from the physical input and opens the native date menu.
 if day then closeClaim.set('PAD3','CLICK '..day..':RightButton')end
 closeClaim.commit()
end
local function checkedClose()
 local ok,err=pcall(syncClose)
 if not ok then
  ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.calendarCloseError=tostring(err)
 end
end
local function eventCard(frame,form)
 local bg=frame:CreateTexture(nil,'BACKGROUND')
 bg:SetAllPoints();bg:SetColorTexture(.025,.030,.029,1)
 for _,edge in ipairs({{'TOPLEFT','TOPRIGHT'},{'BOTTOMLEFT','BOTTOMRIGHT'},{'TOPLEFT','BOTTOMLEFT',true},{'TOPRIGHT','BOTTOMRIGHT',true}})do
  local line=frame:CreateTexture(nil,'BORDER')
  line:SetPoint(edge[1]);line:SetPoint(edge[2])
  if edge[3] then line:SetWidth(1)else line:SetHeight(1)end
  line:SetColorTexture(.72,.60,.39,1)
 end
 if frame.Border then frame.Border:SetAlpha(0)end
 -- The generic holiday-card texture is decoration. Day-specific art stays
 -- in the grid and the native event title and description stay in the card.
 if not form and frame.Texture then frame.Texture:SetAlpha(0)end
 local buttonBackground=_G[frame:GetName()..'ButtonBackground']
 if safe(buttonBackground) then buttonBackground:SetAlpha(0)end
 if not frame:IsProtected() then frame:SetClampedToScreen(true)end
 local header=frame.Header
 if header then
  for _,r in ipairs({header:GetRegions()})do
   if safe(r) and r:IsObjectType('Texture') then r:SetAlpha(0)end
  end
  readable(header.Text,16)
 end
 local scroll=frame.ScrollingFont
 if safe(scroll) and scroll.GetFontString and scroll.SetFontObject then
  if not detailFont then
   local face,_,flags=scroll:GetFontString():GetFont()
   if face then
    detailFont=CreateFont('ForeverHandheldCalendarDescriptionFont')
    detailFont:SetFont(face,16,flags);detailFont:SetTextColor(.94,.90,.82)
   end
  end
  -- ScrollingFont's native setter recomputes extent and returns to the first
  -- line; changing its inner region directly would clip the larger text.
  if detailFont then scroll:SetFontObject(detailFont)end
 end
 if form then
  local strip=frame:CreateTexture(nil,'ARTWORK')
  strip:SetPoint('TOPLEFT',frame,'BOTTOMLEFT',0,0)
  strip:SetPoint('TOPRIGHT',frame,'BOTTOMRIGHT',0,0)
  strip:SetHeight(25);strip:SetColorTexture(.025,.030,.029,1)
  local hint=frame:CreateFontString(nil,'OVERLAY')
  hint:SetPoint('TOP',frame,'BOTTOM',0,-5)
  hint:SetFont(STANDARD_TEXT_FONT,15,'OUTLINE')
  hint:SetTextColor(.88,.75,.52)
  hint:SetText(moveHint)
  if frame==_G.CalendarCreateEventFrame then
   readable(_G.CalendarCreateEventTitleEdit,15)
   local container=_G.CalendarCreateEventDescriptionContainer
   local description=container and container.ScrollingEditBox
   if description then readable(description:GetEditBox(),15)end
  end
 end
end
local function hookEventCard(root,frame,form)
 if not safe(frame) then return end
 local painted,owner
 local function takeFocus(f)
  if not safe(f) or not f:IsVisible() or InCombatLockdown() then return end
  local m=GamepadMode and GamepadMode.FrameControlsManager
  if not InputUtil or not InputUtil.IsGamepadUIEnabled() or not m or not m.HandlePopupShown then return end
  local active=m:GetActiveFrame()
  if active==root then
   -- The native popup stack preserves the date selection on return.
   m:HandlePopupShown(f)
   if m:GetActiveFrame()==f then owner=m end
  end
 end
 local function checkedFocus(f)
  local ok,err=pcall(takeFocus,f)
  ForeverHandheldDB=ForeverHandheldDB or {}
  if not ok then ForeverHandheldDB.calendarCardError=tostring(err)
  elseif owner then ForeverHandheldDB.calendarCardFocus='3.7.149' end
  checkedClose()
 end
 local function shown(f)
  if InCombatLockdown() or not safe(f) then return end
  local ok,err=pcall(function()
   if not painted then eventCard(f,form);painted=true end
   if form and not f:IsProtected() then
    -- The day grid shares the native event form's strata. A centered
    -- form needs its own layer so the grid cannot cover its controls.
    f:SetFrameStrata('DIALOG')
    f:ClearAllPoints()
    f:SetPoint('CENTER',UIParent,'CENTER',0,-14)
   end
  end)
  if not ok then
   ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.calendarCardError=tostring(err)
  end
  local m=GamepadMode and GamepadMode.FrameControlsManager
  if form and m and calendarMenu(m:GetActiveFrame()) then
   -- The menu's click runs before it returns focus to Calendar.
   C_Timer.After(0,function() checkedFocus(f)end)
  else
   checkedFocus(f)
  end
 end
 frame:HookScript('OnShow',shown)
 frame:HookScript('OnHide',function(f)
  local m=owner;owner=nil
  if m and InputUtil and InputUtil.IsGamepadUIEnabled() then m:FrameHidden(f)end
  checkedClose()
 end)
 if frame:IsVisible() then shown(frame)end
end
local function dockDayTooltip(day)
 local root,tip=_G.CalendarFrame,_G.GameTooltip
 if InCombatLockdown() or not InputUtil or not InputUtil.IsGamepadUIEnabled() or
    not safe(root) or not safe(tip) or not tip:IsShown() or tip:GetOwner()~=day then return end
 local ratio=tip:GetEffectiveScale()/root:GetEffectiveScale()
 local width=tip:GetWidth()*ratio
 local screenWidth=UIParent:GetWidth()*UIParent:GetEffectiveScale()/root:GetEffectiveScale()
 local left,right=root:GetLeft(),root:GetRight()
 if not left or not right then return end
 tip:SetAnchorType('ANCHOR_NONE')
 tip:ClearAllPoints()
 if screenWidth-right>=width+16 then
  tip:SetPoint('TOPLEFT',root,'TOPRIGHT',8,-48)
 elseif left>=width+16 then
  tip:SetPoint('TOPRIGHT',root,'TOPLEFT',-8,-48)
 else
  -- On the Deck's narrower screen, stay below the month and filter row.
  local dayX=day:GetCenter()
  if dayX and dayX>(left+right)/2 then
   tip:SetPoint('TOPLEFT',root,'TOPLEFT',12,-82)
  else
   tip:SetPoint('TOPRIGHT',root,'TOPRIGHT',-12,-82)
  end
 end
end
local function checked(root)
 if applied or InCombatLockdown() then return end
 local ok,err=pcall(paint,root)
 ForeverHandheldDB=ForeverHandheldDB or {}
 if ok then ForeverHandheldDB.calendarStyle='3.7.149'
 else ForeverHandheldDB.calendarStyleError=tostring(err) end
 applied=true
end
local function attach()
 local root=_G.CalendarFrame
 if not root or (root.IsForbidden and root:IsForbidden()) then return end
 root:HookScript('OnShow',checked)
 hookEventCard(root,_G.CalendarViewHolidayFrame)
 hookEventCard(root,_G.CalendarViewRaidFrame)
 hookEventCard(root,_G.CalendarViewEventFrame,true)
 hookEventCard(root,_G.CalendarCreateEventFrame,true)
 if CalendarDayButton_OnEnter then hooksecurefunc('CalendarDayButton_OnEnter',dockDayTooltip)end
 if SmartNavigation and SmartNavigation.RegisterCallback then
  local scheduled
  SmartNavigation:RegisterCallback('SelectedButtonUpdated',function()
   if scheduled or not root:IsShown() then return end
   scheduled=true
   C_Timer.After(0,function() scheduled=false;checkedClose()end)
  end,driver)
 end
 if root:IsShown() then checked(root)end
 driver:UnregisterAllEvents()
end
driver:RegisterEvent('ADDON_LOADED')
driver:RegisterEvent('PLAYER_LOGIN')
driver:SetScript('OnEvent',function(_,event,name)
 if event=='PLAYER_LOGIN' or name=='Blizzard_Calendar' then attach()end
end)
EventRegistry:RegisterCallback('Gamepad.RefreshFrameFocus',checkedClose,{})
