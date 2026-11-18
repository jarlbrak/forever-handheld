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

function M:RegisterEvent(k)self.events=self.events or {};self.events[k]=true end
function M:SetWidth(w)self.w=w end
function M:SetTextColor(...)self.color={...}end
function InCombatLockdown()return combat end
UIParent=CreateFrame('Frame');UISpecialFrames={};STANDARD_TEXT_FONT='Font';SlashCmdList={}
local secret={};function issecretvalue(v)return v==secret end
local cursorX,cursorY=400,300
function GetCursorPosition()return cursorX,cursorY end
dofile(arg[1]);local R=ForeverHandheldFieldReader
assert(R.open());local f=R.window
assert(f.rows[1].left:GetText():find('Inspect a unit') and f.bar.hidden)
f.close.scripts.OnClick();assert(not f:IsShown())
local rows={{leftText='Holy Light',rightText='35 Mana',leftColor={.2,.8,.3,1}},
 {leftText=string.rep('Full native spell description. ',300),rightText='Rank 2'}}
R.capture(rows,'FIELD NOTES / SPELL',true);assert(R.open())
assert(f.rows[1].left:GetText()=='Holy Light' and f.rows[1].right:GetText()=='35 Mana')
assert(f.rows[1].left.w==590 and f.rows[1].left.color[2]==.8)
assert(f.rows[2].left:GetText()==rows[2].leftText and f.bar.hi>0,'long description was shortened or cannot scroll')
f.bar:SetValue(200);assert(f.scroll.scroll==200)
R.capture({{leftText='Changed while reading'}},'other');assert(f.rows[1].left:GetText()=='Holy Light','reading changed underneath user')
f:Hide();R.open();assert(f.rows[1].left:GetText()=='Holy Light' and f.scroll.scroll==0)
f:Hide();R.capture({},'empty');R.capture({{leftText='Passive target'}},'FIELD NOTES / TARGET');R.open();assert(f.rows[1].left:GetText()=='Holy Light','menu transition or empty refresh erased spell inspection')
f:Hide();R.capture({{leftText='NPC exposed by closing spellbook'}},'FIELD NOTES');R.open()
assert(f.rows[1].left:GetText()=='Holy Light','stationary pointer overwrote spell snapshot after book close')
f:Hide();cursorX=401;R.capture({{leftText='Deliberate new hover'}},'FIELD NOTES');R.open()
assert(f.rows[1].left:GetText()=='Deliberate new hover','real pointer movement did not permit a new inspection')
f:Hide();R.capture(rows,'FIELD NOTES / SPELL',true);R.open()
combat=true;f.scripts.OnEvent(f,'PLAYER_REGEN_DISABLED');assert(not f:IsShown() and not R.open(),'reader opened or stayed open in combat')
R.capture({{leftText='Combat replacement'}},'combat');combat=false;R.open();assert(f.rows[1].left:GetText()=='Holy Light')
f:Hide();cursorX=cursorX+1;R.capture({{leftText='|TInterface/Icons/Spell_Holy_HolyBolt:20|t Spell',rightText=secret,leftColor={secret,.5,.5,1}}},'icon');R.open()
assert(f.rows[1].left:GetText():find('|T',1,true) and f.rows[1].right:GetText()=='' and f.rows[1].left.w==858,'native icon or secret handling failed')
f:Hide();local huge={};for i=1,65 do huge[i]={leftText='line '..i}end;R.capture(huge,'large');R.open();assert(f.rows[1].left:GetText():find('exceeds the reader limit') and f.rows[2].left.hidden,'oversized description silently truncated')
assert(not f.scripts.OnUpdate,'reader added polling')
f:Hide();UIParent.GetEffectiveAlpha=function()return 0 end
assert(not R.open() and not f:IsShown(),'cinematic fade created an invisible input-owning modal')
UIParent.GetEffectiveAlpha=function()return 1 end
for _,eventFrame in ipairs(frames)do if eventFrame.events and eventFrame.events.PLAYER_TARGET_CHANGED then eventFrame.scripts.OnEvent(eventFrame,'PLAYER_TARGET_CHANGED')end end
R.capture({{leftText='New selected target'}},'FIELD NOTES / TARGET');R.open();assert(f.rows[1].left:GetText()=='New selected target','changed target did not replace the previous inspection')
assert(f.foreverJourneyScroll.frame==f.scroll and f.foreverJourneyScroll.bar==f.bar and f.close.foreverJourneyLabel=='Close')
assert(rows[1].leftText=='Holy Light' and rows[1].rightText=='35 Mana','reader mutated source')
print('PASS: full long text/right columns, native icon/color preservation, scroll/reset, stable snapshot, empty/oversize/secret handling, combat close/guard, shared native navigation descriptor, no polling or source mutation')
