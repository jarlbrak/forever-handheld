-- Presentation only for the native chat configuration window. Native tabs,
-- checked values, color swatches, filters, callbacks and focus retain ownership.
local driver=CreateFrame('Frame')
local elapsed=0
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function shown(f)return f and not (f.IsForbidden and f:IsForbidden()) and f:IsShown()end
local function protected(f)return f.IsProtected and f:IsProtected()end
local function readable(r)
 if not r or not r.GetFont then return false end
 local face,size,flags=r:GetFont()
 if public(face) and public(size) and type(face)=='string' and type(size)=='number' and size<16 then
  r:SetFont(face,16,flags);return true
 end
 return false
end
local function paint(f,depth,budget)
 if depth>8 or budget.n>=350 or not shown(f) then return end
 budget.n=budget.n+1
 if not protected(f) then
  for _,r in ipairs({f:GetRegions()})do
   if r.IsObjectType and r:IsObjectType('FontString') then readable(r)end
  end
  if f.IsObjectType and f:IsObjectType('EditBox') then readable(f)end
  -- Narrow native rows reserve only 178px for labels. At the handheld font
  -- size their color buttons overlap long names; the column gutter has room.
  local name=f.GetName and f:GetName()
  if name and name:match('^CombatConfigMessageTypes') and f.GetPoint then
   local point,relative,relativePoint,x,y=f:GetPoint(1)
   if public(x) and type(x)=='number' and math.abs(x-60)<.01 and (point=='LEFT' or point=='TOPLEFT') and (relativePoint=='RIGHT' or relativePoint=='TOPRIGHT') then
    f:SetPoint(point,relative,relativePoint,80,y)
   end
  end
  local swatch=f.ColorSwatch or (name and _G[name..'ColorSwatch'])
  if shown(swatch) and not protected(swatch) and swatch.GetPoint then
   local point,relative,relativePoint,x,y=swatch:GetPoint(1)
   ForeverHandheldDB=ForeverHandheldDB or {}
   if public(x) and type(x)=='number' and math.abs(x-178)<.01 and point=='LEFT' and (relative==f or relative==nil) and (relativePoint=='LEFT' or relativePoint==nil) then
    swatch:SetPoint('LEFT',f,'LEFT',220,y)
   end
  end
 end
 for _,c in ipairs({f:GetChildren()})do paint(c,depth+1,budget)end
end
local function update()
 local root=_G.ChatConfigFrame
 if InCombatLockdown() or not shown(root) then return end
 -- The native tab manager already handles available width and tab art. Only
 -- ask it to remeasure when our font change invalidates its old measurement.
 local manager=root.ChatTabManager
 local resize=false
 if manager and shown(manager) and manager.GetChildren then
  for _,tab in ipairs({manager:GetChildren()})do
   if shown(tab) and not protected(tab) and readable(tab.Text) then resize=true end
  end
  if resize and manager.UpdateWidth and not protected(manager) then manager:UpdateWidth()end
 end
 for i=1,5 do
  local tab=_G['CombatConfigTab'..i]
  if shown(tab) and not protected(tab) and readable(tab.Text) and PanelTemplates_TabResize then
   PanelTemplates_TabResize(tab,0)
  end
 end
 local budget={n=0};paint(root,0,budget)
 for i=1,7 do
  local button=_G['ChatConfigCategoryFrameButton'..i]
  if shown(button) and not protected(button) and button:GetHeight()<24 then button:SetHeight(24)end
 end
 for _,name in ipairs({'ChatConfigFrameDefaultButton','ChatConfigFrameRedockButton','ChatConfigFrameOkayButton','ChatConfigFrameCancelButton','CombatLogDefaultButton','TextToSpeechDefaultButton','ChatConfigCombatSettingsFiltersDeleteButton','ChatConfigCombatSettingsFiltersAddFilterButton','ChatConfigCombatSettingsFiltersCopyFilterButton'})do
  local button=_G[name]
  if shown(button) and not protected(button) and button.GetTextWidth then
   local width=button:GetTextWidth()
   if public(width) and type(width)=='number' and button:GetWidth()<width+24 then button:SetWidth(width+24)end
  end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.chatSettings={version='3.7.51',seen=GetTime(),visited=budget.n}
end
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.3 then return end;elapsed=0
 local ok,err=pcall(update)
 if not ok then
  ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.chatSettingsError=tostring(err)
  driver:SetScript('OnUpdate',nil)
 end
end)

-- The native controller looks for a CloseButton. Chat Settings instead
-- provides Okay or Cancel in its footer. Route B to the visible exit action.
local closeClaim, closeButton, closeHint, hookedRoot
local function visible(frame)
 return shown(frame) and frame:IsVisible()
end
local function updateClose()
 local root=_G.ChatConfigFrame
 local manager=GamepadMode and GamepadMode.FrameControlsManager
 local target
 if visible(root) and manager and manager:GetActiveFrame()==root and
    InputUtil and InputUtil.IsGamepadUIEnabled() and not InCombatLockdown() then
  local cancel=_G.ChatConfigFrameCancelButton
  local okay=_G.ChatConfigFrameOkayButton
  if visible(cancel) and cancel:IsEnabled() then target=cancel
  elseif visible(okay) and okay:IsEnabled() then target=okay end
  for index=1,4 do
   if visible(_G['StaticPopup'..index]) then target=nil;break end
  end
 end
 if target==closeButton then return end
 if target then
  local binds=ControllerForever and ControllerForever.Binds
  if not binds or not binds.claimant or not binds.PRIORITY then return end
  closeClaim=closeClaim or binds:claimant('foreverChatSettingsClose',binds.PRIORITY.gamewindow+1,
   {overGame=true,outOfFight=true})
  if not closeHint then
   local footer=CreateFrame('Frame','ForeverHandheldChatSettingsHint',root)
   footer:EnableMouse(false)
   footer:SetSize(108,22)
   footer:SetPoint('TOPRIGHT',root,'BOTTOMRIGHT',-8,-5)
   footer:SetFrameLevel(root:GetFrameLevel()+2)
   closeHint=footer:CreateFontString(nil,'OVERLAY','GameFontNormal')
   closeHint:SetPoint('CENTER')
  end
  closeHint:SetText(target==_G.ChatConfigFrameCancelButton and 'B  Cancel' or 'B  Done')
  closeHint:Show()
  closeButton=target
  closeClaim.set('PAD2','CLICK '..target:GetName()..':LeftButton')
  closeClaim.commit()
  ForeverHandheldDB=ForeverHandheldDB or {}
  ForeverHandheldDB.chatSettingsController='3.7.103'
 else
  closeHint:Hide()
  closeButton=nil
  closeClaim.clear()
  closeClaim.commit()
 end
end
local function checkedClose()
 local ok,err=pcall(updateClose)
 if not ok then
  ForeverHandheldDB=ForeverHandheldDB or {}
  ForeverHandheldDB.chatSettingsControllerError=tostring(err)
 end
end
local function refreshClose()
 local root=_G.ChatConfigFrame
 if root and root~=hookedRoot and not root:IsForbidden() and not InCombatLockdown() then
  root:HookScript('OnHide',checkedClose)
  hookedRoot=root
 end
 checkedClose()
end
if EventRegistry then EventRegistry:RegisterCallback('Gamepad.RefreshFrameFocus',refreshClose,{}) end
driver:RegisterEvent('PLAYER_REGEN_DISABLED')
driver:RegisterEvent('PLAYER_REGEN_ENABLED')
driver:SetScript('OnEvent',checkedClose)
