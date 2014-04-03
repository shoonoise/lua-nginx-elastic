json = require "json"
socket = require "socket"


if ngx.var.request_method == "GET" then
    options = { copy_all_vars = true }
elseif ngx.var.request_method == "POST" then
    options = { copy_all_vars = true, method = ngx.HTTP_POST }
elseif ngx.var.request_method == "HEAD" then
    options = { copy_all_vars = true, method = ngx.HTTP_HEAD }
else
    return ngx.exit(ngx.HTTP_METHOD_NOT_IMPLEMENTED)
end

function loc_capture(a, b)
    return ngx.location.capture(a, b)
end

target_url = ngx.var.target_url

target_resp = ngx.thread.spawn(loc_capture, target_url .. ngx.var.request_uri, options)

ok, result = ngx.thread.wait(target_resp)
request_time = ngx.now() - ngx.req.start_time()

if ok then
    ngx.log(ngx.INFO, target_url, " ", result.status)
    ngx.status = result.status
    exitcode = result.status
    resp_headers = result.header
    for key, value in pairs(result.header) do
        ngx.header[key] = value
    end
    ok, err = ngx.print(result.body)
    if not ok then
        ngx.log(ngx.ERR, target_url, " ngx.print failed ", err)
        exitcode = ngx.HTTP_INTERNAL_SERVER_ERROR
    end
    ok, err = ngx.eof()
    if not ok then
        ngx.log(ngx.ERR, target_url, " ngx.eof failed ", err)
        exitcode = ngx.HTTP_INTERNAL_SERVER_ERROR
    end
else
    ngx.log(ngx.ERR, target_url, " ngx.thread.wait() failed ", result.status, result.body)
    exitcode = ngx.HTTP_INTERNAL_SERVER_ERROR
end

function send_stat(body, _index, _type)
    url = '/elasticsearch' .. _index .. _type
    ngx.log(ngx.INFO, " sending logs to  ", url)
    res = ngx.location.capture(url, {method = ngx.HTTP_POST, body = body})
    return res
end

_index = string.format('/log-%s', os.date('%Y-%m-%d', ngx.req.start_time()))
_type = '/accesslog/'

-- Build JSON after getting original response
data = {}
data.status = result.status
data.request_url = ngx.var.request_uri
data.request_headers = ngx.req.get_headers()
data.resp_headers = resp_headers
data.request_time = request_time
data['@timestamp'], r =  string.gsub(ngx.utctime(), " ", "T")
data.method = ngx.req.get_method()
data.args = ngx.req.get_uri_args()
data.post_body = ngx.req.get_post_args()
data.host = socket.dns.gethostname()
data.remote_addr = ngx.var.remote_addr

if data.request_headers.cookie then 
    parsed_cookies = {}
    for key, value in string.gmatch(data.request_headers.cookie, "(%S-)=([^;]+)") do
        parsed_cookies[key] = value
    end
    data.request_cookies = parsed_cookies
end

data.set_cookies = data.resp_headers["Set-Cookie"]

if ngx.var.send_body == 'on' then
    data.body = result.body
end

body = json.encode(data) 
ngx.log(ngx.INFO, " SEND BODY ", body)

-- Send statistic
send_stat_result = ngx.thread.spawn(send_stat, body, _index, _type)

-- Wait ElasticSearch's response
ok, result = ngx.thread.wait(send_stat_result)
if ok and result.body then
     if json.decode(result.body).created then
        ngx.log(ngx.INFO, " ElasticSearch record created ", result.body)
     else
        ngx.log(ngx.ALERT, " ElasticSearch record failed ", result.status, result.body)
     end
else 
    ngx.log(ngx.ALERT, " Failed to send statistic to ElasticSearch ")
end

ngx.exit(exitcode)
