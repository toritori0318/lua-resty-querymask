local cjson = require "cjson"
local resty_sha1 = require "resty.sha1"
local str = require "resty.string"

local ok, tbl_new = pcall(require, "table.new")
if not ok then
    tbl_new = function (narr, nrec) return {} end
end

local _M = {
    _VERSION = '0.01',
}

local mt = { __index = _M }


function _M.new(self, p)
    p = p or {}
    local mode             = p["mode"] or "whitelist"
    local mask_part_string = p["mask_part_string"] or "*"
    local mask_part_length = p["mask_part_length"] or 3
    local mask_fill_string = p["mask_fill_string"] or "-"
    local mask_hash_seed   = p["mask_hash_seed"] or "seeeeeed"
    local max_field_length = p["max_field_length"] or 512
    local fields           = p["fields"] or {}

    return setmetatable({
        mode             = mode,
        mask_part_string = mask_part_string,
        mask_part_length = mask_part_length,
        mask_fill_string = mask_fill_string,
        mask_hash_seed   = mask_hash_seed,
        max_field_length = max_field_length,
        fields           = fields,
    }, mt)
end

function _M.get_query_data(self)
  local method = ngx.req.get_method()
  if method == "GET" then
    return ngx.req.get_uri_args()
  end

  ngx.req.read_body()
  
  local data = {}
  local content_type = ngx.req.get_headers()['content-type'] or ""
  if content_type:find("application/x-www-form-urlencoded", 1, true) then
    data = ngx.req.get_post_args()
  elseif content_type:find("application/json", 1, true) then
    local body = ngx.req.get_body_data()
    if body ~= nil then
      if not pcall(function () data = cjson.decode(body) end) then
        ngx.log(ngx.ERR, "json parse error.")
      end
    end
  end

  return data
end

function _M._mask_part(self, data)
  local data_length = data:len()
  if data_length <= self.mask_part_length then
    return data
  end

  local sub_str = data:sub(1, self.mask_part_length)
  local repeat_mask_str = string.rep(self.mask_part_string, data_length - self.mask_part_length)
  return sub_str .. repeat_mask_str
end

function _M._mask_hash(self, data)
  data = data or ""
  local sha1 = resty_sha1:new()
  sha1:update(data .. self.mask_hash_seed)
  local digest = sha1:final()
  return str.to_hex(digest)
end

function _M._mask(self, data)
  local ret = {}

  -- convert table
  --
  --  fields = {
  --    ["origin"] = {"attr1", "attr2"},
  --    ["part"]   = {"attr3"},
  --  }
  --
  --  to
  --
  --  fields = {
  --    ["attr1"] = "origin",
  --    ["attr2"] = "origin",
  --    ["attr3"] = "part",
  --  }
  local convert_fields = {}
  if self.mode == "blacklist" then
    -- target all keys
    for key, value in pairs(data) do
      convert_fields[key] = "origin"
    end
  end

  -- convert
  for key, fields in pairs(self.fields) do
    fields = fields or {}
    for j, field in ipairs(fields) do
      convert_fields[field] = key
    end
  end

  -- masked
  for field, op in pairs(convert_fields) do
    local mask_row = nil

    local param = data[field]
    if param then
      if op == "origin" then
        mask_row = param
      elseif op == "part" then
        mask_row = self:_mask_part(param)
      elseif op == "hash" then
        mask_row = self:_mask_hash(param)
      elseif op == "fill" then
        -- for blacklist
        mask_row = self.mask_fill_string
      end
    end

    if mask_row ~= nil then
      if (op == "origin" or op == "part") and string.len(mask_row) > self.max_field_length then
        mask_row = mask_row:sub(1, self.max_field_length-3) .. "..."
      end
      ret[field] = mask_row
    end
  end

  return ret
end

function _M.mask_query_table(self)
  local query_data = self:get_query_data()
  return self:_mask(query_data)
end

function _M.mask_query_string(self)
  return ngx.encode_args(self:mask_query_table())
end

return _M
