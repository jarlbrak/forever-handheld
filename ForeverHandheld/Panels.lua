-- Shared presentation for every registered game panel and supported addon window.
-- Native frames retain their parents, scripts, navigation, and actions.
local VERSION='3.7.152'
ForeverHandheldPanels={active=false,roots={}}
local P=ForeverHandheldPanels
local configs={}
local function add(category,title,names,mode)
 for name in names:gmatch('%S+') do configs[name]={category=category,title=title,mode=mode or 'workspace'} end
end
add('CHARACTER','Character','CharacterFrame')
add('INSPECT','Inspect','InspectFrame')
add('ABILITIES','Spells & talents','PlayerSpellsFrame SpellBookFrame ClassTalentFrame TalentFrame PlayerTalentFrame')
add('JOURNAL','World & quests','WorldMapFrame QuestLogFrame')
add('COLLECTION','Collections','CollectionsJournal')
add('JOURNAL','Achievements','AchievementFrame')
add('JOURNAL','Legacy','LegacySystemFrame')
add('JOURNAL','Adventure guide','EncounterJournal')
add('SOCIAL','Friends & groups','FriendsFrame SocialUIFrame')
add('SOCIAL','Chat channels','ChannelFrame')
add('SOCIAL','Guild','GuildFrame CommunitiesFrame')
add('SOCIAL','Select an Icon','CommunitiesAvatarPickerDialog','native-header')
add('SOCIAL','Group finder','PVEFrame LFGListFrame LFDParentFrame LFGParentFrame')
add('SOCIAL','Battlegrounds','PVPUIFrame PVPFrame')
add('BATTLEGROUND','Match scoreboard','PVPMatchScoreboard')
add('BATTLEGROUND','Match results','PVPMatchResults')
add('SOCIAL','Raid','RaidParentFrame RaidFrame RaidInfoFrame')
add('TRADE','Merchant','MerchantFrame','paired')
add('MAILBOX','Mailbox','MailFrame','paired')
add('TRADE','Letter','OpenMailFrame','attached')
add('TRADE','Trade','TradeFrame','paired')
add('STORAGE','Bank','BankFrame','paired')
add('STORAGE','Guild bank','GuildBankFrame')
add('MARKET','Auction house','AuctionFrame AuctionHouseFrame','paired')
add('CONVERSATION','Conversation','GossipFrame QuestFrame','paired')
add('JOURNAL','Reading','ItemTextFrame')
add('TRAVEL','Flight routes','TaxiFrame FlightMapFrame')
add('COMPANIONS','Companions','PetStableFrame PetPaperDollFrame')
add('CHARACTER','Dressing room','DressUpFrame')
add('GUILD','Guild registration','GuildRegistrarFrame')
add('GUILD','Guild charter','PetitionFrame')
add('GUILD','Guild tabard','TabardFrame')
add('WORKSHOP','Professions','TradeSkillFrame CraftFrame ProfessionsBookFrame')
add('TRAINING','Trainer','ClassTrainerFrame','paired')
add('SYSTEM','Game menu','GameMenuFrame','menu')
add('SYSTEM','Layout editor','EditModeManagerFrame','layout-editor')
add('SYSTEM','Layout dialog','EditModeImportLayoutDialog EditModeLayoutDialog EditModeUnsavedChangesDialog EditModeSystemSettingsDialog','native-dialog')
add('SYSTEM','Settings','SettingsPanel InterfaceOptionsFrame VideoOptionsFrame AudioOptionsFrame')
add('COMMS','Chat settings','ChatConfigFrame')
add('CONTROLS','Key bindings','KeyBindingFrame')
add('CONTROLS','Click casting','ClickBindingFrame')
add('CONTROLS','Quick keybind','QuickKeybindFrame')
add('ABILITIES','Cooldown settings','CooldownViewerSettings')
add('CONTROLS','Macros','MacroFrame')
add('ADDONS','Addons','AddonList')
add('SUPPORT','Help','HelpFrame')
add('ADDONS','Questie','QuestieConfig QuestieQuestFrame QuestieDebugOfferFrame QuestieStandaloneSettings')
add('ADDONS','RestedXP','RXPGuidesSettingsFrame RXPG_MenuFrame RXPGuidesTrainerFrame')
add('ADDONS','RareScanner','RSImportNpcsFrame RareScannerTelemetryExportFrame')
add('JOURNEY','Nearby services','LorewardDirectionsWindow')
add('JOURNEY','Find a destination','LorewardFindWindow')
add('JOURNEY','Plan your journey','LorewardPlanWindow')
add('JOURNEY','Choose your next chapter','LorewardWhereNextBox')
add('JOURNEY','Journey preferences','LorewardSetupBox')
add('JOURNEY','Loreward community','LorewardDiscordBox')
-- Passive Loreward notes are mirrored into the journal, never a workspace.
add('JOURNEY','Story journal','ForeverHandheldStoryReader')
add('JOURNEY','Next chapter','ForeverHandheldJourneyNoticeWindow','existing')
add('DISCOVERIES','Rare loot','ForeverHandheldRareReaderWindow','existing')
add('INSPECTION','Field notes','ForeverHandheldFieldReaderWindow','existing')
add('CONTROLS','Controller settings','ControllerForeverMenu')
add('CONTROLS','Controller tutorial','ControllerForeverTutorial','native-header')
add('CONTROLS','Controller bindings','ControllerForeverShoulderSetup','native-header')
add('LOOT','Loot','LootFrame','compact')
-- The parent remains shown for the initiator while its listener prompt is
-- hidden. Decorate the actual response view, never that state-only parent.
add('GROUP','Group ready','LFGDungeonReadyDialog ReadyCheckListenerFrame','compact')
add('GROUP','Group invitation','LFGInvitePopup','compact')
add('SYSTEM','Confirm','StaticPopup1 StaticPopup2 StaticPopup3 StaticPopup4','compact')
for i=1,4 do add('LOOT','Loot roll','GroupLootFrame'..i,'compact') end
local skins=setmetatable({},{__mode='k'})
local gold={.72,.60,.39,1}
local cream={.94,.90,.82,1}
local function safe(x) return not (issecretvalue and issecretvalue(x)) end
local function visible(f)
 if not f or not f.IsVisible or (f.IsForbidden and f:IsForbidden()) or not f:IsVisible() then return false end
 -- CF keeps the native bank open to retain the banker session, but fades
 -- its paint with an animation. GetAlpha can still read 1 during that fade.
 -- Our opaque paired header must follow the owner's explicit fade state.
 local kit=ControllerForever and ControllerForever.Kit
 local fade=kit and kit.fades and kit.fades[f]
 if fade and fade.on then return false end
 local alpha=f.GetEffectiveAlpha and f:GetEffectiveAlpha() or f:GetAlpha()
 return safe(alpha) and alpha>.01
end
local function text(f,value,x,y,size)
 local t=f:CreateFontString(nil,'OVERLAY');t:SetFont(STANDARD_TEXT_FONT,size,'');t:SetTextColor(unpack(cream));t:SetJustifyH('LEFT');t:SetPoint('TOPLEFT',x,-y);t:SetText(value);return t
end
local function line(f,a,b,vertical)
 local t=f:CreateTexture(nil,'BORDER');t:SetColorTexture(unpack(gold));t:SetPoint(unpack(a));t:SetPoint(unpack(b));if vertical then t:SetWidth(1) else t:SetHeight(1) end;return t
end
local function edge(f)
 line(f,{'TOPLEFT',0,0},{'TOPRIGHT',0,0})
 line(f,{'TOPLEFT',0,0},{'BOTTOMLEFT',0,0},true)
 line(f,{'TOPRIGHT',0,0},{'BOTTOMRIGHT',0,0},true)
end
local function avatarHeader(root,c)
 if skins[root] or (root.IsProtected and root:IsProtected()) then return end
 local instructions=COMMUNITIES_CREATE_DIALOG_AVATAR_PICKER_INSTRUCTIONS
 if type(instructions)~='string' or not safe(instructions) then return end
 for _,region in ipairs({root:GetRegions()}) do
  local label=region:IsObjectType('FontString') and region:GetText()
  if safe(label) and label==instructions then
   local header=CreateFrame('Frame','ForeverHandheldCommunityAvatarHeader',root)
   header:EnableMouse(false)
   header:SetPoint('TOPLEFT',root,'TOPLEFT',2,-2)
   header:SetPoint('TOPRIGHT',root,'TOPRIGHT',-2,-2)
   header:SetHeight(58)
   header:SetFrameLevel(root:GetFrameLevel()+1)
   local kicker=text(header,'F O R E V E R  /  '..c.category,18,8,10)
   kicker:SetTextColor(unpack(gold))
   text(header,instructions,18,24,22)
   line(header,{'BOTTOMLEFT',18,0},{'BOTTOMRIGHT',-18,0})
   region:SetAlpha(0)
   skins[root]={frame=header}
   return
  end
 end
end
local function make(root,c,name)
 local f=CreateFrame('Frame','ForeverHandheldPanel'..name,root);f:EnableMouse(false)
 -- Native paired panels dim when inventory owns focus. Keep the title opaque
 -- so the HUD behind it cannot show through; native controls still dim normally.
 if c.mode=='paired' then f:SetIgnoreParentAlpha(true) end
 -- Edit Mode opens native DIALOG-level popups at level100. Its external
 -- title needs only to sit above its level1 owner, not above those popups.
 f:SetFrameLevel(root:GetFrameLevel()+(name=='EditModeManagerFrame' and 1 or 200))
 local compact=c.mode=='compact'
 local h=compact and 28 or 64
 f:SetPoint('BOTTOMLEFT',root,'TOPLEFT',0,0);f:SetPoint('BOTTOMRIGHT',root,'TOPRIGHT',0,0);f:SetHeight(h)
 local bg=f:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(.025,.030,.029,1)
 edge(f);line(f,{'BOTTOMLEFT',12,0},{'BOTTOMRIGHT',-12,0})
 local kicker=text(f,'F O R E V E R  /  '..c.category,18,compact and 8 or 8,compact and 10 or 10)
 kicker:SetTextColor(unpack(gold))
 local title
 if not compact then
  title=text(f,c.title,18,26,25);title:SetPoint('RIGHT',-18,0);title:SetMaxLines(1)
 end
 return {frame=f,title=title,baseScale=root:GetScale(),height=h,name=name,mode=c.mode}
end
local function quietTitle(root,name)
 if name:match('^Loreward') and root.title and root.title.SetAlpha then root.title:SetAlpha(0) end
 -- MainMenuFrameTemplate's decorative Header remains visible after its text
 -- is hidden. It has no controls; the shared title above replaces it fully.
 if name=='GameMenuFrame' then
  if root.Header then root.Header:Hide() end
  -- The native outer focus outline includes a duplicate empty title tab.
  -- Individual buttons retain their own focus arrow and highlight.
  if root.FrameGlow then root.FrameGlow:Hide() end
 end
 if name=='QuickKeybindFrame' and root.Header then root.Header:SetAlpha(0) end
 if root.TitleContainer then root.TitleContainer:SetAlpha(0) end
 local t=root.TitleText or _G[name..'TitleText'];if t and t.SetAlpha then t:SetAlpha(0) end
 if root.PortraitContainer then root.PortraitContainer:SetAlpha(0) end
 if root.portrait then root.portrait:SetAlpha(0) end
 if root.Portrait then root.Portrait:SetAlpha(0) end
 local portrait=_G[name..'Portrait'];if portrait and portrait.SetAlpha then portrait:SetAlpha(0) end
 -- Dialog header is decorative; do not hide any title containing controls.
 if root.Header and root.Header.Text and root.Header.UpdateWidth then root.Header:SetAlpha(0) end
 if root.GetRegions then
  for _,r in ipairs({root:GetRegions()}) do
   if r.IsObjectType and r:IsObjectType('FontString') then
    local p,relative,rp,x,y=r:GetPoint(1)
    if r~=root.InstructionText and p=='TOP' and (relative==root or relative==nil) and type(y)=='number' and y<=0 and y>=-20 then r:SetAlpha(0) end
   end
  end
 end
end
local function center(root,x,y)
 local p,r,rp,px,py=root:GetPoint(1)
 if root:GetNumPoints()~=1 or p~='CENTER' or r~=UIParent or rp~='CENTER' or type(px)~='number' or type(py)~='number' or math.abs(px-x)>.01 or math.abs(py-y)>.01 then
  root:ClearAllPoints();root:SetPoint('CENTER',UIParent,'CENTER',x,y)
 end
end
local function menuGrid(root)
 local buttons={}
 for _,f in ipairs({root:GetChildren()}) do
  if f.GetText and visible(f) and type(f:GetText())=='string' and f:GetText()~='' and f:GetWidth()>80 then buttons[#buttons+1]=f end
 end
 if #buttons<3 then return end
 -- Native menu buttons are pooled and relabelled each time it opens.
 -- Sort current actions, never retain recycled button identities.
 local order={['options']=1,['shop']=2,['controller forever']=3,['addons']=4,['edit mode']=5,
  ['support']=6,['macros']=7,['log out']=8,['exit game']=9,['return to game']=10}
 local function label(f)return f:GetText():gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):lower()end
 table.sort(buttons,function(a,b)
  local x,y=label(a),label(b);local ax,by=order[x] or 50,order[y] or 50
  return ax==by and x<y or ax<by
 end)
 local s=skins[root];s.menuOrder=buttons
 local rows=math.ceil(#s.menuOrder/2);local h=rows*52+42
 if root:GetWidth()~=700 then root:SetWidth(700) end
 if math.abs(root:GetHeight()-h)>.1 then root:SetHeight(h) end
 for i,f in ipairs(s.menuOrder) do
  local col=math.floor((i-1)/rows);local row=(i-1)%rows
  local x=24+col*338;local y=-20-row*52
  local p,r,rp,px,py=f:GetPoint(1)
  if p~='TOPLEFT' or r~=root or px~=x or py~=y then f:ClearAllPoints();f:SetPoint('TOPLEFT',root,'TOPLEFT',x,y) end
  f:SetSize(314,42)
  local fs=f:GetFontString();if fs then local font,_,flags=fs:GetFont();fs:SetFont(font,16,flags) end
 end
end
local mailCount
local function minimumMailFont(region,minimum)
 if not region or not region.GetFont then return end
 local face,size,flags=region:GetFont()
 if safe(face) and safe(size) and type(face)=='string' and type(size)=='number' and size<minimum then
  region:SetFont(face,minimum,flags)
 end
end
local function paintMailField(field,caption,minimum)
 if not field or (field.IsForbidden and field:IsForbidden()) then return end
 minimumMailFont(field,minimum)
 if not caption or not field.GetRegions then return end
 for _,region in ipairs({field:GetRegions()})do
  if region:IsObjectType('FontString') then
   local value=region:GetText()
   if safe(value) and value==caption then
    minimumMailFont(region,minimum)
    region:SetTextColor(unpack(gold))
   end
  end
 end
end
local function mailbox(root,s)
 local compose=visible(_G.SendMailFrame)
 local inbox=visible(_G.InboxFrame)
 local title=compose and 'Send mail' or inbox and 'Inbox' or 'Mailbox'
 if s.mailTitle~=title then
  s.title:SetText(title)
  s.mailTitle=title
  if compose then
   paintMailField(_G.SendMailNameEditBox,_G.MAIL_TO_LABEL,16)
   paintMailField(_G.SendMailSubjectEditBox,_G.MAIL_SUBJECT_LABEL,16)
   paintMailField(_G.SendMailBodyEditBox,nil,18)
   paintMailField(_G.SendMailCostMoneyFrame,_G.SEND_MAIL_COST,14)
  end
 end
 local empty=mailCount==0 and inbox and not compose and
  not visible(_G.OpenMailFrame) and not visible(root.trialError)
 if empty and not s.mailEmpty then
  local card=CreateFrame('Frame','ForeverHandheldEmptyInbox',root)
  card:SetPoint('TOPLEFT',root,'TOPLEFT',12,-67)
  card:SetPoint('BOTTOMRIGHT',root,'BOTTOMRIGHT',-12,39)
  card:SetFrameLevel(root:GetFrameLevel()+45)
  card:EnableMouse(false)
  card.ForeverHandheldOwnedPresentation=true
  local fill=card:CreateTexture(nil,'BACKGROUND')
  fill:SetAllPoints(card);fill:SetColorTexture(.040,.045,.037,1)
  edge(card)
  local icon=card:CreateTexture(nil,'ARTWORK')
  icon:SetPoint('CENTER',card,'CENTER',0,23)
  icon:SetSize(38,38)
  icon:SetTexture('Interface\\Icons\\INV_Letter_15')
  icon:SetTexCoord(.08,.92,.08,.92)
  local label=text(card,'Inbox is empty',0,0,21)
  label:ClearAllPoints();label:SetPoint('TOP',icon,'BOTTOM',0,-12)
  label:SetJustifyH('CENTER')
  s.mailEmpty=card
 end
 if s.mailEmpty and s.mailEmpty:IsShown()~=empty then s.mailEmpty:SetShown(empty)end
end
local function decorate(root,c,name)
 local shown=visible(root)
 local previous=root and skins[root]
 if previous and c.mode=='paired' then previous.frame:SetShown(shown) end
 if not shown then return false end
 if name:match('^Loreward') and ForeverHandheldJourneyControls then ForeverHandheldJourneyControls.layout(root) end
 local ancestor=root:GetParent()
 while ancestor and ancestor~=UIParent do
  if configs[ancestor:GetName() or ''] then P.roots[root]=true;return false end
  ancestor=ancestor:GetParent()
 end
 local w,h=root:GetSize()
 if not safe(w) or not safe(h) or w<100 or h<50 then return false end
 if c.mode=='native-header' or c.mode=='native-dialog' then
  if name=='CommunitiesAvatarPickerDialog' then avatarHeader(root,c) end
  -- Enlarge the entire ordinary dialog, preserving native text, field and
  -- focus geometry together. Keep native anchors and the native modal layer.
  if c.mode=='native-dialog' and not (root.IsProtected and root:IsProtected()) then
   local target=math.min(1.3,(UIParent:GetWidth()-48)/w,(UIParent:GetHeight()-48)/h)
   if target>0 and math.abs(root:GetScale()-target)>.002 then root:SetScale(target)end
  end
  -- The tutorial continuously fits its own header, sample, steps and hints.
  -- A second external title/fit loop fights that owner and clips off-screen.
  -- Register it for Windows.lua's paint-only finish; retain all native geometry.
  P.roots[root]=true
  local ratio=root:GetEffectiveScale()/UIParent:GetEffectiveScale()
  local l,r,t,b=root:GetLeft(),root:GetRight(),root:GetTop(),root:GetBottom()
  local fits=l and r and t and b and safe(l) and safe(r) and safe(t) and safe(b) and
   l*ratio>=0 and r*ratio<=UIParent:GetWidth() and t*ratio<=UIParent:GetHeight() and b*ratio>=0
  ForeverHandheldDB=ForeverHandheldDB or {}
  ForeverHandheldDB.panelCoverage=ForeverHandheldDB.panelCoverage or {}
  ForeverHandheldDB.panelCoverage[name]={version=VERSION,seen=GetTime(),mode=c.mode,width=w,height=h,scale=root:GetScale(),fits=not not fits}
  return true
 end
 local s=skins[root]
 if not s then s=make(root,c,name);skins[root]=s end
 P.roots[root]=true
 if name=='MailFrame' then mailbox(root,s) end
 if name=='SocialUIFrame' then
  local label=root.GetTitleForSelectedTab and root:GetTitleForSelectedTab()
  local title=safe(label) and type(label)=='string' and label~='' and label or c.title
  local raid=root.RaidFrame
  if raid and visible(raid) then
   if title==c.title then title='Raid'end
   local description=raid.RaidDescription
   local face,size,flags=description:GetFont()
   if face and size<16 then description:SetFont(face,16,flags)end
   for _,button in ipairs({raid.RaidInfoButton,raid.ConvertToRaidButton})do
    local label=button and button.GetFontString and button:GetFontString()
    if label then local f,n,fl=label:GetFont();if f and n<14 then label:SetFont(f,14,fl)end end
   end
  end
  if s.socialTitle~=title then s.title:SetText(title);s.socialTitle=title end
 end
 if name=='ItemTextFrame' then
  local native=root.GetTitleText and root:GetTitleText() or root.TitleText
  local label=native and native.GetText and native:GetText()
  if s.title then s.title:SetText(safe(label) and type(label)=='string' and label~='' and label or c.title)end
 end
 if name=='InspectFrame' then
  local native=root.GetTitleText and root:GetTitleText() or root.TitleText
  local label=native and native.GetText and native:GetText()
  if s.title then s.title:SetText(safe(label) and type(label)=='string' and label~='' and label or c.title) end
  -- The client's rank text uses +10 below the season, overlapping it.
  -- Move only the text anchor; inspected values and native actions stay intact.
  local info=InspectPVPFrame and InspectPVPFrame.MainInfoFrame
  if info and info.CurrentSeasonField and info.CurrentRankField then
   local rank,season=info.CurrentRankField,info.CurrentSeasonField
   local a,b,cx,x,y=rank:GetPoint(1)
   if a~='TOP' or b~=season or cx~='BOTTOM' or x~=0 or y~=-10 then
    rank:ClearAllPoints();rank:SetPoint('TOP',season,'BOTTOM',0,-10)
   end
  end
 end
 if c.mode=='menu' then menuGrid(root);w,h=root:GetSize() end
 if c.mode~='compact' and c.mode~='attached' and c.mode~='existing' then
  quietTitle(root,name)
  local preferred=name:match('^Loreward') and math.max(s.baseScale,1.25) or s.baseScale
  -- These compact native forms were designed for desktop viewing. Scale the
  -- whole form so text, hit areas and native focus geometry stay aligned.
  if name=='GuildRegistrarFrame' or name=='PetitionFrame' or name=='TabardFrame' or name=='QuickKeybindFrame' or name=='MacroFrame' then preferred=math.max(s.baseScale,1.4) end
  local maxScale=math.min(preferred,(UIParent:GetWidth()-80)/w,(UIParent:GetHeight()-105)/(h+s.height))
  maxScale=math.max(.55,maxScale)
  if math.abs(root:GetScale()-maxScale)>.002 then root:SetScale(maxScale) end
  if c.mode=='paired' then
   -- Paired windows keep the native panel manager's horizontal arrangement.
   -- Only lift/lower if the new title would leave the screen.
   local top=root:GetTop();local ratio=root:GetEffectiveScale()/UIParent:GetEffectiveScale()
   if top and safe(top) and (top+s.height)*ratio>UIParent:GetHeight()-12 then
    local p,r,rp,x,y=root:GetPoint(1)
    if (r==UIParent or r==nil) and safe(y) then
     root:ClearAllPoints();root:SetPoint(p,r or UIParent,rp,x,y-((top+s.height)*ratio-UIParent:GetHeight()+14)/ratio)
    end
   end
  elseif c.mode~='layout-editor' then
   -- Edit Mode owns native dragging. Recentring each tick hides the very
   -- preview the user is trying to inspect and undoes their movement.
   local x=0
   local binding=_G.ClickBindingFrame
   local companion=visible(_G.PlayerSpellsFrame) and _G.PlayerSpellsFrame or (visible(_G.MacroFrame) and _G.MacroFrame)
   if visible(binding) and companion and (root==binding or root==companion) then
    -- Both native panels are needed to choose a spell/macro. Centering each
    -- independently obscures one; place the pair around their shared center.
    local peer=root==binding and companion or binding
    local peerWidth=peer:GetWidth()*peer:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local ratio=root:GetEffectiveScale()/UIParent:GetEffectiveScale()
    x=(root==binding and 1 or -1)*(peerWidth/2+8)/ratio
   end
   local opaque=visible(binding) and companion==root
   if s.companionOpaque~=not not opaque then
    s.frame:SetIgnoreParentAlpha(not not opaque);s.companionOpaque=not not opaque
   end
   center(root,x,-22)
  end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 local db=ForeverHandheldDB;db.panelCoverage=db.panelCoverage or {}
 local ratio=root:GetEffectiveScale()/UIParent:GetEffectiveScale()
 local l,r,t,b=root:GetLeft(),root:GetRight(),root:GetTop(),root:GetBottom()
 db.panelCoverage[name]={version=VERSION,seen=GetTime(),mode=c.mode,width=w,height=h,scale=root:GetScale(),
  fits=l and safe(l) and l*ratio>=-2 and r*ratio<=UIParent:GetWidth()+2 and (t+s.height)*ratio<=UIParent:GetHeight()+2 and b*ratio>=-2 or false}
 return true
end
local cfMarks=setmetatable({},{__mode='k'})
local bankLegends=setmetatable({},{__mode='k'})
local nativeFooters={
 {root='BankFrame',name='ForeverHandheldNativeBankFooter',width=300,back='Close bank',diagnostic='nativeBankFooter'},
 {root='DressUpFrame',name='ForeverHandheldDressingRoomFooter',width=244,back='Close preview',diagnostic='dressingRoomFooter'},
 {root='SocialUIFrame',name='ForeverHandheldSocialFooter',width=310,back='Close',navigation=true,diagnostic='socialFooter'},
}
local function hasStaticPopup()
 for i=1,4 do if visible(_G['StaticPopup'..i]) then return true end end
 return false
end
P.hasStaticPopup=hasStaticPopup
local function nativeFooterOwner(combat)
 local nav=_G.SmartNavigation
 local kit=ControllerForever and ControllerForever.Kit
 return not combat and nav and nav.GetActiveFrame and InputUtil and InputUtil.IsGamepadUIEnabled and
  InputUtil.IsGamepadUIEnabled() and not (kit and kit.typing and kit.typing()) and not hasStaticPopup() and nav:GetActiveFrame()
end
local function focusedFriendCard(owner,selected)
 if owner~=_G.SocialUIFrame or not visible(owner) or not visible(selected) or
    type(selected.OpenMenu)~='function' or not selected.IsObjectType or not selected:IsObjectType('Button') then return end
 local list=owner.FriendsList
 if not visible(list) or (selected.HasAccessConstraints and selected:HasAccessConstraints()) then return end
 local forbidden=Enum and Enum.ForbiddenAspect and Enum.ForbiddenAspect.ScriptedInput
 if forbidden and selected.HasAnyForbiddenAspects and selected:HasAnyForbiddenAspects(forbidden) then return end
 if selected.IsEnabled and not selected:IsEnabled() then return end
 local parent=selected:GetParent()
 for _=1,16 do
  if not parent or parent==owner then return end
  if parent==list then return selected end
  parent=parent:GetParent()
 end
end
local friendActionsButton,friendActionsClaim,friendActionRow
local function bindFriendActions(row,combat)
 if combat then return false end
 if not row and not friendActionRow then return false end
 if not friendActionsButton then
  local binds=ControllerForever and ControllerForever.Binds
  if not binds or not binds.claimant or not binds.PRIORITY then return false end
  local button=CreateFrame('Button','ForeverHandheldFriendActionsButton',UIParent,'SecureActionButtonTemplate')
  button:RegisterForClicks('RightButtonUp')
  button:SetAttribute('useOnKeyDown',false)
  button:SetAttribute('type2','click')
  button:SetScript('PreClick',function(self)
   if InCombatLockdown() then return end
   local owner=nativeFooterOwner(false)
   local nav=_G.SmartNavigation
   local selected=owner and nav.GetCurrentButton and nav:GetCurrentButton()
   -- A focus change and X can arrive in the same frame. Disarm a stale
   -- delegate rather than opening the previous friend's menu.
   if focusedFriendCard(owner,selected)~=friendActionRow then self:SetAttribute('clickbutton2',nil)end
  end)
  friendActionsButton=button
  friendActionsClaim=binds:claimant('forever-handheld-friend-actions',binds.PRIORITY.gamewindow+3,{overGame=true,outOfFight=true})
 end
 if friendActionsButton:GetAttribute('clickbutton2')~=row then
  friendActionsButton:SetAttribute('clickbutton2',row)
 end
 if (row~=nil)~=(friendActionRow~=nil) then
  if row then friendActionsClaim.set('PAD3','CLICK ForeverHandheldFriendActionsButton:RightButton')
  else friendActionsClaim.clear()end
  friendActionsClaim.commit()
 end
 friendActionRow=row
 return row~=nil
end
local function updateNativeFooters(combat)
 local nav=_G.SmartNavigation
 local active=nativeFooterOwner(combat)
 local selected=active and nav.GetCurrentButton and nav:GetCurrentButton()
 local friendActions=bindFriendActions(focusedFriendCard(active,selected),combat)
 for _,spec in ipairs(nativeFooters)do
  local owner,footer=_G[spec.root],spec.frame
  if active and owner==active and visible(owner) then
   if not footer then
    footer=CreateFrame('Frame',spec.name,owner)
    footer:EnableMouse(false);footer:SetPoint('TOPLEFT',owner,'BOTTOMLEFT',0,-4);footer:SetSize(spec.width,32)
    footer:SetFrameLevel(owner:GetFrameLevel()+2)
    local bg=footer:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(footer);bg:SetColorTexture(.025,.030,.029,1)
    edge(footer);line(footer,{'BOTTOMLEFT',0,0},{'BOTTOMRIGHT',0,0})
    footer.hint=text(footer,'',12,8,15)
    spec.frame=footer
   end
   local selectHint=false
   if visible(selected) then
    local enabled=not selected.IsEnabled or selected:IsEnabled()
    selectHint=safe(enabled) and enabled
   end
   local bags=false
   if spec.root=='BankFrame' then
    bags=visible(_G.ContainerFrameCombinedBags)
    if not bags then
     for i=1,13 do if visible(_G['ContainerFrame'..i]) then bags=true;break end end
    end
   end
   local navigation=spec.navigation and '|cfff0cf88D-pad|r Navigate     ' or ''
   local actions=spec.root=='SocialUIFrame' and friendActions
   local hint=navigation..(selectHint and '|cfff0cf88A|r Select     ' or '')..
    (actions and '|cfff0cf88X|r Actions     ' or '')..(bags and '|cfff0cf88RT|r Bags     ' or '')..'|cfff0cf88B|r '..spec.back
   if footer.caption~=hint then footer:SetWidth(spec.width+(actions and 88 or 0));footer.hint:SetText(hint);footer.caption=hint end
   if not footer:IsShown() then footer:Show()end
   ForeverHandheldDB=ForeverHandheldDB or {}
   ForeverHandheldDB[spec.diagnostic]=VERSION
  elseif footer and footer:IsShown() then footer:Hide()end
 end
end
local function bankLegend(inst)
 local cf=ControllerForever;local kit=cf and cf.Kit
 local zone=inst.zones and inst.zones.legend
 if not zone or not zone.text then return end
 local s=bankLegends[inst.frame]
 local bank=cf.Inv and cf.Inv.bankView
 local active=bank and kit and kit.top and kit.top(inst)==bank and not (kit.typing and kit.typing())
 local entries=active and kit.legendOf and kit.legendOf(inst)
 -- The bank supplies seven hints, with B last. Kit's six-entry drawing cap
 -- drops it. Mirror the same contextual entries in two rows; no key routing,
 -- transactions, view stack or owner preferences are changed.
 if type(entries)~='table' or #entries<=6 or not kit.glyphs then
  if s then s.text:Hide();zone.text:SetAlpha(s.alpha)end
  return
 end
 if not s then
  local t=zone:CreateFontString(nil,'OVERLAY');t:SetFont(STANDARD_TEXT_FONT,15.5,'OUTLINE')
  t:SetTextColor(unpack(cream));t:SetPoint('CENTER',zone,'CENTER',0,-2)
  t:SetMaxLines(2);t:SetJustifyH('CENTER')
  s={text=t,alpha=zone.text:GetAlpha()};bankLegends[inst.frame]=s
 end
 s.text:SetWidth(math.max(100,zone:GetWidth()-36))
 local pieces={}
 local waiting=inst.state and inst.state.waitShownAt and kit.now and kit.now()-inst.state.waitShownAt<.6
 for i,entry in ipairs(entries)do
  if i>12 then break end
  local label=tostring(entry.label or '')
  if entry.grey then label='|cff8a8580'..label..'|r'end
  if waiting and (entry.key=='A' or entry.key=='X' or entry.key=='Y') then label=label..' |cffa8a29a(a moment)|r'end
  pieces[#pieces+1]=kit.glyphs(entry.key,15.5)..' '..label
 end
 local split=math.ceil(#pieces/2)
 local value=table.concat(pieces,'    ',1,split)..'\n'..table.concat(pieces,'    ',split+1)
 if s.value~=value then s.text:SetText(value);s.value=value end
 zone.text:SetAlpha(0);s.text:Show()
end
local parkedInventory,parkedScreen,inventoryResume
local parkedFrames,resumeClaim,resumeBound
local function isFadedInventory(kit,frame)
 local fade=frame and kit.fades and kit.fades[frame]
 if not fade or not fade.on then return end
 local name=frame.GetName and frame:GetName()
 if type(name)=='string' and (name=='BankFrame' or name=='ContainerFrameCombinedBags' or name:match('^ContainerFrame%d+$')) then return name end
end
local function removeParkedFocus(kit,inv)
 local manager=GamepadMode and GamepadMode.FrameControlsManager
 local binds=ControllerForever.Binds
 if not manager or manager.isUIFocused or not manager.FrameHidden or not manager.FrameShown or
    not inv.holdBack or not binds or not binds.claimant or type(manager.shownFrames)~='table' or
    (GetCursorInfo and GetCursorInfo()) or (SpellCanTargetItem and SpellCanTargetItem()) then return end
 local frames={}
 for _,frame in ipairs(manager.shownFrames)do
  if not isFadedInventory(kit,frame) then return end
  frames[#frames+1]=frame
 end
 if #frames==0 then return end
 -- The inventory is already out of UI focus after View. Unregister its
 -- faded native panels for the duration of Play so menu close cannot select
 -- them. Keep the actual frames and the bank or bag session open.
 parkedFrames={manager=manager}
 for _,frame in ipairs(frames)do
  if manager:FrameHidden(frame) then parkedFrames[#parkedFrames+1]=frame end
 end
 if #parkedFrames==0 then parkedFrames=nil;return end
 inv.holdBack(false)
 ForeverHandheldDB.inventoryPlay.detached=#parkedFrames
end
local function restoreParkedFocus()
 local parked=parkedFrames
 if not parked then return end
 parkedFrames=nil
 local manager=GamepadMode and GamepadMode.FrameControlsManager
 if manager~=parked.manager then return end
 for _,frame in ipairs(parked)do
  if frame:IsShown() then manager:FrameShown(frame,false,false) end
 end
end
local function bindInventoryResume(wanted)
 wanted=not not wanted
 if wanted==not not resumeBound then return end
 if not resumeClaim then
  local binds=ControllerForever.Binds
  local button=CreateFrame('Button','ForeverHandheldInventoryResumeButton',UIParent)
  button:RegisterForClicks('AnyDown')
  button:SetScript('OnClick',function()
   if not resumeBound or InCombatLockdown() or not parkedInventory or parkedInventory.away~='focus' then return end
   local inv,kit=ControllerForever.Inv,ControllerForever.Kit
   restoreParkedFocus()
   inv.endVisit(parkedInventory)
   if kit.back(parkedInventory) then ForeverHandheldDB.inventoryPlay.explicitResume=true end
  end)
  resumeClaim=binds:claimant('forever-handheld-inventory-resume',binds.PRIORITY.gamewindow+3,{overGame=true,outOfFight=true})
 end
 if wanted then resumeClaim.set('PADBACK','CLICK ForeverHandheldInventoryResumeButton:LeftButton') else resumeClaim.clear()end
 resumeBound=wanted
 resumeClaim.commit()
end
local function resumeRefocusedInventory(kit,inv,inst)
 if visible(_G.GamepadRadial) or not (inv and inv.endVisit and kit.back) then return end
 local manager=GamepadMode and GamepadMode.FrameControlsManager
 local focused=manager and manager.isUIFocused and manager.GetActiveFrame and manager:GetActiveFrame()
 local name=isFadedInventory(kit,focused)
 if not name then return end
 -- The radial can refocus the faded native inventory on close. Resume the
 -- corresponding visible inventory using the same path as its View binding.
 inv.endVisit(inst)
 if not kit.back(inst) then return end
 ForeverHandheldDB.inventoryPlay.resumedFocus=name
 return true
end
local function updateInventoryPlay(combat)
 local cf=ControllerForever
 local kit=cf and cf.Kit
 local inst=kit and kit.live and kit.live.bags
 local frame=inst and inst.frame
 local plain=frame
  and not (frame.IsForbidden and frame:IsForbidden()) and not (frame.IsProtected and frame:IsProtected())
 local playing=plain and inst.open and inst.mode=='live' and inst.away=='focus'
 if parkedInventory and (parkedInventory~=inst or not playing) then
  -- Kit.back and Kit.open show their own frame. The combat inventory can
  -- take over an already-open Bags frame without showing it again.
  if parkedInventory==inst and plain and inst.open and inst.fightMode and not frame:IsShown() then
   frame:Show()
  end
  parkedInventory,parkedScreen=nil,nil
 end
 if not playing then return end
 if not combat and frame:IsShown() then
  -- Hide the plain inventory frame so its item buttons also leave hit-testing.
  -- Kit retains the open session, selected item, and native View binding.
  frame:Hide()
  parkedInventory=inst
  local view=kit.top and kit.top(inst)
  local bank=cf.Inv and cf.Inv.bankView
  parkedScreen=bank and view==bank and 'Bank' or 'Bags'
  ForeverHandheldDB=ForeverHandheldDB or {}
  ForeverHandheldDB.inventoryPlay={version=VERSION,screen=parkedScreen}
  removeParkedFocus(kit,cf.Inv)
 end
 if parkedInventory==inst and not combat then
  if not parkedFrames and resumeRefocusedInventory(kit,cf.Inv,inst) then
   parkedInventory,parkedScreen=nil,nil
   return
  end
  return parkedScreen
 end
end
local function showInventoryResume(screen)
 if screen and not inventoryResume then
  local chip=CreateFrame('Frame','ForeverHandheldInventoryResume',UIParent)
  chip:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',20,194);chip:SetSize(156,28)
  chip:SetFrameStrata('LOW');chip:EnableMouse(false)
  local bg=chip:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(chip);bg:SetColorTexture(.025,.030,.029,.92)
  edge(chip);line(chip,{'BOTTOMLEFT',0,0},{'BOTTOMRIGHT',0,0})
  chip.hint=text(chip,'',0,0,14);chip.hint:ClearAllPoints();chip.hint:SetPoint('CENTER',chip,'CENTER');chip.hint:SetJustifyH('CENTER')
  inventoryResume=chip
 end
 if not inventoryResume then return end
 if screen and screen~=inventoryResume.screen then
  inventoryResume.hint:SetText('|cfff0cf88View|r  Resume '..screen:lower());inventoryResume.screen=screen
 end
 local shown=screen~=nil
 if inventoryResume:IsShown()~=shown then inventoryResume:SetShown(shown)end
end
local inventoryLabels=setmetatable({},{__mode='k'})
local function fitInventorySections(inst)
 local rows=inst.column and inst.column.rows
 if not rows then return end
 for _,row in ipairs(rows)do
  local label,count=row.name,row.count
  if label and count and visible(row) then
   local last=inventoryLabels[label]
   if not last then
    label:SetMaxLines(1);label:SetWordWrap(false)
    count:ClearAllPoints();count:SetPoint('RIGHT',row,'RIGHT',-8,0)
   end
   local countWidth=count:GetStringWidth()
   -- The owner puts the label 48 units from the left, after the icon.
   local width=math.max(1,math.floor(row:GetWidth()-48-8-countWidth-(countWidth>0 and 5 or 0)))
   local value,scale=label:GetText(),row:GetEffectiveScale()
   if not last or last.width~=width or last.value~=value or last.scale~=scale then
    local font,size,flags=label:GetFont()
    local measured=label:GetUnboundedStringWidth()
    local fit=measured>0 and math.max(13,math.min(16,math.floor(size*(width-1)/measured))) or 16
    if fit~=size then label:SetFont(font,fit,flags)end
    if math.abs(label:GetWidth()-width)>.1 then label:SetWidth(width)end
    inventoryLabels[label]={width=width,value=value,scale=scale}
   end
  end
 end
end
local serviceBagsHint
local function updateServiceBagsHint(inst,covered)
 local frame=inst and inst.away=='visit' and inst.frame
 local shown=not covered and visible(frame) and not hasStaticPopup() and
  not visible(_G.ControllerForeverChatEdit) and not (ForeverHandheldComms and ForeverHandheldComms.active)
 if shown then
  if not serviceBagsHint then
   local hint=CreateFrame('Frame','ForeverHandheldServiceBagsHint',UIParent)
   hint:SetSize(114,30);hint:SetFrameStrata('MEDIUM');hint:SetClampedToScreen(true);hint:EnableMouse(false)
   local bg=hint:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(hint);bg:SetColorTexture(.025,.030,.029,.95)
   edge(hint);line(hint,{'BOTTOMLEFT',0,0},{'BOTTOMRIGHT',0,0})
   text(hint,'|cfff0cf88RT|r  Bags',12,7,15)
   serviceBagsHint=hint
  end
  if serviceBagsHint.owner~=frame then
   serviceBagsHint:ClearAllPoints();serviceBagsHint:SetPoint('TOPRIGHT',frame,'BOTTOMRIGHT',0,-5)
   serviceBagsHint.owner=frame
  end
 end
 if serviceBagsHint and serviceBagsHint:IsShown()~=not not shown then serviceBagsHint:SetShown(not not shown)end
end
local bagsPreviewLayer
local function placeBagsBelowPreview(inst,combat)
 local frame=inst and inst.frame
 local preview=_G.DressUpFrame
 local covered=not combat and visible(frame) and visible(preview) and
  not (frame.IsProtected and frame:IsProtected())
 if bagsPreviewLayer and (not covered or bagsPreviewLayer.frame~=frame) then
  local previous=bagsPreviewLayer.frame
  if not (previous.IsForbidden and previous:IsForbidden()) and not (previous.IsProtected and previous:IsProtected()) then
   previous:SetFrameStrata(bagsPreviewLayer.strata)
  end
  bagsPreviewLayer=nil
 end
 if not covered then return end
 local strata=preview:GetFrameStrata()=='LOW' and 'BACKGROUND' or 'LOW'
 if not bagsPreviewLayer then bagsPreviewLayer={frame=frame,strata=frame:GetFrameStrata()} end
 if frame:GetFrameStrata()~=strata then frame:SetFrameStrata(strata)end
end
local function cfWindow(inst)
 if not inst or not visible(inst.frame) or not inst.zones or not inst.zones.header then return false end
 local f,h=inst.frame,inst.zones.header
 P.roots[f]=true
 local tag=cfMarks[f]
 if not tag then
  local shell=CreateFrame('Frame',nil,h);shell:SetAllPoints(h);shell:EnableMouse(false);shell:SetFrameLevel(h:GetFrameLevel()+8)
  tag=text(shell,'F O R E V E R  /  '..(inst.id=='bags' and 'INVENTORY' or 'MARKET'),24,6,10);tag:SetTextColor(unpack(gold));cfMarks[f]=tag
 end
 if h.logo then h.logo:SetAlpha(0) end
 if h.title then
  h.title:ClearAllPoints();h.title:SetPoint('TOPLEFT',h,'TOPLEFT',24,-23)
  local font,_,flags=h.title:GetFont();h.title:SetFont(font,25,flags)
 end
 if h.band then h.band:SetColorTexture(.055,.062,.057,1) end
 if inst.id=='bags' then
  bankLegend(inst)
  fitInventorySections(inst)
 end
 ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.panelCoverage=ForeverHandheldDB.panelCoverage or {}
 ForeverHandheldDB.panelCoverage[f:GetName() or ('sample-'..(inst.id or 'window'))]={version=VERSION,seen=GetTime(),mode=inst.mode or 'live',width=f:GetWidth(),height=f:GetHeight()}
 return true
end
local auctionLayer
local auctionContinue
local hookedCommodity
local function styleAuctionCommodity(ah,sheet)
 local f=sheet.f
 if not visible(f) or not f.total or not f.limit then return end
 local total=f.total:GetText()
 if safe(total) and type(total)=='string' then
  local compact=total:gsub('(|TInterface\\MoneyFrame\\UI%-%a+Icon:)%d+:%d+(:[^|]*|t)',function(prefix,suffix)
   return prefix..'15:15'..suffix
  end)
  if compact~=total then f.total:SetText(compact) end
 end
 if ah.get('confirm')=='limit' then return end
 local win=ah.win
 local over=win.tr('Over your %s limit: A gets the price, A again buys.')
 local line=f.limit:GetText()
 if safe(line) and line==string.format(over,win.money(ah.get('limit'),{letters=true})) then
  f.limit:SetText(win.tr('A gets the price. A again buys.'))
 end
end
local function auctionWindow()
 local cf=ControllerForever
 local ah=cf and cf.AH
 local state=ah and ah.win and ah.win.state
 local f=state and state.frame
 if not f then return false end
 local sell=cf.AH.views and cf.AH.views['sell.list']
 local cards=sell and sell.ui and sell.ui.cards
 if cards and cards.hint then
  -- Rear buttons belong to voice/chat/mouse in this setup. Sell already
  -- supports section changes on Left/Right and paging on LT/RT.
  cards.hint:SetText('D-pad Left / Right: sections\nLT / RT: page')
 end
 local help=cf.AH.views and cf.AH.views.help
 if help and help.card and help.card.ok and not auctionContinue then
  -- The native help draws its A prompt as text, with no pointer target.
  -- A transparent button over that prompt offers the identical help-only
  -- action to touch/mouse users; controller routing stays with the owner.
  auctionContinue=CreateFrame('Button','ForeverHandheldAuctionContinue',help.card)
  auctionContinue:SetSize(160,36)
  auctionContinue:SetPoint('CENTER',help.card.ok,'CENTER',0,0)
  auctionContinue:SetScript('OnClick',function()
   if not InCombatLockdown() and visible(f) and visible(help.card) and
    cf.AH.win.current and cf.AH.win.current()==help and help.onKey then help.onKey('A') end
  end)
 end
 if not visible(f) then
  if auctionLayer and auctionLayer.frame==f then
   f:SetFrameLevel(auctionLayer.level);auctionLayer=nil
  end
  return false
 end
 local commodity=ah.views and ah.views['buy.commodity']
 if commodity and commodity~=hookedCommodity and type(commodity.refresh)=='function' then
  local function paint()
   local ok,err=pcall(styleAuctionCommodity,ah,commodity)
   if not ok then
    ForeverHandheldDB=ForeverHandheldDB or {}
    ForeverHandheldDB.auctionCommodityError=tostring(err)
   end
  end
  hooksecurefunc(commodity,'refresh',paint)
  hookedCommodity=commodity
  paint()
 end
 -- This controller window already has its own fitted header. Reuse it,
 -- rather than attaching a second title outside the native screen bounds.
 local bags=_G.ControllerForeverWin_bags
 if bags and visible(bags) then
  auctionLayer=auctionLayer or {frame=f,level=f:GetFrameLevel()}
  -- Controller Bags intentionally stays drawn while another window owns
  -- focus. Its full-screen form must be behind the auction workspace.
  -- Only presentation changes: the owners retain visibility and bindings.
  local wanted=math.max(auctionLayer.level,bags:GetFrameLevel()+100)
  if f:GetFrameLevel()~=wanted then f:SetFrameLevel(wanted) end
 elseif auctionLayer then
  f:SetFrameLevel(auctionLayer.level);auctionLayer=nil
 end
 return cfWindow({id='auction',frame=f,zones=state.zones,mode='live'})
end
-- AceGUI containers can be anonymous. Discover them through their library,
-- not a periodic sweep of the entire (very large) game global table.
local aceFrames=setmetatable({},{__mode='k'})
local aceHooked,aceNumber=nil,0
local function observeAce(widget)
 if type(widget)~='table' or (widget.type~='Frame' and widget.type~='Window') then return end
 local f=widget.frame;if not f or aceFrames[f] then return end
 aceNumber=aceNumber+1
 aceFrames[f]={name='AddonWindow'..aceNumber,category='ADDONS',title='Addon settings',mode='workspace'}
end
local function discoverAce()
 if not LibStub then return end
 local ace=LibStub('AceGUI-3.0',true)
 if ace and ace~=aceHooked and hooksecurefunc and ace.RegisterAsContainer then
  hooksecurefunc(ace,'RegisterAsContainer',function(_,widget)observeAce(widget)end)
  aceHooked=ace
 end
 if ace then
  for _,kind in ipairs({'Frame','Window'}) do
   for widget in pairs(ace.objPools and ace.objPools[kind] or {}) do observeAce(widget) end
  end
 end
 local dialog=LibStub('AceConfigDialog-3.0',true)
 for _,widget in pairs(dialog and dialog.OpenFrames or {}) do observeAce(widget) end
 -- Questie supplies its own root to AceConfigDialog, so it is neither in
 -- OpenFrames nor the released-widget pool when already created at startup.
 local questie=_G.QuestieConfigFrame
 observeAce(questie)
 if questie and questie.frame and aceFrames[questie.frame] then aceFrames[questie.frame].title='Questie' end
end
-- Native tutorial pages sometimes dock above the action bars to demonstrate
-- them. Keep modal ownership separate from whether those pages cover our dock.
local function coversDock(root,c)
 if c.mode~='native-header' then return true end
 local dock=_G.ForeverHandheldDock
 if not dock or (dock.IsForbidden and dock:IsForbidden()) then return true end
 local bottom,top=root:GetBottom(),dock:GetTop()
 local rs,ds=root:GetEffectiveScale(),dock:GetEffectiveScale()
 for _,v in ipairs({bottom,top,rs,ds})do
  if not safe(v) or type(v)~='number' or v~=v then return true end
 end
 if not bottom or not top or not rs or not ds or rs<=0 or ds<=0 then return true end
 return bottom*rs < top*ds+8
end
local tick,discovered=0,0
local resetDiagnostics=true
local driver=CreateFrame('Frame')
driver:RegisterEvent('PLAYER_LOGIN')
driver:RegisterEvent('MAIL_SHOW')
driver:RegisterEvent('MAIL_INBOX_UPDATE')
driver:RegisterEvent('MAIL_CLOSED')
driver:SetScript('OnEvent',function(_,event)
 if event=='PLAYER_LOGIN' then
  local nav=_G.SmartNavigation
  local pending
  local function socialFocusChanged()
   if pending or (not friendActionRow and not visible(_G.SocialUIFrame)) then return end
   pending=true
   C_Timer.After(0,function()
    pending=false
    local ok,err=pcall(updateNativeFooters,InCombatLockdown())
    if not ok then
     ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.socialActionsError=tostring(err)
    end
   end)
  end
  if nav and nav.RegisterCallback then nav:RegisterCallback('SelectedButtonUpdated',socialFocusChanged,driver)end
  if EventRegistry then EventRegistry:RegisterCallback('Gamepad.RefreshFrameFocus',socialFocusChanged,driver)end
  return
 end
 if event~='MAIL_INBOX_UPDATE' then mailCount=nil;return end
 local count=GetInboxNumItems and GetInboxNumItems()
 mailCount=safe(count) and type(count)=='number' and count or nil
end)
driver:SetScript('OnUpdate',function(_,dt)
 tick=tick+dt;if tick<.25 then return end;tick=0
 -- SavedVariables can arrive after Lua files execute. Reset prior errors
 -- once the session starts so subsequent failures remain available.
 if resetDiagnostics then
  resetDiagnostics=false
  ForeverHandheldDB=ForeverHandheldDB or {}
  ForeverHandheldDB.panelError=nil
  ForeverHandheldDB.auctionCommodityError=nil
 end
 local combat=InCombatLockdown()
 local ok,err=pcall(function()
  local cf=ControllerForever
  local kit=cf and cf.Kit
  local bags=kit and kit.live and kit.live.bags
  placeBagsBelowPreview(bags,combat)
  local inventoryScreen=updateInventoryPlay(combat)
  if parkedFrames and not inventoryScreen and not combat then restoreParkedFocus() end
  updateNativeFooters(combat)
  if combat then
   bindInventoryResume(false)
   showInventoryResume(nil)
   updateServiceBagsHint(nil,true)
   return
  end
  -- The radial's lower native shortcuts occupy the same space as the dock.
  -- Keep the world controls out of view until the radial relinquishes input.
  local radialShown=visible(_G.GamepadRadial)
  local active,dockCovered=radialShown,radialShown
  discovered=discovered+.25
  if discovered>2 then
   discovered=0
   for name in pairs(UIPanelWindows or {}) do
    if not configs[name] and name~='ProfessionsFrame' and name~='ReadyCheckFrame' and not name:find('ContainerFrame') then configs[name]={category='WORLD',title=name:gsub('Frame$',''):gsub('(%l)(%u)','%1 %2'),mode='workspace'} end
   end
   discoverAce()
  end
  local visited={}
  for name,c in pairs(configs) do
   if name~='ProfessionsFrame' then
    if _G[name] then visited[_G[name]]=true end
    local good,on=pcall(decorate,_G[name],c,name)
    if not good then
     ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.panelErrors=ForeverHandheldDB.panelErrors or {};ForeverHandheldDB.panelErrors[name]=tostring(on)
    elseif on and c.mode~='compact' and c.mode~='attached' then
     active=true;if coversDock(_G[name],c) then dockCovered=true end
    end
   end
  end
  for f,c in pairs(aceFrames) do
   if not visited[f] then
    local good,on=pcall(decorate,f,c,c.name)
    if not good then
     ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.panelErrors=ForeverHandheldDB.panelErrors or {};ForeverHandheldDB.panelErrors[c.name]=tostring(on)
    elseif on then active=true;dockCovered=true end
   end
  end
  if auctionWindow() then active=true;dockCovered=true end
  if kit then
   for _,inst in pairs(kit.live or {}) do if cfWindow(inst) then active=true;dockCovered=true end end
   for _,inst in pairs(kit.samples or {}) do cfWindow(inst) end
  end
  updateServiceBagsHint(bags,radialShown or visible(_G.DressUpFrame))
  P.active=active;P.dockCovered=dockCovered
  local showResume=inventoryScreen and not active and not visible(_G.ProfessionsFrame) and not hasStaticPopup() and
   not (ForeverHandheldComms and ForeverHandheldComms.active)
  bindInventoryResume(showResume and parkedFrames)
  showInventoryResume(showResume and inventoryScreen or nil)
 end)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.panelError=tostring(err) end
end)
P.configs=configs
P.aceFrames=aceFrames
pcall(discoverAce)
