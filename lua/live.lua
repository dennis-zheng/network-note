
function GetHttpServer(device, arrayT)
	local redis = require("resty.redis")
	local red = redis:new()
	red:set_timeout(2000)

	local ok, err = red:connect("172.10.0.226", 63791)
	if not ok then
		ngx.say("connect redis error:", err)
		return 0
	end
	
	local httptype = 0
	local deviceid = "livems_"..device
	ok, err = red:get(deviceid)
	if ok ~= ngx.null then
		red:expire(deviceid, 300) -- 5min
		httptype = ok
	else
		arrayLiveServer = {}
		for key, value in pairs(arrayT)
		do
			ok, err = red:get(value)
                        if ok ~= ngx.null then 
		        	arrayLiveServer[key] = 0
				httptype = key
				--ngx.say(key, value, ok,":", arrayLiveServer[key])
			end
		end
		
		local res, err = red:smembers("LiveMS_Device")
		for key,value in pairs(res) do
		        ok, err = red:get(value)
		        if ok == ngx.null then
		                red:srem("LiveMS_Device", value)
			else
				--ngx.say(key, value, ok,":", arrayLiveServer[tonumber(ok)])
				ok = tonumber(ok)
				arrayLiveServer[ok] = arrayLiveServer[ok] + 1
		        end
		end
		
		minT = 65535
		--httptype = arrayLiveServer
		for key, value in pairs(arrayLiveServer)
		do
		        if (value <= 0)
		        then
		                minT = value
		                httptype = key
				break
		        elseif (value < minT)
		        then
		                minT = value
		                httptype = key
		        end
		end
		red:sadd("LiveMS_Device", deviceid)
		red:set(deviceid, httptype)
		red:expire(deviceid, 300)
	end
	--red:disconnect()
	return httptype
end

--local arrayT = {"1", "2", "3"}
local arrayT = {"http://172.10.0.111:8778_ms","http://172.10.10.111:8778_ms"}
local args = ngx.req.get_uri_args()
local device = args["device"]
local channel = args["channel"]

if (device and channel and device ~= '' and channel ~= '')
then
	local httptype = GetHttpServer(device..'_'..channel, arrayT)
	--local res_uri = ngx.re.gsub(ngx.var.request_uri, [=[[\?&]*type=[^&]+]=], "", "j") .. "&httpms=" .. httptype
	local res_uri = ngx.var.request_uri .. "&ms=" .. httptype
	--ngx.say(res_uri)
	ngx.exec(res_uri)
else
	ngx.say("uri error by lua.")
end

