-- access_by_lua_file '/usr/local/nginx/conf/hd_url.lua';
 --        
if ngx.re.match(ngx.var.request_uri,"(/Capply/get_verify_code).*$") then
    local method=ngx.req.get_method()
    if method == "POST" then
        local argsMobile = nil
        ngx.req.read_body()
        local args = ngx.req.get_post_args()
        local ck = ngx.var.http_cookie

        argsMobile = args["mobile"]
        if argsMobile == nil or argsMobile=="test" then
            ngx.exit(444)
        elseif ck == nil then
            ngx.exit(401)
        end

        return
    else
        ngx.exit(444)
    end
end
