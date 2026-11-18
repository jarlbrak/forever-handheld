-- Special native dialogs do not emit PopupOpened. Subscribe through the
-- documented frame manager entry points; native navigation owns all buttons.
local driver=CreateFrame('Frame')
local hooked,registered,views={},{},{}
local elapsed=0
local function safe(f)return f and not (f.IsForbidden and f:IsForbidden()) and not (f.IsProtected and f:IsProtected())end
-- The root stays shown while Info/Entry swap. Native navigation otherwise
-- retains the button from the hidden view. Refresh only on those transitions,
-- through taint-wrapped public APIs, without invoking or replacing any action.
local function viewFocus(frame,manager)
 if not frame:IsShown() then views[frame]=nil;return end
 local info=frame.InfoFrame or _G.AddFriendInfoFrame
 local entry=frame.EntryFrame or _G.AddFriendEntryFrame
 local mode=info and info:IsShown() and 'info' or entry and entry:IsShown() and 'entry'
 local previous=views[frame]
 if not mode or not InputUtil or not InputUtil.IsGamepadUIEnabled() or manager.focusedFrame~=frame then return end
 local nav=_G.SmartNavigation
 if previous and previous~=mode and nav and nav.RefreshButtonGroups and nav.SetTargetButtonForFrame then
  local target=mode=='info' and info.OkayButton or _G.AddFriendEntryFrameInfoButton
  if safe(target) and target:IsShown() then
   nav:RefreshButtonGroups(frame)
   nav:SetTargetButtonForFrame(frame,target)
  end
 end
 views[frame]=mode
end
local function reconcile(frame)
 if InCombatLockdown() or not safe(frame) then return end
 local manager=GamepadMode and GamepadMode.FrameControlsManager
 if not manager or not manager.FrameShown or not manager.FrameHidden then return end
 -- The native manager clears its list when gamepad UI uninitializes.
 -- Read membership to detect that reset even if it occurred between ticks.
 if registered[frame]==manager and type(manager.shownFrames)=='table' then
  local present=false
  for _,shown in ipairs(manager.shownFrames)do if shown==frame then present=true;break end end
  if not present then registered[frame]=nil end
 end
 if frame:IsShown() then
  if registered[frame] and registered[frame]~=manager then registered[frame]=nil end
  if not registered[frame] and InputUtil and InputUtil.IsGamepadUIEnabled() then
   -- FrameShown is the client's public, taint-wrapped registration interface.
   if manager:FrameShown(frame,true) then registered[frame]=manager end
  end
 elseif registered[frame] then
  if InputUtil and InputUtil.IsGamepadUIEnabled() then
   registered[frame]:FrameHidden(frame);registered[frame]=nil
  end
 end
 viewFocus(frame,manager)
 ForeverHandheldDB=ForeverHandheldDB or {}
 local previous=ForeverHandheldDB.socialDialogNavigation or {}
 local lastFocused=previous.lastShownFocused
 if frame:IsShown() then lastFocused=manager.focusedFrame==frame end
 ForeverHandheldDB.socialDialogNavigation={lastShownFocused=lastFocused,version='3.7.92',seen=GetTime(),shown=frame:IsShown(),registered=registered[frame]~=nil,focused=manager.focusedFrame==frame}
end
local function checked(frame)
 local ok,err=pcall(reconcile,frame)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.socialDialogError=tostring(err)end
end
local activityWasShown=false
local function groupFinderFocus()
 local listing=_G.LFGListingFrame
 local activity=listing and listing.ActivityView
 local showing=activity and not (activity.IsForbidden and activity:IsForbidden()) and activity:IsVisible()
 local opened=showing and not activityWasShown
 activityWasShown=not not showing
 if not opened or not InputUtil or not InputUtil.IsGamepadUIEnabled() then return end
 local nav=_G.SmartNavigation
 local target=activity.PlayStyleDropdown
 if not nav or not nav.GetActiveFrame or not nav.RefreshButtonGroups or not nav.SetTargetButtonForFrame or
    not safe(target) or not target:IsVisible() or not target:IsEnabled() then return end
 local owner=nav:GetActiveFrame()
 if owner~=listing and owner~=_G.LFGParentFrame then return end
 if not owner then return end
 -- Keep any valid focus that the client already chose. Replace only the
 -- stale selection from the category that just became hidden.
 local selected=nav.currentButton
 if selected and (selected:IsForbidden() or selected:IsVisible()) then return end
 nav:RefreshButtonGroups(owner)
 nav:SetTargetButtonForFrame(owner,target)
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.groupFinderFocus='3.7.96'
end
local ignoreWasShown=false
local function ignoreListFocus()
 local root=_G.SocialUIFrame
 local list=root and root.IgnoreListFrame
 local showing=safe(list) and list:IsVisible()
 local closed=ignoreWasShown and not showing
 ignoreWasShown=not not showing
 if not closed or not safe(root) or not root:IsVisible() or
    not InputUtil or not InputUtil.IsGamepadUIEnabled() then return end
 local nav=_G.SmartNavigation
 if not nav or not nav.GetActiveFrame or nav:GetActiveFrame()~=root or not nav.GetCurrentButton or
    not nav.RefreshButtonGroups or not nav.SetTargetButtonForFrame then return end
 local selected=nav:GetCurrentButton()
 if not safe(selected) or selected:IsVisible() then return end
 local parent=selected
 while parent and parent~=root and parent~=list do parent=parent:GetParent() end
 if not list or parent~=list then return end
 local bar=root.BattleNetBar
 local target=bar and bar.ControlsContainer and bar.ControlsContainer.BattleNetMenuButton
 if not safe(target) or not target:IsVisible() or not target:IsEnabled() then return end
 nav:RefreshButtonGroups(root)
 nav:SetTargetButtonForFrame(root,target)
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.socialIgnoreFocus='3.7.137'
end
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 if InCombatLockdown() then return end
 local ok,err=pcall(groupFinderFocus)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.groupFinderFocusError=tostring(err)end
 if _G.SocialUIFrame then
  ok,err=pcall(ignoreListFocus)
  if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.socialDialogError=tostring(err)end
 end
 local frame=_G.AddFriendFrame
 if not safe(frame) then return end
 if not hooked[frame] then
  frame:HookScript('OnShow',checked);frame:HookScript('OnHide',checked);hooked[frame]=true
 end
 checked(frame)
end)
