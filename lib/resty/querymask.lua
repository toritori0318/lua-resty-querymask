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
    local mask_part_string = p["mask_part_string"] or "*"
    local mask_part_length = p["mask_part_length"] or 3
    local mask_all_string  = p["mask_all_string"] or "-"
    local mask_hash_seed   = p["mask_hash_seed"] or "seeeeeed"
    local mask_fields      = p["mask_fields"] or {}

    return setmetatable({
        mask_part_string = mask_part_string,
        mask_part_length = mask_part_length,
        mask_all_string  = mask_all_string,
        mask_hash_seed   = mask_hash_seed,
        mask_fields      = mask_fields,
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
  for key, value in pairs(data) do
    local mask_row = data[key]

    local exitst_op = self.mask_fields[key] or ""
    if exitst_op == "part" then
      mask_row = self:_mask_part(value)
    elseif exitst_op == "all" then
      mask_row = self.mask_all_string
    elseif exitst_op == "hash" then
      mask_row = self:_mask_hash(value)
    elseif exitst_op == "trim" then
      mask_row = nil
    end

    if mask_row ~= nil then
      ret[key] = mask_row
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
