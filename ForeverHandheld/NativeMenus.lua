-- Resize ordinary text during public menu initialization, before native layout.
-- The native menu retains its responders, final initializer, focus and scrolling.
local driver=CreateFrame('Frame')
local descriptions=setmetatable({},{__mode='k'})
local saved=setmetatable({},{__mode='k'})
local fonts={}
local hooked,elapsed
local syncDriver
elapsed=0
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function safe(f)
 return f and not (f.IsForbidden and f:IsForbidden()) and not (f.IsProtected and f:IsProtected())
end
local function ownerRoot(owner)
 for _=1,16 do
  if not safe(owner) then return end
  if owner==_G.SettingsPanel or owner==_G.CooldownViewerSettings then return owner end
  owner=owner.GetParent and owner:GetParent()
 end
end
local function restore(menu)
 local entries=saved[menu]
 if not entries then return end
 if InCombatLockdown() then entries.pending=true;syncDriver();return end
 for region,old in pairs(entries)do
  if type(old)=='table' and safe(old.frame) then
   region:SetFontObject(old.fontObject)
   region:SetWidth(old.width);region:SetHeight(old.height)
  end
 end
 saved[menu]=nil
 syncDriver()
end
local function initialize(frame,description,menu)
 if InCombatLockdown() or not safe(frame) or not safe(menu) then return end
 local owner=menu.GetOwnerRegion and menu:GetOwnerRegion()
 -- A submenu can be owned by its parent menu; follow that public owner link.
 local root=ownerRoot(owner)
 for _=1,6 do
  if root or not safe(owner) or not owner.GetOwnerRegion then break end
  owner=owner:GetOwnerRegion();root=ownerRoot(owner)
 end
 if not root or not root:IsShown() then return end
 local region=frame.fontString or frame.Text
 if not region or not region.GetFont or not region:IsShown() then return end
 local face,size,flags=region:GetFont()
 local originalFont=region.GetFontObject and region:GetFontObject()
 local width,height=region:GetWidth(),region:GetHeight()
 if not originalFont or not public(originalFont) or not public(face) or not public(size) or not public(flags) or not public(width) or not public(height) or
  type(face)~='string' or type(size)~='number' or size<=0 or type(width)~='number' or type(height)~='number' then return end
 local target=math.max(size,16)
 local targetHeight=math.max(height,26)
 if target==size and targetHeight==height then return end
 saved[menu]=saved[menu] or {}
 if not saved[menu][region] then saved[menu][region]={frame=frame,fontObject=originalFont,width=width,height=height}end
 -- The menu compositor deliberately disallows FontString:SetFont. Its public
 -- SetFontObject path supports an owned font without altering global fonts.
 local font
 for _,entry in ipairs(fonts)do
  if entry.face==face and entry.size==target and entry.flags==flags then font=entry.font;break end
 end
 if not font then
  if #fonts>=24 then return end
  font=CreateFont('ForeverHandheldNativeMenuFont'..(#fonts+1))
  font:SetFont(face,target,flags)
  fonts[#fonts+1]={face=face,size=target,flags=flags,font=font}
 end
 region:SetFontObject(font)
 -- SetTextToFit has already sized the native region at its original font.
 -- Keep its text/anchors intact and grow that measured width proportionally.
 region:SetWidth(math.max(width,width*target/size))
 region:SetHeight(targetHeight)
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.nativeMenus={version='3.7.166',seen=GetTime(),font=target,rowTextHeight=targetHeight}
end
local function guardedInitialize(...)
 local ok,err=pcall(initialize,...)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.nativeMenuError=tostring(err)end
 syncDriver()
end
local function populate(_,owner,root)
 if not ownerRoot(owner) or not root or descriptions[root] or not root.AddMenuReleasedCallback then return end
 local count=0
 local function walk(description,depth)
  if depth>6 or count>=240 or not description.EnumerateElementDescriptions then return end
  for _,child in description:EnumerateElementDescriptions() do
   count=count+1;if count>240 then break end
   if not descriptions[child] and child.AddInitializer then
    child:AddInitializer(guardedInitialize);descriptions[child]=true
   end
   walk(child,depth+1)
  end
 end
 walk(root,0)
 root:AddMenuReleasedCallback(restore)
 descriptions[root]=true
end
local function tick(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 local ok,err=pcall(function()
  if not InCombatLockdown() then
   for menu,entries in pairs(saved)do
    if entries.pending then restore(menu)
    elseif safe(menu) and menu:IsShown() then
     for region,old in pairs(entries)do
      if type(old)=='table' and safe(old.frame) then
       local _,size=region:GetFont()
       if public(size) and type(size)=='number' then
        if ForeverHandheldDB and ForeverHandheldDB.nativeMenus then ForeverHandheldDB.nativeMenus.observedFont=size end
       end
      end
     end
    end
   end
  end
  if Menu and Menu.PopulateDescription and hooksecurefunc and hooked~=Menu then
   hooksecurefunc(Menu,'PopulateDescription',function(...)
    local good,why=pcall(populate,...)
    if not good then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.nativeMenuError=tostring(why)end
   end)
   hooked=Menu
  end
 end)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.nativeMenuError=tostring(err)end
 syncDriver()
end

local running=false
syncDriver=function()
 -- Menu creation and release already pass through our existing callbacks.
 -- Once discovery is complete, only live or deferred pool records need a
 -- render driver; ordinary world play has no menu work to poll.
 local wanted=not hooked or next(saved)~=nil
 if wanted==running then return end
 running=wanted;elapsed=0
 driver:SetScript('OnUpdate',wanted and tick or nil)
end
syncDriver()
