## Name


ngx_lua_log - 用于将通过Nginx请求的method,headers,body等以json的形式保存到文件或者kafka中。

## depend

* 需要openresty，或者Nginx安装ngx_lua模块。[openresty-更好的Nginx](https://github.com/openresty)
* 如果保存到kafka，则需要安装[lua_resty_kafka](https://github.com/doujiang24/lua-resty-kafka)
* 因为Nginx使用自带的resolver，如果域名不能解析或者自定义的域名可以使用[dnsmasq](http://www.cnblogs.com/mentalidade/p/6934162.html)

## example

请求`http://wyc.com:9999/ttt/aaa/bbb?log_type=file&log_body=true&path=/tmp/test.log`

#### 请求参数

> 仅仅为了举例，为了直观方便调试，将这些放到url参数中。将这些以配置的方式放到config.lua文件中更好。

| Name               | Description                                            |
| ------------------| -------------------------------------------------------|
| `log_type`          | 日志类型：file:以文件形式保存 kafka: 保存到kafka           |
| `log_body`         | 是否记录请求和接口返回的body体                       |
| `path`             | 日志文件保存的路径文件，该目录和文件需要Nginx读写的权限      |

#### 返回：

```
{
    "time": 1502274241,
    "uri": "/test/aaa/bbb",
    "request_uri": "/test/aaa/bbb?log_type=file&log_body=true&path=/tmp/test.log"
}

```

#### 日志内容

```
{
    "request": {
        "method": "GET",
        "uri": "/ttt/aaa/bbb?log_type=file&log_body=true&path=/tmp/test.log",
        "size": "477",
        "request_uri": "http://wyc.com:9999/ttt/aaa/bbb?log_type=file&log_body=true&path=/tmp/test.log",
        "querystring": {
            "path": "/tmp/test.log",
            "log_type": "file",
            "log_body": "true"
        },
        "headers": {
            "host": "wyc.com:9999",
            "accept-language": "zh-CN,zh;q=0.8,en;q=0.6",
            "cookie": "V2EX_LANG=zhcn",
            "connection": "keep-alive",
            "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
            "accept-encoding": "gzip, deflate",
            "upgrade-insecure-requests": "1",
            "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36"
        }
    },
    "started_at": 1502274241665,
    "response": {
        "status": 200,
        "body": "{\"time\":1502274241,\"uri\":\"\\/test\\/aaa\\/bbb\",\"request_uri\":\"\\/test\\/aaa\\/bbb?log_type=file&log_body=true&path=\\/tmp\\/test.log\"}\n",
        "size": "282",
        "headers": {
            "content-length": "127",
            "content-type": "text/plain",
            "connection": "close"
        }
    },
    "client_ip": "127.0.0.1"
}

```

