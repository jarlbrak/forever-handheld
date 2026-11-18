-- Professions workbench: native widgets, native navigation, new visual layout.
-- No action handlers, focus ownership, protected state, or native methods replaced.
local VERSION='3.7.73'
local ui,elapsed
local gold={.72,.60,.39,1}
local function rect(parent,x,y,w,h,color)
 local t=parent:CreateTexture(nil,'BACKGROUND');t:SetPoint('TOPLEFT',x,-y);t:SetSize(w,h);t:SetColorTexture(unpack(color));return t
end
local function label(parent,text,x,y,size,color)
 local f=parent:CreateFontString(nil,'OVERLAY');f:SetFont(STANDARD_TEXT_FONT,size,'');f:SetPoint('TOPLEFT',x,-y);f:SetTextColor(unpack(color or gold));f:SetText(text);return f
end
local function anchor(f,relative,x,y,w,h)
 if not f then return end
 local p,r,rp,px,py=f:GetPoint(1)
 if f:GetNumPoints()~=1 or p~='TOPLEFT' or r~=relative or rp~='TOPLEFT' or px~=x or py~=-y then
  f:ClearAllPoints();f:SetPoint('TOPLEFT',relative,'TOPLEFT',x,-y)
 end
 if w and math.abs(f:GetWidth()-w)>.1 then f:SetWidth(w) end
 if h and math.abs(f:GetHeight()-h)>.1 then f:SetHeight(h) end
end
local function clearBackdrops(frame,depth)
 if not frame or depth>4 or frame.ForeverHandheldOwnedPresentation then return end
 for _,r in ipairs({frame:GetRegions()}) do
  if r:IsObjectType('Texture') and r:GetWidth()>150 and r:GetHeight()>100 then r:SetColorTexture(0,0,0,0);r:SetAlpha(0) end
 end
 for _,c in ipairs({frame:GetChildren()}) do
  if c~=frame.RankBar and c~=frame.StatusBar then clearBackdrops(c,depth+1) end
 end
end
local function make(root)
 local f=CreateFrame('Frame','ForeverHandheldWorkbench',root)
 f:SetAllPoints(root);f:SetFrameLevel(root:GetFrameLevel()+1);f:EnableMouse(false)
 rect(f,2,2,996,596,{.025,.030,.029,1})
 rect(f,2,2,996,72,{.055,.062,.057,1})
 rect(f,16,90,158,458,{.043,.049,.045,1})
 local cards={rect(f,190,90,346,458,{.035,.041,.038,1}),rect(f,550,90,432,458,{.043,.049,.045,1})}
 local overview={}
 for i=0,1 do overview[#overview+1]=rect(f,190,90+i*130,792,120,{.043,.049,.045,1}) end
 for i=0,2 do overview[#overview+1]=rect(f,190+i*264,350,256,198,{.043,.049,.045,1}) end
 rect(f,16,73,966,1,gold);rect(f,16,549,966,1,gold)
 rect(f,16,90,3,458,gold)
 label(f,'F O R E V E R   /   W O R K S H O P',24,15,11)
 local title=label(f,'Professions',24,33,27,{.94,.9,.8,1})
 label(f,'DISCIPLINES',30,104,11)
 local catalog=label(f,'RECIPE CATALOG',205,104,11)
 local detail=label(f,'CRAFTING',566,104,11)
 local rail={}
 local tabs={root.ProfessionsOverviewTab}
 for i=1,7 do tabs[#tabs+1]=root['Professions'..i..'Tab'] end
 for _,tab in ipairs(tabs) do
  local l=label(f,'',78,0,14,{.87,.85,.77,1});l:SetWidth(110);l:SetHeight(44);l:SetWordWrap(true);l:SetMaxLines(2);l:SetJustifyH('LEFT');l:SetJustifyV('MIDDLE');rail[tab]=l
 end
 return {cards=cards,overview=overview,frame=f,title=title,catalog=catalog,detail=detail,tabs=tabs,rail=rail}
end

local function layout()
 local root=ProfessionsFrame
 if not root or not root:IsShown() then
  if ForeverHandheldDock then ForeverHandheldDock:SetAlpha(ForeverHandheldPanels and ForeverHandheldPanels.dockCovered and 0 or 1) end
  return
 end
 if InCombatLockdown() then return end
 if not ui then ui=make(root) end
 -- Keep the native panel parent and all native controls. Only geometry changes.
 if math.abs(root:GetWidth()-1000)>.1 then root:SetWidth(1000) end
 if math.abs(root:GetHeight()-600)>.1 then root:SetHeight(600) end
 local p,r,rp,x,y=root:GetPoint(1)
 if p~='CENTER' or r~=UIParent or rp~='CENTER' or x~=0 or y~=12 then
  root:ClearAllPoints();root:SetPoint('CENTER',UIParent,'CENTER',0,12)
 end
 if root.TitleContainer then root.TitleContainer:SetAlpha(0) end
 if root.PortraitContainer then root.PortraitContainer:SetAlpha(0) end
 if root.portrait then root.portrait:SetAlpha(0) end
 if root.Portrait then root.Portrait:SetAlpha(0) end
 if root.CloseButton then anchor(root.CloseButton,root,960,12) end
 local page=root.CraftingPage
 local craft=page and page:IsShown()
 clearBackdrops(page,0);clearBackdrops(root.BookPage,0)
 ui.catalog:SetAlpha(craft and 1 or 0);ui.detail:SetAlpha(craft and 1 or 0)
 for _,t in ipairs(ui.cards) do t:SetAlpha(craft and 1 or 0) end
 for _,t in ipairs(ui.overview) do t:SetAlpha(craft and 0 or 1) end
 local name=root.TitleContainer and root.TitleContainer.TitleText and root.TitleContainer.TitleText:GetText()
 ui.title:SetText(name and name~='' and name or 'Professions')
 local n=0
 for _,tab in ipairs(ui.tabs) do
  local l=ui.rail[tab]
  if tab:IsShown() then
   anchor(tab,root,27,134+n*65,44,44)
   l:ClearAllPoints();l:SetPoint('LEFT',tab,'RIGHT',6,0)
   l:SetText(tab.tooltipText or 'Overview');l:SetAlpha(1)
   n=n+1
  else l:SetAlpha(0) end
 end
 if craft then
  anchor(page.RecipeList,page,190,126,346,415)
  anchor(page.SchematicForm,page,550,132,432,408)
  page.RankBar:SetScale(.8);anchor(page.RankBar,page,712.5,48.75)
  anchor(page.CreateAllButton,page,566,558,120,22)
  anchor(page.CreateButton,page,701,558,120,22)
  anchor(page.CreateMultipleInputBox,page,848,558)
  if page.GamepadCreateMultiple then anchor(page.GamepadCreateMultiple,page,833,556) end
  if page.TrackRecipeCheckbox then anchor(page.TrackRecipeCheckbox,page,803,507) end
 else
  if root.BookPage then
   anchor(root.BookPage,root,194,100,786,440)
   local c=root.BookPage.ProfessionsContentFrame
   if c then
    anchor(c.PrimaryProfession1,c,0,0,770,120)
    anchor(c.PrimaryProfession2,c,0,130,770,120)
    if c.PrimaryProfession1.ProfessionName then c.PrimaryProfession1.ProfessionName:SetAlpha(0) end
    if c.PrimaryProfession2.ProfessionName then c.PrimaryProfession2.ProfessionName:SetAlpha(0) end
    for i=1,3 do anchor(c['SecondaryProfession'..i],c,(i-1)*256,250,250,185) end
   end
  end
 end
 if ForeverHandheldDock then ForeverHandheldDock:SetAlpha(0) end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.workbench={version=VERSION,applied=GetTime(),crafting=craft,width=root:GetWidth(),height=root:GetHeight()}
end
local driver=CreateFrame('Frame')
elapsed=0
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 local ok,err=pcall(layout)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.workbenchError=tostring(err) end
end)
