-- Presentation-only copies for protected profession overview labels.
-- Native buttons, font regions, callbacks, focus, icons and hit areas are read-only.
local copies=setmetatable({},{__mode='k'})
local serial=0
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function available(f)return f and not (f.IsForbidden and f:IsForbidden())end
local function value(r)
 if not available(r) or not r:IsShown() then return end
 local alpha=r.GetAlpha and r:GetAlpha() or 1
 local text=r:GetText()
 if not public(alpha) or type(alpha)~='number' or alpha<=0 or not public(text) or type(text)~='string' or text=='' then return end
 return text
end
local function font(parent,size)
 local r=parent:CreateFontString(nil,'OVERLAY')
 r:SetFont(STANDARD_TEXT_FONT,size,'');r:SetJustifyH('LEFT');r:SetJustifyV('TOP')
 return r
end
local function copyText(target,source,text)
 if target:GetText()~=text then target:SetText(text)end
 local r,g,b,a=source:GetTextColor()
 if public(r) and public(g) and public(b) and public(a) and type(r)=='number' and type(g)=='number' and type(b)=='number' and type(a)=='number' then
  local x,y,z,w=target:GetTextColor()
  if x~=r or y~=g or z~=b or w~=a then target:SetTextColor(r,g,b,a)end
 end
end
local function acquire(owner,book,width,kind)
 local e=copies[owner]
 if e then return e end
 serial=serial+1
 -- The shared window painter excludes named ForeverHandheld presentation.
 local frame=CreateFrame('Frame','ForeverHandheldProfessionLabel'..serial,book)
 frame.ForeverHandheldOwnedPresentation=true
 frame:EnableMouse(false);frame:SetFrameLevel(owner:GetFrameLevel()+3)
 frame:SetWidth(width)
 local bg=frame:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(.025,.030,.029,1)
 local title=font(frame,16);title:SetPoint('TOPLEFT',0,0);title:SetWidth(width)
 if kind=='button' then
  frame:SetPoint('LEFT',owner,'RIGHT',5,0);frame:SetHeight(42)
  local sub=font(frame,14);sub:SetPoint('TOPLEFT',0,-23);sub:SetWidth(width)
  e={frame=frame,title=title,sub=sub}
 else
  -- Regions have no frame level; owner here is their card, anchor below.
  e={frame=frame,title=title}
 end
 copies[owner]=e;return e
end
function ForeverHandheldPaintProfessionLabels(book)
 if InCombatLockdown() or not available(book) or not book:IsShown() then return end
 local content=book.ProfessionsContentFrame
 if not available(content) then return end
 local seen,count={},0
 for _,key in ipairs({'PrimaryProfession1','PrimaryProfession2','SecondaryProfession1','SecondaryProfession2','SecondaryProfession3'})do
  local card=content[key]
  if available(card) and card:IsShown() then
   for i=1,4 do
    local button=card['SpellButton'..i]
    if available(button) and button:IsShown() then
     local text=value(button.spellString)
     if text then
      local e=acquire(button,book,160,'button')
      copyText(e.title,button.spellString,text)
      local sub=value(button.subSpellString)
      if sub then copyText(e.sub,button.subSpellString,sub) elseif e.sub:GetText()~='' then e.sub:SetText('')end
      if not e.frame:IsShown() then e.frame:Show()end
      seen[button]=true;count=count+1
     end
    end
   end
   for _,field in ipairs({'ProfessionName','missingHeader','missingText'})do
    local source=card[field];local text=value(source)
    if text then
     local e=copies[source]
     if not e then
      -- Use the card only for frame-level lookup; key copies by source region.
      e=acquire(card,book,220,'text');copies[card]=nil;copies[source]=e
      e.frame:SetPoint(field=='missingText' and 'TOP' or 'CENTER',source,field=='missingText' and 'TOP' or 'CENTER',0,0)
      if field~='missingText' then e.title:SetJustifyH('CENTER')end
     end
     copyText(e.title,source,text)
     local h=math.max(22,e.title:GetStringHeight()+2)
     if math.abs(e.frame:GetHeight()-h)>.5 then e.frame:SetHeight(h)end
     if not e.frame:IsShown() then e.frame:Show()end
     seen[source]=true;count=count+1
    end
   end
  end
 end
 for owner,e in pairs(copies)do if not seen[owner] and e.frame:IsShown() then e.frame:Hide()end end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.professionLabels={version='3.7.60',seen=GetTime(),count=count}
end
