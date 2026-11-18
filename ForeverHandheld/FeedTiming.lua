-- The two passive feeds wake for messages, Comms changes and visible fades.
local _, addon=...
local feeds={}

function addon.createFeedRefresh(draw, errorKey)
  local timer,scheduledAt
  local function refresh()
    local now=GetTime()
    local ok,nextAt=pcall(draw,now)
    if not ok then
      ForeverHandheldDB=ForeverHandheldDB or {}
      ForeverHandheldDB[errorKey]=tostring(nextAt)
      nextAt=nil
    end
    if nextAt==scheduledAt then return end
    if timer then timer:Cancel();timer=nil end
    scheduledAt=nextAt
    if nextAt then
      timer=C_Timer.NewTimer(math.max(0,nextAt-now),function()
        timer,scheduledAt=nil,nil
        refresh()
      end)
    end
  end
  feeds[#feeds+1]=refresh
  return refresh
end

function addon.refreshFeeds()
  for _,refresh in ipairs(feeds) do refresh() end
end
