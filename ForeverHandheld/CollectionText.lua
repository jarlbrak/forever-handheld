-- Readable collection and social controls; retain native models, text, focus and actions.
local driver=CreateFrame('Frame')
local elapsed=0
local guildLayout=setmetatable({},{__mode='k'})
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function safe(f)return f and not (f.IsForbidden and f:IsForbidden()) and not (f.IsProtected and f:IsProtected())end
local function number(v)return public(v) and type(v)=='number'end
local function fitActivityLevel(row)
 local level=row.Level
 local name=row.NameButton and row.NameButton.Name
 if not (row.CheckButton and safe(level) and safe(name) and level:IsObjectType('FontString') and level:IsShown()) then return end
 local value=level:GetText()
 if not public(value) or type(value)~='string' or value=='' then return end
 local width=level:GetWidth()
 if number(width) and width>0 and width<88 then level:SetWidth(88)end
 if level:GetJustifyH()~='RIGHT' then level:SetJustifyH('RIGHT')end
 local levelLeft,nameLeft,nameWidth=level:GetLeft(),name:GetLeft(),name:GetWidth()
 if number(levelLeft) and number(nameLeft) and number(nameWidth) then
  local available=levelLeft-nameLeft-8
  if available>0 and nameWidth>available+.5 then name:SetWidth(available)end
 end
end
local function font(region)
 if not region or not region.GetFont or not region.SetFont then return false end
 local face,size,flags=region:GetFont()
 if not public(face) or not public(size) or not public(flags) or type(face)~='string' or type(size)~='number' or size<=0 then return false end
 if size<16 then region:SetFont(face,16,flags);return true,true end
 return true,false
end
-- Only the public text regions change. The native pools keep their row
-- geometry, focus, scrolling, button callbacks and voice controls.
local function finite(v)return number(v) and v==v and math.abs(v)<math.huge end
local function channelLabel(text,size,height)
 if not safe(text) or not text.IsObjectType or not text:IsObjectType('FontString') or not text:IsShown() then return end
 local value=text:GetText()
 local h=text:GetHeight()
 local face,old,flags=text:GetFont()
 if not public(value) or type(value)~='string' or value=='' or not finite(h) or h<0 or
    not public(face) or type(face)~='string' or not finite(old) or old<=0 or old>size+.05 or not public(flags) then return end
 -- Native geometry and font getters round after UI scale conversion.
 if old<size-.05 then text:SetFont(face,size,flags)end
 if h<height-.05 then text:SetHeight(height)end
 return true
end
local function hasControl(control)
 return control and ((control.IsForbidden and control:IsForbidden()) or control:IsShown())
end
local function fitRosterName(row,text)
 -- The native roster reserves 140px even in wider plain-text rows. Grow
 -- only the label in those rows. Native voice or rank controls keep their
 -- complete space, including the notification that may appear later.
 if not row.IsVoiceEnabled or not row.GetRight or not text.GetLeft then return end
 local voice=row:IsVoiceEnabled()
 if not public(voice) or voice~=false or hasControl(row.Rank) or hasControl(row.SelfDeafenButton) or
    hasControl(row.SelfMuteButton) or hasControl(row.MemberMuteButton) then return end
 local right,left,width=row:GetRight(),text:GetLeft(),text:GetWidth()
 if not finite(right) or not finite(left) or not finite(width) or width<=0 then return end
 local available=right-left-8
 if available>width+.5 then text:SetWidth(available)end
end
local function updateChannelText()
 if InCombatLockdown() then return end
 local root=_G.ChannelFrame
 if not root or (root.IsForbidden and root:IsForbidden()) or not root:IsShown() then return end
 local count,visited=0,0
 local function rowText(row,key)
  visited=visited+1
  if visited>160 or not safe(row) or not row:IsShown() then return end
  local height=row:GetHeight()
  if not finite(height) or height<19.5 then return end
  local text=row[key]
  if channelLabel(text,16,18) then
   count=count+1
   if key=='Name' then fitRosterName(row,text)end
  end
 end
 local list=root.ChannelList
 if list and not (list.IsForbidden and list:IsForbidden()) and list:IsShown() then
  for _,row in ipairs(list.buttons or {})do if visited>=160 then break end;rowText(row,'Text')end
 end
 local roster=root.ChannelRoster
 if roster and not (roster.IsForbidden and roster:IsForbidden()) and roster:IsShown() then
  channelLabel(roster.ChannelName,14,16)
  channelLabel(roster.ChannelCount,14,16)
  local scroll=roster.ScrollBox or roster.ScrollFrame
  if scroll and not (scroll.IsForbidden and scroll:IsForbidden()) and scroll:IsShown() then
   if scroll.EnumerateFrames then
    for _,row in scroll:EnumerateFrames()do if visited>=160 then break end;rowText(row,'Name')end
   else
    for _,row in ipairs(scroll.buttons or {})do if visited>=160 then break end;rowText(row,'Name')end
   end
  end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 local d=ForeverHandheldDB.channelText or {}
 ForeverHandheldDB.channelText=d
 d.version='3.7.168';d.seen=GetTime();d.count=count;d.visited=visited;d.font=16
end
local function update(rootName)
 if InCombatLockdown() then return end
 local root=_G[rootName]
 if not root or (root.IsForbidden and root:IsForbidden()) or not root:IsShown() then return end
 local visited,count=0,0
 local popup=rootName:match('^StaticPopup%d+$')~=nil
 -- StaticPopup owns protected cancel/timeout handling. Calling its Lua
 -- layout methods from addon code can taint the later native update path.
 -- Keep font changes paint-only and leave popup reflow to its native owner.
 local reflow=rootName=='AddFriendFrame' or rootName=='PlayerSpellsFrame'
 local function walk(frame,depth)
  if depth>6 or visited>=160 or not frame or (frame.IsForbidden and frame:IsForbidden()) or not frame:IsShown() then return end
  -- Native legends size and position icon/text pairs together. Leave that
  -- independent controller layout intact while resizing ordinary book labels.
  if frame.promptFrames and frame.ApplyDefaultPromptPositioning then return end
  local name=frame.GetName and frame:GetName()
  if frame.ForeverHandheldOwnedPresentation or (public(name) and type(name)=='string' and name:match('^ForeverHandheld')) then return end
  visited=visited+1
  local changed=false
  if safe(frame) then
   -- This native sidebar reserves 24px beyond its label. Recover that inner
   -- padding for readable words without moving the row, icon or focus target.
   if rootName=='CommunitiesFrame' and frame.buttonContext=='ButtonContext_CommunitiesListEntryButton' and safe(frame.Name) and not guildLayout[frame.Name] then
    frame.Name:SetPoint('RIGHT',frame,'RIGHT',-6,0)
    guildLayout[frame.Name]=true
   end
   if frame.IsObjectType and frame:IsObjectType('EditBox') then
    local readable,resized=font(frame)
    if readable then count=count+1 end;changed=resized or changed
    local height=frame:GetHeight()
    if public(height) and type(height)=='number' and height>0 and height<26 then frame:SetHeight(26);changed=true end
   end
   for _,region in ipairs({frame:GetRegions()})do
    if safe(region) and region.IsObjectType and region:IsObjectType('FontString') and region:IsShown() then
     local text=region:GetText()
     if public(text) and type(text)=='string' and text~='' then
      local readable,resized=font(region);if readable then count=count+1 end;changed=resized or changed
     end
    end
   end
   -- The activity template reserves 60 px at the old font size. Widen the
   -- right-aligned level column and keep the native row and checkbox intact.
   if rootName=='LFGParentFrame' then fitActivityLevel(frame)end
  end
  -- Protected ancestors may contain ordinary presentation children. Only the
  -- child being changed is guarded; ancestry itself is inspected read-only.
  for _,child in ipairs({frame:GetChildren()})do changed=walk(child,depth+1) or changed end
  -- Native resize containers own wrapping and geometry. Dirty only after a
  -- presentation change; never replace their layout or focus callbacks.
  if reflow and changed and safe(frame) and frame.MarkDirty then frame:MarkDirty()end
  return changed
 end
 walk(root,0)
 if rootName=='LFGParentFrame' then
  local listing=_G.LFGListingFrame
  local activity=listing and listing.ActivityView
  local play=activity and activity.PlayStyleDropdown
  local ranges=activity and activity.LevelRangesCheckbox and activity.LevelRangesCheckbox.Text
  if safe(activity) and activity:IsShown() and safe(play) and safe(ranges) then
   -- Use the empty left inset before enlarging toward the ranges checkbox.
   local p,relative,rp,x,y=play:GetPoint(1)
   if p=='TOPLEFT' and (relative==activity or relative==nil) and rp=='TOPLEFT' and
      number(x) and number(y) and x>=28 then play:SetPoint(p,relative,rp,10,y)end
   local width,right,limit=play:GetWidth(),play:GetRight(),ranges:GetLeft()
   if number(width) and number(right) and number(limit) and width>0 then
    local target=math.min(274,width+math.max(0,limit-right-10))
    if target>width+.5 then play:SetWidth(target)end
   end
  end
  local browse=_G.LFGBrowseFrame
  if safe(browse) and browse:IsShown() then
   for _,key in ipairs({'SendMessageButton','GroupInviteButton'})do
    local button=browse[key]
    if safe(button) then
     local width=button:GetWidth()
     if public(width) and type(width)=='number' and width>0 and width<140 then button:SetWidth(140)end
    end
   end
   local category=browse.CategoryDropdown
   if safe(category) then
    local width=category:GetWidth()
    if public(width) and type(width)=='number' and width>0 and width<168 then
     local point,relative,relativePoint,x,y=category:GetPoint(1)
     -- Expand into the native left margin, preserving the right edge and the
     -- activity dropdown that is anchored there.
     if point=='TOPLEFT' and public(x) and public(y) and type(x)=='number' and type(y)=='number' and x>=168-width+12 then
      category:SetPoint(point,relative,relativePoint,x-(168-width),y)
      category:SetWidth(168)
     end
    end
   end
  end
  local who=_G.LFGWhoListFrame
  local search=who and who.EditBox
  if safe(who) and who:IsShown() and safe(search) then
   local width=search:GetWidth()
   if public(width) and type(width)=='number' and width>0 and width<291 then
    local point,relative,relativePoint,x,y=search:GetPoint(1)
    if point=='TOPLEFT' and public(x) and public(y) and type(x)=='number' and type(y)=='number' and x>=291-width+12 then
     search:SetPoint(point,relative,relativePoint,x-(291-width),y)
     search:SetWidth(291)
    end
   end
  end
 end
 if rootName=='CommunitiesFrame' then
  local finder=root.GuildFinderFrame
  local disabled=finder and finder.DisabledFrame
  local description=disabled and disabled.Description
  -- The native unavailable-guild message is centered in a fixed 500px square.
  -- Larger text otherwise grows upward through its title. Anchor this purely
  -- informational paragraph below that title, retaining its native content.
  if safe(disabled) and disabled:IsShown() and safe(description) and disabled.Title and not guildLayout[description] then
   description:ClearAllPoints()
   description:SetPoint('TOP',disabled.Title,'BOTTOM',0,-18)
   description:SetHeight(180)
   description:SetJustifyV('TOP')
   guildLayout[description]=true
  end
 end
 -- The selected weapon text uses a fixed native dropdown width. Give the
 -- ordinary control room for complete one-/two-handed category names.
 if rootName=='CollectionsJournal' then
  local wardrobe=_G.WardrobeCollectionFrame
  local items=wardrobe and wardrobe.ItemsCollectionFrame
  local dropdown=items and items.WeaponDropdown
  if safe(dropdown) and dropdown:IsShown() then
   local width=dropdown:GetWidth()
   if public(width) and type(width)=='number' and width>0 and width<240 then dropdown:SetWidth(240)end
  end
 end
 -- Keep the anonymous native Ignore List attached; enlarge only within
 -- the current screen space. Native scroll, anchors and block actions stay put.
 if rootName=='SocialUIFrame' then
  local side=root.IgnoreListFrame
  if safe(side) and side:IsShown() then
   local width,left=side:GetWidth(),side:GetLeft()
   local ratio=side:GetEffectiveScale()/UIParent:GetEffectiveScale()
   if public(width) and public(left) and public(ratio) and type(width)=='number' and type(left)=='number' and type(ratio)=='number' and ratio>0 then
    local target=math.max(width,math.min(360,(UIParent:GetWidth()-16)/ratio-left))
    if target>width+.5 then side:SetWidth(target)end
    local buttonWidth=math.min(160,(target-50)/2)
    for _,button in ipairs({side.BlockButton,side.UnblockButton})do
     if safe(button) then
      local current=button:GetWidth()
      if public(current) and type(current)=='number' and buttonWidth>current+.5 then button:SetWidth(buttonWidth)end
     end
    end
   end
  end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 local key=rootName=='CollectionsJournal' and 'collectionText' or rootName=='PlayerSpellsFrame' and 'spellBookText' or rootName=='LFGParentFrame' and 'groupFinderText' or rootName=='CommunitiesFrame' and 'guildText' or rootName=='CommunitiesAvatarPickerDialog' and 'communityIconText' or rootName=='AddFriendFrame' and 'socialDialogText' or (popup and 'popupText' or 'socialText')
 ForeverHandheldDB[key]={version=rootName=='LFGParentFrame' and '3.7.96' or '3.7.72',seen=GetTime(),count=count,visited=visited,font=16}
end
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 local ok,err=pcall(function()for _,name in ipairs({'CollectionsJournal','PlayerSpellsFrame','LFGParentFrame','CommunitiesFrame','CommunitiesAvatarPickerDialog','SocialUIFrame','AddFriendFrame','StaticPopup1','StaticPopup2','StaticPopup3','StaticPopup4'})do update(name)end;updateChannelText()end)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.collectionTextError=tostring(err)end
end)
