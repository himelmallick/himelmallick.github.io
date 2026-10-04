-- Builds the lists on the Talks page from the "talks" entries at the top of
-- talks/index.qmd. An entry moves from "Upcoming" to its own list by itself
-- once its date has passed, because the site is rebuilt every night.
--
-- Each entry has: date ("2027-03" or "2027-03-14"), type (course, keynote or
-- invited), title, where, and optionally link and note.

local MONTHS = { "January", "February", "March", "April", "May", "June", "July",
                 "August", "September", "October", "November", "December" }
local LABELS = { course = "Short course", keynote = "Keynote", invited = "Invited talk" }

local function text(value)
  return value and pandoc.utils.stringify(value) or ""
end

local function inlines(value)
  if value == nil then return pandoc.Inlines({}) end
  if pandoc.utils.type(value) == "Inlines" then return value end
  return pandoc.Inlines({ pandoc.Str(pandoc.utils.stringify(value)) })
end

-- "2027-03" is treated as the last day of that month, so an event stays under
-- "Upcoming" until its month is over.
local function last_day(date)
  if #date == 7 then return date .. "-31" end
  return date
end

local function pretty(date)
  local y, m, d = date:match("^(%d%d%d%d)-(%d%d)-?(%d*)$")
  if not y then return date end
  local month = MONTHS[tonumber(m)] or m
  if d ~= "" then return month .. " " .. tonumber(d) .. ", " .. y end
  return month .. " " .. y
end

local function entry_blocks(e, with_label)
  local line = pandoc.Inlines({})
  local title = pandoc.Strong(inlines(e.title))
  if e.link then
    line:insert(pandoc.Link({ title }, text(e.link)))
  else
    line:insert(title)
  end
  line:insert(pandoc.LineBreak())
  line:extend(inlines(e.where))
  local small = {}
  if with_label then small[#small + 1] = LABELS[text(e.type)] or text(e.type) end
  if e.note then small[#small + 1] = text(e.note) end
  if #small > 0 then
    line:insert(pandoc.LineBreak())
    line:insert(pandoc.Span({ pandoc.Str(table.concat(small, " · ")) }, pandoc.Attr("", { "where" })))
  end
  return { pandoc.Para(line) }
end

local function list_of(entries, with_label)
  local items = {}
  for _, e in ipairs(entries) do
    items[#items + 1] = { { pandoc.Str(pretty(text(e.date))) }, { entry_blocks(e, with_label) } }
  end
  return pandoc.Div({ pandoc.DefinitionList(items) }, pandoc.Attr("", { "honors", "talks" }))
end

function Pandoc(doc)
  local talks = doc.meta.talks
  if not talks then return doc end
  -- New York time, to the nearest hour or so; only the date matters
  local today = os.getenv("SITE_TODAY") or os.date("!%Y-%m-%d", os.time() - 5 * 3600)
  local shown = tonumber(text(doc.meta["invited-shown"])) or 10

  local upcoming, past = {}, { course = {}, keynote = {}, invited = {} }
  for i, e in ipairs(talks) do
    e.position = i                      -- keeps the order of the file when dates tie
    local kind = text(e.type)
    if last_day(text(e.date)) >= today then
      upcoming[#upcoming + 1] = e
    elseif past[kind] then
      table.insert(past[kind], e)
    end
  end
  table.sort(upcoming, function(a, b)
    if text(a.date) ~= text(b.date) then return text(a.date) < text(b.date) end
    return a.position < b.position
  end)
  for _, group in pairs(past) do
    table.sort(group, function(a, b)
      if last_day(text(a.date)) ~= last_day(text(b.date)) then
        return last_day(text(a.date)) > last_day(text(b.date))
      end
      return a.position < b.position
    end)
  end
  local invited = {}
  for i = 1, math.min(shown, #past.invited) do invited[i] = past.invited[i] end

  local lists = {
    ["talks-upcoming"] = #upcoming > 0 and list_of(upcoming, true)
      or pandoc.Para({ pandoc.Str("Nothing is scheduled at the moment.") }),
    ["talks-courses"]  = list_of(past.course, false),
    ["talks-keynotes"] = list_of(past.keynote, false),
    ["talks-invited"]  = list_of(invited, false),
  }
  doc.blocks = doc.blocks:walk({
    Div = function(div)
      if lists[div.identifier] then return lists[div.identifier] end
    end
  })
  return doc
end
