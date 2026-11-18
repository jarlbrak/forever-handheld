-- Shared handheld window finish. Paint only: native windows own layout, focus,
-- input, visibility, selection, and actions. No native scripts or state tables
-- are replaced. Our noninteractive rim inherits panel visibility; its background stays below the panel.
local VERSION='3.7.169'
local GOLD={.68,.56,.36,1}
local BODY={.025,.030,.025,.98}
local registry={
  'ProfessionsFrame','ProfessionsBookFrame','TradeSkillFrame','CraftFrame',
  'CharacterFrame','InspectFrame','PlayerSpellsFrame','SpellBookFrame','TalentFrame',
  'ClassTalentFrame','PlayerTalentFrame','PetStableFrame','PetPaperDollFrame',
  'QuestFrame','GossipFrame','QuestLogFrame','WorldMapFrame',
  'MerchantFrame','MailFrame','OpenMailFrame','SendMailFrame','BankFrame',
  'AuctionHouseFrame','AuctionFrame','TradeFrame','LootFrame','ItemTextFrame',
  'ContainerFrameCombinedBags','GameMenuFrame','SettingsPanel','InterfaceOptionsFrame',
  'VideoOptionsFrame','KeyBindingFrame','MacroFrame','AddonList','HelpFrame','ColorPickerFrame',
  'FriendsFrame','SocialUIFrame','AddFriendFrame','CommunitiesFrame','CommunitiesAvatarPickerDialog','GuildFrame','GuildBankFrame','PVEFrame',
  'LFGDungeonReadyDialog','ReadyCheckListenerFrame','LFGInvitePopup','LFGListFrame','PVPUIFrame','RaidParentFrame','RaidFrame','RaidInfoFrame',
  'AchievementFrame','LegacySystemFrame','CollectionsJournal','EncounterJournal','DressUpFrame',
  'QuestieConfig','QuestieQuestFrame','QuestieStandaloneSettings','RXPGuidesSettingsFrame',
  'ControllerForeverMenu','ControllerForeverAHWindow','ControllerForeverTutorial',
  'ControllerForeverShoulderSetup','ControllerForeverKeybindDetail','ControllerForeverPicker','ControllerForeverChatEdit',
  'EditModeImportLayoutDialog','EditModeLayoutDialog','EditModeUnsavedChangesDialog','EditModeSystemSettingsDialog',
  'QuestieDebugOfferFrame','RSImportNpcsFrame','DropDownList1','DropDownList2','DropDownList3',
  'RareScannerTelemetryExportFrame','RXPG_MenuFrame','RXPGuidesTrainerFrame',
  'LorewardDirectionsWindow','LorewardFindWindow','LorewardPlanWindow','LorewardWhereNextBox',
  'LorewardSetupBox','LorewardDiscordBox','LorewardStepNotes','LorewardTourCard',
}
for i=1,13 do registry[#registry+1]='ContainerFrame'..i end
for i=1,4 do registry[#registry+1]='StaticPopup'..i end
local skins=setmetatable({},{__mode='k'})
local painted=setmetatable({},{__mode='k'})
local owned=setmetatable({},{__mode='k'})
local menus=setmetatable({},{__mode='k'})
local menuDescriptions=setmetatable({},{__mode='k'})
local hookedMenu
-- These shells are addon-owned. Keep the last applied values so a steady
-- window doesn't resubmit identical visibility, alpha and layering changes.
local function shellProperty(state,key,frame,setter,value)
  if state[key]~=value then
    setter(frame,value)
    state[key]=value
  end
end
local function showShell(state,shown,backgroundOnly)
  if not backgroundOnly then shellProperty(state,'edgeShown',state.edge,state.edge.SetShown,shown) end
  shellProperty(state,'bgShown',state.bg,state.bg.SetShown,shown)
end
local function menuAcquired(frame)
  menus[frame]=true
  if skins[frame] then skins[frame].last=-10 end
end
local function menuReleased(frame)
  menus[frame]=nil
  local s=skins[frame]
  if s then showShell(s,false) end
end
local function observeMenuDescription(_,_,description)
  if not description or menuDescriptions[description] or not description.AddMenuAcquiredCallback then return end
  -- Supported description callbacks include submenus. Never replace menu
  -- scripts, responders, focus/navigation state, or private manager tables.
  local ok,err=pcall(function()
    description:AddMenuAcquiredCallback(menuAcquired)
    description:AddMenuReleasedCallback(menuReleased)
    menuDescriptions[description]=true
  end)
  if not ok then
    ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.windowErrors=ForeverHandheldDB.windowErrors or {}
    ForeverHandheldDB.windowErrors.MenuDescriptions=tostring(err)
  end
end
local function discoverMenus()
  if not Menu or not Menu.PopulateDescription or not hooksecurefunc or hookedMenu==Menu then return end
  hooksecurefunc(Menu,'PopulateDescription',observeMenuDescription);hookedMenu=Menu
  local manager=Menu.GetManager and Menu.GetManager()
  local root=manager and manager.GetOpenMenu and manager:GetOpenMenu()
  if root then menuAcquired(root) end
end
local driver=CreateFrame('Frame')
driver:RegisterEvent('PLAYER_LOGIN')
driver:SetScript('OnEvent',function()
  ForeverHandheldDB=ForeverHandheldDB or {}
  if not ForeverHandheldDB.windowPaletteBefore and type(ControllerForeverDB)=='table' then
    local d=ControllerForeverDB
    ForeverHandheldDB.windowPaletteBefore={look=d.winLook or 'ornate',color=d.winColor or 'default',
      border=d.winBorder or 'default',background=d.winBackground or 100}
    -- Supported CF preferences: its own painter propagates these to inventory,
    -- mail, shops, auction house, menus, detail cards, and selection highlights.
    d.winLook='dark';d.winColor='cf';d.winBorder='thin';d.winBackground=100
  end
end)
local strataOrder={BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,FULLSCREEN=6,FULLSCREEN_DIALOG=7,TOOLTIP=8}
local function public(v) return not (issecretvalue and issecretvalue(v)) end
local function texture(o) return o and o.IsObjectType and o:IsObjectType('Texture') end
local function solid(t,r,g,b,a)
  if not texture(t) then return end
  t:SetColorTexture(r,g,b,a)
  t:SetVertexColor(1,1,1,1)
end
local function mute(t)
  if texture(t) then t:SetAlpha(0) end
end
local function regions(frame,fn)
  if frame and frame.GetRegions then
    for _,r in ipairs({frame:GetRegions()}) do fn(r) end
  end
end
local function borderTexture(parent,point1,point2,width,height)
  local t=parent:CreateTexture(nil,'OVERLAY')
  t:SetColorTexture(unpack(GOLD));t:SetPoint(unpack(point1))
  if point2 then t:SetPoint(unpack(point2)) end
  if width then t:SetWidth(width) end
  if height then t:SetHeight(height) end
  return t
end
local function shell(frame)
  local out=CreateFrame('Frame',nil,frame)
  owned[out]=true
  out:EnableMouse(false)
  out:SetAllPoints(frame)
  local strata,level=frame:GetFrameStrata(),frame:GetFrameLevel()
  local edgeLevel,bgLevel=level+520,math.max(0,level-1)
  out:SetFrameStrata(strata)
  out:SetFrameLevel(edgeLevel)
  borderTexture(out,{'TOPLEFT',1,-1},{'TOPRIGHT',-1,-1},nil,1)
  borderTexture(out,{'BOTTOMLEFT',1,1},{'BOTTOMRIGHT',-1,1},nil,1)
  borderTexture(out,{'TOPLEFT',1,-1},{'BOTTOMLEFT',1,1},1,nil)
  borderTexture(out,{'TOPRIGHT',-1,-1},{'BOTTOMRIGHT',-1,1},1,nil)
  -- Small corner inlays echo the action-dock jewel without adding labels.
  for _,p in ipairs({'TOPLEFT','TOPRIGHT','BOTTOMLEFT','BOTTOMRIGHT'}) do
    local x=p:find('LEFT') and 3 or -3
    local y=p:find('TOP') and -3 or 3
    local t=borderTexture(out,{p,x,y},nil,4,4);t:SetRotation(math.pi/4)
  end
  local bg=CreateFrame('Frame',nil,UIParent)
  owned[bg]=true;bg:EnableMouse(false);bg:SetAllPoints(frame)
  bg:SetFrameStrata(strata);bg:SetFrameLevel(bgLevel)
  local fill=bg:CreateTexture(nil,'BACKGROUND');fill:SetAllPoints(bg);solid(fill,unpack(BODY))
  if not menus[frame] then
    local header=bg:CreateTexture(nil,'ARTWORK');header:SetPoint('TOPLEFT',2,-2)
    header:SetPoint('TOPRIGHT',-2,-2);header:SetHeight(25)
    solid(header,.075,.071,.052,.98)
  end
  return {edge=out,bg=bg,last=-10,edgeShown=true,bgShown=true,edgeStrata=strata,bgStrata=strata,bgLevel=bgLevel,bgAlpha=1}
end
local function textColor(r)
  if not r.IsObjectType or not r:IsObjectType('FontString') then return end
  local red,green,blue=r:GetTextColor()
  -- Only dark parchment text needs conversion. Preserve rarity, red costs,
  -- class colors, native disabled labels and all inline color markup.
  if public(red) and public(green) and public(blue) and red<.35 and green<.35 and blue<.35 then
    r:SetTextColor(.94,.90,.82)
    r:SetShadowColor(0,0,0,.8);r:SetShadowOffset(1,-1)
  end
end
local function trainerFont(label,minimum)
  if not label or not label.GetFont then return end
  local face,size,flags=label:GetFont()
  if public(face) and public(size) and type(face)=='string' and type(size)=='number' and size<minimum then
    label:SetFont(face,minimum,flags)
  end
end
local function paint(frame,depth,budget,keepArtwork)
  if depth>(budget.settings and 10 or 7) or budget.n>1100 or owned[frame] then return end
  if frame.IsForbidden and frame:IsForbidden() then return end
  -- Hidden tabs and pooled rows cannot contribute to this window's appearance.
  -- Revisit them through the normal paint pass once their native owner shows them.
  if frame.IsVisible and not frame:IsVisible() then return end
  budget.n=budget.n+1
  if frame.GetFrameStrata and frame:IsVisible() then
    local strata=frame:GetFrameStrata()
    local rank=strataOrder[strata] or 0
    if rank<8 and rank>(budget.rank or 0) then budget.rank=rank;budget.strata=strata end
    budget.level=math.max(budget.level or 0,frame:GetFrameLevel())
  end
  local name=frame.GetName and frame:GetName() or ''
  if depth==0 and name:match('^Loreward') and frame.SetBackdropColor then
    frame:SetBackdropColor(unpack(BODY))
    if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(0,0,0,0) end
  end
  -- These interfaces already have their own approved handheld presentation.
  if name:find('ChatFrame') or name:find('ForeverHandheld') then return end
  keepArtwork=keepArtwork or (frame.IsObjectType and (frame:IsObjectType('Cooldown') or frame:IsObjectType('StatusBar') or frame:IsObjectType('PlayerModel')))
  -- Color swatches, checkerboard and wheel/value/alpha gradients are data.
  -- Theme only the outer dialog, never these native selection surfaces.
  keepArtwork=keepArtwork or (ColorPickerFrame and frame==ColorPickerFrame.Content)
  if frame==ColorPickerFrame then
    regions(frame.Header,mute)
    local title=frame.Header and frame.Header.Text
    if title and title.GetFont then
      local face,size,flags=title:GetFont()
      if face and size<16 then title:SetFont(face,16,flags)end
    end
  end
  -- TrainerTextures is a numeric/shared atlas in the live client. Match its
  -- documented frame fields rather than recoloring every use of that atlas.
  if frame==_G.ClassTrainerFrame then
    solid(frame.BG,unpack(BODY))
    local rank=_G.ClassTrainerStatusBar
    if rank then
      trainerFont(rank.rankText,14)
      rank:SetStatusBarColor(.65,.49,.27,1)
      solid(_G.ClassTrainerStatusBarBackground,.14,.13,.09,1)
    end
    trainerFont(frame.FilterDropdown and frame.FilterDropdown.Text,14)
  end
  -- This dialog keeps its ornamental rim in a dedicated, noninteractive BG
  -- child. Our shared background/rim replaces only that decoration.
  if frame==_G.QuickKeybindFrame or (depth==0 and name:match('^StaticPopup%d+$')) then regions(frame.BG,mute) end
  -- The avatar grid is a separate ScrollBox. Selector owns only its decorative
  -- panel regions; preserve its child accept/cancel controls and all icon rows.
  if frame==_G.CommunitiesAvatarPickerDialog then regions(frame.Selector,mute) end
  -- Edit Mode modal decoration is a Border child, separate from all fields,
  -- buttons and the controller focus outline. The shared opaque underlay
  -- covers the paused editor while leaving the native dialog above it.
  if frame==_G.EditModeImportLayoutDialog or frame==_G.EditModeLayoutDialog or
     frame==_G.EditModeUnsavedChangesDialog or frame==_G.EditModeSystemSettingsDialog then
    regions(frame.Border,mute)
  end
  if frame==_G.ItemTextPageText and frame.GetFont and frame.GetSpacing then
    -- Books use SimpleHTML rather than ordinary FontStrings. Retain the
    -- native fonts, paging and scroll owner; give small text handheld sizing.
    local changed=false
    for _,style in ipairs({{'P',18,3},{'H1',24,4},{'H2',21,4},{'H3',19,3}})do
      local tag,size,spacing=unpack(style)
      local face,current,flags=frame:GetFont(tag)
      if public(face) and public(current) and type(face)=='string' and type(current)=='number' and current<size then
        frame:SetFont(tag,face,size,flags);changed=true
      end
      local currentSpacing=frame:GetSpacing(tag)
      if public(currentSpacing) and type(currentSpacing)=='number' and currentSpacing<spacing then
        frame:SetSpacing(tag,spacing);changed=true
      end
    end
    if changed and _G.ItemTextScrollFrame then ItemTextScrollFrame:UpdateScrollChildRect()end
  end
  -- Guild banner and its background share one atlas. Replace only the named
  -- parchment texture; preserve the real guild's tabard, crest and colors.
  if frame==_G.InspectGuildFrame then solid(_G.InspectGuildFrameBG,unpack(BODY)) end
  if frame==_G.MailFrame or frame==_G.OpenMailFrame then
    -- These original textures contain transparent padding beyond the panel;
    -- suppress them instead of turning their entire 512px rectangle opaque.
    for _,key in ipairs({'InboxFrameBg','SendStationeryBackgroundLeft','SendStationeryBackgroundRight',
      'OpenStationeryBackgroundLeft','OpenStationeryBackgroundRight'}) do solid(_G[key],0,0,0,0) end
    local body=_G.SendMailBodyEditBox
    if body and body.SetTextColor then body:SetTextColor(.94,.90,.82) end
  end
  if name:match('^MailItem%d+$') then
    regions(frame,function(r)
      if texture(r) and r:GetDrawLayer()=='BACKGROUND' then
        r:SetDesaturated(true);r:SetVertexColor(.35,.38,.33,1)
      end
    end)
  end
  if depth==0 and (name:match('^L_DropDownList%d+$') or name:match('^DropDownList%d+$')) then
    -- Legacy/native and LibUIDropDownMenu lists have dedicated paint-only
    -- backdrop children. The menu root owns selection, timers and navigation.
    regions(frame.Backdrop,mute);regions(frame.MenuBackdrop,mute)
  end
  if budget.trainer and frame.icon and frame.selectedTex and frame.disabledBG and frame.GetNormalTexture then
    local normal=frame:GetNormalTexture()
    if texture(normal) then normal:SetDesaturated(true);normal:SetVertexColor(.35,.38,.33,1) end
    trainerFont(frame.subText,13)
    local label=frame.name
    local width=frame:GetWidth()
    if label and label.GetNumPoints and public(width) and type(width)=='number' and width>140 then
      -- The native cost frame can reserve more width than its visible coins.
      -- Keep 80 units for prices and give the remaining space to the name.
      local p,anchor,rp,x,y=label:GetPoint(1)
      if label:GetNumPoints()~=1 or p~='TOPLEFT' or anchor~=frame.icon or rp~='TOPRIGHT' or x~=6 or y~=-1 then
        label:ClearAllPoints()
        label:SetPoint('TOPLEFT',frame.icon,'TOPRIGHT',6,-1)
      end
      local available=math.floor(width-128)
      if math.abs(label:GetWidth()-available)>.1 then label:SetWidth(available) end
      local face,size,flags=label:GetFont()
      local measured=label:GetUnboundedStringWidth()
      if public(face) and public(size) and public(measured) and type(face)=='string' and type(size)=='number'
        and type(measured)=='number' and measured>0 then
        local fit=math.max(13,math.min(16,math.floor(size*(available-1)/measured)))
        if fit~=size then label:SetFont(face,fit,flags) end
        if label:GetHeight()<18 then label:SetHeight(18) end
      end
    end
  end
  local nine=frame.NineSlice
  local input=frame.IsObjectType and frame:IsObjectType('EditBox')
  -- Input borders communicate where text belongs; they are not window chrome.
  if nine and not input then regions(nine,mute) end
  if nine and input and not (frame.IsProtected and frame:IsProtected()) then
    regions(nine,function(r)
      if texture(r) then r:SetVertexColor(unpack(r==nine.Center and BODY or GOLD))end
    end)
  end
  if depth==0 then
    for _,key in ipairs({'Border','BorderFrame'}) do
      local b=frame[key]
      if texture(b) then mute(b) elseif b and b.GetRegions then regions(b,mute) end
    end
  end
  if type(frame.crChrome)=='table' then
    for _,t in ipairs(frame.crChrome) do
      if texture(t) then
        local layer=t:GetDrawLayer()
        if layer=='BACKGROUND' then solid(t,unpack(BODY)) else mute(t) end
      end
    end
  end
  -- The style-2 dropdown atlas includes 7px transparent padding outside its
  -- 25px button. Filling the atlas bounds merges adjacent settings rows.
  -- Tint the native image instead; its atlas, alpha mask and native state
  -- transitions remain the source of hover/disabled feedback.
  local selectorBackground
  if budget.settings and frame.GetMenuDescription and frame.Arrow and frame.Text and texture(frame.Background) then
    selectorBackground=frame.Background
  end
  if selectorBackground and not (frame.IsProtected and frame:IsProtected()) then
    if not selectorBackground.IsDesaturated or not selectorBackground:IsDesaturated() then selectorBackground:SetDesaturated(true)end
    local r,g,b,a
    if selectorBackground.GetVertexColor then r,g,b,a=selectorBackground:GetVertexColor()end
    if not public(r) or not public(g) or not public(b) or not public(a) then
      -- Keep secret native color data untouched.
    elseif type(r)~='number' or type(g)~='number' or type(b)~='number' or type(a)~='number' or
      math.abs(r-.50)>.001 or math.abs(g-.48)>.001 or math.abs(b-.38)>.001 or math.abs(a-1)>.001 then
      selectorBackground:SetVertexColor(.50,.48,.38,1)
    end
  end
  for _,key in ipairs({'Bg','Background','background','TitleBg','TopTileStreaks','StoneBg',
    'BookBGHalved','BookBGLeft','BookBGRight','TopBar','HeaderBackground','TitleBackground'}) do
    local t=frame[key]
    if texture(t) and not keepArtwork and t~=selectorBackground then
      local w,h=t:GetSize()
      if public(w) and public(h) and w>70 then solid(t,unpack(BODY)) end
    end
  end
  if frame.TitleContainer and frame.TitleContainer.TitleText then
    frame.TitleContainer.TitleText:SetTextColor(.88,.77,.55)
  end
  regions(frame,function(r)
    textColor(r)
    if not texture(r) or keepArtwork or r==selectorBackground then return end
    if budget.workbench and not keepArtwork then
      local w,h=r:GetSize()
      if public(w) and public(h) and w>150 and h>100 then
        solid(r,0,0,0,0);return
      end
    end
    if painted[r] then
      if painted[r]=='body' then solid(r,unpack(BODY)) end
      if painted[r]=='button' then r:SetDesaturated(true);r:SetVertexColor(.50,.48,.38,1) end
      return
    end
    local atlas=r.GetAtlas and r:GetAtlas()
    local file=r.GetTexture and r:GetTexture()
    local tag=((type(atlas)=='string' and atlas or '')..' '..(type(file)=='string' and file or '')):lower()
    -- The appearance list has an unnamed full-panel ornamental texture;
    -- its character scene and item-quality borders are separate artwork.
    if atlas=='dressingroom-sideframe' then mute(r);return end
    if tag:find('dressingroom-background',1,true) then return end
    local w,h=r:GetSize()
    if not public(w) or not public(h) then return end
    if budget.pvp and atlas=='UI-Character-Info-Stat-StoneBG3' then
      -- The native match column header is only 50px tall. Theme this known
      -- decorative strip while retaining team colors, icons and row highlights.
      painted[r]='body';solid(r,unpack(BODY))
    elseif w>80 and h>10 and tag:find('spellbook',1,true) and not tag:find('icon',1,true) and r:GetDrawLayer()~='HIGHLIGHT' then
      painted[r]='body';solid(r,unpack(BODY))
    elseif w>80 and h>50 and (tag:find('background',1,true) or tag:find('parchment',1,true) or tag:find('%-bg') or tag:find('stonebg',1,true))
      and not tag:find('map',1,true) and not tag:find('icon',1,true) then
      painted[r]='body';solid(r,unpack(BODY))
    elseif tag:find('ui%-panel%-button') or tag:find('uipanelbutton') or
      (tag:find('redbutton',1,true) and w>50) then
      -- Red standard buttons become charcoal. Highlight/focus art is untouched.
      local layer=r:GetDrawLayer()
      if layer~='HIGHLIGHT' then
        painted[r]='button';r:SetDesaturated(true);r:SetVertexColor(.50,.48,.38,1)
      end
    end
  end)
  -- Standard text-button skins can use numeric texture IDs. The three-slice
  -- API and text/shape checks distinguish them from spell/item icon buttons.
  if frame.GetText and frame.GetNormalTexture then
    local txt=frame:GetText()
    local w,h=frame:GetSize()
    if public(txt) and type(txt)=='string' and txt~='' and public(w) and public(h) and w>(budget.loreward and 55 or 70) and h<48 then
      for _,t in pairs({frame:GetNormalTexture(),frame.Left,frame.Middle,frame.Center,frame.Right}) do
        if texture(t) then t:SetDesaturated(true);t:SetVertexColor(.50,.48,.38,1) end
      end
      if budget.loreward then
        local highlight=frame.GetHighlightTexture and frame:GetHighlightTexture()
        if texture(highlight) then highlight:SetDesaturated(true);highlight:SetVertexColor(.95,.78,.38,1) end
        local fs=frame.GetFontString and frame:GetFontString()
        if fs and fs.GetFont then local font,size,flags=fs:GetFont();if font and size and size<13 then fs:SetFont(font,13,flags) end end
      end
    end
  end
  if frame.GetChildren then
    for _,child in ipairs({frame:GetChildren()}) do
      if child~=nine then paint(child,depth+1,budget,keepArtwork or child==frame.RankBar or child==frame.StatusBar) end
    end
  end
end
local notesCovered=false
local function visit(frame)
  if not frame or not frame.GetFrameLevel or frame:IsForbidden() then return end
  if frame==_G.ReadyCheckFrame then return end -- The visible listener owns the prompt.
  local s=skins[frame]
  local w,h=frame:GetSize()
  local alpha=frame:IsVisible() and frame:GetAlpha()
  local shown=public(alpha) and type(alpha)=='number' and alpha>.01 and public(w) and public(h) and w>(menus[frame] and 30 or 70) and h>(menus[frame] and 12 or 40)
  local kit=ControllerForever and ControllerForever.Kit
  local fade=kit and kit.fades and kit.fades[frame]
  -- The native window may remain logically open underneath its controller
  -- replacement. Its animation does not hide our independent background.
  if fade and fade.on then shown=false end
  local name=frame:GetName() or ''
  -- The standalone binding list replaces its parent workspace visually.
  -- Hide only our own ancestor rim; never hide the native parent or its input.
  local picker=_G.ControllerForeverPicker
  if (frame==_G.ControllerForeverShoulderSetup or frame==_G.ControllerForeverKeybindDetail) and
     picker and not picker:IsForbidden() and picker:IsShown() then shown=false end
  if frame==_G.ControllerForeverChatEdit and (not picker or not picker:IsShown() or frame.mode~='prompt') then shown=false end
  if frame==picker and picker then
    local editing=picker.editBox and not picker.editBox:IsForbidden() and picker.editBox:IsShown()
    local styling=picker.styleBox and not picker.styleBox:IsForbidden() and picker.styleBox:IsShown()
    if editing or styling then shown=false end
  end
  local bags=_G.ControllerForeverWin_bags
  if name:match('^ContainerFrame') and bags and bags:IsShown() then shown=false end
  local notes=_G.ForeverHandheldFieldNotes
  if shown and notes and notes:IsShown() then
    local l,r,t,b=frame:GetLeft(),frame:GetRight(),frame:GetTop(),frame:GetBottom()
    local nl,nr,nt,nb=notes:GetLeft(),notes:GetRight(),notes:GetTop(),notes:GetBottom()
    local scale=frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
    local noteScale=notes.GetEffectiveScale and notes:GetEffectiveScale() or 1
    -- Bounds are expressed in each frame's scaled coordinate system. Compare
    -- screen-space bounds so a compact, scaled book does not mask the side rail.
    if l and r and t and b and nl and nr and nt and nb and
      public(l) and public(r) and public(t) and public(b) and
      public(nl) and public(nr) and public(nt) and public(nb) and public(scale) and public(noteScale) and
      type(scale)=='number' and type(noteScale)=='number' and scale>0 and noteScale>0 and
      r*scale>nl*noteScale and l*scale<nr*noteScale and t*scale>nb*noteScale and b*scale<nt*noteScale then notesCovered=true end
  end
  -- The independent background must follow closures even during combat.
  -- The child rim inherits native visibility; no protected paint in combat.
  if InCombatLockdown() then
    if s then showShell(s,shown,true) end
    return
  end
  if not s and shown then s=shell(frame);skins[frame]=s end
  if not s then return end
  showShell(s,shown)
  if not shown then return end
  local strata,level=frame:GetFrameStrata(),frame:GetFrameLevel()
  shellProperty(s,'bgAlpha',s.bg,s.bg.SetAlpha,alpha)
  shellProperty(s,'edgeStrata',s.edge,s.edge.SetFrameStrata,s.strata or strata)
  shellProperty(s,'bgStrata',s.bg,s.bg.SetFrameStrata,strata)
  -- The parent can shift its child levels during native focus changes.
  local edgeLevel=s.level or (level+520)
  if s.edge:GetFrameLevel()~=edgeLevel then s.edge:SetFrameLevel(edgeLevel) end
  shellProperty(s,'bgLevel',s.bg,s.bg.SetFrameLevel,math.max(0,level-1))
  if GetTime()-s.last>.9 then
    local budget={n=0,settings=frame==_G.SettingsPanel,workbench=frame==_G.ProfessionsFrame and _G.ForeverHandheldWorkbench~=nil,trainer=frame==_G.ClassTrainerFrame,loreward=name:match('^Loreward')~=nil,pvp=frame==_G.PVPMatchScoreboard or frame==_G.PVPMatchResults}
    paint(frame,0,budget);s.last=GetTime()
    s.strata=budget.strata;s.level=(budget.level or frame:GetFrameLevel())+1
    ForeverHandheldDB=ForeverHandheldDB or {}
    local db=ForeverHandheldDB
    db.windowTheme=db.windowTheme or {version=VERSION,seen={}}
    db.windowTheme.version=VERSION
    db.windowTheme.seen[frame:GetName() or 'anonymous']=true
  end
end
local elapsed,discovered=0,-10
local custom={}
local communityShade
local communityVeil
local function updateCommunityShade()
  -- Community creation/join dialogs live in Blizzard's forbidden environment.
  -- Its public outbound visibility function is the only observation needed.
  -- Keep all native dialog objects, input, text and bindings entirely untouched.
  local shown=false
  if type(AddCommunitiesFlow_IsShown)=='function' then
    local ok,value=pcall(AddCommunitiesFlow_IsShown)
    shown=ok and public(value) and value==true
  end
  -- The icon picker is an ordinary, lower-strata frame. It receives the shared
  -- window shell directly; never cover it with the secure-dialog underlay.
  local avatarShown=false
  if shown and type(CommunitiesAvatarPicker_IsShown)=='function' then
    local ok,value=pcall(CommunitiesAvatarPicker_IsShown)
    avatarShown=ok and public(value) and value==true
    if not ok or not public(value) or value then shown=false end
  end
  -- The normal picker can sit below some guild text regions. Temporarily veil
  -- that ordinary parent window's paint, never its visibility or focus state.
  local guild=_G.CommunitiesFrame
  local safeGuild=guild and not (guild.IsForbidden and guild:IsForbidden()) and not (guild.IsProtected and guild:IsProtected())
  if communityVeil and (not avatarShown or guild~=communityVeil.frame) then
    local f=communityVeil.frame
    if not (f.IsForbidden and f:IsForbidden()) and not (f.IsProtected and f:IsProtected()) and f:GetAlpha()==0 then f:SetAlpha(communityVeil.alpha)end
    communityVeil=nil
  end
  if avatarShown and safeGuild and not communityVeil then
    local alpha=guild:GetAlpha()
    if public(alpha) and type(alpha)=='number' then
      communityVeil={frame=guild,alpha=alpha};guild:SetAlpha(0)
    end
  end
  if shown and not communityShade then
    communityShade=CreateFrame('Frame','ForeverHandheldCommunityBackdrop',UIParent)
    owned[communityShade]=true
    communityShade:EnableMouse(false)
    communityShade:SetAllPoints(UIParent)
    -- HIGH stays below the secure DIALOG layer and its native controller footer.
    communityShade:SetFrameStrata('HIGH');communityShade:SetFrameLevel(9990)
    local fill=communityShade:CreateTexture(nil,'BACKGROUND')
    fill:SetAllPoints(communityShade);solid(fill,.025,.030,.025,.98)
  end
  if communityShade then communityShade:SetShown(shown) end
  if shown then
    ForeverHandheldDB=ForeverHandheldDB or {}
    ForeverHandheldDB.communityDialogBackdrop={version=VERSION,seen=GetTime(),nativeDialogUntouched=true}
  end
end
driver:SetScript('OnUpdate',function(_,dt)
  elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
  local ok,err=pcall(function()
    updateCommunityShade()
    notesCovered=false
    local seen={}
    local function once(f)
      if not f or seen[f] then return end
      seen[f]=true
      local good,why=pcall(visit,f)
      if not good then
        ForeverHandheldDB=ForeverHandheldDB or {}
        ForeverHandheldDB.windowErrors=ForeverHandheldDB.windowErrors or {}
        local name=f.GetName and f:GetName() or 'anonymous'
        ForeverHandheldDB.windowErrors[name or 'anonymous']=tostring(why)
      end
    end
    -- The installed RXP uses LibUIDropDownMenu's three shared list frames.
    -- Classify before visiting so short submenus get a flat rim, not a header.
    for i=1,3 do
      for _,prefix in ipairs({'DropDownList','L_DropDownList'}) do
        local f=_G[prefix..i]
        if f then menus[f]=true;once(f) end
      end
    end
    for _,name in ipairs(registry) do once(_G[name]) end
    -- Native anonymous binding dialogs are exposed by their owner.
    local picker=_G.ControllerForeverPicker
    if picker and not picker:IsForbidden() then once(picker.editBox);once(picker.styleBox)end
    -- These extend outside the dressing-room root. Visit their actual bounds
    -- so their thin rim/background and inspection-card occlusion follow them.
    local dress=_G.DressUpFrame
    if dress then
      once(dress.CustomSetDetailsPanel)
      once(dress.SetSelectionPanel)
    end
    -- Native panel names are a small registry. ControllerForever windows and
    -- anonymous AceGUI roots are supplied by their owning registries below.
    if GetTime()-discovered>3 then
      custom={}
      discoverMenus()
      -- Include other native panel-manager windows as their modules load.
      for name in pairs(UIPanelWindows or {}) do
        if type(name)=='string' and _G[name] then custom[#custom+1]=_G[name] end
      end
      discovered=GetTime()
    end
    for _,f in ipairs(custom) do once(f) end
    for f in pairs(menus) do once(f) end
    local kit=ControllerForever and ControllerForever.Kit
    if kit then
      for _,inst in pairs(kit.live or {}) do once(inst.frame) end
      for _,inst in pairs(kit.samples or {}) do once(inst.frame) end
    end
    -- This native side window is anonymous and absent from UIPanelWindows.
    once(_G.SocialUIFrame and _G.SocialUIFrame.IgnoreListFrame)
    if ForeverHandheldPanels then for f in pairs(ForeverHandheldPanels.roots) do once(f) end end
    -- Last-inspected information remains stored; large windows temporarily
    -- cover its paint so it cannot bleed through settings or inventory cards.
    if _G.ForeverHandheldFieldNotes then _G.ForeverHandheldFieldNotes:SetAlpha(notesCovered and 0 or 1) end
  end)
  if not ok then
    ForeverHandheldDB=ForeverHandheldDB or {}
    ForeverHandheldDB.windowThemeError=tostring(err)
  end
end)
