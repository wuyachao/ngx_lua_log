reated by IntelliJ IDEA.
-- User: wyc
-- Date: 17/8/9
-- Time: 下午3:58
-- To change this template use File | Settings | File Templates.
--
local string_find = string.find
local req_read_body = ngx.req.read_body
local req_get_headers = ngx.req.get_headers
local req_get_body_data = ngx.req.get_body_data
local req_get_post_args = ngx.req.get_post_args
local req_body, res_body = "", ""
local req_post_args = {}

local args = ngx.req.get_uri_args()

if args.log_body then
  req_read_body()
  req_body = req_get_body_data()

  local headers = req_get_headers()
  local content_type = headers["content-type"]
  if content_type and string_find(content_type:lower(), "application/x-www-form-urlencoded", nil, true) then
    req_post_args = req_get_post_args()
  end
end

-- keep in memory the bodies for this request
ngx.ctx.file_log = {
  req_body = req_body,
  res_body = res_body,
  req_post_args = req_post_args
}
