-- Paint the native breath/fatigue/death timers. Their original owner still
-- controls timing, visibility, pause state, layout and edit-mode placement.
local WHITE='Interface\\Buttons\\WHITE8X8'
local styles=setmetatable({},{__mode='k'})
local colors={BREATH={.35,.66,.80},EXHAUSTION={.87,.64,.29},DEATH={.90,.37,.29},FEIGNDEATH={.65,.58,.80}}
local driver=CreateFrame('Frame')
local queued=false
local function paint(frame)
 if not frame or not frame.StatusBar or not frame.Text or frame:IsForbidden() then return end
 local bar=frame.StatusBar
 local s=styles[frame]
 if not s then
  s={};styles[frame]=s
  -- Put the fill below the native status bar, whose level is lower than its
  -- parent. A backdrop on the parent would obscure the countdown itself.
  s.bg=CreateFrame('Frame',nil,frame)
  s.bg:EnableMouse(false);s.bg:SetAllPoints(frame)
  s.bg:SetFrameLevel(math.max(0,bar:GetFrameLevel()-1))
  local fill=s.bg:CreateTexture(nil,'BACKGROUND');fill:SetAllPoints(s.bg)
  fill:SetColorTexture(.025,.030,.025,.94)
  s.rim=CreateFrame('Frame',nil,frame,'BackdropTemplate')
  s.rim:EnableMouse(false);s.rim:SetAllPoints(frame)
  s.rim:SetFrameLevel(frame:GetFrameLevel()+1)
  s.rim:SetBackdrop({edgeFile=WHITE,edgeSize=1})
  s.rim:SetBackdropBorderColor(.68,.56,.36,1)
  for _,r in ipairs({frame:GetRegions()})do
   if r:IsObjectType('Texture') then r:SetAlpha(0)end
  end
  frame.Text:SetFont('Fonts\\ARIALN.TTF',15,'OUTLINE')
  frame.Text:SetTextColor(.94,.90,.82)
  frame.Text:SetShadowColor(0,0,0,.8);frame.Text:SetShadowOffset(1,-1)
 end
 local kind=frame.timer
 if issecretvalue and issecretvalue(kind) then kind=nil end
 -- Setup replaces the native fill atlas on each timer start. Repaint only
 -- on lifecycle events, never from the native countdown's OnUpdate.
 bar:SetStatusBarTexture(WHITE)
 bar:SetStatusBarColor(unpack(colors[kind] or {.68,.56,.36}))
 ForeverHandheldDB=ForeverHandheldDB or {}
 local d=ForeverHandheldDB.environment or {version='3.7.17',seen={}}
 ForeverHandheldDB.environment=d
 if type(kind)=='string' then d.seen[kind]=true end
 d.styled=true
end
local function apply()
 queued=false
 -- Native regions are left untouched while protected combat work is active;
 -- a timer already styled keeps its decoration and original live countdown.
 if InCombatLockdown() then return end
 local ok,err=pcall(function()
  local root=_G.MirrorTimerContainer
  for i,frame in ipairs(root and root.mirrorTimers or {})do
   if i>3 then break end
   paint(frame)
  end
 end)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.environmentError=tostring(err)end
end
local function queue()
 if queued then return end;queued=true;C_Timer.After(0,apply)
end
-- A short, clearly labelled native edit-mode preview supports visual checks
-- at an inn. It never creates a game timer or changes the native timer type.
local preview
local function clearPreview()
 local p=preview;if not p then return end;preview=nil
 for _,saved in ipairs(p.frames)do
  local f=saved.frame
  -- A real timer starting during preview owns its fresh value and label.
  if not f.timer then
   f.Text:SetText(saved.text);f.StatusBar:SetMinMaxValues(saved.min,saved.max);f.StatusBar:SetValue(saved.value)
  end
 end
 p.root:SetIsInEditMode(false)
end
local function showPreview()
 clearPreview()
 local root=_G.MirrorTimerContainer
 if InCombatLockdown() or not root or root.isInEditMode then return end
 local saved={root=root,frames={}}
 for i,f in ipairs(root.mirrorTimers or {})do
  if i>3 or f.timer then return end
  local low,high=f.StatusBar:GetMinMaxValues();local value=f.StatusBar:GetValue()
  if issecretvalue and (issecretvalue(low) or issecretvalue(high) or issecretvalue(value)) then return end
  saved.frames[i]={frame=f,text=f.Text:GetText(),min=low,max=high,value=value}
 end
 preview=saved
 for i,v in ipairs(saved.frames)do
  v.frame.Text:SetText(({'Breath','Fatigue','Death'})[i]..' · preview')
  v.frame.StatusBar:SetMinMaxValues(0,100);v.frame.StatusBar:SetValue(80-i*15)
 end
 root:SetIsInEditMode(true)
 C_Timer.After(12,function()if preview==saved then clearPreview()end end)
end
SLASH_FOREVERENVIRONMENT1='/fhtimers'
SlashCmdList.FOREVERENVIRONMENT=function(argument)
 if argument=='hide' then clearPreview() else showPreview()end
end
for _,event in ipairs({'PLAYER_LOGIN','PLAYER_ENTERING_WORLD','MIRROR_TIMER_START','PLAYER_REGEN_ENABLED','ADDON_LOADED'})do driver:RegisterEvent(event)end
driver:SetScript('OnEvent',function(_,event,name)
 if event=='MIRROR_TIMER_START' then clearPreview()end
 if event~='ADDON_LOADED' or name=='Blizzard_MirrorTimer' then queue()end
end)
