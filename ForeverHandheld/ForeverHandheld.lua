-- Visual-only companion to ControllerForever. Secure input and action resolution
-- stay in the original addon; native icons and dynamic macros are mirrored live.
local VERSION=42
local WHITE='Interface\\Buttons\\WHITE8X8'
local MASK='Interface\\CharacterFrame\\TempPortraitAlphaMask'
local RING='Interface\\AddOns\\ControllerForever\\Assets\\Skins\\border_round_bevel'
local FONT='Fonts\\ARIALN.TTF'
local TITLE='Fonts\\FRIZQT__.TTF'
local GOLD={.68,.56,.36,1}
local SETS={'top','left','right','bottom'}
local TITLES={top='BASE',left='LT',right='RT',bottom='LT + RT'}
local ORDER={2,1,4,3,8,7,5,6}
local KEYS={'↑','←','↓','→','A','B','X','Y'}
-- Native PadDisplay slot order, before ORDER rearranges it for the HUD.
local PAD_KEYS={'PADDLEFT','PADDUP','PADDRIGHT','PADDDOWN','PAD3','PAD4','PAD2','PAD1'}
local FACE_COLOR={A={.65,.85,.45},B={.96,.50,.42},X={.50,.75,.98},Y={.96,.83,.40}}
local hud,slots,banks={}, {}, {}
local ready=false
local events=CreateFrame('Frame')
local function secret(v) return issecretvalue and issecretvalue(v) end
local function safeNumber(v,fallback)
  if type(v)~='number' or (issecretvalue and issecretvalue(v)) then return fallback or 0 end
  return v
end
local function text(parent,size,anchor,x,y,font,relative)
  local t=parent:CreateFontString(nil,'OVERLAY')
  t:SetFont(font or FONT,size,'OUTLINE');t:SetTextColor(.94,.90,.82)
  if relative then t:SetPoint(anchor,relative,anchor,x or 0,y or 0)
  else t:SetPoint(anchor,x or 0,y or 0) end
  return t
end
local function rect(parent,layer,r,g,b,a)
  local t=parent:CreateTexture(nil,layer or 'BACKGROUND')
  t:SetColorTexture(r,g,b,a or 1);return t
end
local function panel(parent,name)
  local f=CreateFrame('Frame',name,parent,'BackdropTemplate')
  f:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
  f:SetBackdropColor(.025,.03,.025,.88);f:SetBackdropBorderColor(unpack(GOLD))
  f:EnableMouse(false);return f
end
local function sourceFor(set,index) return _G['ControllerForeverPad'..(set=='top' and '' or set)..index] end
local function spellName(id)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  return GetSpellInfo and GetSpellInfo(id)
end
local SHORT={['Jump / Swim Up']='Jump',['Interact With Target']='Interact',['Window wheel']='Windows',['Consumables wheel']='Consumables',['Controller Forever']='Settings',['Back / Stop Casting']='Back',['Interact / Loot']='Interact',['Inspect / Mark Target']='Inspect'}
local BAR='GamepadMainActionBarFramePageUnit'
local NATIVE_BARS={top=BAR..'TopCenteredAnchorTopBar',left=BAR..'LeftCenteredAnchorLeftBar',right=BAR..'RightCenteredAnchorRightBar',bottom=BAR..'BottomCenteredAnchorBottomBar'}
local function flyoutName(id)
  if not secret(id) and type(id)=='number' and GetFlyoutInfo then
    local name=GetFlyoutInfo(id)
    if not secret(name) and type(name)=='string' and name~='' then return name end
  end
  return 'Spell group'
end
local function actionName(source,set,index)
  local a=source and source.crDrawn
  local rb=ControllerForever.RuleBar
  local game=a and rb.gameActionOf and rb.gameActionOf(a)
  local look=source and source.crLookSrc
  local name=(game and game.name) or (a and a.spellID and spellName(a.spellID)) or (a and a.macroName)
  if not name and look and not secret(look.kind) and look.kind=='flyout' then name=flyoutName(look.id) end
  if not name and look and not secret(look.kind) and look.kind=='spell' then name=spellName(look.id) end
  if not name and look and not secret(look.kind) and look.kind=='item' and C_Item and C_Item.GetItemNameByID then name=C_Item.GetItemNameByID(look.id) or 'Item' end
  if not name and source and source.crMode=='slot' and set and index then
    local native=_G[(NATIVE_BARS[set] or '')..'ActionButton'..index]
    local slot=native and (native.action or (native.GetAttribute and native:GetAttribute('action')))
    if not slot and native and ControllerForever.PadDisplay and ControllerForever.PadDisplay.gameSlotOf then slot=ControllerForever.PadDisplay.gameSlotOf(native) end
    if slot and not secret(slot) then
      local nativeGame=rb.nativeSlotGameAction and rb.nativeSlotGameAction(slot)
      if nativeGame then name=nativeGame.name
      elseif GetActionInfo then
        local kind,id=GetActionInfo(slot)
        if not secret(kind) and kind=='flyout' then
          -- A single learned spell may take the native direct-cast path.
          local spellID=native and native.isFlyoutAction and native.spellID
          if not secret(spellID) and type(spellID)=='number' then name=spellName(spellID) end
          name=name or flyoutName(id)
        elseif not secret(kind) and not secret(id) then
          if kind=='spell' then name=spellName(id)
          elseif kind=='item' and C_Item and C_Item.GetItemNameByID then name=C_Item.GetItemNameByID(id) or 'Item'
          elseif kind=='macro' and GetMacroInfo then name=GetMacroInfo(id)end
        end
      end
    end
  end
  if name and not secret(name) then return SHORT[name] or name end
end
local function orb(parent,x,label,r,g,b)
  local f=CreateFrame('StatusBar',nil,parent);f:SetSize(72,72);f:SetPoint('CENTER',parent,'BOTTOM',x,52)
  local mask=f:CreateMaskTexture();mask:SetTexture(MASK,'CLAMPTOBLACKADDITIVE','CLAMPTOBLACKADDITIVE');mask:SetAllPoints(f)
  f.bg=rect(f,'BACKGROUND',.025,.025,.025,1);f.bg:SetAllPoints(f);f.bg:AddMaskTexture(mask)
  f.fill=rect(f,'ARTWORK',1,1,1,1);f.fill:SetAllPoints(f);f.fill:AddMaskTexture(mask);f:SetStatusBarTexture(f.fill);f:SetOrientation('VERTICAL');f:SetMinMaxValues(0,1)
  f.fill:SetGradient('VERTICAL',CreateColor(r*.35,g*.35,b*.35,1),CreateColor(r,g,b,1))
  local shine=rect(f,'OVERLAY',1,1,1,.1);shine:SetAllPoints(f);shine:AddMaskTexture(mask)
  shine:SetGradient('VERTICAL',CreateColor(1,1,1,0),CreateColor(1,.96,.85,.18))
  local ring=f:CreateTexture(nil,'OVERLAY');ring:SetTexture(RING);ring:SetPoint('CENTER');ring:SetSize(86,86);ring:SetVertexColor(.76,.66,.47)
  f.valueText=text(f,17,'CENTER',0,0)
  for _,v in ipairs({{-44,0},{44,0},{0,44},{0,-44}}) do
    local tip=rect(f,'OVERLAY',.67,.56,.37,1);tip:SetSize(5,5);tip:SetPoint('CENTER',v[1],v[2]);tip:SetRotation(math.pi/4)
  end
  f.label=text(f,13,'TOP',0,-83);f.label:SetText(label)
  return f
end
local function makeDock()
  hud.shade=CreateFrame('Frame',nil,UIParent);hud.shade:SetFrameStrata('BACKGROUND');hud.shade:SetPoint('BOTTOMLEFT');hud.shade:SetPoint('BOTTOMRIGHT');hud.shade:SetHeight(220)
  local shade=rect(hud.shade,'BACKGROUND',1,1,1,1);shade:SetAllPoints(hud.shade);shade:SetGradient('VERTICAL',CreateColor(.015,.018,.016,.92),CreateColor(.015,.018,.016,0))
  hud.root=CreateFrame('Frame','ForeverHandheldDock',UIParent)
  hud.root:SetSize(920,116);hud.root:SetPoint('BOTTOM',0,96);hud.root:SetFrameStrata('LOW');hud.root:EnableMouse(false)
  local width,gap=167,18
  for group,set in ipairs(SETS) do
    local bank=CreateFrame('Frame',nil,hud.root);bank:SetSize(width,116)
    bank:SetPoint('BOTTOMLEFT',hud.root,'BOTTOM',(group-1)*(width+gap)-(4*width+3*gap)/2,0)
    local inset=rect(bank,'BACKGROUND',1,1,1,1);inset:SetPoint('TOPLEFT',-6,-24);inset:SetPoint('BOTTOMRIGHT',6,-2);inset:SetGradient('VERTICAL',CreateColor(.02,.022,.018,.68),CreateColor(.025,.028,.023,.30))
    bank.jewel=rect(bank,'OVERLAY',.84,.69,.43,1);bank.jewel:SetSize(5,5);bank.jewel:SetPoint('CENTER',bank,'TOP',0,0);bank.jewel:SetRotation(math.pi/4)
    bank.line=rect(bank,'ARTWORK',.55,.47,.32,.8);bank.line:SetPoint('TOPLEFT');bank.line:SetPoint('TOPRIGHT');bank.line:SetHeight(1)
    bank.label=text(bank,17,'TOP',0,-5,TITLE);bank.label:SetText(TITLES[set]);banks[set]=bank
    slots[set]={}
    for pos,index in ipairs(ORDER) do
      local f=panel(bank)
      f:SetSize(38,38);f:SetPoint('TOPLEFT',((pos-1)%4)*43,-30-math.floor((pos-1)/4)*44)
      f.icon=f:CreateTexture(nil,'ARTWORK');f.icon:SetPoint('TOPLEFT',1,-1);f.icon:SetPoint('BOTTOMRIGHT',-1,1)
      f.cd=CreateFrame('Cooldown',nil,f,'CooldownFrameTemplate');f.cd:SetAllPoints(f.icon);f.cd:SetDrawEdge(false);f.cd:EnableMouse(false)
      f.over=CreateFrame('Frame',nil,f);f.over:SetAllPoints(f);f.over:SetFrameLevel(f.cd:GetFrameLevel()+2)
      local badge=panel(f.over);badge:SetSize(21,21);badge:SetPoint('BOTTOMRIGHT',3,-5);badge:SetBackdropBorderColor(.45,.42,.32,1)
      f.key=text(badge,16,'CENTER');f.key:SetText(KEYS[pos]);if FACE_COLOR[KEYS[pos]] then f.key:SetTextColor(unpack(FACE_COLOR[KEYS[pos]])) end
      f.count=text(f.over,12,'TOPRIGHT',-2,-2)
      f.press=rect(f.over,'OVERLAY',0,0,0,.35);f.press:SetAllPoints(f.icon);f.press:Hide()
      f.nativeIndex=index;f.keyName=KEYS[pos];slots[set][pos]=f
    end
  end
  hud.xp=ForeverHandheldProgress.Create(UIParent)
  hud.health=orb(hud.root,-433,'HEALTH',.78,.12,.11)
  hud.power=orb(hud.root,433,'MANA',.20,.53,.85)
  -- Inherit dock opacity even if its render callback is suspended when covered.
  hud.dpadHint=text(hud.root,15,'BOTTOM',0,72,nil,UIParent);hud.dpadHint:SetWidth(1150);hud.dpadHint:SetJustifyH('CENTER');hud.dpadHint:SetMaxLines(1)
  hud.feedback=text(hud.root,16,'BOTTOM',0,226,nil,UIParent);hud.feedback:SetWidth(800);hud.feedback:SetJustifyH('CENTER');hud.feedback:SetMaxLines(1)
  hud.hint=text(hud.root,16,'BOTTOM',0,52,nil,UIParent);hud.hint:SetWidth(1150);hud.hint:SetJustifyH('CENTER');hud.hint:SetMaxLines(1)
  hud.utility=text(hud.root,14,'BOTTOM',0,29,nil,UIParent)
  hud.flyoutHint=text(hud.root,16,'BOTTOM',0,230,nil,UIParent)
  hud.flyoutHint:SetText('Right stick to choose  ·  Release to cast  ·  B Close')
  hud.flyoutHint:Hide()
end
local function makeTarget()
  local f=CreateFrame('Frame','ForeverHandheldTarget',UIParent)
  f:SetSize(360,84);f:SetPoint('TOP',0,-43);f:SetFrameStrata('LOW');f:EnableMouse(false)
  f.name=text(f,18,'TOPLEFT',0,0,TITLE);f.name:SetWidth(270);f.name:SetJustifyH('LEFT');f.name:SetMaxLines(1)
  f.info=text(f,14,'TOPRIGHT',0,-2)
  f.health=CreateFrame('StatusBar',nil,f);f.health:SetPoint('TOPLEFT',0,-27);f.health:SetPoint('TOPRIGHT',0,-27);f.health:SetHeight(9)
  f.health:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');f.health:SetMinMaxValues(0,1)
  local bg=rect(f.health,'BACKGROUND',.04,.025,.02,.9);bg:SetAllPoints(f.health)
  for _,side in ipairs({'LEFT','RIGHT'}) do
    local edge=rect(f.health,'OVERLAY',.69,.60,.42,1);edge:SetSize(8,8);edge:SetPoint('CENTER',f.health,side,side=='LEFT' and -4 or 4,0);edge:SetRotation(math.pi/4)
  end
  f.cast=CreateFrame('StatusBar',nil,f);f.cast:SetPoint('TOPLEFT',0,-47);f.cast:SetPoint('TOPRIGHT',0,-47);f.cast:SetHeight(4);f.cast:SetStatusBarTexture(WHITE);f.cast:SetMinMaxValues(0,1)
  bg=rect(f.cast,'BACKGROUND',.09,.08,.06,.9);bg:SetAllPoints(f.cast)
  f.castName=text(f,14,'TOPLEFT',0,-57);f.castName:SetWidth(195);f.castName:SetJustifyH('LEFT');f.castName:SetMaxLines(1)
  f.response=text(f,14,'TOPRIGHT',0,-57);f.response:SetTextColor(.88,.75,.47)
  hud.target=f;f:Hide()
end
local function activeSet()
  local rb=ControllerForever.RuleBar
  local pad=rb.readPadState();local held=pad and pad.buttons or {}
  local lt=held[rb.gamepadStateIndex('PADLTRIGGER') or 0]
  local rt=held[rb.gamepadStateIndex('PADRTRIGGER') or 0]
  local latch=rb.latched and rb.latched()
  lt=lt or latch=='lt' or latch=='ltrt';rt=rt or latch=='rt' or latch=='ltrt'
  return (lt and rt and 'bottom' or lt and 'left' or rt and 'right' or 'top'),held
end
local function controllerInterface()
  local rb=ControllerForever and ControllerForever.RuleBar
  if rb and rb.isGamepadOn then return rb.isGamepadOn() end
  return not C_CVar or C_CVar.GetCVar('InputDeviceInterfaceStyle')~='0'
end
local function mirrorIcons(worldHints,flyout)
  local enabled=controllerInterface()
  local showBanks=enabled and not flyout
  for _,set in ipairs(SETS) do banks[set]:SetShown(showBanks) end
  hud.flyoutHint:SetShown(enabled and flyout==true)
  hud.hint:SetShown(enabled);hud.dpadHint:SetShown(enabled);hud.utility:SetShown(enabled)
  ForeverHandheldDB.controllerDockVisible=enabled
  if not enabled then
    -- The mouse interface owns its action bar. Keep health/mana, target, chat,
    -- and inspection intact, but do not leave empty controller banks above it.
    hud.hint:SetText('');hud.dpadHint:SetText('');hud.utility:SetText('');hud.feedback:SetText('')
    for _,set in ipairs(SETS) do for _,f in ipairs(slots[set]) do f.wasPressed=false end end
    ForeverHandheldDB.activeBank=nil;ForeverHandheldDB.mirroredSlots=0
    return
  end
  local rb=ControllerForever.RuleBar
  local active,held=activeSet()
  local worldInput=worldHints and not (rb.state and rb.state.bindingHold)
  local controls=ForeverHandheldControls
  if not worldInput and controls and controls.feedbackKind=='input' then controls.untilTime=0 end
  ForeverHandheldDB.activeBank=active
  local hint,dpadHint={},{}
  local available=0
  for _,set in ipairs(SETS) do
    local on=set==active
    -- These are our own decorations, driven only by the selected bank. Avoid
    -- repainting unchanged backdrops; native icon/label/input reads stay live.
    if banks[set].hudActive~=on then
      banks[set].hudActive=on
      banks[set].line:SetColorTexture(on and .84 or .44,on and .69 or .39,on and .43 or .30,on and 1 or .7)
      banks[set].jewel:SetAlpha(on and 1 or .18)
      banks[set].label:SetTextColor(on and .95 or .75,on and .80 or .71,on and .53 or .63)
    end
    for pos,f in ipairs(slots[set]) do
      local source=sourceFor(set,f.nativeIndex)
      if source and source.icon then
        available=available+1
        local src=source.icon
        local tex=src:GetTexture();local atlas=src:GetAtlas()
        -- Cache only public paint state on our own mirror. Secret values pass
        -- through unchanged and invalidate the relevant cache for recovery.
        if secret(atlas) then
          f.paintImageKnown=false;f.icon:SetAtlas(atlas)
        elseif atlas then
          if not f.paintImageKnown or f.paintAtlas~=atlas then
            f.icon:SetAtlas(atlas);f.paintAtlas=atlas;f.paintTexture=nil;f.paintImageKnown=true
          end
        elseif secret(tex) then
          f.paintImageKnown=false;f.icon:SetTexture(tex)
        elseif not f.paintImageKnown or f.paintAtlas or f.paintTexture~=tex then
          f.icon:SetTexture(tex);f.paintAtlas=nil;f.paintTexture=tex;f.paintImageKnown=true
        end
        -- UV, tint and opacity can be secret. Keep their native copies
        -- direct instead of adding tuple scans to every slot tick.
        f.icon:SetTexCoord(src:GetTexCoord())
        f.icon:SetVertexColor(src:GetVertexColor())
        f.icon:SetDesaturated(src:IsDesaturated())
        f.icon:SetAlpha(src:GetAlpha())
        local count=''
        if source.count then count=source.count:GetText()end
        if secret(count) then f.paintCountKnown=false;f.count:SetText(count)
        elseif not f.paintCountKnown or f.paintCount~=count then f.count:SetText(count);f.paintCount=count;f.paintCountKnown=true end
        if not f.hooked then
          hooksecurefunc(source.cooldown,'SetCooldown',function(_,...)f.cd:SetCooldown(...)end)
          hooksecurefunc(source.cooldown,'Clear',function()f.cd:Clear()end)
          if source.cooldown.SetCooldownFromDurationObject then hooksecurefunc(source.cooldown,'SetCooldownFromDurationObject',function(_,...)f.cd:SetCooldownFromDurationObject(...)end) end
          f.hooked=true
        end
        local start,duration=source.cooldown:GetCooldownTimes()
        if not secret(start) and not secret(duration) then
        start,duration=safeNumber(start),safeNumber(duration)
        if start~=f.cdStart or duration~=f.cdDuration then
          f.cdStart,f.cdDuration=start,duration
          if duration>0 then f.cd:SetCooldown(start/1000,duration/1000) else f.cd:Clear() end
        end
        end
        -- PadDisplay paints raw presses even when a modal owns the binding.
        -- Its overlay can also outlive the release that dismissed the modal.
        local press=on and source.press and source.press:IsShown() and
          held[rb.gamepadStateIndex(PAD_KEYS[f.nativeIndex]) or 0]==true
        f.press:SetShown(press and worldInput)
        local proc=source.crProcOn and true or false
        if f.hudProc~=proc then
          f.hudProc=proc
          if proc then f:SetBackdropBorderColor(1,.80,.28,1) else f:SetBackdropBorderColor(unpack(GOLD)) end
        end
        if set==active then
          local name=actionName(source,set,f.nativeIndex)
          local list=pos>=5 and hint or dpadHint
          list[#list+1]=f.keyName..' '..(name or 'Unassigned')
          if worldInput and press and not f.wasPressed and controls then
            controls.notify((set=='top' and '' or TITLES[set]..' + ')..f.keyName..'  '..(name or 'Unassigned'),'input',.8)
            -- Keep only the latest observed edge for physical-controller checks.
            ForeverHandheldDB.lastPadPress={at=GetTime(),bank=set,key=f.keyName,action=name or 'Unassigned'}
          end
          f.wasPressed=press
        else f.wasPressed=false end
        if f.hudActive~=on then f.hudActive=on;f:SetAlpha(on and 1 or .90)end
      end
    end
  end
  hud.hint:SetText(table.concat(hint,'   ·   '))
  hud.dpadHint:SetText((active=='top' and '' or TITLES[active]..'  ·  ')..table.concat(dpadHint,'   ·   '))
  local device=controls and controls.kind=='xbox' and 'Xbox · ' or controls and controls.kind=='deck' and 'Deck · ' or ''
  hud.utility:SetText(device..'LB Friend     RB Enemy     Menu Menu     LT + View Settings')
  local message=controls and (controls.untilTime or 0)>GetTime() and controls.message or ''
  hud.feedback:SetText(message)
  if controls and controls.feedbackKind=='error' then hud.feedback:SetTextColor(1,.56,.42)
  elseif controls and controls.feedbackKind=='success' then hud.feedback:SetTextColor(.65,.85,.55)
  else hud.feedback:SetTextColor(.94,.90,.82)end
  ForeverHandheldDB.mirroredSlots=available
end
local INTERRUPTS={[96231]=true,[2139]=true,[1766]=true,[6552]=true,[57994]=true,[47528]=true,[106839]=true,[19647]=true,[15487]=true}
local function interruptHint()
  if not controllerInterface() then return nil end
  local rb=ControllerForever.RuleBar
  for _,set in ipairs(SETS) do
    for pos,f in ipairs(slots[set]) do
      local source=sourceFor(set,f.nativeIndex);local action=source and source.crDrawn
      local cd=source and source.crLookSrc
      local id=(cd and cd.kind=='spell' and cd.id) or (action and action.spellID)
      if id and INTERRUPTS[id] then
        local start,duration=source.cooldown:GetCooldownTimes();local readable=not secret(start) and not secret(duration);start,duration=safeNumber(start),safeNumber(duration)
        local usable=true
        if C_Spell and C_Spell.IsSpellUsable then usable=C_Spell.IsSpellUsable(id) elseif IsUsableSpell then usable=IsUsableSpell(id) end
        local inRange=C_Spell and C_Spell.IsSpellInRange and C_Spell.IsSpellInRange(id,'target')
        if not secret(inRange) and inRange==nil and IsSpellInRange then inRange=IsSpellInRange(spellName(id),'target') end
        if readable and not secret(usable) and not secret(inRange) and usable and inRange~=false and inRange~=0 and (duration<=1500 or GetTime()*1000>=start+duration) then
          return (set=='top' and '' or TITLES[set]..' + ')..KEYS[pos]..' Interrupt'
        end
      end
    end
  end
end
local function interactHint()
  if not controllerInterface() or (ForeverHandheldPanels and ForeverHandheldPanels.active) then return '' end
  local rb=ControllerForever.RuleBar
  for _,set in ipairs(SETS) do
    for pos,f in ipairs(slots[set]) do
      local source=sourceFor(set,f.nativeIndex)
      local game=source and source.crDrawn and rb.gameActionOf(source.crDrawn)
      if game and game.key=='interact' then return (set=='top' and '' or TITLES[set]..' + ')..KEYS[pos]..' Interact' end
    end
  end
  return ''
end
local function healthPercent(unit,scale)
  if UnitHealthPercent then return UnitHealthPercent(unit,false,scale and CurveConstants.ScaleTo100 or nil) end
  return safeNumber(UnitHealth(unit))/math.max(1,safeNumber(UnitHealthMax(unit),1))*(scale and 100 or 1)
end
local function powerPercent(unit,kind,scale)
  if UnitPowerPercent then return UnitPowerPercent(unit,kind,false,scale and CurveConstants.ScaleTo100 or nil) end
  return safeNumber(UnitPower(unit))/math.max(1,safeNumber(UnitPowerMax(unit),1))*(scale and 100 or 1)
end
local function updateUnits()
  if RXPG_ARROW and RXPG_ARROW.handheldDistance then RXPG_ARROW.handheldDistance:SetFormattedText('%.0f yd',safeNumber(RXPG_ARROW.distance)) end
  hud.health:SetValue(healthPercent('player'))
  hud.health.valueText:SetFormattedText('%.0f%%',healthPercent('player',true))
  local powerType,token=UnitPowerType('player')
  if secret(powerType) then powerType=0 end
  hud.power:SetValue(powerPercent('player',powerType))
  if powerType==0 then hud.power.valueText:SetFormattedText('%.0f%%',powerPercent('player',powerType,true)) else hud.power.valueText:SetFormattedText('%d',UnitPower('player')) end
  hud.power.label:SetText(token)
  if not UnitExists('target') then hud.target:Hide();return end
  local f=hud.target;f:Show();f.name:SetText(UnitName('target'))
  f.health:SetValue(healthPercent('target'))
  local hostile=UnitCanAttack('player','target');local friendly=UnitIsFriend('player','target')
  if secret(hostile) then hostile=false end;if secret(friendly) then friendly=false end
  if hostile then f.health:SetStatusBarColor(.68,.22,.15) elseif friendly then f.health:SetStatusBarColor(.43,.63,.32) else f.health:SetStatusBarColor(.75,.62,.21) end
  f.info:SetFormattedText('%d   %.0f%%',UnitLevel('target'),healthPercent('target',true))
  local name,_,_,start,finish,_,_,locked=UnitCastingInfo('target')
  local channel=false
  local duration=UnitCastingDuration and UnitCastingDuration('target')
  local casting=duration~=nil
  if not casting and UnitChannelDuration then
    duration=UnitChannelDuration('target');casting=duration~=nil;channel=casting
    if casting then name,_,_,start,finish,_,locked=UnitChannelInfo('target') end
  elseif not UnitCastingDuration then
    casting=not secret(name) and name~=nil
    if not casting then name,_,_,start,finish,_,locked=UnitChannelInfo('target');casting=not secret(name) and name~=nil;channel=casting end
  end
  if casting then
    f.cast:Show()
    if duration and f.cast.SetTimerDuration then f.cast:SetTimerDuration(duration,0,channel and 1 or 0)
    elseif not secret(start) and not secret(finish) and finish>start then f.cast:SetValue(channel and (finish-GetTime()*1000)/(finish-start) or (GetTime()*1000-start)/(finish-start)) end
    f.cast:SetStatusBarColor(.88,.73,.38);f.castName:SetText(name)
    f.response:SetText(hostile and not secret(locked) and (locked and 'Cannot interrupt' or interruptHint() or '') or '')
  else
    f.cast:Hide();f.castName:SetText('');f.response:SetText(friendly and not UnitIsPlayer('target') and interactHint() or '')
  end
end
local function guideLook()
  if not RXPFrame or InCombatLockdown() then return end
  local f=RXPFrame
  if f.GuideName then f.GuideName:SetAlpha(0) end
  if f.Footer then f.Footer:SetAlpha(0) end
  local current=f.CurrentStepFrame
  if current then
    for _,step in ipairs(current.framePool or {}) do
      -- RXP promotes active steps to MEDIUM, above some native service panels.
      -- Keep the guide in the HUD layer without firing its OnHide lifecycle.
      step:SetFrameStrata('BACKGROUND')
      step:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1});step:SetBackdropColor(.025,.03,.025,.72);step:SetBackdropBorderColor(.55,.46,.31,.55)
      if step.number then step.number:SetBackdropColor(.025,.03,.025,.85);step.number:SetBackdropBorderColor(.55,.46,.31,0);step.number.text:SetTextColor(.86,.74,.50) end
    end
    if not hud.guideFooter then hud.guideFooter=panel(f);hud.guideFooter:SetFrameLevel(f:GetFrameLevel());hud.guideFooter:SetBackdropColor(.025,.03,.025,.64);hud.guideFooter:SetBackdropBorderColor(.55,.46,.31,.35) end
    hud.guideFooter:ClearAllPoints();hud.guideFooter:SetPoint('TOPLEFT',current,'BOTTOMLEFT',0,-5);hud.guideFooter:SetPoint('TOPRIGHT',current,'BOTTOMRIGHT',0,-5);hud.guideFooter:SetHeight(39)
    if f.Footer and f.Footer.cog then f.Footer.cog:ClearAllPoints();f.Footer.cog:SetPoint('RIGHT',hud.guideFooter,'RIGHT',-6,0);f.Footer.cog:SetAlpha(.55) end
  end
  if RXPG_ARROW then
    RXPG_ARROW:SetFrameStrata('BACKGROUND')
    RXPG_ARROW:ClearAllPoints();RXPG_ARROW:SetPoint('TOPLEFT',current or f,'BOTTOMLEFT',8,-11);RXPG_ARROW:SetScale(.9)
    if RXPG_ARROW.texture then RXPG_ARROW.texture:SetTexture('Interface\\AddOns\\RXPGuides\\Textures\\rxp_navigation_arrow-1');RXPG_ARROW.texture:SetVertexColor(1,1,1,1) end
    if RXPG_ARROW.text then RXPG_ARROW.text:SetAlpha(0) end
    if not RXPG_ARROW.handheldDistance then
      RXPG_ARROW.handheldDistance=text(RXPG_ARROW,16,'LEFT',40,0)
      RXPG_ARROW.handheldDistance:SetTextColor(.85,.82,.73)
    end
  end
  if RXPTargetFrame then
    RXPTargetFrame:SetFrameStrata('BACKGROUND')
    RXPTargetFrame:ClearAllPoints();RXPTargetFrame:SetPoint('TOPRIGHT',current or f,'BOTTOMRIGHT',-5,-9)
    RXPTargetFrame:SetBackdropColor(0,0,0,0);RXPTargetFrame:SetBackdropBorderColor(0,0,0,0)
    if RXPTargetFrame.title then RXPTargetFrame.title:SetAlpha(0) end
  end
end
local function castLook()
  local f=ControllerForeverCastBar
  if f and hud.root then f:ClearAllPoints();f:SetPoint('BOTTOM',hud.root,'TOP',0,8);f:SetWidth(220) end
end
-- Edge panels are independent displays. Never hook Blizzard's tooltip callbacks:
-- running addon code in the gamepad tooltip call chain taints its protected menus.
local function makeUnitCard(name,unit,w,h,parent,preview)
  local f=CreateFrame(preview and 'Frame' or 'Button',name,parent or UIParent,preview and 'BackdropTemplate' or 'SecureUnitButtonTemplate,BackdropTemplate')
  f:SetSize(w,h);f:SetFrameStrata('LOW');f:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
  f:SetBackdropColor(.025,.03,.025,.78);f:SetBackdropBorderColor(.40,.36,.26,.65)
  f.unit=unit
  if preview then f:EnableMouse(false) else
    f:SetAttribute('unit',unit);f:SetAttribute('type1','target');f:RegisterForClicks('AnyUp')
    f:SetScript('OnEnter',function()hud.hoverUnit=unit end)
    f:SetScript('OnLeave',function()if hud.hoverUnit==unit then hud.hoverUnit=nil end end)
  end
  f.name=text(f,w<100 and 11 or 15,'TOPLEFT',7,-6,TITLE);f.name:SetWidth(w-14);f.name:SetJustifyH('LEFT');f.name:SetMaxLines(1)
  f.health=CreateFrame('StatusBar',nil,f);f.health:SetPoint('BOTTOMLEFT',6,7);f.health:SetPoint('BOTTOMRIGHT',-6,7);f.health:SetHeight(h<40 and 5 or 8);f.health:SetStatusBarTexture(WHITE);f.health:SetMinMaxValues(0,1)
  local bg=rect(f.health,'BACKGROUND',.07,.07,.06,1);bg:SetAllPoints(f.health)
  f.power=CreateFrame('StatusBar',nil,f);f.power:SetPoint('BOTTOMLEFT',6,3);f.power:SetPoint('BOTTOMRIGHT',-6,3);f.power:SetHeight(2);f.power:SetStatusBarTexture(WHITE);f.power:SetMinMaxValues(0,1);f.power:SetStatusBarColor(.25,.52,.78)
  f.info=text(f,12,'TOPRIGHT',-6,-24);f.info:SetJustifyH('RIGHT')
  f.mark=text(f,12,'TOPLEFT',7,-24);f.mark:SetTextColor(.9,.77,.47)
  f.compact=w<100
  if f.compact then
    f.name:ClearAllPoints();f.name:SetPoint('TOPLEFT',7,-3)
    f.mark:ClearAllPoints();f.mark:SetPoint('BOTTOMLEFT',7,1)
    f.mark:SetFont(FONT,10,'OUTLINE');f.mark:SetWidth(w-14);f.mark:SetMaxLines(1)
  end
  f.auras={}
  if w>=100 then
    for i=1,3 do local t=f:CreateTexture(nil,'OVERLAY');t:SetSize(15,15);t:SetPoint('TOPLEFT',7+(i-1)*18,-24);f.auras[i]=t end
    f.mark:ClearAllPoints();f.mark:SetPoint('TOPLEFT',66,-25)
  end
  return f
end
local function makeFieldNotes()
  if hud.notes then return end
  local f=panel(UIParent,'ForeverHandheldFieldNotes');hud.notes=f
  f:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-19,-330);f:SetWidth(242);f:SetHeight(70);f:SetFrameStrata('MEDIUM')
  f:SetBackdropBorderColor(.45,.38,.25,.65);f:SetBackdropColor(.025,.03,.025,.86)
  f.heading=text(f,11,'TOPLEFT',13,-10,TITLE);f.heading:SetText('FIELD NOTES');f.heading:SetTextColor(.76,.65,.43)
  local line=rect(f,'ARTWORK',.50,.42,.27,.7);line:SetPoint('TOPLEFT',13,-28);line:SetPoint('TOPRIGHT',-13,-28);line:SetHeight(1)
  f.scroll=CreateFrame('ScrollFrame',nil,f);f.scroll:SetPoint('TOPLEFT',13,-36);f.scroll:SetWidth(216)
  f.body=CreateFrame('Frame',nil,f.scroll);f.body:SetSize(216,1);f.scroll:SetScrollChild(f.body)
  f.offset=0;f.maxScroll=0
  local function scrollBy(delta) f.offset=math.max(0,math.min(f.maxScroll,f.offset+delta));f.scroll:SetVerticalScroll(f.offset) end
  f:EnableMouseWheel(true);f:SetScript('OnMouseWheel',function(_,delta)scrollBy(-delta*36)end)
  f.scrollButtons={}
  for i,glyph in ipairs({'↑','↓'}) do
    local b=CreateFrame('Button',nil,f);b:SetSize(26,26);b:SetPoint('TOPRIGHT',-8-(2-i)*28,-1)
    local label=text(b,19,'CENTER');label:SetText(glyph);label:SetTextColor(.9,.77,.47)
    b:SetScript('OnClick',function()scrollBy(i==1 and -72 or 72)end);f.scrollButtons[i]=b
  end
  f.lines={}
  for i=1,24 do
    local row={};row.left=text(f.body,i==1 and 17 or 14,'TOPLEFT',13,-36,i==1 and TITLE or FONT);row.left:SetJustifyH('LEFT');row.left:SetWidth(216)
    row.right=text(f.body,13,'TOPRIGHT',-13,-36);row.right:SetJustifyH('RIGHT');row.right:SetWidth(76);row.rightWidth=76;f.lines[i]=row
  end
  f:Hide()
end
local function makeEdges()
  makeFieldNotes()
  hud.focus=makeUnitCard('ForeverHandheldFocus','focus',242,58)
  hud.focus:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-19,-543)
  hud.focusLabel=text(hud.focus,11,'BOTTOMLEFT',0,62,TITLE);hud.focusLabel:SetText('FOCUS');hud.focusLabel:SetTextColor(.76,.65,.43)
  RegisterUnitWatch(hud.focus)
  hud.tot=makeUnitCard('ForeverHandheldTargetOfTarget','targettarget',220,35)
  hud.tot:SetPoint('TOP',UIParent,'TOP',0,-151)
  hud.tot.info:Hide();hud.tot.mark:Hide();hud.tot.name:SetFont(FONT,13,'OUTLINE')
  hud.totLabel=text(hud.tot,10,'BOTTOMLEFT',0,39,TITLE);hud.totLabel:SetText('TARGET OF TARGET');hud.totLabel:SetTextColor(.76,.65,.43)
  RegisterUnitWatch(hud.tot)
  hud.roster={}
  for i=1,4 do
    local c=makeUnitCard('ForeverHandheldParty'..i,'party'..i,242,58)
    c:SetPoint('TOPLEFT',UIParent,'TOPLEFT',20,-237-(i-1)*65)
    RegisterStateDriver(c,'visibility','[group:raid] hide; [@party'..i..',exists] show; hide')
    hud.roster[#hud.roster+1]=c
  end
  for i=1,40 do
    local c=makeUnitCard('ForeverHandheldRaid'..i,'raid'..i,66,29)
    c:SetPoint('TOPLEFT',UIParent,'TOPLEFT',20+math.floor((i-1)/10)*69,-237-((i-1)%10)*32)
    c.info:Hide();RegisterUnitWatch(c);hud.roster[#hud.roster+1]=c
  end
  hud.rosterTitle=text(UIParent,11,'TOPLEFT',20,-216,TITLE);hud.rosterTitle:SetTextColor(.76,.65,.43)
end
local function unitStatus(f,connected,dead,role)
  if not secret(connected) and connected==false then f.mark:SetText('OFFLINE')
  elseif not secret(dead) and dead then f.mark:SetText('DEAD')
  elseif not secret(role) and role=='TANK' then f.mark:SetText('TANK')
  elseif not secret(role) and role=='HEALER' then f.mark:SetText('HEAL') else f.mark:SetText('') end
  if f.compact then
    local unavailable=(not secret(connected) and connected==false) or (not secret(dead) and dead)
    -- Status occupies the existing bar area only when bars are not useful.
    -- Keep the member's name and secure targeting available in every state.
    f.mark:SetShown(unavailable)
    f.health:SetAlpha(unavailable and 0 or 1);f.power:SetAlpha(unavailable and 0 or 1)
  end
end
local function updateDebuffs(f,getDebuff)
  for i,t in ipairs(f.auras) do
    local icon
    if getDebuff then
      local ok,aura=pcall(getDebuff,f.unit,i)
      if ok and not secret(aura) and type(aura)=='table' then icon=aura.icon end
      if not ok then getDebuff=nil end
    end
    if not secret(icon) and icon then t:SetTexture(icon);t:Show() else t:Hide() end
  end
end
local function updateCard(f,getDebuff)
  if not UnitExists(f.unit) then return end
  f.name:SetText(UnitName(f.unit));f.health:SetValue(healthPercent(f.unit))
  f.info:SetFormattedText('%.0f%%',healthPercent(f.unit,true))
  local _,class=UnitClass(f.unit)
  local player=UnitIsPlayer(f.unit)
  local color=not secret(player) and player and not secret(class) and class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  local enemy=UnitCanAttack('player',f.unit)
  if color then f.health:SetStatusBarColor(color.r,color.g,color.b) elseif not secret(enemy) and enemy then f.health:SetStatusBarColor(.68,.22,.15) else f.health:SetStatusBarColor(.48,.64,.35) end
  local kind=UnitPowerType(f.unit);if secret(kind) then kind=0 end
  f.power:SetValue(powerPercent(f.unit,kind))
  local chosen=UnitIsUnit(f.unit,'target');if secret(chosen) then chosen=false end
  local soft=UnitIsUnit(f.unit,'softfriend');if secret(soft) then soft=false end
  if chosen or soft then f:SetBackdropBorderColor(.95,.78,.44,1) else f:SetBackdropBorderColor(.40,.36,.26,.65) end
  local dead=UnitIsDeadOrGhost(f.unit);local connected=UnitIsConnected(f.unit)
  local role=UnitGroupRolesAssigned(f.unit)
  unitStatus(f,connected,dead,role)
  updateDebuffs(f,getDebuff)
end
local function updateEdges()
  local getDebuff=C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex
  local check=C_Secrets and C_Secrets.ShouldAurasBeSecret
  if getDebuff and check then
    local ok,restricted=pcall(check)
    if not ok or secret(restricted) or restricted then getDebuff=nil end
  end
  updateCard(hud.focus,getDebuff);updateCard(hud.tot,getDebuff)
  for _,f in ipairs(hud.roster) do updateCard(f,getDebuff) end
  hud.rosterTitle:SetText(IsInRaid() and 'RAID  ·  LB FRIEND' or IsInGroup() and 'PARTY  ·  LB FRIEND' or '')
end
-- Visual QA uses the same card builder/status paint, never the real unit
-- frames. Samples have no secure unit, input handlers or group actions.
local rosterPreview,previewSerial= nil,0
local function closeRosterPreview()
  previewSerial=previewSerial+1
  if rosterPreview then rosterPreview:Hide() end
end
local function previewRoster()
  closeRosterPreview()
  if InCombatLockdown() or IsInGroup() or IsInRaid() then return end
  if not rosterPreview then
    local root=CreateFrame('Frame','ForeverHandheldRosterPreview',UIParent)
    rosterPreview=root;root:SetAllPoints(UIParent);root:SetFrameStrata('DIALOG');root:EnableMouse(false)
    local label=text(root,11,'TOPLEFT',20,-216,TITLE);label:SetText('RAID PREVIEW  /  SAMPLE UNITS');label:SetTextColor(.95,.78,.38)
    root.cards={}
    local names={'Aldren','Brielle','Cedric','Dahlia','Elowen','Faelan','Garrick','Helena','Isolde','Jareth'}
    for i=1,40 do
      local f=makeUnitCard(nil,nil,66,29,root,true);root.cards[i]=f
      f:SetPoint('TOPLEFT',root,'TOPLEFT',20+math.floor((i-1)/10)*69,-237-((i-1)%10)*32)
      f.name:SetText(names[(i-1)%10+1]);f.info:Hide()
      f.health:SetValue(.35+(i%6)*.1);f.health:SetStatusBarColor(.55,.70,.42);f.power:SetValue(.65)
      unitStatus(f,i~=2,i==3,'NONE')
      if i==4 then f:SetBackdropBorderColor(.95,.78,.44,1) end
    end
    root:RegisterEvent('PLAYER_REGEN_DISABLED');root:RegisterEvent('GROUP_ROSTER_UPDATE')
    root:SetScript('OnEvent',closeRosterPreview)
  end
  rosterPreview:Show();local serial=previewSerial
  C_Timer.After(12,function()if previewSerial==serial then closeRosterPreview()end end)
end
SLASH_FOREVERROSTER1='/fhroster'
-- The native command registry already exists. Reassigning its global taints
-- built-in commands (including Inspect) and their secure controller bindings.
SlashCmdList.FOREVERROSTER=function(argument)if argument=='hide' then closeRosterPreview()else previewRoster()end end
-- Hide paint layers, not the frame or its opacity. The native FadeOut animation
-- owns alpha and can repaint between our updates if we try to force alpha to zero.
local TIP_LAYERS={'BACKGROUND','BORDER','ARTWORK','OVERLAY','HIGHLIGHT'}
local function veilTooltip(tip,owner)
  hud.veiled=hud.veiled or {}
  local record=hud.veiled[tip]
  if not record then record={frames={},owner=owner};hud.veiled[tip]=record end
  local function visit(frame,depth)
    if depth>12 or (frame.IsForbidden and frame:IsForbidden()) then return end
    local flags=record.frames[frame]
    if not flags then flags={};record.frames[frame]=flags end
    for _,layer in ipairs(TIP_LAYERS) do
      local on=frame:IsDrawLayerEnabled(layer)
      if flags[layer]==nil then flags[layer]=secret(on) and true or on end
      -- Keep the per-render guard: native repaint can re-enable a layer
      -- between updates. Already-veiled layers need no renderer mutation.
      if secret(on) or on then frame:DisableDrawLayer(layer) end
    end
    for _,child in ipairs({frame:GetChildren()}) do visit(child,depth+1) end
  end
  visit(tip,0)
end
local function restoreTooltip(tip)
  local record=tip and hud.veiled and hud.veiled[tip]
  if not record then return end
  for frame,flags in pairs(record.frames) do
    for layer,on in pairs(flags) do
      if on then frame:EnableDrawLayer(layer) else frame:DisableDrawLayer(layer) end
    end
  end
  hud.veiled[tip]=nil
end
local function chatTakesRail()
  local chat=ForeverHandheldComms
  if chat and chat.visible then return true end
  local edit=ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
  return edit and not (edit.IsForbidden and edit:IsForbidden()) and edit.HasFocus and edit:HasFocus()
end
local function socialTakesRail()
  local social=_G.SocialUIFrame
  return social and not (social.IsForbidden and social:IsForbidden()) and social:IsVisible()
end
local function tooltipContext()
  hud.veiled=hud.veiled or {}
  local tip=GameTooltip
  local rare=_G.RARESCANNER_BUTTON
  local rareTip=rare and rare.LootBar and rare.LootBar.LootBarToolTip
  local rareHover=rare and rare:IsShown() and rareTip and rareTip:IsShown()
  if rareHover then tip=rareTip end
  local binding=_G.GamepadActionBarEditFrame
  local bindingTip=binding and binding:IsShown() and binding.ActionTooltip and binding.ActionTooltip:IsShown()
  if bindingTip then tip=binding.ActionTooltip;rareHover=false end
  local owner=tip and tip:GetOwner()
  local alpha=owner and owner.GetEffectiveAlpha and owner:GetEffectiveAlpha()
  local world=owner==WorldFrame or owner==UIParent or (type(alpha)=='number' and not secret(alpha) and alpha<.01)
  local hudOwner,bookOwner,lootOwner=false,nil,false
  local ancestor=owner
  for i=1,12 do
    if not ancestor then break end
    if ancestor==BuffFrame or ancestor==DebuffFrame or ancestor==ControllerForeverPadDisplay then hudOwner=true;break end
    if ancestor==_G.PlayerSpellsFrame then bookOwner=ancestor;break end
    if ancestor==_G.LootFrame then lootOwner=true;break end
    ancestor=ancestor.GetParent and ancestor:GetParent()
  end
  if bindingTip then bookOwner=binding.BindingInfoFrame end
  local unitTip=tip and tip.IsTooltipType and tip:IsTooltipType(Enum.TooltipDataType.Unit)
  if secret(unitTip) then unitTip=false end
  local itemTip=tip and tip.IsTooltipType and tip:IsTooltipType(Enum.TooltipDataType.Item)
  if secret(itemTip) then itemTip=false end
  local bookSpell=bookOwner and tip and tip.IsTooltipType and tip:IsTooltipType(Enum.TooltipDataType.Spell)
  if secret(bookSpell) then bookSpell=false end
  -- Spellbook flyout groups (for example Blessings) have their own tooltip
  -- type. Keep selected group details in the rail instead of stale world info.
  local flyoutType=Enum.TooltipDataType.Flyout
  local bookFlyout=bookOwner and not bindingTip and tip and tip.IsTooltipType and flyoutType and tip:IsTooltipType(flyoutType)
  if not secret(bookFlyout) and bookFlyout then bookSpell=true end
  local bookFits=false
  if bookSpell and bookOwner:IsShown() then
    local right=bookOwner:GetRight()
    local ratio=bookOwner:GetEffectiveScale()/UIParent:GetEffectiveScale()
    bookFits=not secret(right) and not secret(ratio) and type(right)=='number' and type(ratio)=='number' and
      right*ratio<=UIParent:GetWidth()-19-242-12
  end
  -- Compact spellbooks share the inspection rail. A wide book keeps its full
  -- native tooltip rather than covering the spell grid with the rail.
  local mirror=tip and tip:IsShown() and (rareHover or world or hudOwner or unitTip or hud.hoverUnit or bookFits)
  if bookSpell and not bookFits then mirror=false end
  if itemTip and not hud.hoverUnit and not rareHover then mirror=false end
  -- Native comparisons need their original side-by-side geometry and all data.
  if rareHover then
    for _,comparison in ipairs(rareTip.shoppingTooltips or {})do
      if comparison:IsShown() then mirror=false;break end
    end
  end
  local veiled=tip and hud.veiled[tip]
  local fading=veiled and tip:IsShown() and not itemTip and (not bookSpell or bookFits) and (owner==veiled.owner or owner==nil)
  if fading then mirror=true end
  if lootOwner then itemTip=tip:IsShown();mirror=false end
  if mirror and (chatTakesRail() or socialTakesRail()) then mirror=false end
  return tip,owner,unitTip,itemTip,mirror,fading,rareHover,bookSpell,bindingTip
end
-- The heavy text/layout pass stays at 10 Hz. This small paint gate runs on our
-- own frame every render, never inside Blizzard's tooltip/controller callbacks.
-- Keep the last veil while hidden so a subsequent world hover cannot flash its
-- native box before the next text refresh. Deliberate window/item inspection
-- restores the original draw-layer flags immediately on its next render.
local function updateTooltipPaint()
  -- Chat and Social can open between text refreshes. Social row tooltips
  -- extend into the right rail, so yield before they can cover stale notes.
  if hud.notes and hud.notes:IsShown() and (chatTakesRail() or socialTakesRail()) then hud.notes:Hide() end
  local tip,owner,_,_,mirror=tooltipContext()
  if not tip or not tip:IsShown() then return end
  local n=safeNumber(tip:NumLines())
  if mirror and n<=24 then veilTooltip(tip,owner)
  else restoreTooltip(tip) end
end
local function updateFieldNotes()
  local f=hud.notes
  if socialTakesRail() or chatTakesRail() then f:Hide();return end
  local tip,owner,unitTip,itemTip,mirror,_,rareHover,bookSpell,bindingTip=tooltipContext()
  local strata=bindingTip and mirror and bookSpell and 'DIALOG' or 'MEDIUM'
  if f:GetFrameStrata()~=strata then f:SetFrameStrata(strata) end
  local rareAlert=_G.RARESCANNER_BUTTON
  if not rareAlert or not rareAlert:IsShown() or hud.hoverUnit or UnitExists('mouseover') or
    (not rareHover and tip and tip:IsShown()) then hud.lastRareRows=nil end
  -- A deliberate item inspection already has a complete native tooltip.
  -- Do not place stale mouseover/target facts beside those equipment details.
  if (itemTip or bookSpell) and not mirror then
    hud.lastRareRows=nil
    f:Hide();ForeverHandheldDB.contextRows=0;ForeverHandheldDB.contextFits=true
    ForeverHandheldDB.contextDebug={owner=owner and owner.GetName and owner:GetName() or 'none',itemTip=true,mirrored=false}
    return
  end
  local rows={};local heading=bookSpell and 'FIELD NOTES  /  SPELL' or (rareHover and 'FIELD NOTES  /  RARE LOOT' or 'FIELD NOTES')
  local inspectedUnit=not bookSpell and not rareHover and (unitTip or hud.hoverUnit)
  if mirror then
    local n=safeNumber(tip:NumLines())
    local prefix=(rareHover or bindingTip) and tip:GetName() or 'GameTooltip'
    for i=1,n do
      local l=_G[prefix..'TextLeft'..i];local r=_G[prefix..'TextRight'..i]
      rows[#rows+1]={leftText=l and l:GetText(),rightText=r and r:IsShown() and r:GetText() or nil,leftColor=l and {l:GetTextColor()},rightColor=r and {r:GetTextColor()}}
    end
    if rareHover then hud.lastRareRows=n<=24 and rows or nil end
  end
  -- Keep the inspected loot available when moving onto the rail's scroll
  -- controls. A new inspection or disappearance of the alert releases it.
  local rareReading=rareHover or (#rows==0 and hud.lastRareRows~=nil)
  if rareReading then inspectedUnit=false end
  if #rows==0 and rareReading then rows=hud.lastRareRows or {};heading='FIELD NOTES  /  RARE LOOT' end
  -- Controller selection and ordinary mouseover also have a stable home here,
  -- even when the engine chooses not to open a floating tooltip.
  local controller=not ForeverHandheldControls or ForeverHandheldControls.gamepadActive
  local ally=controller and UnitExists('softfriend') and 'softfriend'
  if not bookSpell and not rareReading and (#rows==0 or hud.hoverUnit or (ally and unitTip and not UnitExists('mouseover'))) then
    rows={}
    local u=hud.hoverUnit or (UnitExists('mouseover') and 'mouseover' or ally or UnitExists('target') and 'target')
    if u and C_TooltipInfo and C_TooltipInfo.GetUnit then
      inspectedUnit=true
      local info=C_TooltipInfo.GetUnit(u)
      if info and info.lines then for _,v in ipairs(info.lines) do rows[#rows+1]=v end end
      heading=(hud.hoverUnit or u=='mouseover') and 'FIELD NOTES  /  HOVER' or u=='softfriend' and 'FIELD NOTES  /  ALLY' or 'FIELD NOTES  / TARGET'
    end
  end
  if #rows>0 and inspectedUnit then hud.lastUnitRows=rows end
  if #rows==0 and hud.lastUnitRows and not itemTip and not bookSpell then rows=hud.lastUnitRows;heading='FIELD NOTES  /  LAST INSPECTED' end
  if ForeverHandheldFieldReader then ForeverHandheldFieldReader.capture(rows,heading,bookSpell) end
  local y=0
  for i,row in ipairs(f.lines) do
    local d=rows[i]
    if d then
      local left=d.leftText;local right=d.rightText
      row.left:SetText(left);row.right:SetText(right)
      local rightSecret=secret(right)
      local hasRight=rightSecret or (right~=nil and right~='')
      local width=216
      if hasRight then
        local rightWidth=76
        if not rightSecret then
          if row.measuredText~=right then
            local measured=safeNumber(row.right.GetUnboundedStringWidth and row.right:GetUnboundedStringWidth())
            row.measuredText=right
            row.measuredWidth=measured>0 and math.max(26,math.min(76,math.ceil(measured)+2)) or 76
          end
          rightWidth=row.measuredWidth
        end
        if row.rightWidth~=rightWidth then row.right:SetWidth(rightWidth);row.rightWidth=rightWidth end
        width=210-rightWidth
      end
      -- Reflow only when the column width or preceding text height changes.
      if row.layoutWidth~=width then row.left:SetWidth(width);row.layoutWidth=width end
      if row.layoutY~=y then
        row.left:ClearAllPoints();row.left:SetPoint('TOPLEFT',f.body,'TOPLEFT',0,-y)
        row.right:ClearAllPoints();row.right:SetPoint('TOPRIGHT',f.body,'TOPRIGHT',0,-y)
        row.layoutY=y
      end
      local lc=d.leftColor;local rc=d.rightColor
      if lc and lc.GetRGBA then row.left:SetTextColor(lc:GetRGBA()) elseif lc and lc[1] then row.left:SetTextColor(unpack(lc)) else row.left:SetTextColor(.91,.88,.80) end
      if rc and rc.GetRGBA then row.right:SetTextColor(rc:GetRGBA()) elseif rc and rc[1] then row.right:SetTextColor(unpack(rc)) else row.right:SetTextColor(.85,.82,.73) end
      row.left:Show();row.right:Show()
      y=y+math.max(i==1 and 20 or 16,safeNumber(row.left:GetStringHeight()),safeNumber(row.right:GetStringHeight()))+3
    else row.left:Hide();row.right:Hide() end
  end
  local fits=#rows<=24
  -- Reserve the right-rail alert slot only while RareScanner needs it.
  local viewport=math.min(y,rareAlert and rareAlert:IsShown() and 60 or (bookSpell and (not hud.focus or not hud.focus:IsShown()) and 300 or 160))
  f.body:SetHeight(math.max(1,y));f.scroll:SetHeight(math.max(1,viewport));f.maxScroll=math.max(0,y-viewport)
  local first=rows[1] and rows[1].leftText
  if not secret(first) and first~=f.subject then f.subject=first;f.offset=0 end
  f.offset=math.min(f.offset,f.maxScroll);f.scroll:SetVerticalScroll(f.offset)
  for _,b in ipairs(f.scrollButtons) do b:SetShown(f.maxScroll>0) end
  -- Extremely long tooltips keep their complete native view; ordinary descriptions scroll here.
  f.heading:SetText(heading);f:SetHeight(viewport+48);f:SetShown(#rows>0 and fits)
  ForeverHandheldDB.contextRows=#rows;ForeverHandheldDB.contextFits=fits
  ForeverHandheldDB.contextDebug={owner=owner and owner.GetName and owner:GetName() or 'none',unitTip=unitTip and true or false,mirrored=mirror and true or false,hover=hud.hoverUnit}
end

local function configureTooltips()
  local cv={'GamepadShowAutoAuraTooltip','SoftTargetTooltipEnemy','SoftTargetTooltipFriend','SoftTargetTooltipInteract','SoftTargetTooltipLocked'}
  ForeverHandheldDB.tooltipSettingsBefore=ForeverHandheldDB.tooltipSettingsBefore or {}
  ForeverHandheldDB.tooltipSettings={}
  for _,name in ipairs(cv) do
    local value=C_CVar.GetCVar(name)
    if value~=nil then
      if ForeverHandheldDB.tooltipSettingsBefore[name]==nil then ForeverHandheldDB.tooltipSettingsBefore[name]=value end
      local desired=name=='GamepadShowAutoAuraTooltip' and '0' or ForeverHandheldDB.tooltipSettingsBefore[name]
      C_CVar.SetCVar(name,desired);ForeverHandheldDB.tooltipSettings[name]=C_CVar.GetCVar(name)
    end
  end
  ControllerForeverDB.targetTooltip=nil
  if ControllerForeverTargetTooltip then ControllerForeverTargetTooltip:Hide() end
  -- The CVar above disables automatic aura tooltips. Do not clear Blizzard's
  -- queue from addon code: that marks the native queue as addon-owned.

end
local function configure()
  if InCombatLockdown() then return end
  configureTooltips()
  local d=ControllerForeverDB;local layout=ControllerForever.Layout
  local w,h=UIParent:GetWidth(),UIParent:GetHeight()
  if ForeverHandheldDB.layoutVersion~=VERSION then
    d.padLayout='cross';d.ffSameSize=true;d.ffAllLit=true;d.padSectionOffsets={};d.gamepadUI={scale=1,dx=0,dy=0,spread=0}
    d.stickHidden=true;d.selectHidden=true;d.startHidden=true
    d.skins.minimap.shape='square';d.skins.minimap.border='thin';d.skins.minimap.color='gold';d.skins.minimap.textSize='normal'
    d.skins.chat.bgShows='mouseover';d.skins.chat.bgOpacity=20
    d.gameWindows=d.gameWindows or {}
    d.gameWindows.PlayerFrame={x=w/2-433,y=116,scale=1}
    d.gameWindows.TargetFrame={x=w/2,y=h-80,scale=1}
    d.gameWindows.MinimapCluster={x=w-130,y=h-151,scale=1}
    d.gameWindows.BuffFrame={x=120,y=160,scale=.8}
    d.gameWindows.ChatFrame1={x=160,y=250,scale=1}
    if ChatFrame1 then ChatFrame1:SetSize(280,90);ChatFrame1:SetFading(true);ChatFrame1:SetTimeVisible(10) end
    ControllerForever.Skins.apply();layout.apply('handheld');ControllerForever.PadDisplay.redrawSoon()
    ForeverHandheldDB.layoutVersion=VERSION;ForeverHandheldDB.edgeLayoutVersion=nil
    ForeverHandheldDB.appliedAt=date('%Y-%m-%d %H:%M:%S')
  end
  -- A centered buff anchor can put a full native icon grid beyond the left
  -- edge. Pin its complete container inside the left rail; retain the game's
  -- icon direction, wrap, tooltips and cancellation controls.
  if ForeverHandheldDB.buffRailVersion~=2 then
    ForeverHandheldDB.previousBuffRail=ForeverHandheldDB.previousBuffRail or d.gameWindows.BuffFrame
    d.gameWindows.BuffFrame={x=20,y=233,scale=.7,topLeft=true}
    ForeverHandheldDB.buffRailVersion=2
  end
  d.gameWindowsOff=d.gameWindowsOff or {}
  for _,name in ipairs({'PlayerFrame','TargetFrame','FocusFrame','TargetFrameToT','PartyFrame','CompactPartyFrame','CompactRaidFrameContainer','StatusTrackingBarManager','ObjectiveTrackerFrame','ControllerForeverPadDisplay','ControllerForeverShoulderLB','ControllerForeverShoulderRB','ControllerForeverShoulderL3','ControllerForeverShoulderR3','ControllerForeverShoulderST','ControllerForeverShoulderSE'}) do d.gameWindowsOff[name]=true end
  d.gameWindows.ChatFrame1={x=w-240,y=h-400,scale=1}
  if ChatFrame1 then ChatFrame1:SetSize(380,180);ChatFrame1:SetFading(false) end
  layout.placeGameWindows()
  -- Its visuals are already hidden through gameWindowsOff. SetCollapsed runs
  -- the native tracker layout and taints its blocks and shared layout state.
  for k,v in pairs({GamepadShowPersistentInputLegend='0',nameplateShowSelf='0'}) do if C_CVar.GetCVar(k)~=nil then C_CVar.SetCVar(k,v) end end
end
local function failSafe(err)
  for tip in pairs(hud.veiled or {})do restoreTooltip(tip)end
  if hud.notes then hud.notes:Hide() end
  if hud.focus then hud.focus:SetAlpha(0) end
  if hud.tot then hud.tot:SetAlpha(0) end
  if hud.roster then for _,f in ipairs(hud.roster) do f:SetAlpha(0) end end
  if hud.rosterTitle then hud.rosterTitle:Hide() end
  ForeverHandheldDB.lastError=tostring(err)
  if hud.root then hud.root:Hide();hud.root:SetScript('OnUpdate',nil) end
  if hud.target then hud.target:Hide() end
  if hud.hint then hud.hint:Hide() end
  if hud.dpadHint then hud.dpadHint:Hide() end
  if hud.feedback then hud.feedback:Hide() end
  if hud.shade then hud.shade:Hide() end
  if ForeverHandheldProgress then ForeverHandheldProgress.Stop() end
  if hud.utility then hud.utility:Hide() end
  for _,name in ipairs({'PlayerFrame','TargetFrame','FocusFrame','TargetFrameToT','PartyFrame','CompactPartyFrame','CompactRaidFrameContainer','StatusTrackingBarManager','ControllerForeverPadDisplay','ControllerForeverShoulderLB','ControllerForeverShoulderRB','ControllerForeverShoulderST','ControllerForeverShoulderSE'}) do
    if ControllerForeverDB.gameWindowsOff then ControllerForeverDB.gameWindowsOff[name]=nil end
    if _G[name] then _G[name]:SetAlpha(1) end
  end
  geterrorhandler()(err)
end
-- A focused native editor or its controller menu owns the face buttons.
-- A parked draft does not: keep world hints until chat actually takes input.
-- Read native focus/menu state so this does not depend on Comms tick ordering.
local function chatOwnsControls()
  local edit=ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
  if edit and not (edit.IsForbidden and edit:IsForbidden()) and edit.HasFocus and edit:HasFocus() then return true end
  for i=1,(NUM_CHAT_WINDOWS or 10) do
    local chat=_G['ChatFrame'..i]
    if chat and not (chat.IsForbidden and chat:IsForbidden()) and chat.IsGamepadMenuOpen and chat:IsGamepadMenuOpen() then return true end
  end
  return false
end
local function start()
  if ready or InCombatLockdown() or not ControllerForever or not ControllerForever.RuleBar then return end
  ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.lastError=nil
  configure();makeDock();makeTarget();makeEdges();guideLook();castLook()
  if RXPFrame then hooksecurefunc(RXPFrame,'UpdateVisuals',guideLook) end
  if ControllerForever.CastBar then hooksecurefunc(ControllerForever.CastBar,'apply',castLook) end
  ready=true
  events:SetScript('OnUpdate',nil)
  if ForeverHandheldDB.inspectionStartup then ForeverHandheldDB.inspectionStartup.handoffAt=GetTime() end
  local elapsed=0
  hud.root:SetScript('OnUpdate',function(_,dt)
    elapsed=elapsed+dt
    local ok,err=pcall(function()
      updateTooltipPaint()
      if elapsed<.1 then return end;elapsed=0
      -- Tutorial samples may leave the dock visible, but the active native
      -- interface owns input. Do not advertise world actions beneath its hints.
      local editing=ControllerForeverEditPanel and ControllerForeverEditPanel:IsShown()
      local panels=ForeverHandheldPanels
      local wheel=_G.GamepadSpellFlyout
      local flyout=wheel and not (wheel.IsForbidden and wheel:IsForbidden()) and wheel:IsShown()
      local guidePicker=_G.ForeverHandheldRestedXPWindow
      local worldHints=not (editing or flyout or (guidePicker and guidePicker:IsShown()) or chatOwnsControls() or (panels and
        (panels.active or (panels.hasStaticPopup and panels.hasStaticPopup()))))
      mirrorIcons(worldHints,flyout);updateUnits();updateEdges();updateFieldNotes()
      local hintAlpha=worldHints and 1 or 0
      if hud.hintAlpha~=hintAlpha then
        hud.hint:SetAlpha(hintAlpha)
        hud.dpadHint:SetAlpha(hintAlpha)
        hud.feedback:SetAlpha(hintAlpha)
        hud.utility:SetAlpha(hintAlpha)
        hud.hintAlpha=hintAlpha
      end
    end)
    if not ok then failSafe(err) end
  end)
  C_Timer.After(2,function()configure();guideLook();castLook()end)
  C_Timer.After(8,function()configure();guideLook()end)
end
-- Field notes have no secure units or native controller initialization dependency.
-- Build and populate them during world entry, before the full HUD's delayed setup.
-- Transfer rendering to the normal HUD once it is ready; never keep two drivers.
local startupElapsed=0
local function earlyInspection(dt)
  if ready then events:SetScript('OnUpdate',nil);return end
  local ok,err=pcall(function()
    ForeverHandheldDB=ForeverHandheldDB or {}
    makeFieldNotes()
    startupElapsed=startupElapsed+(dt or .1)
    if startupElapsed>=.1 then
      startupElapsed=0;updateFieldNotes()
      local d=ForeverHandheldDB.inspectionStartup
      if d and not d.readerAt then d.readerAt=GetTime() end
    end
    updateTooltipPaint()
  end)
  if not ok then
    for tip in pairs(hud.veiled or {})do restoreTooltip(tip)end
    if hud.notes then hud.notes:Hide()end
    events:SetScript('OnUpdate',nil)
    ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.startupInspectionError=tostring(err)
    ForeverHandheldDB.inspectionStartupFailure={version='3.7.78',seen=GetTime(),message=tostring(err)}
    return false
  end
  return true
end
events:RegisterEvent('PLAYER_ENTERING_WORLD');events:RegisterEvent('PLAYER_REGEN_ENABLED');events:RegisterEvent('GROUP_ROSTER_UPDATE')
events:SetScript('OnEvent',function(_,event)
  if event=='PLAYER_ENTERING_WORLD' then
    if not ready then
      ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.startupInspectionError=nil
      ForeverHandheldDB.inspectionStartup={version='3.7.78',enteredAt=GetTime()}
      if earlyInspection(.1) then events:SetScript('OnUpdate',function(_,dt)earlyInspection(dt)end)end
    end
    C_Timer.After(3,function()local ok,err=pcall(start);if not ok then ForeverHandheldDB=ForeverHandheldDB or {};failSafe(err)end end)
  elseif event=='PLAYER_REGEN_ENABLED' and not ready then
    local ok,err=pcall(start);if not ok then ForeverHandheldDB=ForeverHandheldDB or {};failSafe(err)end
  elseif ready then configure();guideLook() end
end)
