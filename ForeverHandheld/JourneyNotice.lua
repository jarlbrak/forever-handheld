-- Surface responses from our Next chapter action without requiring chat.
-- Observe only synchronous Loreward output; never replace its command, print,
-- chat method, guide state, or native chapter-choice window.
local J={version='3.7.38'}
ForeverHandheldJourneyNotice=J
local capture,observed,window
local function clean(message)
 if type(message)~='string' or (issecretvalue and issecretvalue(message)) then return end
 message=message:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
 if not message:match('^%[Loreward%]') then return end
 return message:gsub('^%[Loreward%]%s*','')
end
local function label(parent,size)
 local t=parent:CreateFontString(nil,'OVERLAY');t:SetFont(STANDARD_TEXT_FONT,size,'')
 t:SetTextColor(.94,.90,.82);t:SetJustifyH('LEFT');t:SetWordWrap(true);return t
end
local function build()
 local f=CreateFrame('Frame','ForeverHandheldJourneyNoticeWindow',UIParent,'BackdropTemplate')
 f:Hide();f:SetSize(800,280);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true)
 f:SetBackdrop({bgFile='Interface/Buttons/WHITE8X8',edgeFile='Interface/Buttons/WHITE8X8',edgeSize=1})
 f:SetBackdropColor(.025,.030,.029,1);f:SetBackdropBorderColor(.72,.60,.39,1)
 f.scroll=CreateFrame('ScrollFrame',nil,f);f.scroll:SetPoint('TOPLEFT',24,-24);f.scroll:SetWidth(744)
 f.content=CreateFrame('Frame',nil,f.scroll);f.content:SetWidth(744);f.scroll:SetScrollChild(f.content)
 f.body=label(f.content,20);f.body:SetPoint('TOPLEFT');f.body:SetWidth(736);f.body:SetSpacing(5)
 f.bar=CreateFrame('Slider',nil,f);f.bar:SetPoint('TOPLEFT',774,-24);f.bar:SetWidth(8);f.bar:SetOrientation('VERTICAL');f.bar:SetValueStep(32)
 f.bar:SetThumbTexture('Interface/Buttons/WHITE8X8');f.bar:GetThumbTexture():SetSize(6,28);f.bar:GetThumbTexture():SetVertexColor(.72,.60,.39,1)
 f.bar:SetScript('OnValueChanged',function(_,v)f.scroll:SetVerticalScroll(v)end)
 f.scroll:EnableMouseWheel(true);f.scroll:SetScript('OnMouseWheel',function(_,delta)
  local lo,hi=f.bar:GetMinMaxValues();f.bar:SetValue(math.max(lo,math.min(hi,f.bar:GetValue()-delta*60)))
 end)
 f.foreverJourneyScroll={frame=f.scroll,bar=f.bar,content=f.content}
 local function button(text,x,width,action)
  local b=CreateFrame('Button',nil,f,'BackdropTemplate');b:SetPoint('BOTTOMLEFT',x,20);b:SetSize(width,36)
  b:SetBackdrop({bgFile='Interface/Buttons/WHITE8X8',edgeFile='Interface/Buttons/WHITE8X8',edgeSize=1})
  b:SetBackdropColor(.045,.052,.047,1);b:SetBackdropBorderColor(.72,.60,.39,.65)
  local t=label(b,17);t:SetPoint('CENTER');t:SetText(text);b.foreverJourneyLabel=text
  b:SetHighlightTexture('Interface/Buttons/WHITE8X8');b:GetHighlightTexture():SetVertexColor(.72,.60,.39,.16)
  b:SetScript('OnClick',function()if not InCombatLockdown() then action()end end);return b
 end
 f.plan=button('Plan your journey',24,260,function()f:Hide();if SlashCmdList.LOREWARD then SlashCmdList.LOREWARD('plan')end end)
 f.close=button('Close',610,166,function()f:Hide()end)
 f:RegisterEvent('PLAYER_REGEN_DISABLED');f:SetScript('OnEvent',function()f:Hide()end)
 f:SetScript('OnUpdate',function()
  -- A delayed native branch chooser takes precedence over its waiting notice.
  if LorewardWhereNextBox and LorewardWhereNextBox:IsShown() then f:Hide()end
 end)
 UISpecialFrames[#UISpecialFrames+1]='ForeverHandheldJourneyNoticeWindow'
 J.window=f;return f
end
function J.show(message)
 if InCombatLockdown() or not message or message=='' then return false end
 if LorewardWhereNextBox and LorewardWhereNextBox:IsShown() then return false end
 if message:find('RestedXP shows no Loreward guide.',1,true) then
  message='Your current RestedXP guide does not use Loreward chapters.\n\nOpen Plan your journey to browse Loreward guides and their routes. Your current guide stays selected until you choose another.'
 end
 window=window or build();window.body:SetText(message)
 local height=math.max(1,window.body:GetStringHeight()+10);local view=math.min(340,math.max(120,height))
 window:SetHeight(view+120);window.scroll:SetHeight(view);window.bar:SetHeight(view);window.content:SetHeight(height)
 window.bar:SetMinMaxValues(0,math.max(0,height-view));window.bar:SetValue(0);window.bar:SetShown(height>view)
 window.bar:GetThumbTexture():SetHeight(math.max(24,math.min(view,view*view/height)))
 window:Show();return true
end
function J.run()
 if InCombatLockdown() or not SlashCmdList or not SlashCmdList.LOREWARD then return false end
 if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME~=observed and hooksecurefunc then
  observed=DEFAULT_CHAT_FRAME
  hooksecurefunc(observed,'AddMessage',function(_,message)
   if not capture or #capture>=8 then return end
   local text=clean(message);if text then capture[#capture+1]=text end
  end)
 end
 local messages={};capture=messages
 local ok,err=pcall(SlashCmdList.LOREWARD,'next')
 capture=nil
 if not ok then
  ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.journeyNoticeError=tostring(err)
  return J.show('Chapter information is unavailable right now. You can still browse guides in Plan your journey.')
 end
 if #messages>0 then return J.show(table.concat(messages,'\n\n'))end
 return true
end
