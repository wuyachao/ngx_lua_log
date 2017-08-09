--
-- Created by IntelliJ IDEA.
-- User: wyc
-- Date: 17/8/9
-- Time: 下午4:08
-- To change this template use File | Settings | File Templates.
--

local ffi = require "ffi"
local cjson = require "cjson"
local system_constants = require "lua_system_constants"
local producer = require "resty.kafka.producer"

local ngx_timer = ngx.timer.at

local O_CREAT = system_constants.O_CREAT()
local O_WRONLY = system_constants.O_WRONLY()
local O_APPEND = system_constants.O_APPEND()
local S_IRUSR = system_constants.S_IRUSR()
local S_IWUSR = system_constants.S_IWUSR()
local S_IRGRP = system_constants.S_IRGRP()
local S_IROTH = system_constants.S_IROTH()

local oflags = bit.bor(O_WRONLY, O_CREAT, O_APPEND)
local mode = bit.bor(S_IRUSR, S_IWUSR, S_IRGRP, S_IROTH)

local function serialize(ngx)
  local file_log_ctx = ngx.ctx.file_log or {}
  return {
    request = {
      uri = ngx.var.request_uri,
      request_uri = ngx.var.scheme .. "://" .. ngx.var.host .. ":" .. ngx.var.server_port .. ngx.var.request_uri,
      querystring = ngx.req.get_uri_args(), -- parameters, as a table
      method = ngx.req.get_method(), -- http method
      headers = ngx.req.get_headers(),
      body = file_log_ctx.req_body,
      size = ngx.var.request_length
    },
    response = {
      status = ngx.status,
      headers = ngx.resp.get_headers(),
      size = ngx.var.bytes_sent,
      body = file_log_ctx.res_body
    },
    client_ip = ngx.var.remote_addr,
    started_at = ngx.req.start_time() * 1000
  }
end

ffi.cdef [[
int open(char * filename, int flags, int mode);
int write(int fd, void * ptr, int numbytes);
int close(int fd);
char *strerror(int errnum);
]]

local function string_to_char(str)
  return ffi.cast("uint8_t*", str)
end

-- fd tracking utility functions
local file_descriptors = {}

-- Log to a file. Function used as callback from an nginx timer.
-- @param `premature` see OpenResty `ngx.timer.at()`
-- @param `conf`     Configuration table, holds http endpoint details
-- @param `message`  Message to be logged
local function log(premature, conf, message)
  if premature then return end

  local msg = cjson.encode(message) .. "\n"

  local fd = file_descriptors[conf.path]

  if fd and conf.reopen then
    -- close fd, we do this here, to make sure a previously cached fd also
    -- gets closed upon dynamic changes of the configuration
    ffi.C.close(fd)
    file_descriptors[conf.path] = nil
    fd = nil
  end

  if not fd then
    fd = ffi.C.open(string_to_char(conf.path), oflags, mode)
    if fd < 0 then
      local errno = ffi.errno()
      ngx.log(ngx.ERR, "[file-log] failed to open the file: ", ffi.string(ffi.C.strerror(errno)))
    else
      file_descriptors[conf.path] = fd
    end
  end

  ffi.C.write(fd, string_to_char(msg), #msg)
end

-- log to kafka
local function kafka(premature, conf, message)
  if premature then return end

  local msg = cjson.encode(message)

  local broker_list = {
    { host = conf.kafka_host, port = conf.kafka_port },
  }

  local p = producer:new(broker_list, { producer_type = "async" })

  local size, err = p:send("log", nil, msg)
  if not size then
    ngx.log(ngx.ERR, "send log to kafka err:", err)
    return true
  end
end

local message = serialize(ngx)

local args = ngx.req.get_uri_args()

if args.log_type == 'file' then
  local ok, err = ngx_timer(0, log, args, message)
  if not ok then
    ngx.log(ngx.ERR, "[file-log] failed to create timer: ", err)
  end
else
  local ok, err = ngx_timer(0, kafka, args, message)
  if not ok then
    ngx.log(ngx.ERR, "[kafka-log] failed to create timer: ", err)
  end
end


