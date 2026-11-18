-- Complete native equipment details in the margins; no copied or shortened stats.
-- Tooltip data, scripts, owners, comparison routing and controller bindings stay native.
local driver=CreateFrame('Frame')
local records,backings={},{}
local VERSION='3.7.153'
local roots={InspectFrame=true,CharacterFrame=true,DressUpFrame=true,MerchantFrame=true,LootFrame=true}
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function shown(f)return f and f:IsShown()end
local function kit()
 return ControllerForever and ControllerForever.Kit
end
local function tooltipShown(tip)
 if not shown(tip) or tip:IsForbidden() then return false end
 local k=kit()
 local fade=k and k.fades and k.fades[tip]
 if fade and fade.on then return false end
 local alpha=tip.GetEffectiveAlpha and tip:GetEffectiveAlpha() or 1
 return public(alpha) and alpha>.01
end
local function controllerBags()
 local k=kit()
 return k and k.live and k.live.bags
end
local function rootOf(owner)
 for i=1,16 do
  if not owner or (owner.IsForbidden and owner:IsForbidden()) then return end
  if roots[owner:GetName() or ''] then return owner end
  owner=owner:GetParent()
 end
end
local function ours(tip,r)
 local p,relative,rp,x,y=tip:GetPoint(1)
 return tip:GetNumPoints()==1 and p==r.point and relative==UIParent and rp==r.point and x==r.x and y==r.y
end
local function release(tip)
 local r=records[tip]
 if backings[tip] then backings[tip]:Hide()end
 if r and ours(tip,r) then
  if tip.SetAnchorType and r.anchor then tip:SetAnchorType(r.anchor)end
  tip:ClearAllPoints();for _,p in ipairs(r.points)do tip:SetPoint(unpack(p))end
 end
 records[tip]=nil
end
local function releaseAll()
 for tip in pairs(records)do release(tip)end
end
local function fits(tip,root,side)
 if tip:IsForbidden() then return false end
 local w,h=tip:GetSize()
 local ratio=tip:GetEffectiveScale()/UIParent:GetEffectiveScale()
 local boundary=side=='right' and root:GetRight() or root:GetLeft()
 local rootRatio=root:GetEffectiveScale()/UIParent:GetEffectiveScale()
 local bottom=UIParent:GetHeight()-190
 if side=='right' and shown(ForeverHandheldFocus) then bottom=math.min(bottom,535)end
 if not public(w) or not public(h) or not public(boundary) or not boundary or
  ratio~=1 or w<=0 or h<=0 or h>bottom-330 then return false end
 if side=='right' then return UIParent:GetWidth()-19-w>=boundary*rootRatio+12 end
 return 20+w<=boundary*rootRatio-12
end
local function merchantFocused(root)
 local nav=SmartNavigation
 local bags=controllerBags()
 return nav and nav.GetActiveFrame and nav:GetActiveFrame()==root and
  not (bags and bags.open and bags.away~='visit') and
  not (ForeverHandheldComms and ForeverHandheldComms.active)
end
local function pixels(frame,edge)
 local value=frame[edge](frame)
 local scale=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
 if public(value) and type(value)=='number' and public(scale) then return value*scale end
end
local function lootFocused(root)
 local nav=SmartNavigation
 return InputUtil and InputUtil.IsGamepadUIEnabled() and nav and nav.GetActiveFrame and nav:GetActiveFrame()==root and
  not root.isInEditMode and not (ForeverHandheldComms and ForeverHandheldComms.active)
end
local function placeLoot(root)
 if InCombatLockdown() or not InputUtil or not InputUtil.IsGamepadUIEnabled() or
    root:IsForbidden() or root:IsProtected() or not root:IsShown() or root.isInEditMode or
    root.acquiredFromItem or IsInGroup() then return end
 local screen=UIParent:GetHeight()
 local top=screen-231
 local guide=_G.RXPFrame
 if shown(guide) then
  local bottom=pixels(guide,'GetBottom')
  if bottom then top=math.min(top,bottom-36)end
 end
 local ratio=root:GetEffectiveScale()/UIParent:GetEffectiveScale()
 local width,height=root:GetSize()
 -- Leave room for the native footer and the action dock. Oversize and
 -- grouped windows keep the game's layout, including the raid/party rail.
 if not public(ratio) or not public(width) or not public(height) or ratio<=0 or
    width<=0 or height<=0 or width*ratio>290 or top-height*ratio<198 then return end
 root:ClearAllPoints()
 root:SetPoint('TOPLEFT',UIParent,'TOPLEFT',20/ratio,(top-screen)/ratio)
end
local function fitsInColumn(tip,x,y,left,bottom)
 if tip:IsForbidden() or tip:GetEffectiveScale()~=UIParent:GetEffectiveScale() then return false end
 local w,h=tip:GetSize()
 return public(w) and public(h) and w>0 and h>0 and
  UIParent:GetWidth()+x-w>=left and UIParent:GetHeight()+y-h>=bottom
end
local function lootComparisonLayout(tip,root,compare)
 if not lootFocused(root) or IsInGroup() or root.acquiredFromItem then return end
 local width,height=UIParent:GetSize()
 local edge=pixels(root,'GetRight')
 if not edge or edge>310 then return end
 local left,bottom=math.max(edge+12,width*.625),190
 if shown(ForeverHandheldFocus) then bottom=math.max(bottom,height-535)end
 local x,y=-19,-330
 if not fitsInColumn(tip,x,y,left,bottom) then return end
 -- Reserve space above the equipped comparison for its native title.
 local otherY=y-math.ceil(tip:GetHeight())-28
 if fitsInColumn(compare,x,otherY,left,bottom) then return x,y,x,otherY,left,bottom end
 local otherX=x-math.ceil(tip:GetWidth())-12
 if fitsInColumn(compare,otherX,y,left,bottom) then return x,y,otherX,y,left,bottom end
end
local function merchantLayout(tip,root,compare)
 if not merchantFocused(root) then return end
 local bags=controllerBags()
 local details=bags and bags.away=='visit' and bags.zones and bags.zones.detail
 local screenH=UIParent:GetHeight()
 local top,bottom=screenH-330,190
 if details and details:IsVisible() then
  top=pixels(details,'GetTop') or top
  bottom=(pixels(details,'GetBottom') or bottom)+8
 end
 local left=pixels(root,'GetRight')
 if not left then return end
 left=left+16
 local x,y=-22,math.floor(top-screenH)
 if not fitsInColumn(tip,x,y,left,bottom) then return end
 local otherX
 if compare then
  local width=tip:GetWidth()
  if not public(width) then return end
  otherX=x-math.ceil(width)-12
  if not fitsInColumn(compare,otherX,y,left,bottom) then return end
 end
 return x,y,otherX,left,bottom
end
local function dock(tip,owner,point,x,y,columnLeft,columnBottom)
 local r=records[tip]
 if not r or r.owner~=owner or (not ours(tip,r) and tip.GetAnchorType and tip:GetAnchorType()~='ANCHOR_NONE') then
  local points={};for i=1,tip:GetNumPoints()do points[#points+1]={tip:GetPoint(i)}end
  r={owner=owner,points=points,anchor=tip.GetAnchorType and tip:GetAnchorType()};records[tip]=r
 end
 r.point,r.x,r.y,r.columnLeft,r.columnBottom=point,x,y,columnLeft,columnBottom
 -- Release the engine's owner-relative anchor before applying explicit points.
 if tip.SetAnchorType and tip:GetAnchorType()~='ANCHOR_NONE' then tip:SetAnchorType('ANCHOR_NONE')end
 if not ours(tip,r) then tip:ClearAllPoints();tip:SetPoint(point,UIParent,point,x,y)end
 local bg=backings[tip]
 if not bg then
  bg=CreateFrame('Frame',nil,UIParent,'BackdropTemplate');backings[tip]=bg;bg:EnableMouse(false)
  bg:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
  bg:SetBackdropColor(.025,.03,.025,1);bg:SetBackdropBorderColor(.68,.56,.36,1)
  bg:SetPoint('TOPLEFT',tip,'TOPLEFT',-1,1);bg:SetPoint('BOTTOMRIGHT',tip,'BOTTOMRIGHT',1,-1)
 end
 local strata,level=tip:GetFrameStrata(),math.max(0,tip:GetFrameLevel()-1)
 if bg:GetFrameStrata()~=strata then bg:SetFrameStrata(strata)end
 if bg:GetFrameLevel()~=level then bg:SetFrameLevel(level)end
 if not bg:IsShown() then bg:Show()end
end
local function update()
 local tip=GameTooltip
 if not tip or tip:IsForbidden() then return end
 if InCombatLockdown() then
  for t,bg in pairs(backings)do bg:SetShown(records[t]~=nil and tooltipShown(t))end
  return
 end
 local owner=tip:GetOwner()
 local root=owner and rootOf(owner)
 local loot=root and root==_G.LootFrame
 local item=tooltipShown(tip) and ((loot and owner.GetSlotIndex~=nil) or tip:IsTooltipType(Enum.TooltipDataType.Item))
 if not public(item) or not item or not root or not root:IsShown() then releaseAll();return end
 if loot and not lootFocused(root) then releaseAll();return end
 local compare
 for _,t in pairs({ShoppingTooltip1,ShoppingTooltip2,ItemRefShoppingTooltip1,ItemRefShoppingTooltip2})do
  if tooltipShown(t) then if compare then releaseAll();return end;compare=t end
 end
 -- Oversized/multiple comparisons retain the full original view. Never shrink
 -- fonts, clip stats, overlap the main panel or cover the action dock.
 local merchant=root==MerchantFrame
 local x,y,otherX,otherY,left,bottom
 if merchant then
  x,y,otherX,left,bottom=merchantLayout(tip,root,compare)
  if not x then releaseAll();return end
 elseif loot and compare then
  x,y,otherX,otherY,left,bottom=lootComparisonLayout(tip,root,compare)
  if not x then releaseAll();return end
 elseif not fits(tip,root,'right') or (compare and not fits(compare,root,'left')) then releaseAll();return end
 for t in pairs(records)do if t~=tip and t~=compare then release(t)end end
 dock(tip,owner,'TOPRIGHT',x or -19,y or -330,left,bottom)
 if compare then
  if otherX then dock(compare,owner,'TOPRIGHT',otherX,otherY or y,left,bottom)
  else dock(compare,owner,'TOPLEFT',20,-330)end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 local w,h=tip:GetSize()
 ForeverHandheldDB.itemDetails={version=VERSION,owner=owner:GetName(),width=w,height=h,comparison=compare~=nil,at=GetTime(),merchant=merchant,loot=loot}
end
-- Native Inspect renews its owner-relative tooltip each render. Reapply only
-- an already validated placement after that owner change; never replace the
-- native owner, item population, controller callback or comparison function.
local function keepAnchor(tip,owner)
 local r=records[tip]
 if not r or r.owner~=owner or InCombatLockdown() or tip:IsForbidden() then return end
 local root=rootOf(owner)
 if not root or not root:IsShown() then return end
 if root==_G.LootFrame and not lootFocused(root) then return end
 local side=r.point=='TOPRIGHT' and 'right' or 'left'
 if r.columnLeft then
  if root==MerchantFrame and not merchantFocused(root) then return end
  if root==_G.LootFrame and (IsInGroup() or root.acquiredFromItem) then return end
  if not fitsInColumn(tip,r.x,r.y,r.columnLeft,r.columnBottom) then return end
 elseif not fits(tip,root,side) then return end
 if tip:GetAnchorType()~='ANCHOR_NONE' then tip:SetAnchorType('ANCHOR_NONE')end
 if not ours(tip,r) then tip:ClearAllPoints();tip:SetPoint(r.point,UIParent,r.point,r.x,r.y)end
end
if GameTooltip and hooksecurefunc then
 hooksecurefunc(GameTooltip,'SetOwner',keepAnchor)
end
if C_TooltipComparison and C_TooltipComparison.CompareItem and hooksecurefunc then
 hooksecurefunc(C_TooltipComparison,'CompareItem',function(_,tip)
  if tip~=GameTooltip then return end
  local owner=tip:GetOwner()
  keepAnchor(tip,owner)
  for t,r in pairs(records)do if t~=tip and r.owner==owner and shown(t) then keepAnchor(t,owner)end end
 end)
end
driver:RegisterEvent('PLAYER_LOGIN')
driver:SetScript('OnEvent',function()
 local loot=_G.LootFrame
 if loot and loot.Open and hooksecurefunc then hooksecurefunc(loot,'Open',placeLoot)end
 driver:UnregisterEvent('PLAYER_LOGIN')
end)
local elapsed=0
driver:SetScript('OnUpdate',function(_,dt)
 for tip,bg in pairs(backings)do if bg:IsShown() and not tooltipShown(tip) then bg:Hide()end end
 elapsed=elapsed+dt;if elapsed<.1 then return end;elapsed=0
 local ok,why=pcall(update)
 if not ok then
  for _,bg in pairs(backings)do bg:Hide()end
  ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.itemDetailError=tostring(why)
 end
end)
