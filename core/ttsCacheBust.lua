-- TTS cache-buster for the 12.0 speech engine (TBC Anniversary, Mists, Retail).
--
-- The engine caches synthesized audio keyed by the spoken text and, when the
-- same text comes again, REPLAYS the cached audio without invoking the voice.
-- For a real voice the replay is audible. For a screen-reader bridge voice
-- (NVDA through SAPI2SR) the voice is never called, so the cached audio is
-- silent: an entry goes quiet from its second visit on, and stays quiet.
--
-- Appending a varying run of U+00A0 NO-BREAK SPACE makes every repeat a new
-- text, so every utterance is a cache miss and the voice runs. Trailing
-- whitespace is inaudible, and U+00A0 is not XML whitespace, so the engine's
-- normalization cannot trim it back into one cache key.
--
-- Ported from Sku's SkuVoice-1.0 (v43.2 to v43.5), where each rule was
-- measured on the client:
-- - Markup does NOT bust (a varying <bookmark>): the engine strips it before
--   keying the cache. Only real character data works.
-- - The count is kept PER TEXT. One global counter cycling 1..64 let a line
--   repeated exactly 64 utterances later collide with itself.
-- - A text seen for the first time starts at a rotating seed, not at 1, so
--   wiping the table cannot collide every text with its own first use.
-- - The counts survive /reload: the cache lives in the engine, not in Lua.
--   They are kept in the account store.
local cacheBust = {}
WowVision.ttsCacheBust = cacheBust

local NBSP = "\194\160"
-- 512 variants per text: the trailing run cycles 1..64 fastest; each wrap adds
-- one more LEADING no-break space (0..7). Inaudible in both places.
local TRAIL = 64
local LEAD = 8
local MAX = TRAIL * LEAD
-- The table is bounded by a plain wipe, not an LRU; the seeding keeps a wipe
-- harmless (see nextRun).
local KEYS_MAX = 512
-- Longer texts (quest text) are keyed by a hash so the saved table stays small.
local KEY_VERBATIM_MAX = 48

cacheBust.MAX = MAX
cacheBust.KEYS_MAX = KEYS_MAX

local function newStore()
    return { seen = {}, keys = 0, seed = 0 }
end

local function validStore(store)
    if type(store.seen) ~= "table" then
        store.seen = {}
    end
    if type(store.keys) ~= "number" then
        store.keys = 0
    end
    if type(store.seed) ~= "number" then
        store.seed = 0
    end
    return store
end

-- Counts handed out before the account store is bound (and on a client that
-- swaps the store in late) live here and are carried over on adoption.
local current = newStore()

-- Returns the persisted store, or nil while the account store is not bound.
-- Replaceable so the headless tests can run without a db.
function cacheBust.defaultStoreSource()
    local db = WowVision.globalDb
    if type(db) ~= "table" then
        return nil
    end
    local store = db._ttsCacheBust
    if type(store) ~= "table" then
        store = newStore()
        db._ttsCacheBust = store
    end
    return validStore(store)
end
cacheBust.storeSource = cacheBust.defaultStoreSource

-- Carry the counts handed out so far into a newly bound store. Where both
-- know a text the store's count wins: it is the longer history.
local function adopt(store)
    for key, run in pairs(current.seen) do
        if store.seen[key] == nil then
            store.seen[key] = run
            store.keys = store.keys + 1
        end
    end
    if current.seed > store.seed then
        store.seed = current.seed
    end
    current = store
end

local function getStore()
    local store = cacheBust.storeSource()
    if store ~= nil and store ~= current then
        adopt(store)
    end
    return current
end

function cacheBust.textKey(text)
    local length = #text
    if length <= KEY_VERBATIM_MAX then
        return text
    end
    local hash = 5381
    local byte = string.byte
    for i = 1, length do
        hash = (hash * 33 + byte(text, i)) % 4294967296
    end
    return string.format("#%d:%08x", length, hash)
end

local function nextRun(key)
    local store = getStore()
    if store.keys >= KEYS_MAX then
        store.seen = {}
        store.keys = 0
    end
    local run = store.seen[key]
    if run ~= nil then
        run = (run % MAX) + 1
    else
        store.seed = (store.seed % MAX) + 1
        run = store.seed
        store.keys = store.keys + 1
    end
    store.seen[key] = run
    return run
end

local function speakable(text)
    -- Retail's secret values throw on any string operation; they pass through
    -- untouched (the speech API accepts them).
    if issecretvalue ~= nil and issecretvalue(text) then
        return false
    end
    return type(text) == "string" and text ~= ""
end

-- Make this utterance's text unique so the engine cannot replay cached audio.
function cacheBust.bust(text)
    if not speakable(text) then
        return text
    end
    local run = nextRun(cacheBust.textKey(text))
    local trail = ((run - 1) % TRAIL) + 1
    local lead = math.floor((run - 1) / TRAIL)
    return string.rep(NBSP, lead) .. text .. string.rep(NBSP, trail)
end

-- Whether a buster is already applied: the spoken text (markup removed) ends
-- in a no-break space. Ours does; Sku's appends one before its bookmarks.
function cacheBust.isBusted(text)
    local bare = string.gsub(text, "%b<>", "")
    return string.sub(bare, -2) == NBSP
end

-- For text from other callers (Blizzard, other addons) routed through our
-- speech queue: bust it unless it already carries a buster, so lines from an
-- addon with its own buster do not churn our table.
function cacheBust.bustForeign(text)
    if not speakable(text) or cacheBust.isBusted(text) then
        return text
    end
    return cacheBust.bust(text)
end

-- Tests only: forget the in-memory counts.
function cacheBust._reset()
    current = newStore()
end
