local combat=false
local frames={}
local M={}
function M:SetScript(k,v)self.scripts[k]=v end
function M:HookScript(k,v)self.hooks[k]=v end
function M:IsShown()return not self.hidden end
function M:Hide()self.hidden=true;self.hides=(self.hides or 0)+1 end
function M:Show()self.hidden=false;if self.hooks.OnShow then self.hooks.OnShow(self)end end
function M:SetText(v)self.text=v end
function M:GetText()return self.text end
function M:SetAlpha(v)self.alpha=v end
function M:SetPoint(...)self.point={...}end
function M:ClearAllPoints()self.point=nil end
function M:EnableMouse(v)self.mouse=v end
function M:SetSize(w,h)self.w=w;self.h=h end
function M:SetHeight(h)self.h=h end
function M:GetHeight()return self.h or 100 end
function M:GetWidth()return self.w or 100 end
function M:GetStringHeight()return math.ceil(#(self.text or '')/60)*24 end
function M:SetMinMaxValues(lo,hi)self.lo=lo;self.hi=hi end
function M:GetMinMaxValues()return self.lo,self.hi end
function M:SetValue(v)self.value=v;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v)end end
function M:GetValue()return self.value or 0 end
function M:SetShown(v)self.hidden=not v end
function M:SetVerticalScroll(v)self.scroll=v end
function M:SetEnabled(v)self.enabled=v end
function CreateFrame(kind,name,parent)
 local f=setmetatable({kind=kind,name=name,parent=parent,scripts={},hooks={}},{__index=function(_,k)
  if M[k] then return M[k] end
  if k:match('^Set') or k:match('^Enable') then return function()end end
 end})
 frames[#frames+1]=f;if name then _G[name]=f end;return f
end
function M:CreateFontString()return CreateFrame('FontString',nil,self)end
function M:GetFontString()self.font=self.font or self:CreateFontString();return self.font end
function M:GetThumbTexture()self.thumb=self.thumb or CreateFrame('Texture');return self.thumb end
function M:GetHighlightTexture()self.highlight=self.highlight or CreateFrame('Texture');return self.highlight end
function hooksecurefunc(owner,key,fn)
 local original=owner[key]
 owner[key]=function(...)local result=original(...);fn(...);return result end
end
function InCombatLockdown()return combat end
UIParent=CreateFrame('Frame');UISpecialFrames={};STANDARD_TEXT_FONT='Font'
local notices={}
ForeverHandheldActivityFeed={StoryNotice=function(t)notices[#notices+1]=t end}


function M:RegisterEvent()end
function M:CreateTexture()return CreateFrame('Texture',nil,self)end
function M:GetTexture()return self.texture end
function M:SetTexture(v)self.texture=v end
function M:ClearLines()self.lines={}end
function M:SetHyperlink(link)
 self.link=link;self.lines={link,'Native complete stat line','Sell Price: 5 silver'};self.h=link:find('long',1,true) and 900 or 140
 for i=1,#self.lines do for _,side in ipairs({'Left','Right'})do _G['ForeverHandheldRareItemTooltipText'..side..i]=CreateFrame('FontString')end end
end
function M:NumLines()return #(self.lines or {})end
function M:AddLine(s)self.lines[#self.lines+1]=s end
function M:GetPoint()return unpack(self.point or {},1,5)end
function M:SetWidth(w)self.w=w end
function M:IsForbidden()return false end
C_Item={GetItemInfo=function(link)return link:match('item:(.*)')end,GetItemIconByID=function(id)return id end}
local function alert(id,name,items)
 local b=CreateFrame('Button');b.entityID=id;b.atlasName='npc';b.Title=b:CreateFontString();b.Title:SetText(name)
 b.LootBar={itemFramesPool={EnumerateActive=function()return ipairs(items or {}) end}}
 -- EnumerateActive yields frames, unlike the array iterator.
 b.LootBar.itemFramesPool.EnumerateActive=function()local i=0;return function()i=i+1;return (items or {})[i]end end
 return b
end
local function item(id,x,y,chance)
 local f=CreateFrame('Frame');f.itemID=id;f.itemLink='item:'..id;f.Icon=f:CreateTexture();f.Icon:SetTexture(id);f.dropChance=chance
 f:SetPoint('TOPLEFT',nil,nil,x,y);return f
end
function GetTime()return 10 end
SlashCmdList={};C_Timer={After=function()end}
dofile(arg[1]);local R=ForeverHandheldRareReader
local native=item(1,21,0,5);local first=item(2,0,0)
RARESCANNER_BUTTON=alert(10,'Rare one',{native,first});local original=RARESCANNER_BUTTON.Title:GetText()
R.capture(RARESCANNER_BUTTON);assert(#R.history==1 and R.history[1].items[1].id==2,'native visual order not retained')
local empty=alert(10,'Rare one',{});R.capture(empty);assert(#R.history[1].items==2,'delayed recycling erased items')
R.open();local w=R.window;assert(w:IsShown() and w.tip.link=='item:2','initial details not selected')
w.items[2].scripts.OnClick();assert(w.tip.link=='item:1' and w.tip.lines[4]:find('5%%'),'native link/chance not retained')
local old=w.history[1];for i=11,20 do R.capture(alert(i,'Rare '..i,{item(i,0,0)}))end
assert(#R.history==8 and R.history[1].key=='13:npc','history not bounded')
w.items[1].scripts.OnClick();assert(w.tip.link=='item:2' and w.history[1]==old,'new alerts changed an open reader')
RARESCANNER_BUTTON=nil;R.refresh();assert(#w.history==8,'refresh did not replace snapshot')
R.capture(alert(21,'Long note',{item('long',0,0)}));R.open();assert(w.tip:GetHeight()==900 and w.bar:IsShown() and w.content.h==912,'long native detail not scrollable')
w.bar:SetValue(200);assert(w.scroll.scroll==200,'detail scroll failed')
w.scripts.OnEvent(w,'GET_ITEM_INFO_RECEIVED',999);assert(w.scroll.scroll==200,'unrelated item cache event reset reading position')
combat=true;assert(not R.open(),'reader opened in combat');w.scripts.OnEvent(w,'PLAYER_REGEN_DISABLED');assert(not w:IsShown(),'combat failed to close');combat=false
R.history={};R.open();assert(w.empty:IsShown() and not w.tip:IsShown() and not w.bar:IsShown(),'empty state is not usable');w.scripts.OnUpdate(w,.3);assert(not w.bar:IsShown(),'empty detail exposed stale scroll')
local many={};for i=1,15 do many[i]=item(i,(i-1)*21,0)end;R.capture(alert(30,'Many',many));assert(#R.history[1].items==10 and R.history[1].total==15,'displayed-item bound failed')
assert(native.itemLink=='item:1' and original=='Rare one','native source mutated')
print('PASS: native visual ordering/data preserved; delayed loading; bounded history/items; stable open snapshot; explicit refresh; native link/chance rendering; long detail scroll; empty state; combat guard/closure.')
