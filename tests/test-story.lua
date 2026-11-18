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
dofile(arg[1])
local S=ForeverHandheldStory
local native=CreateFrame('Button');native.title=native:CreateFontString();native.title:SetText('The canal')
native.text=native:CreateFontString();native.text:SetText('A story with |Hquest:1|h[quest text]|h and |cffff0000color|r.')
local timer=function()end;native.scripts.OnUpdate=timer
local hide=function()error('must not advance native queue')end;native.scripts.OnHide=hide
S.capture(native,'tour')
local list=ForeverHandheldDB.storyHistory
assert(#list==1 and #notices==1 and list[1].text:find('%[quest text%]'),'capture lost readable text')
assert(native.scripts.OnUpdate==timer and native.scripts.OnHide==hide and not native.hides,'native queue or timer changed')
assert(native.alpha==0 and not native.mouse and native.point[4]==-10000,'invisible native hover region remains in world')
native:SetAlpha(.7);assert(native.alpha==0,'native fade paints an invisible duplicate')
native:SetPoint('CENTER',UIParent,'CENTER',0,0);assert(native.point[4]==-10000,'native relayout reintroduced center hover region')
for i=1,50 do S.capture(native,'tour')end
assert(#list==1 and #notices==1,'polling duplicated a story')
native:Hide();native:Show();assert(#list==1,'reshowing same text duplicated history')
native.text:SetText('A new chapter');S.capture(native,'tour');assert(#list==2,'changed note was lost')
combat=true;native.text:SetText('Deferred');S.capture(native,'tour');assert(#list==2 and not S.open(),'combat mutated reader')
combat=false;S.capture(native,'tour');assert(#list==3,'deferred note did not recover')
for i=1,30 do native.text:SetText('Story '..i);S.capture(native,'tour')end
assert(#list==20 and list[1].text=='Story 11' and list[20].text=='Story 30','history not bounded newest-first')
native.text:SetText(string.rep('Readable long story. ',300));S.capture(native,'tour')
assert(S.open() and S.reader.body:GetText()==list[#list].text,'reader lost complete long text')
local reader=S.reader
assert(reader.bar.hi>0 and reader.previous.enabled and not reader.next.enabled,'long reader does not scroll or history order broken')
reader.bar:SetValue(200);assert(reader.scroll.scroll==200,'scrollbar did not move text')
reader.previous.scripts.OnClick();assert(reader.body:GetText()=='Story 30' and reader.scroll.scroll==0 and reader.next.enabled,'previous note did not reset reading position')
reader.next.scripts.OnClick();assert(reader.body:GetText()==list[#list].text,'next note lost full text')
reader.close.scripts.OnClick();assert(reader.hidden,'close did not return to world')
assert(native.scripts.OnUpdate==timer and native.scripts.OnHide==hide,'reading changed native lifecycle')
print('Story contracts passed: bounded deduplication, complete reading, native timer/queue preservation, no invisible hover region, combat deferral, scroll/history and close lifecycle.')

native.title:SetText(string.rep('A wrapped chapter title ',8));native.text:SetText(string.rep('Long readable text. ',400));S.capture(native,'tour');S.open()
local titleBottom=24+reader.heading:GetStringHeight()
local counterTop=-reader.position.point[3]
local bodyTop=-reader.scroll.point[3]
assert(counterTop>titleBottom,'wrapped title overlaps counter')
assert(bodyTop>counterTop+reader.position:GetStringHeight(),'counter overlaps reading area')
assert(bodyTop+reader.scroll:GetHeight()<=458,'reading area overlaps buttons')
assert(reader.bar:GetHeight()==reader.scroll:GetHeight() and reader.bar.hi>0,'long title breaks scroll sizing')
print('PASS: wrapped chapter header, counter and long-note viewport remain separated; fixed controls remain clear.')
