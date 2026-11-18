-- Readable native help in Settings, Professions and Collections. Preserve owner, content, anchors and input.
local driver=CreateFrame('Frame')
local record,elapsed=nil,0
local covered
local fills=setmetatable({},{__mode='k'})
local body={.025,.030,.025,.98}
local border={.68,.56,.36,1}
local pieces={'Center','TopLeftCorner','TopRightCorner','BottomLeftCorner','BottomRightCorner','TopEdge','BottomEdge','LeftEdge','RightEdge'}
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function safe(f)return f and not (f.IsForbidden and f:IsForbidden()) and not (f.IsProtected and f:IsProtected())end
local function rootOf(owner)
 local protected=false
 for _=1,20 do
  if not owner or (owner.IsForbidden and owner:IsForbidden()) then return end
  protected=protected or (owner.IsProtected and owner:IsProtected())
  -- The profession book uses secure spell buttons. Only inspect their ancestry;
  -- the separate, ordinary tooltip is the only frame this module paints.
  if owner==_G.ProfessionsFrame or owner==_G.CollectionsJournal or owner==_G.SocialUIFrame or owner==_G.AddFriendFrame then return owner end
  if owner==_G.SettingsPanel or owner==_G.CooldownViewerSettings then
   if not protected then return owner end
   return
  end
  local parent=owner.GetParent and owner:GetParent()
  -- Anonymous native menus expose their owner through this public API.
  owner=owner.GetOwnerRegion and owner:GetOwnerRegion() or parent
 end
end
local function colorOf(t)
 local values={t:GetVertexColor()}
 for i=1,4 do if not public(values[i]) or type(values[i])~='number' then return end end
 return values
end
local function same(a,b)
 if not a or not b then return false end
 for i=1,4 do if math.abs(a[i]-b[i])>.001 then return false end end
 return true
end
local function paint(r,root)
 if root==_G.SocialUIFrame and r.tip.CreateTexture then
  local fill=fills[r.tip]
  if not fill then
   fill=r.tip:CreateTexture(nil,'BACKGROUND',nil,-8)
   fill:SetAllPoints(r.tip);fill:SetColorTexture(unpack(body));fills[r.tip]=fill
  end
  if not fill:IsShown() then fill:Show()end;r.fill=fill
 end
 local slice=r.tip.NineSlice
 if not safe(slice) then return end
 r.colors=r.colors or {}
 for _,name in ipairs(pieces)do
  local t=slice[name]
  if safe(t) and t.GetVertexColor and t.SetVertexColor then
   local current=colorOf(t);local target=name=='Center' and body or border
   if current then
    if not r.colors[t] then r.colors[t]={before=current,applied=target}end
    if not same(current,target) then t:SetVertexColor(unpack(target))end
   end
  end
 end
end
local function release()
 if not record then return end
 local r=record;record=nil
 if r.fill then r.fill:Hide()end
 if not safe(r.tip) then return end
 for t,c in pairs(r.colors or {})do
  if safe(t) and same(colorOf(t),c.applied) then t:SetVertexColor(unpack(c.before))end
 end
 if math.abs(r.tip:GetScale()-r.applied)<.001 then r.tip:SetScale(r.scale)end
 if r.tip:IsClampedToScreen()==true and not r.clamped then r.tip:SetClampedToScreen(false)end
end
local function uncover()
 if not covered then return end
 local c=covered;covered=nil
 if safe(c.tip) and c.tip:GetAlpha()==0 then c.tip:SetAlpha(c.alpha)end
end
local function update()
 local settingsTip=_G.SettingsTooltip
 local tip=safe(settingsTip) and settingsTip:IsShown() and settingsTip or _G.GameTooltip
 if not safe(tip) or not tip:IsShown() then uncover();release();return end
 local owner=tip:GetOwner();local root=rootOf(owner)
 if not root or not root:IsShown() then uncover();release();return end
 if InCombatLockdown() then return end
 local modal=_G.AddFriendFrame
 local occluded=root==_G.SocialUIFrame and modal and modal:IsShown()
 if covered and (covered.tip~=tip or covered.owner~=owner or not occluded)then uncover()end
 if occluded then
  local alpha=tip:GetAlpha()
  if public(alpha) and type(alpha)=='number' then
   if not covered then covered={tip=tip,owner=owner,alpha=alpha}end
   if alpha~=0 then tip:SetAlpha(0)end
  end
 end
 if record and (record.tip~=tip or record.owner~=owner) then release()end
 local width,height=tip:GetWidth(),tip:GetHeight()
 local scale=record and record.scale or tip:GetScale()
 local effective=tip:GetEffectiveScale()/tip:GetScale()/UIParent:GetEffectiveScale()
 if not public(width) or not public(height) or not public(scale) or not public(effective) or
  type(width)~='number' or type(height)~='number' or width<=0 or height<=0 or type(scale)~='number' or scale<=0 then return end
 local smallest=16
 for _,r in ipairs({tip:GetRegions()})do
  if r.IsObjectType and r:IsObjectType('FontString') and r:IsShown() then
   local text=r:GetText();local _,size=r:GetFont()
   if public(text) and type(text)=='string' and text~='' and public(size) and type(size)=='number' and size>0 then smallest=math.min(smallest,size)end
  end
 end
 local target=math.min(scale*math.min(1.5,16/smallest),(UIParent:GetWidth()-32)/(width*effective),(UIParent:GetHeight()-40)/(height*effective))
 -- Oversized native help keeps its original view; never shrink it to fit.
 if target<scale or math.abs(target-scale)<.01 then target=scale end
 if not record then record={tip=tip,owner=owner,scale=scale,clamped=tip:IsClampedToScreen(),applied=scale}end
 paint(record,root)
 if target>scale and not tip:IsClampedToScreen() then tip:SetClampedToScreen(true)end
 if math.abs(tip:GetScale()-target)>.001 then tip:SetScale(target)end
 record.applied=target
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.settingsHelp={version='3.7.67',seen=GetTime(),context=root==_G.ProfessionsFrame and 'professions' or (root==_G.CollectionsJournal and 'collections' or (root==_G.SocialUIFrame and 'social' or (root==_G.AddFriendFrame and 'friend-dialog' or 'settings'))),scale=target,font=smallest*target/scale,width=width*target*effective,height=height*target*effective,palette=record.colors and 'charcoal-gold' or nil}
end
local hooked={}
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.1 then return end;elapsed=0
 local ok,err=pcall(function()
  for _,name in ipairs({'SettingsTooltip','GameTooltip'})do
   local tip=_G[name]
   if tip and not hooked[tip] and hooksecurefunc then
    hooksecurefunc(tip,'SetOwner',function(_,owner)
     if covered and covered.tip==tip and covered.owner~=owner then uncover()end
     if record and record.tip==tip and record.owner~=owner then release()end
    end)
    -- Apply before a newly shown tooltip can flash over the modal.
    hooksecurefunc(tip,'Show',function()
     local ok,err=pcall(update)
     if not ok then uncover();release();ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.settingsHelpError=tostring(err)end
    end)
    hooked[tip]=true
   end
  end
  update()
 end)
 if not ok then
  uncover();release();ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.settingsHelpError=tostring(err)
 end
end)
