-- Deliberate controller reading of the last Field Notes. Session memory only.
local R={version='3.7.90'}
ForeverHandheldFieldReader=R
local latest,window
local targetChanged=true
local WHITE='Interface/Buttons/WHITE8X8'
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function readable(v)return public(v) and type(v)=='string' and v or '' end
function R.capture(rows,title,fromSpellbook)
 if InCombatLockdown() or (window and window:IsShown()) or type(rows)~='table' or #rows==0 then return end
 local x,y
 if GetCursorPosition then x,y=GetCursorPosition() end
 local cursorReadable=public(x) and public(y) and type(x)=='number' and type(y)=='number'
 -- Closing the book can expose a world unit beneath an unmoved pointer.
 -- The rail can show that unit, but it is not a new deliberate inspection.
 if latest and latest.fromSpellbook and not fromSpellbook and not targetChanged and
  cursorReadable and x==latest.cursorX and y==latest.cursorY then return end
 -- Opening the menu clears a spell/aura tooltip and restores passive target
 -- facts on the rail. That fallback must not erase the item we came to read.
 local passive=type(title)=='string' and (title:find('LAST INSPECTED',1,true) or title:match('/%s*TARGET$'))
 if passive and latest and not targetChanged then return end
 -- The HUD replaces this table on its next refresh; never edit its rows.
 latest={rows=rows,title=title,fromSpellbook=fromSpellbook and true or false,
  cursorX=cursorReadable and x or nil,cursorY=cursorReadable and y or nil}
 targetChanged=false
end
local targetEvents=CreateFrame('Frame')
targetEvents:RegisterEvent('PLAYER_TARGET_CHANGED')
targetEvents:SetScript('OnEvent',function()targetChanged=true end)
local function label(parent,size,width)
 local t=parent:CreateFontString(nil,'OVERLAY');t:SetFont(STANDARD_TEXT_FONT,size,'')
 t:SetTextColor(.94,.90,.82);t:SetJustifyH('LEFT');t:SetWordWrap(true);t:SetWidth(width)
 return t
end
local function color(font,value)
 local r,g,b,a
 if type(value)=='table' then
  if value.GetRGBA then r,g,b,a=value:GetRGBA() else r,g,b,a=unpack(value) end
 end
 if public(r) and public(g) and public(b) and public(a) and type(r)=='number' and type(g)=='number' and type(b)=='number' then
  font:SetTextColor(r,g,b,type(a)=='number' and a or 1)
 else font:SetTextColor(.94,.90,.82)end
end
local function build()
 local f=CreateFrame('Frame','ForeverHandheldFieldReaderWindow',UIParent,'BackdropTemplate')
 f:Hide();f:SetSize(960,540);f:SetPoint('CENTER',UIParent,'CENTER',0,-22)
 f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true)
 f:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
 f:SetBackdropColor(.025,.030,.029,1);f:SetBackdropBorderColor(.72,.60,.39,1)
 -- Panels supplies the shared title; do not duplicate it inside the reader.
 f.subtitle=label(f,14,896);f.subtitle:SetPoint('TOPLEFT',28,-24)
 f.scroll=CreateFrame('ScrollFrame',nil,f);f.scroll:SetPoint('TOPLEFT',28,-56);f.scroll:SetSize(872,402)
 f.content=CreateFrame('Frame',nil,f.scroll);f.content:SetSize(872,1);f.scroll:SetScrollChild(f.content)
 f.bar=CreateFrame('Slider',nil,f);f.bar:SetPoint('TOPLEFT',924,-56);f.bar:SetSize(10,402)
 f.bar:SetOrientation('VERTICAL');f.bar:SetValueStep(48);f.bar:SetMinMaxValues(0,0)
 f.bar:SetThumbTexture(WHITE);f.bar:GetThumbTexture():SetSize(8,32);f.bar:GetThumbTexture():SetVertexColor(.72,.60,.39,1)
 f.bar:SetScript('OnValueChanged',function(_,v)f.scroll:SetVerticalScroll(v)end)
 f.foreverJourneyScroll={frame=f.scroll,bar=f.bar,content=f.content,label='Read'}
 f.scroll:EnableMouseWheel(true);f.scroll:SetScript('OnMouseWheel',function(_,delta)
  local lo,hi=f.bar:GetMinMaxValues();f.bar:SetValue(math.max(lo,math.min(hi,f.bar:GetValue()-delta*64)))
 end)
 f.rows={}
 for i=1,64 do
  local left=label(f.content,i==1 and 22 or 18,858)
  local right=label(f.content,18,250);right:SetJustifyH('RIGHT')
  f.rows[i]={left=left,right=right}
 end
 f.close=CreateFrame('Button',nil,f,'BackdropTemplate');f.close:SetSize(200,36);f.close:SetPoint('TOPLEFT',732,-480)
 f.close:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1});f.close:SetBackdropColor(.045,.052,.047,1);f.close:SetBackdropBorderColor(.72,.60,.39,.65)
 f.close.label=label(f.close,16,188);f.close.label:SetPoint('CENTER');f.close.label:SetJustifyH('CENTER');f.close.label:SetText('Close')
 f.close.foreverJourneyLabel='Close';f.close:SetScript('OnClick',function()f:Hide()end)
 f:RegisterEvent('PLAYER_REGEN_DISABLED');f:SetScript('OnEvent',function()f:Hide()end)
 UISpecialFrames[#UISpecialFrames+1]='ForeverHandheldFieldReaderWindow'
 window=f;R.window=f
end
function R.open()
 if InCombatLockdown() then return false end
 -- Cinematic conversations fade UIParent. Do not create an invisible modal
 -- or claim its input; normal Journey entry is available after returning.
 local alpha=UIParent.GetEffectiveAlpha and UIParent:GetEffectiveAlpha()
 if not public(alpha) or (type(alpha)=='number' and alpha<.01) then return false end
 if not window then build()end
 local rows=latest and latest.rows or {};local f=window;local y=0
 -- Do not silently truncate unusually large native descriptions.
 if #rows>64 then rows={{leftText='This description exceeds the reader limit. Its complete native tooltip remains available.'}} end
 if #rows==0 then rows={{leftText='Inspect a unit, spell, or aura first. Its Field Notes will be available here for controller reading.'}} end
 f.subtitle:SetText('Last inspected details')
 for i,line in ipairs(f.rows)do
  local data=rows[i];line.left:SetShown(data~=nil);line.right:SetShown(data~=nil)
  if data then
   local left,right=readable(data.leftText),readable(data.rightText)
   line.left:SetText(left);line.right:SetText(right)
   line.left:SetWidth(right~='' and 590 or 858)
   line.left:ClearAllPoints();line.left:SetPoint('TOPLEFT',0,-y)
   line.right:ClearAllPoints();line.right:SetPoint('TOPRIGHT',-14,-y)
   color(line.left,data.leftColor);color(line.right,data.rightColor)
   y=y+math.max(i==1 and 28 or 22,line.left:GetStringHeight(),line.right:GetStringHeight())+10
  end
 end
 f.content:SetHeight(math.max(1,y));local range=math.max(0,y-f.scroll:GetHeight())
 f.bar:SetMinMaxValues(0,range);f.bar:SetValue(0);f.scroll:SetVerticalScroll(0);f.bar:SetShown(range>0)
 local view=f.scroll:GetHeight()
 f.bar:GetThumbTexture():SetHeight(math.max(24,math.min(view,view*view/math.max(1,y))))
 f:Show();return true
end
SLASH_FOREVERFIELDNOTES1='/fhnotes'
SlashCmdList.FOREVERFIELDNOTES=function()R.open()end
