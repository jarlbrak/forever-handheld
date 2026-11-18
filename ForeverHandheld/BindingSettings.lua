-- Presentation for native click-casting. No bindings, actions, focus or
-- listeners are replaced; the native spell/macro picker owns all interaction.
local driver=CreateFrame('Frame')
local elapsed=0
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function shown(f)return f and not (f.IsForbidden and f:IsForbidden()) and f:IsShown()end
local function protected(f)return f.IsProtected and f:IsProtected()end
local function font(r,size)
 if not r or not r.GetFont then return end
 local face,n,flags=r:GetFont()
 if public(face) and public(n) and type(face)=='string' and type(n)=='number' and n<size then r:SetFont(face,size,flags)end
end
local function walk(f,depth,budget)
 if depth>7 or budget.n>=180 or not shown(f) then return end
 budget.n=budget.n+1
 if not protected(f) then
  for _,r in ipairs({f:GetRegions()})do
   if r.IsObjectType and r:IsObjectType('FontString') then font(r,r==f.BindingText and 14 or 16)end
  end
  if f.Name and f.BindingText then
   local p,r,rp,x,y=f.BindingText:GetPoint(1)
   if p~='TOPLEFT' or r~=f.Name or rp~='BOTTOMLEFT' or x~=0 or y~=-3 then
    f.BindingText:ClearAllPoints();f.BindingText:SetPoint('TOPLEFT',f.Name,'BOTTOMLEFT',0,-3)
   end
  end
 end
 for _,child in ipairs({f:GetChildren()})do walk(child,depth+1,budget)end
end
-- Native gamepad binding previews retain their input capture, action icons,
-- geometry and native footer. Only decoration is replaced; state stays local.
-- Secure parents may host paint regions out of combat. Never modify their
-- geometry, scripts, native fields or binding-manager state.
local actionSkins=setmetatable({},{__mode='k'})
local function styleActionBox(box)
 if not shown(box) then return end
 local skin=actionSkins[box]
 if not skin then
  local bg=box:CreateTexture(nil,'BACKGROUND');bg:SetPoint('TOPLEFT',0,44);bg:SetPoint('BOTTOMRIGHT');bg:SetColorTexture(.025,.030,.029,1)
  for _,side in ipairs({{'TOPLEFT','TOPRIGHT',false},{'BOTTOMLEFT','BOTTOMRIGHT',false},{'TOPLEFT','BOTTOMLEFT',true},{'TOPRIGHT','BOTTOMRIGHT',true}})do
   local line=box:CreateTexture(nil,'BORDER');line:SetColorTexture(.72,.60,.39,1)
   line:SetPoint(side[1],bg,side[1]);line:SetPoint(side[2],bg,side[2]);if side[3]then line:SetWidth(1)else line:SetHeight(1)end
  end
  local kicker=box:CreateFontString(nil,'OVERLAY');kicker:SetFont(STANDARD_TEXT_FONT,10,'');kicker:SetTextColor(.72,.60,.39);kicker:SetPoint('TOPLEFT',16,35);kicker:SetText('F O R E V E R  /  C O N T R O L S')
  local title=box:CreateFontString(nil,'OVERLAY');title:SetFont(STANDARD_TEXT_FONT,20,'');title:SetTextColor(.94,.90,.82);title:SetPoint('TOPLEFT',16,18);title:SetPoint('RIGHT',-16,0);title:SetJustifyH('LEFT')
  skin={title=title};actionSkins[box]=skin
 end
 for _,part in ipairs({box.Border,box.HighlightFrame,box.TitleBox})do if part and part:GetAlpha()~=0 then part:SetAlpha(0)end end
 local title=box.TitleBox and box.TitleBox.TitleText and box.TitleBox.TitleText:GetText()
 if public(title) and title~=skin.value then skin.title:SetText(title);skin.value=title end
end
local function styleActionBinding()
 local root=_G.GamepadActionBarEditFrame
 if not shown(root) then return end
 styleActionBox(root.BindingInfoFrame);styleActionBox(root.EditActionBarsInfoFrame)
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.actionBindingStyle={version='3.7.91',seen=GetTime(),binding=not not shown(root.BindingInfoFrame),editing=not not shown(root.EditActionBarsInfoFrame),nativeActions=true}
end
local helpSkins=setmetatable({},{__mode='k'})
local function styleClickHelp(help)
 if helpSkins[help] then return end
 local bg=help:CreateTexture(nil,'BACKGROUND',nil,-8);bg:SetAllPoints();bg:SetColorTexture(.025,.030,.029,1)
 for _,side in ipairs({{'TOPLEFT','TOPRIGHT',false},{'BOTTOMLEFT','BOTTOMRIGHT',false},{'TOPLEFT','BOTTOMLEFT',true},{'TOPRIGHT','BOTTOMRIGHT',true}})do
  local line=help:CreateTexture(nil,'BORDER');line:SetColorTexture(.72,.60,.39,1);line:SetPoint(side[1]);line:SetPoint(side[2]);if side[3]then line:SetWidth(1)else line:SetHeight(1)end
 end
 -- Restore the native explanatory illustration as owned paint. The native
 -- close button, tutorial acknowledgement and all text remain the owners.
 local art=help:CreateTexture(nil,'ARTWORK');art:SetAtlas('clickcast-background-tutorial',true);art:SetPoint('BOTTOM',2,3)
 helpSkins[help]={bg=bg,art=art}
end
local function update()
 if InCombatLockdown() then return end
 styleActionBinding()
 local cooldown=_G.CooldownViewerSettings
 if shown(cooldown) then
  local budget={n=0};walk(cooldown,0,budget)
  ForeverHandheldDB=ForeverHandheldDB or {}
  ForeverHandheldDB.cooldownSettings={version='3.7.53',seen=GetTime(),visited=budget.n}
 end
 local root=_G.ClickBindingFrame
 if not shown(root) then return end
 local budget={n=0};walk(root,0,budget)
 local helpButton=root.TutorialButton
 if shown(helpButton) and not protected(helpButton) then
  local p,r,rp,x,y=helpButton:GetPoint(1)
  if p~='TOPLEFT' or r~=root or rp~='TOPLEFT' or math.abs(x-8)>.01 or math.abs(y+24)>.01 then
   helpButton:ClearAllPoints();helpButton:SetPoint('TOPLEFT',root,'TOPLEFT',8,-24)
  end
  if helpButton:GetWidth()~=36 or helpButton:GetHeight()~=36 then helpButton:SetSize(36,36)end
 end
 local help=root.TutorialFrame
 if shown(help) and not protected(help) then
  styleClickHelp(help)
  -- The original +300px anchor crosses the binding list. Keep help above the
  -- companion picker, leaving the current binding list and close control clear.
  local p,r,rp,x,y=help:GetPoint(1)
  if p~='TOPRIGHT' or r~=root or rp~='TOPLEFT' or math.abs(x+16)>.01 or math.abs(y+90)>.01 then
   help:ClearAllPoints();help:SetPoint('TOPRIGHT',root,'TOPLEFT',-16,-90)
  end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.bindingSettings={version='3.7.93',seen=GetTime(),visited=budget.n,helpButtonShown=not not shown(helpButton),helpShown=not not shown(help)}
end
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.3 then return end;elapsed=0
 local ok,err=pcall(update)
 if not ok then
  ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.bindingSettingsError=tostring(err)
  driver:SetScript('OnUpdate',nil)
 end
end)
