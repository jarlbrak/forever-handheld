-- A wide, shorter workspace lets the native scrolling lists stay legible on
-- an 800px handheld display. Native rows, binding listeners and focus own input.
local driver=CreateFrame('Frame')
local elapsed=0
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function available(f)
 return f and not (f.IsForbidden and f:IsForbidden()) and f:IsShown()
end
local function readable(region,size)
 if not region or not region.GetFont then return end
 local face,current,flags=region:GetFont()
 if public(face) and public(current) and type(face)=='string' and type(current)=='number' and current<size then
  region:SetFont(face,size,flags)
 end

end
local function paint(frame,depth,budget)
 if depth>8 or budget.n>=240 or not available(frame) then return end
 budget.n=budget.n+1
 -- A protected preview can make the containing Settings panel protected.
 -- Traverse that container, but paint only unprotected rows.
 local protected=frame.IsProtected and frame:IsProtected()
 if not protected then
  for _,region in ipairs({frame:GetRegions()})do
   if region.IsObjectType and region:IsObjectType('FontString') then readable(region,16)end
  end
 end
 -- Native rows are 26px high with 9px list spacing. A centered 32px text
 -- region fits two 16px lines with 3px remaining between neighboring labels.
 -- Keep the native row extent, horizontal anchors, tooltip and focus region.
 local label=frame.Text
 if not protected and frame.GetSetting and label and label.CanWordWrap and label.GetMaxLines and label.IsShown and label:IsShown() then
  local h=frame:GetHeight()
  local _,size=label:GetFont()
  if public(h) and public(size) and type(h)=='number' and h>=26 and type(size)=='number' and size<=16.01 then
   if not label:CanWordWrap() then label:SetWordWrap(true)end
   if label:GetMaxLines()~=2 then label:SetMaxLines(2)end
   if math.abs(label:GetHeight()-32)>.5 then label:SetHeight(32)end
  end
 end
 -- Native binding labels reserve only 170px although the list can stretch.
 -- Button1 is centered at -80 and Label is inset 37 in the native template.
 if not protected and frame.Label and frame.Button1 and frame.Button2 then
  local width=frame:GetWidth()
  if public(width) and type(width)=='number' then
   local target=math.max(170,width/2-125)
   if math.abs(frame.Label:GetWidth()-target)>.5 then frame.Label:SetWidth(target)end
  end
 end
 -- Native standalone actions retain a fixed 200px button after larger type.
 -- Resize only that documented row type; binding/dropdown geometry is separate.
 local button=frame.Button
 if not protected and frame.EvaluateName and available(button) and not (button.IsProtected and button:IsProtected()) then
  local label=button.GetFontString and button:GetFontString()
  readable(label,16)
  local textWidth=label and label.GetStringWidth and label:GetStringWidth()
  local width=frame:GetWidth()
  if public(textWidth) and public(width) and type(textWidth)=='number' and type(width)=='number' then
   local p,relative,rp=button:GetPoint(1)
   local room=(p=='LEFT' and relative==frame and rp=='CENTER') and width/2+24 or width-48
   local target=math.min(math.max(200,math.ceil(textWidth)+32),math.max(200,room),460)
   if math.abs(button:GetWidth()-target)>.5 then button:SetWidth(target)end
  end
 end
 local control=frame.Control
 local dropdown=control and control.Dropdown
 if not protected and available(control) and available(dropdown) and
  not (control.IsProtected and control:IsProtected()) and not (dropdown.IsProtected and dropdown:IsProtected()) then
  -- Native dropdowns are centered in a 223px container around a 220px
  -- selector. Grow both together so the left edge, steppers and focus stay put.
  local width=frame:GetWidth()
  local p,relative,rp,x=control:GetPoint(1)
  if public(width) and type(width)=='number' and p=='LEFT' and relative==frame and rp=='CENTER' and public(x) and type(x)=='number' then
   local target=math.max(220,math.min(360,width/2-x-48))
   if math.abs(dropdown:GetWidth()-target)>.5 then dropdown:SetWidth(target)end
   if math.abs(control:GetWidth()-(target+3))>.5 then control:SetWidth(target+3)end
  end
  -- Locale names are atlas images, not font strings. Preserve their language,
  -- aspect ratio and native visibility. The atlas includes vertical padding;
  -- a 32px image fits the 38px native selector and makes its glyphs legible.
  local language=dropdown.Language
  if language and language.GetSize and language.IsShown and language:IsShown() then
   local w,h=language:GetSize()
   if public(w) and public(h) and type(w)=='number' and type(h)=='number' and h>0 and h<32 then
    local factor=math.min(32/h,(dropdown:GetWidth()-24)/math.max(w,1))
    if factor>1.01 then language:SetSize(w*factor,h*factor)end
   end
  end
 end
 for _,child in ipairs({frame:GetChildren()})do paint(child,depth+1,budget)end
end
local function update()
 local root=_G.SettingsPanel
 if InCombatLockdown() or not available(root) then return end
 local protected=root:IsProtected()
 -- This fixed-size decorative atlas does not follow native resizing and
 -- otherwise protrudes below the shorter workspace. Windows.lua owns its rim.
 if not protected then
  for _,region in ipairs({root:GetRegions()})do
   if region.GetAtlas and region:GetAtlas()=='Options_InnerFrame' and region:GetAlpha()~=0 then region:SetAlpha(0)end
  end
 end
 -- Panels.lua performs viewport fitting/centering for this whole workspace.
 if not protected and (root:GetWidth()~=1120 or root:GetHeight()~=620) then root:SetSize(1120,620)end
 local categories=root.CategoryList
 if categories and not (categories.IsProtected and categories:IsProtected()) and categories:GetWidth()~=240 then categories:SetWidth(240)end
 local list=root.Container and root.Container.SettingsList
 local budget={n=0}
 paint(categories,0,budget)
 paint(list,0,budget)
 for _,key in ipairs({'GameTab','AddOnsTab','CloseButton','ApplyButton'})do
  local button=root[key]
  if button and not (button.IsProtected and button:IsProtected()) then readable(button.Text or (button.GetFontString and button:GetFontString()),16)end
 end
 if list and list.Header and not (list.Header.IsProtected and list.Header:IsProtected()) then
  readable(list.Header.Title,22)
  readable(list.Header.DefaultsButton and list.Header.DefaultsButton.Text,16)
 end
 if root.SearchBox and not (root.SearchBox.IsProtected and root.SearchBox:IsProtected()) then readable(root.SearchBox,16)end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.nativeSettings={version='3.7.57',seen=GetTime(),visited=budget.n,protectedContainer=not not protected}
end
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 local ok,err=pcall(update)
 if not ok then
  ForeverHandheldDB=ForeverHandheldDB or {}
  ForeverHandheldDB.nativeSettingsError=tostring(err)
  driver:SetScript('OnUpdate',nil)
 end
end)
