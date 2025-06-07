local uv = vim.uv

local frecency = {}
local table = nil

local config = {}

local get_score_from_value = function(value)
  return math.exp(config.gamma * (value - os.time()))
end

local get_value = function(score)
  return (math.log(score) / config.gamma) + os.time()
end

local get_score = function(name)
  local value = table[name]
  if not value then
    return 0
  end

  local score = get_score_from_value(value)
  if score > config.soft_max then
    score = config.soft_max
  end
  return score
end

local file_string = function(name, value)
  return name .. ";" .. tostring(value) .. "\n"
end

local save_score = function(score, name)
  if score > config.hard_max then
    score = config.hard_max
  end

  local value = get_value(score)
  table[name] = value

  local fd = assert(uv.fs_open(config.data_file_path, "a", tonumber("666", 8)))
  assert(uv.fs_write(fd, file_string(name, value)))
  assert(uv.fs_close(fd))

  return value
end

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    if not args.file or string.len(args.file) == 0 then
      -- file name is empty
      return
    end

    local score = get_score(args.file)
    score = score + 1
    save_score(score, args.file)
  end,
})

frecency.setup = function(con)
  if table then
    return
  end
  table = {}
  con = vim.F.if_nil(con, {})

  local halflife = vim.F.if_nil(con.halflife, 24 * 60 * 60)
  config.gamma = math.log(2) / halflife
  config.data_file_path = vim.F.if_nil(con.data_file_path, vim.fn.stdpath "state" .. "/telescope_frecency")
  config.soft_max = vim.F.if_nil(con.soft_max, math.huge)
  config.hard_max = vim.F.if_nil(con.hard_max, math.huge)

  local fd = uv.fs_open(config.data_file_path, "r", tonumber("666", 8))
  if not fd then
    return
  end
  local stat = assert(uv.fs_stat(config.data_file_path))
  local data = assert(uv.fs_read(fd, stat.size))
  assert(uv.fs_close(fd))

  for k, v in string.gmatch(data, "(.-);(.-)\n") do
    table[k] = tonumber(v)
  end

  fd = assert(uv.fs_open(config.data_file_path, "w", tonumber("666", 8)))
  for name, value in pairs(table) do
    assert(uv.fs_write(fd, file_string(name, value)))
  end
  assert(uv.fs_close(fd))
end

local ffi = require "ffi"

local library_path = (function()
  local dirname = string.sub(debug.getinfo(1).source, 2, #"/frecency.lua" * -1)
  if package.config:sub(1, 1) == "\\" then
    return dirname .. "../build/libfrecency.dll"
  else
    return dirname .. "../build/libfrecency.so"
  end
end)()
local native = ffi.load(library_path)

ffi.cdef [[
    typedef struct {} fastMap;

    fastMap *init();
    void set_score(fastMap *, const char *, float);
    float get_score(fastMap *, const char *);
    void freeMap(fastMap *);
]]

frecency.init = function()
  local map = native.init()

  for key, _ in pairs(table) do
    native.set_score(map, key, get_score(key))
  end
  return map
end

frecency.get_score = function(map, key)
  return native.get_score(map, key)
end

frecency.free = function(map)
  native.freeMap(map)
end

return frecency
