--
-- Created by IntelliJ IDEA.
-- User: wyc
-- Date: 17/8/9
-- Time: 下午4:05
-- To change this template use File | Settings | File Templates.
--

local args = ngx.req.get_uri_args()

if args.log_body then
  local chunk = ngx.arg[1]
  local file_log_data = ngx.ctx.file_log or { res_body = "" } -- minimize the number of calls to ngx.ctx while fallbacking on default value
  file_log_data.res_body = file_log_data.res_body .. chunk
  ngx.ctx.file_log = file_log_data
end


