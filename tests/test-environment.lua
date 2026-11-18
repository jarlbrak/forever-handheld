-- Native timers retain their countdown/visibility and consume no paint loop.
local objects,timers={},{}
SlashCmdList={}
local combat=false
local M={}
function M:IsForbidden()return false end
function M:IsObjectType(t)return self.kind==t end
function M:GetRegions()return unpack(self.regions or {})end
function M:GetFrameLevel()return self.level or 10 end
function M:SetFrameLevel(v)assert(not self.native);self.level=v end
function M:SetScript(k,v)assert(not self.native,'native timer script replaced');self[k]=v end
function M:RegisterEvent()assert(not self.native)end
function M:SetAllPoints(v)assert(not self.native);self.anchor=v end
function M:EnableMouse(v)assert(not self.native and not v)end
function M:SetBackdrop()assert(not self.native)end
function M:SetBackdropBorderColor()assert(not self.native)end
function M:SetStatusBarTexture(v)self.texture=v;self.textureWrites=(self.textureWrites or 0)+1 end
function M:SetStatusBarColor(...)self.color={...}end
function M:SetAlpha(v)self.alpha=v end
function M:SetFont(_,size)self.fontSize=size end
function M:SetTextColor(...)self.color={...}end
function M:SetShadowColor()end
function M:SetShadowOffset()end
function M:SetColorTexture(...)self.color={...}end
local function obj(kind,native)
 local f=setmetatable({kind=kind,native=native},{__index=function(_,k)
  if M[k] then return M[k]end
  if k:match('^Set') or k=='Show' or k=='Hide' or k=='Clear' then return function()error('native behavior touched: '..k)end end
 end});objects[#objects+1]=f;return f
end
function M:CreateTexture()return obj('Texture')end
function CreateFrame(_,_,parent)local f=obj('Frame');f.parent=parent;return f end
function InCombatLockdown()return combat end
C_Timer={After=function(_,f)timers[#timers+1]=f end}
MirrorTimerContainer={mirrorTimers={}}
for i,kind in ipairs({'BREATH','EXHAUSTION','FEIGNDEATH'})do
 local f=obj('Frame',true);f.timer=kind;f.StatusBar=obj('StatusBar',true);f.StatusBar.level=9
 f.StatusBar.value=123;f.StatusBar.range={0,180};f.Text=obj('FontString',true);f.Text.label=kind
 f.regions={obj('Texture',true),f.Text};f.nativeOnUpdate=function()end;f.OnUpdate=f.nativeOnUpdate
 MirrorTimerContainer.mirrorTimers[i]=f
end
local before=#objects;dofile(arg[1]);local driver=objects[before+1]
local function flush()while #timers>0 do table.remove(timers,1)()end end
local function fire(event,name)driver.OnEvent(driver,event,name)end
fire('PLAYER_LOGIN');fire('PLAYER_ENTERING_WORLD');assert(#timers==1,'coalesce load events');flush()
assert(not driver.OnUpdate,'no polling/per-frame paint')
assert(not ForeverHandheldDB.environmentError)
for _,f in ipairs(MirrorTimerContainer.mirrorTimers)do
 assert(f.StatusBar.value==123 and f.StatusBar.range[2]==180 and f.OnUpdate==f.nativeOnUpdate,'countdown changed')
 assert(f.Text.fontSize==15 and f.Text.label==f.timer and f.regions[1].alpha==0,'readable native label/chrome')
 local background,rim
 for _,o in ipairs(objects)do if o.parent==f and o.anchor==f then if o.level<9 then background=o else rim=o end end end
 assert(background and rim and rim.level==11,'fill must stay below native bar; edge above label')
end
local allocated=#objects;local bar=MirrorTimerContainer.mirrorTimers[1].StatusBar
bar.texture='native-breath-atlas';fire('MIRROR_TIMER_START');flush()
assert(bar.texture=='Interface\\Buttons\\WHITE8X8' and #objects==allocated,'new timer setup restores flat fill without allocating')
local writes=bar.textureWrites
fire('ADDON_LOADED','unrelated');flush();assert(bar.textureWrites==writes,'unrelated addons do not repaint')
combat=true;fire('MIRROR_TIMER_START');flush();assert(bar.textureWrites==writes,'combat styling deferred')
combat=false;fire('PLAYER_REGEN_ENABLED');flush();assert(bar.textureWrites==writes+1,'deferred styling resumed')
assert(ForeverHandheldDB.environment.seen.BREATH and ForeverHandheldDB.environment.seen.EXHAUSTION)
print('PASS: native timer scripts/value/range/labels/visibility preserved; background layering, restart reuse, event coalescing, no polling, combat defer')

-- Preview uses native edit-mode visibility, restores native fields and yields
-- to a real timer. No fake timer type is installed to drive the preview.
function M:GetMinMaxValues()return unpack(self.range)end
function M:GetValue()return self.value end
function M:GetText()return self.label end
function M:SetText(v)self.label=v end
function M:SetMinMaxValues(a,b)self.range={a,b}end
function M:SetValue(v)self.value=v end
function MirrorTimerContainer:SetIsInEditMode(v)self.isInEditMode=v end
for _,f in ipairs(MirrorTimerContainer.mirrorTimers)do f.timer=nil end
SlashCmdList.FOREVERENVIRONMENT('')
assert(MirrorTimerContainer.isInEditMode and MirrorTimerContainer.mirrorTimers[1].Text.label:find('preview'),'native edit preview labelled')
assert(not MirrorTimerContainer.mirrorTimers[1].timer,'preview must not invent a real timer')
flush()
assert(not MirrorTimerContainer.isInEditMode and bar.value==123 and bar.range[2]==180,'preview expiry restores values/visibility')
SlashCmdList.FOREVERENVIRONMENT('');local real=MirrorTimerContainer.mirrorTimers[1];real.timer='BREATH';real.Text.label='Real breath';bar.value=48
fire('MIRROR_TIMER_START');flush()
assert(not MirrorTimerContainer.isInEditMode and real.Text.label=='Real breath' and bar.value==48,'real timer takes over without restoration overwriting it')
local count=#timers;SlashCmdList.FOREVERENVIRONMENT('');assert(#timers==count and not MirrorTimerContainer.isInEditMode,'refuse preview while real timer active')
print('PASS: native edit-mode preview restores fields, expires, refuses active timers and yields immediately to real timers')
