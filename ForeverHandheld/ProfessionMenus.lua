-- Fit displayed native menus while preserving descriptions, callbacks, fonts,
-- anchors, selection and the secure controller binding stack.
local driver=CreateFrame('Frame')
local elapsed=0
local saved=setmetatable({},{__mode='k'})
local questChrome,questChromeOwner
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function available(f)return f and not (f.IsForbidden and f:IsForbidden())end
local function safe(f)return available(f) and not (f.IsProtected and f:IsProtected())end
local function number(v)return public(v) and type(v)=='number' and v>0 end
local function within(f,root)
 for _=1,20 do
  if not available(f) then return false end
  if f==root then return true end
  f=f.GetParent and f:GetParent()
 end
 return false
end
local function isChatMenuOwner(owner)
 for _=1,20 do
  if not available(owner) then return false end
  local name=owner.GetName and owner:GetName()
  if public(name) and type(name)=='string' and (
    name:match('^ChatFrame%d+$') or name:match('^ChatFrame%d+Tab$') or
    name:match('^ChatFrame%d+EditBox$') or name:match('^ChatFrame%d+ButtonFrame$')
  ) then return true end
  owner=owner.GetParent and owner:GetParent()
 end
 return false
end
local function menuOf(f)
 for _=1,20 do
  if not available(f) then return end
  if f.GetOwnerRegion and f.EnumerateElementDescriptions then return f end
  f=f.GetParent and f:GetParent()
 end
end
local function restoreRim(r)
 if safe(r.rim) then
  local alpha=r.rim:GetAlpha()
  if public(alpha) and alpha==0 then r.rim:SetAlpha(r.rimAlpha)end
 end
 r.rim,r.rimAlpha=nil,nil
end
local function release(menu)
 local r=saved[menu];saved[menu]=nil
 if questChromeOwner==menu then
  questChrome:Hide();questChrome:ClearAllPoints();questChrome:SetParent(UIParent)
  questChromeOwner=nil
 end
 if r and safe(menu) then
  restoreRim(r)
  for texture,layer in pairs(r.layers or {})do
   local parent=available(texture) and texture.GetParent and texture:GetParent()
   if safe(parent) then
    local current,sub=texture:GetDrawLayer()
    if public(current) and public(sub) and current==layer.applied and sub==layer.sub then texture:SetDrawLayer(layer.before,sub)end
   end
  end
  local current=menu:GetScale()
  if number(current) and math.abs(current-r.applied)<.001 then menu:SetScale(r.before)end
 end
end
local function fontSize(menu)
 local budget=0;local smallest=16
 local function visit(f,depth)
  if depth>6 or budget>=200 or not available(f) or not f:IsShown() then return end
  budget=budget+1
  for _,r in ipairs({f:GetRegions()})do
   if available(r) and r.IsObjectType and r:IsObjectType('FontString') and r:IsShown() then
    local text=r:GetText();local _,size=r:GetFont()
    if public(text) and type(text)=='string' and text~='' and number(size) then smallest=math.min(smallest,size)end
   end
  end
  for _,child in ipairs({f:GetChildren()})do visit(child,depth+1)end
 end
 visit(menu,0);return smallest,budget
end
local function questActionBounds(menu)
 -- The native quest context menu can have zero outer width even after it
 -- lays out its buttons. Measure only the displayed text rows, in menu units.
 local left,top,scale=menu:GetLeft(),menu:GetTop(),menu:GetEffectiveScale()
 if not number(scale) or not public(left) or type(left)~='number' or not public(top) or type(top)~='number' then return end
 local right,highest,lowest=left,-math.huge,math.huge
 for _,row in ipairs({menu:GetChildren()})do
  if available(row) and row:IsShown() then
   for _,label in ipairs({row:GetRegions()})do
    if available(label) and label.IsObjectType and label:IsObjectType('FontString') and label:IsShown() then
     local value=label:GetText()
     local r,t,b,s=row:GetRight(),row:GetTop(),row:GetBottom(),row:GetEffectiveScale()
     if public(value) and type(value)=='string' and value~='' and number(r) and number(t) and number(b) and number(s) then
      local ratio=s/scale
      right=math.max(right,r*ratio);highest=math.max(highest,t*ratio);lowest=math.min(lowest,b*ratio)
     end
    end
   end
  end
 end
 local width=right-left
 if width>0 and width<UIParent:GetWidth()/2 and highest>lowest then
  return {width=math.max(150,math.ceil(width+8)),height=math.ceil(highest-lowest+16),top=highest-top+8}
 end
end
local function showQuestChrome(menu,bounds,width)
 if not questChrome then
  local frame=CreateFrame('Frame','ForeverHandheldQuestMenuBackdrop',UIParent,'BackdropTemplate')
  frame:EnableMouse(false)
  local pixel='Interface\\Buttons\\WHITE8X8'
  frame:SetBackdrop({bgFile=pixel,edgeFile=pixel,edgeSize=1})
  frame:SetBackdropColor(.025,.030,.029,1)
  frame:SetBackdropBorderColor(.72,.60,.39,1)
  -- Native menu frames are pooled. Inherited hiding must also clear our
  -- visibility before the native frame can reopen in another context.
  frame:SetScript('OnHide',function(self)if self:IsShown() then self:Hide()end end)
  questChrome=frame
 end
 if questChromeOwner~=menu or questChrome.top~=bounds.top then
  questChrome:SetParent(menu);questChrome:ClearAllPoints()
  questChrome:SetPoint('TOPLEFT',menu,'TOPLEFT',0,bounds.top)
  questChromeOwner=menu
  questChrome.top=bounds.top
 end
 local level,strata=menu:GetFrameLevel()+1,menu:GetFrameStrata()
 if questChrome:GetFrameStrata()~=strata then questChrome:SetFrameStrata(strata)end
 if questChrome:GetFrameLevel()~=level then questChrome:SetFrameLevel(level)end
 if math.abs(questChrome:GetWidth()-width)>.05 then questChrome:SetWidth(width)end
 if math.abs(questChrome:GetHeight()-bounds.height)>.05 then questChrome:SetHeight(bounds.height)end
 if not questChrome:IsShown() then questChrome:Show()end
end
local function apply(menu,questActions)
 local current=menu:GetScale();local w,h=menu:GetWidth(),menu:GetHeight()
 if not number(current) or not number(h) then return end
 local r=saved[menu]
 local bounds
 if questActions and public(w) and w==0 then
  bounds=r and r.height and math.abs(h-r.height)<.05 and r.bounds or questActionBounds(menu)
  w=bounds and bounds.width
 end
 if not number(w) then return end
 local layers=r and r.layers
 local rim,rimAlpha=r and r.rim,r and r.rimAlpha
 if r and math.abs(current-r.applied)>.001 then saved[menu]=nil;r=nil end
 local base=r and r.before or current
 local effective=menu:GetEffectiveScale()/current/UIParent:GetEffectiveScale()
 if not number(effective) then return end
 local font,visited=fontSize(menu)
 local target=math.min(base*math.min(1.5,16/font),(UIParent:GetWidth()-32)/(w*effective),(UIParent:GetHeight()-40)/(h*effective))
 -- Oversized native menus retain their existing scroll behavior and scale.
 target=math.max(base,target)
 if not r then r={before=base,applied=current,layers=layers,rim=rim,rimAlpha=rimAlpha};saved[menu]=r end
 if bounds then
  local left=menu:GetLeft()
  if number(left) then target=math.min(target,math.max(base,(UIParent:GetWidth()-left*effective*current-8)/(w*effective)))end
 end
 if math.abs(current-target)>.001 then menu:SetScale(target)end
 r.applied=target
 if bounds then
  r.height,r.bounds=h,bounds
  -- The Camelot template's outer focus glow follows the collapsed root.
  -- The native row focus arrow and row highlight are separate regions.
  local rim=menu.FrameGlow
  if not r.rim and safe(rim) and rim.GetAlpha and rim.SetAlpha then
   local alpha=rim:GetAlpha()
   if number(alpha) then r.rim,r.rimAlpha=rim,alpha;rim:SetAlpha(0)end
  end
  local left=menu:GetLeft()
  local visibleWidth=number(left) and math.max(80,(UIParent:GetWidth()-6)/(effective*target)-left) or w
  showQuestChrome(menu,bounds,math.min(w,visibleWidth))
 elseif questChromeOwner==menu then
  questChrome:Hide();restoreRim(r)
 end
 return font*target/base,visited
end
-- Native submenu legends can hit frame-level 10000. Their default ARTWORK
-- background then shares a layer with the native A/B icons. Separate only the
-- legend artwork layers; do not refresh prompted bindings or force icon state.
local function legendLayers(menu)
 local state=saved[menu];if not state then return end
 state.layers=state.layers or setmetatable({},{__mode='k'})
 local visited=0
 local function walk(f,depth)
  if depth>5 or visited>=100 or not safe(f) then return end
  visited=visited+1
  for _,t in ipairs({f:GetRegions()})do
   if safe(t) and t.GetAtlas and t.GetDrawLayer and t.SetDrawLayer then
    local atlas=t:GetAtlas()
    local target=public(atlas) and (atlas=='gamepad-footer-slot-bg' and 'BACKGROUND' or
     (type(atlas)=='string' and atlas:match('^gamepad%-footer%-slot%-frame') and 'BORDER'))
    if target then
     local layer,sub=t:GetDrawLayer()
     if public(layer) and public(sub) and type(layer)=='string' and type(sub)=='number' then
      local prior=state.layers[t]
      if prior and (layer~=prior.applied or sub~=prior.sub) then state.layers[t]=nil;prior=nil end
      if layer~=target then
       state.layers[t]=prior or {before=layer,sub=sub,applied=target}
       t:SetDrawLayer(target,sub)
      end
     end
    end
   end
  end
  for _,child in ipairs({f:GetChildren()})do walk(child,depth+1)end
 end
 walk(menu,0)
end
local function update()
 if InCombatLockdown() then return end
 local context
 local manager=Menu and Menu.GetManager and Menu.GetManager()
 local root=manager and manager.GetOpenMenu and manager:GetOpenMenu()
 if safe(root) and root:IsShown() and root.GetOwnerRegion then
  for _,name in ipairs({'ProfessionsFrame','CollectionsJournal','SocialUIFrame','LFGParentFrame','CommunitiesFrame','CalendarFrame','ChatConfigFrame','WorldMapFrame'})do
   local candidate=_G[name]
   if available(candidate) and candidate:IsShown() and within(root:GetOwnerRegion(),candidate) then context=name;break end
  end
  if not context and isChatMenuOwner(root:GetOwnerRegion()) then context='Chat' end
 end
 if not context then
  for menu in pairs(saved)do release(menu)end
  return
 end
 local selected={[root]=true};local menus={root}
 local parent=root:GetParent()
 -- Native submenus are siblings anchored to a row in their preceding menu.
 -- Discover them through public geometry; no private manager/description state.
 local siblings=available(parent) and {parent:GetChildren()} or {}
 -- Camelot also creates parentless menu frames. Discover the focused menu
 -- through native read-only input APIs, then retain it while its anchors still
 -- connect to this root. Never replace native focus or call a menu responder.
 local focused=SmartNavigation and SmartNavigation.GetCurrentButton and SmartNavigation:GetCurrentButton()
 local focusedMenu=menuOf(focused)
 if focusedMenu then siblings[#siblings+1]=focusedMenu end
 for _,f in ipairs(GetMouseFoci and GetMouseFoci() or {})do
  local menu=menuOf(f);if menu then siblings[#siblings+1]=menu end
 end
 for menu in pairs(saved)do siblings[#siblings+1]=menu end
 for _=1,6 do
  local added=false
  for i=1,math.min(#siblings,256)do
   local candidate=siblings[i]
   if #menus<7 and not selected[candidate] and safe(candidate) and candidate:IsShown() and candidate.GetOwnerRegion and candidate.EnumerateElementDescriptions then
    for point=1,math.min(candidate:GetNumPoints(),4)do
     local _,relative=candidate:GetPoint(point)
     for _,known in ipairs(menus)do
      if within(relative,known) then
       selected[candidate]=true;menus[#menus+1]=candidate;added=true;break
      end
     end
     if selected[candidate] then break end
    end
   end
  end
  if not added then break end
 end
 for menu in pairs(saved)do if not selected[menu] then release(menu)end end
 local count,minimum,visited=0,16,0
 for _,menu in ipairs(menus)do
  local font,n=apply(menu,menu==root and context=='WorldMapFrame')
  if font then legendLayers(menu)end
  if font then count=count+1;minimum=math.min(minimum,font);visited=visited+n end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.professionMenus={version='3.7.111',context=context,seen=GetTime(),count=count,font=minimum,visited=visited}
end
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.1 then return end;elapsed=0
 local ok,err=pcall(update)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.professionMenuError=tostring(err)end
end)
