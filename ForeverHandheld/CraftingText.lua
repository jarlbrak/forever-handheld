-- Readable recipe catalog and crafting controls. Native list geometry,
-- selection, search, navigation and crafting callbacks continue to own input.
local driver=CreateFrame('Frame')
local elapsed=0
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function safe(f)return f and not (f.IsForbidden and f:IsForbidden()) and not (f.IsProtected and f:IsProtected())end
local function available(f)return f and not (f.IsForbidden and f:IsForbidden())end
local function readable(r,minimum)
 minimum=minimum or 16
 if not safe(r) or not r.GetFont then return end
 local face,size,flags=r:GetFont()
 if not public(face) or not public(size) or not public(flags) or type(face)~='string' or type(size)~='number' then return end
 if size<minimum then r:SetFont(face,minimum,flags)end
 -- Some native list text regions reserve only 12-13px inside 20px rows.
 -- Enlarge that text region only; preserve dynamic/multiline heights and rows.
 if r.IsObjectType and r:IsObjectType('FontString') and r.GetHeight then
  local h=r:GetHeight()
  if public(h) and type(h)=='number' and h>0 and h<20 then r:SetHeight(20)end
 end
end
local function reflow(r,width)
 if not safe(r) or not r:IsShown() or not r.GetStringHeight then return end
 if width then
  local old=r:GetWidth()
  if public(old) and type(old)=='number' and math.abs(old-width)>.5 then r:SetWidth(width)end
 end
 local needed,current=r:GetStringHeight(),r:GetHeight()
 if public(needed) and public(current) and type(needed)=='number' and type(current)=='number' and needed>0 and math.abs(current-needed-1)>.5 then r:SetHeight(needed+1)end
end
local function recipeWidth(f)
 local label,count,skill=f.Label,f.Count,f.SkillUps
 if not safe(f) or not safe(label) or not safe(count) or not safe(skill) or not label.GetUnboundedStringWidth then return end
 local w,needed,skillWidth=f:GetWidth(),label:GetUnboundedStringWidth(),skill:GetWidth()
 local countWidth=count:IsShown() and count:GetStringWidth() or 0
 local locked=f.LockedIcon
 local lockWidth=available(locked) and locked:IsShown() and locked:GetWidth() or 0
 if not public(w) or not public(needed) or not public(skillWidth) or not public(countWidth) or not public(lockWidth) then return end
 if type(w)~='number' or type(needed)~='number' or type(skillWidth)~='number' or type(countWidth)~='number' or type(lockWidth)~='number' then return end
 -- Native Init measures this label before the larger font is applied. Remeasure
 -- only its text region, reserving the existing count, skill and lock icons.
 local target=math.min(needed,math.max(1,w-skillWidth-countWidth-lockWidth-10))
 local current=label:GetWidth()
 if public(current) and type(current)=='number' and math.abs(current-target)>.5 then label:SetWidth(target)end
end
local function walk(f,depth,budget)
 if depth>6 or budget.n>=160 or not available(f) or not f:IsShown() then return end
 budget.n=budget.n+1
 if safe(f) then
  readable(f)
  for _,r in ipairs({f:GetRegions()})do
   if r.IsObjectType and r:IsObjectType('FontString') then readable(r)end
  end
 end
 for _,child in ipairs({f:GetChildren()})do walk(child,depth+1,budget)end
 recipeWidth(f)
 -- Native reagent rows are 50px high with 108px names beside their icons.
 -- Three lines fit the existing row; keep the original item/count and anchors.
 if safe(f) and safe(f.Name) and f.Button and f.Checkbox and f.Name:IsShown() then
  local h=f.Name:GetHeight()
  if public(h) and type(h)=='number' and h<48 then f.Name:SetHeight(48)end
 end
end
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 if InCombatLockdown() then return end
 local root=_G.ProfessionsFrame
 if not available(root) or not root:IsShown() then return end
 local page=root.CraftingPage
 local crafting=available(page) and page:IsShown()
 local book=root.BookPage
 if not crafting and not (available(book) and book:IsShown()) then return end
 local ok,err=pcall(function()
  local budget={n=0}
  if crafting then
  for _,key in ipairs({'RecipeList','CreateButton','CreateAllButton','CreateMultipleInputBox','GamepadCreateMultiple','SchematicForm','RankBar'})do
   walk(page[key],0,budget)
  end
  local form=page.SchematicForm
  if safe(form) and form:IsShown() then
   reflow(form.OutputText,225)
   reflow(form.RequiredTools,250)
   reflow(form.Description,305)
  end
  local rank=page.RankBar and page.RankBar.Rank
  if safe(rank) then readable(rank.Text,20)end
  local prompt=page.GamepadCreateMultiple
  local desc=prompt and prompt.ControlDescText
  local text=desc and desc.FontString
  if safe(desc) and safe(text) and desc:IsShown() then
   -- Native prompt text reserves just 45px. The workbench footer has room for
   -- its complete label beside the unchanged right-stick icon and input owner.
   if desc:GetWidth()~=110 then desc:SetWidth(110)end
   if desc:GetHeight()~=20 then desc:SetHeight(20)end
   if text:GetWidth()~=110 then text:SetWidth(110)end
   if text:GetHeight()~=20 then text:SetHeight(20)end
  end
  else
   walk(book.ProfessionsContentFrame,0,budget)
   if ForeverHandheldPaintProfessionLabels then ForeverHandheldPaintProfessionLabels(book)end
  end
  ForeverHandheldDB=ForeverHandheldDB or {}
  ForeverHandheldDB.craftingText={version='3.7.60',seen=GetTime(),visited=budget.n,mode=crafting and 'recipe' or 'overview'}
 end)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.craftingTextError=tostring(err)end
end)
