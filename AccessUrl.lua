ip_bind_time = 300  --封禁IP 5分种时间,以秒为单位  
ip_bind_time_two = 3600  --封禁IP时间1小时 , 以秒为单位
ip_bind_time_three = 18000   --封禁IP时间5小时
ip_bind_time_four = 86400 --封禁IP时间1天
ip_bind_time_five = 864000 --封禁IP时间10天
ip_time_out = 60    --指定ip访问频率时间段  
connect_count = 5 --指定ip访问频率计数最大值  
--连接redis  
if whiteip() then
elseif blockip() then
elseif ngx.re.match(ngx.var.uri,"/xxxxxxxx","i") then
local redis = require "resty.redis"
local cache = redis.new()  
local ok , err = cache.connect(cache,"ip","port")
cache:set_timeout(60000)  
--如果连接失败，跳转到脚本结尾  
if not ok then  
  goto A  
end  
--查询ip是否在封禁段内，若在则返回403错误代码  
--因封禁时间会大于ip记录时间，故此处不对ip时间key和计数key做处理  
is_bind , err = cache:get("bind_"..ngx.var.remote_addr)  
if is_bind == "1" then  
  say_htmlcc(ngx.var.remote_addr)
  goto A
end  
start_time , err = cache:get("time_"..ngx.var.remote_addr)  
ip_count , err = cache:get("count_"..ngx.var.remote_addr)  
--如果ip记录时间大于指定时间间隔或者记录时间或者不存在ip时间key则重置时间key和计数key  
--如果ip时间key小于时间间隔，则ip计数+1，且如果ip计数大于ip频率计数，则设置ip的封禁key为1  
--同时设置封禁key的过期时间为封禁ip的时间  
if start_time == ngx.null or os.time() - start_time > ip_time_out then  
  res , err = cache:set("time_"..ngx.var.remote_addr , os.time())  
  res , err = cache:set("count_"..ngx.var.remote_addr , 1)  
else  
  ip_count = ip_count + 1  
  res , err = cache:incr("count_"..ngx.var.remote_addr)  
  if ip_count >= connect_count then 
    local acc_level , err = cache:zscore("block_ip",ngx.var.remote_addr)
    res , err = cache:set("bind_"..ngx.var.remote_addr,1)  
    if acc_level == null or  acc_level == ngx.null  then
        res , err = cache:expire("bind_"..ngx.var.remote_addr,ip_bind_time) 
        res , err = cache:zincrby("block_ip",1,ngx.var.remote_addr)
     elseif tonumber(acc_level) >= 1  and tonumber(acc_level) < 5 then
        res , err = cache:expire("bind_"..ngx.var.remote_addr,ip_bind_time_two) 
        res , err = cache:zincrby("block_ip",1,ngx.var.remote_addr)
     elseif tonumber(acc_level) >= 5  and tonumber(acc_level) < 10 then
        res , err = cache:expire("bind_"..ngx.var.remote_addr,ip_bind_time_three) 
        res , err = cache:zincrby("block_ip",1,ngx.var.remote_addr)
     elseif tonumber(acc_level) >= 10  and tonumber(acc_level) < 15 then
           res , err = cache:expire("bind_"..ngx.var.remote_addr,ip_bind_time_four)
           res , err = cache:zincrby("block_ip",1,ngx.var.remote_addr)
     else
        res , err = cache:expire("bind_"..ngx.var.remote_addr,ip_bind_time_five)
        res , err = cache:zincrby("block_ip",1,ngx.var.remote_addr)
    end
  end  
end  
--结尾标记  
::A::  
local ok, err = cache:close()  
end
