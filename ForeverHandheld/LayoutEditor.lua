-- Presentation only: native editor owns selection, input, movement and persistence.
local VERSION='3.7.87'
local driver=CreateFrame('Frame','ForeverHandheldLayoutEditorDriver')
local elapsed=0
local styled=setmetatable({},{__mode='k'})
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function safe(f)
 return f and not (f.IsForbidden and f:IsForbidden()) and not (f.IsProtected and f:IsProtected())
end
local function number(v)return public(v) and type(v)=='number' and v==v and v>0 end
local function width(f,w)if math.abs(f:GetWidth()-w)>.1 then f:SetWidth(w)end end
local function height(f,h)if math.abs(f:GetHeight()-h)>.1 then f:SetHeight(h)end end
local function anchor(f,parent,x,y)
 local a,b,c,d,e=f:GetPoint(1)
 if a~='TOPLEFT' or b~=parent or c~='TOPLEFT' or d~=x or e~=y then
  f:ClearAllPoints();f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y)
 end
end
local function text(f,size,w)
 if not safe(f) then return false end
 local face,old,flags=f:GetFont()
 if not public(face) or type(face)~='string' or not number(old) or not public(flags) then return false end
 if old~=size then f:SetFont(face,size,flags or '')end
 if not styled[f] then
  f:SetWordWrap(true);f:SetJustifyH('LEFT');f:SetJustifyV('TOP');f:SetSpacing(2);styled[f]=true
 end
 width(f,w)
 local h=f:GetStringHeight()
 if not number(h) then return false end
 height(f,h+2)
 return h+2
end
local function paint(f)
 if styled[f] then return end
 if safe(f.bg) then f.bg:SetColorTexture(.025,.030,.025,.98)end
 -- Keep native selection outlines and semantic colors; only the panel surface changes.
 styled[f]=true
end
local function listText(f,size,w,h)
 if not safe(f) or not f.GetFont then return end
 local face,old,flags=f:GetFont()
 if not public(face) or type(face)~='string' or not number(old) or not public(flags) then return end
 if old~=size then f:SetFont(face,size,flags or '')end
 if not styled[f] then
  f:SetWordWrap(true);f:SetJustifyH('LEFT');f:SetJustifyV('TOP');f:SetSpacing(0);styled[f]=true
 end
 width(f,w);height(f,h)
end
local function gridStyle()
 local list=_G.ControllerForeverEditList
 if not safe(list) or not list:IsShown() then return end
 local w=list:GetWidth()
 if not number(w) or w<400 then return end
 paint(list)
 listText(list.title,20,w-40,26)
 listText(list.tabs,16,w-40,24)
 listText(list.footer,15,w-40,24)
 local count=0
 for _,tile in ipairs(list.tiles or {})do
  if safe(tile) and tile:IsShown() then
   local tw,th=tile:GetWidth(),tile:GetHeight()
   if number(tw) and number(th) and tw>=120 and th>=60 then
    listText(tile.name,16,tw-20,32)
    if safe(tile.name)then anchor(tile.name,tile,10,-7)end
    listText(tile.state,15,tw-20,17)
    if safe(tile.state)then anchor(tile.state,tile,10,-th+21)end
    -- Native redraw owns the selected/unselected colors. A fixed tint
    -- neutralizes blue surfaces while preserving its amber selection.
    if safe(tile.bg) and not styled[tile.bg] then
     tile.bg:SetVertexColor(.5,.4,.25,1);styled[tile.bg]=true
    end
    count=count+1
   end
  end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.layoutGrid={version=VERSION,seen=GetTime(),visibleTiles=count,nameFont=16,stateFont=15,nativeActions=true}
end
local function update()
 if InCombatLockdown() then return end
 local panel=_G.ControllerForeverEditPanel
 if not safe(panel) or not panel:IsShown() or not safe(panel.title) or not safe(panel.hint) then return end
 local w=panel:GetWidth()
 if not number(w) or w<400 then return end
 local th=text(panel.title,17,w-32);local hh=text(panel.hint,15,w-32)
 if not th or not hh then return end
 anchor(panel.title,panel,16,-12);anchor(panel.hint,panel,16,-th-22)
 height(panel,th+hh+34);paint(panel)
 gridStyle()
 local options=_G.ControllerForeverEditOptions
 local oh
 if safe(options) and options:IsShown() and safe(options.title) and safe(options.body) then
  width(options,360)
  local title=text(options.title,18,332);local body=text(options.body,16,332)
  if title and body then
   anchor(options.title,options,14,-14);anchor(options.body,options,14,-title-24)
   oh=title+body+40;height(options,oh);paint(options)
   if not options:IsClampedToScreen() then options:SetClampedToScreen(true)end
  end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.layoutEditorError=nil
 local d=ForeverHandheldDB.layoutEditor or {};ForeverHandheldDB.layoutEditor=d
 d.version=VERSION;d.seen=GetTime();d.toolbarHeight=panel:GetHeight();d.hintFont=15;d.optionsHeight=oh;d.nativeActions=true
end
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.15 then return end;elapsed=0
 local ok,err=pcall(update)
 if not ok then
  ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.layoutEditorError=tostring(err)
  ForeverHandheldDB.layoutEditorLastError={version=VERSION,seen=GetTime(),message=tostring(err)}
 end
end)
