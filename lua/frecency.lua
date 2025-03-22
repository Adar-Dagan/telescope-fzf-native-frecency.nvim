local uv = vim.uv

local frecency = {}
local table = nil

local halflife_in_secs = 60 * 60 * 24
local gamma = math.log(2) / halflife_in_secs
local save_file_path = vim.fn.stdpath "state" .. "/telescope_frecency"

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    if not args.file or string.len(args.file) == 0 then
      -- file name is empty
      return
    end

    local score = frecency.get_score(args.file)
    score = score + 1
    frecency.save_score(score, args.file)
  end,
})

local get_score = function(value)
  return math.exp(gamma * (value - os.time()))
end

local get_value = function(score)
  return (math.log(score) / gamma) + os.time()
end

frecency.get_score = function(name)
  local value = table[name]
  if not value then
    return 0
  end

  return get_score(value)
end

local file_string = function(name, value)
  return name .. ";" .. tostring(value) .. "\n"
end

frecency.save_score = function(score, name)
  local value = get_value(score)
  table[name] = value

  local fd = assert(uv.fs_open(save_file_path, "a", tonumber("666", 8)))
  assert(uv.fs_write(fd, file_string(name, value)))
  assert(uv.fs_close(fd))

  return value
end

frecency.setup = function()
  if table then
    return
  end
  table = {}

  local fd = uv.fs_open(save_file_path, "r", tonumber("666", 8))
  if not fd then
    return
  end
  local stat = assert(uv.fs_stat(save_file_path))
  local data = assert(uv.fs_read(fd, stat.size))
  assert(uv.fs_close(fd))

  for k, v in string.gmatch(data, "(.-);(.-)\n") do
    table[k] = tonumber(v)
  end

  fd = assert(uv.fs_open(save_file_path, "w", tonumber("666", 8)))
  for name, value in pairs(table) do
    assert(uv.fs_write(fd, file_string(name, value)))
  end
  assert(uv.fs_close(fd))
end

return frecency
