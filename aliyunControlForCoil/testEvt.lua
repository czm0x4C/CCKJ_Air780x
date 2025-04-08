local sys = require "sys"
aliyun = require "aliyun"
require "relayControl"
-- 按键的状态
oneceFlag = {false, false, false, false, false, false, false, false, false, false, false, false}   -- 定时的一分钟只是执行一次
loopTimeOneceFlag = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
--[[
函数名：pubqos1testackcb
功能  ：发布1条qos为1的消息后收到PUBACK的回调函数
参数  ：
		usertag：调用mqttclient:publish时传入的usertag
		result：任意数字表示发布成功，nil表示失败
返回值：无
]]
function publishFinishCb(result,para)
    log.info("aliyun", "发布后的反馈", result,para)
end

---数据接收的处理函数
-- @string topic，UTF8编码的消息主题
-- @string payload，原始编码的消息负载
local function rcvCbFnc(topic,payload,qos,retain,dup)
    log.info("aliyun", "收到下行数据", topic,payload,qos,retain,dup)
    --/* 解析订阅的消息 */
    
    if(topic == "/sys/".. aliyun.opts.ProductKey.."/".. aliyun.opts.DeviceName.."/thing/service/property/set") then --设备属性设置topic
        local jsonData, result, errinfo = json.decode(payload)
        
        if(result) then
            -- 变化上报
            if(jsonData["params"]["updateRule"]) then 
                print("updateRule",jsonData["params"]["updateRule"])
                updateRule = tonumber(jsonData["params"]["updateRule"])
                fskv.set("updateRule", updateRule)
            end
            -- 时间上报
            if(jsonData["params"]["updateTime"]) then 
                print("updateTime",jsonData["params"]["updateTime"])
                updateTime = tonumber(jsonData["params"]["updateTime"])
                fskv.set("updateTime", updateTime)
            end
            -- 通道1折算
            if(jsonData["params"]["channel_1_scale"]) then 
                print("channel_1_scale",jsonData["params"]["channel_1_scale"])
                reflectionScale_A = tonumber(jsonData["params"]["channel_1_scale"])
                fskv.set("reflectionScale_A", reflectionScale_A)
            end
            -- 通道2折算
            if(jsonData["params"]["channel_2_scale"]) then 
                print("channel_2_scale",jsonData["params"]["channel_2_scale"])
                reflectionScale_B = tonumber(jsonData["params"]["channel_2_scale"])
                fskv.set("reflectionScale_B", reflectionScale_B)
            end
            -- 开关状态设置的json解析
            if(jsonData["params"]["relay_1_out"]) then 
                if(1 == jsonData["params"]["relay_1_out"]) then
                    openRelay(1)
                    openLed(1)
                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        "{\"params\":{\"relay_1_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                        publishFinishCb,"打开 通道 1 继电器")
                else
                    closeRelay(1)
                    closeLed(1)
                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        "{\"params\":{\"relay_1_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                        publishFinishCb,"关断 通道 1 继电器")
                end
            end

            if(jsonData["params"]["relay_2_out"]) then 
                if(1 == jsonData["params"]["relay_2_out"]) then
                    openRelay(2)
                    openLed(2)
                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        "{\"params\":{\"relay_2_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                        publishFinishCb,"打开 通道 2 继电器")
                else
                    closeRelay(2)
                    closeLed(2)
                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        "{\"params\":{\"relay_2_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                        publishFinishCb,"关断 通道 2 继电器")
                end
            end

            if(jsonData["params"]["relay_3_out"]) then 
                if(1 == jsonData["params"]["relay_3_out"]) then
                    openRelay(3)
                    openLed(3)
                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        "{\"params\":{\"relay_3_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                        publishFinishCb,"打开 通道 3 继电器")
                else
                    closeRelay(3)
                    closeLed(3)
                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        "{\"params\":{\"relay_3_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                        publishFinishCb,"关断 通道 3 继电器")
                end
            end

            if(jsonData["params"]["relay_4_out"]) then 
                if(1 == jsonData["params"]["relay_4_out"]) then
                    openRelay(4)
                    openLed(4)
                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        "{\"params\":{\"relay_4_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                        publishFinishCb,"打开 通道 4 继电器")
                else
                    closeRelay(4)
                    closeLed(4)
                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        "{\"params\":{\"relay_4_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                        publishFinishCb,"关断 通道 4 继电器")
                end
            end
            -- 定时设置判断
            if(jsonData["params"]["DeviceTimer"]) then
                local newTimer = {
                    E = 0,
                    Y = 0
                }
                for i=1,12 do -- 遍历13组定时
                    if  json.encode(jsonData["params"]["DeviceTimer"][i]["Y"]) == "0" then         -- 判断定时器是否被配置 0:未配置
                        table.remove(jsonData.params.DeviceTimer, i)                               -- 删除未配置的定时组
                        table.insert(jsonData.params.DeviceTimer, i, newTimer)
                    end
                end
                -- 定时的时间消息发送到客户端的时候，需要注意这段数据直接再发送到服务器端，这样云智能APP端的定时才会显示
                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        json.encode(jsonData),
                        publishFinishCb,"send orginal timer table")
                -- 手机端的定时显示是不会再次交互了，意思就是定时时间结束设备这边是不会收到信息的，同时超过实际的定时时间也是不会显示的（例如定时为6.30 在6.40再发送一次6.30的定时时间，APP端不会显示）
                -- 过期的时间应该就在设备端删除再上传更新到云端，APP端也会同步更新
                timerList = json.encode(jsonData["params"]) -- 记录定时表
                fskv.set("timerList", timerList)
                print(timerList)
            end
        else
            print("payload = ",payload,"json parese error:",errinfo)
        end
    end
end

--- 连接结果的处理函数
-- @bool result，连接结果，true表示连接成功，false或者nil表示连接失败
local function connectCbFnc(result)
    log.info("aliyun","连接结果", result)
    if result then
        sys.publish("aliyun_ready")
        log.info("aliyun", "连接成功")
        --订阅主题
        aliyun.subscribe("/sys".."/".. aliyun.opts.ProductKey.."/".. aliyun.opts.DeviceName.."/thing/service/property/set",1)
        aliyun.subscribe("/sys".."/".. aliyun.opts.ProductKey.."/".. aliyun.opts.DeviceName.."/thing/event/property/post_reply",1)
        --初始化设置开关状态
        aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        "{\"params\":{\"CellSignalStrength\":"..tostring(mobile.csq())..
                        ",\"CardID\":\""..mobile.iccid().."\""..
                        ",\"channel_1_scale\":"..tostring(reflectionScale_A)..
                        ",\"channel_2_scale\":"..tostring(reflectionScale_B)..
                        ",\"updateRule\":"..tostring(updateRule)..
                        ",\"updateTime\":"..tostring(updateTime)..
                        "},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                        publishFinishCb,"发送上电初始值")
    else
        log.warn("aliyun", "连接失败")
    end
end

-- 连接状态的处理函数
aliyun.on("connect",connectCbFnc)

-- 数据接收的处理函数
aliyun.on("receive",rcvCbFnc)

-- 计算当前时间距离目标时间的分钟数差值
-- @param current_hour 当前时间的小时（0~23）
-- @param current_minute 当前时间的分钟（0~59）
-- @param target_hour 目标时间的小时（0~23）
-- @param target_minute 目标时间的分钟（0~59）
-- @return 当前时间距离目标时间的分钟数差值
function get_minutes_difference(current_hour, current_minute, target_hour, target_minute)
    -- 计算总分钟数
    local current_total_minutes = current_hour * 60 + current_minute
    local target_total_minutes = target_hour * 60 + target_minute

    -- 计算差值
    local difference_minutes = target_total_minutes - current_total_minutes

    return difference_minutes
end

-- 定时功能任务
-- 生活物联网的定时规则说明: https://help.aliyun.com/document_detail/250198.html?spm=5176.2020520104.console-base_help.dexternal.47a643ecFofQW4
sys.taskInit(function()
    
    while true do
        -- 获取当前时间
        local current_time = os.time()
        -- 根据RTC时间来判断定时时间是否到达
        local jsonData, result, errinfo = json.decode(timerList)
        -- 数据格式说明https://help.aliyun.com/document_detail/250198.html?spm=a2c4g.129209.0.0.50db590dqM38He
        if result then
            for i=1,12 do -- 遍历13组定时
                -- cron格式：分 时 日 月 周 年
                if  json.encode(jsonData["DeviceTimer"][i]["Y"]) == "1"  and  json.encode(jsonData["DeviceTimer"][i]["E"]) == "1" then         -- 判断定时器是否被配置 1:倒计时
                    -- print(i,jsonData["DeviceTimer"][i]["A"]) -- 动作
                    -- print(i,jsonData["DeviceTimer"][i]["T"]) -- 时间
                    -- 对于倒计时来说，设置的时间是固定时间,所以直接判断
                    local words = string.split(jsonData["DeviceTimer"][i]["T"],' ') -- 获得时间表中的定时时间 cron格式的各部分
                    if os.date("%Y", current_time) == words[6]  and os.date("%m", current_time) == words[4] and os.date("%d", current_time) == words[3] then -- 年月日相等
                        if tonumber(os.date("%H", current_time)) >= tonumber(words[2])  and tonumber(os.date("%M", current_time)) >= tonumber(words[1]) then -- 时分相等
                            print("倒计时定时时间到")
                            -- 此处添加定时任务到了的动作

                            if json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_1_out:0\"" then
                                closeRelay(1)
                                closeLed(1)
                                if aliyun.ready() then
                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                    "{\"params\":{\"relay_1_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                    publishFinishCb,"send relay_1_out stat 0")
                                end
                            elseif json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_1_out:1\"" then
                                openRelay(1)
                                openLed(1)
                                if aliyun.ready() then
                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                    "{\"params\":{\"relay_1_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                    publishFinishCb,"send relay_1_out stat 1")
                                end
                            end

                            if json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_2_out:0\"" then
                                closeRelay(2)
                                closeLed(2)
                                if aliyun.ready() then
                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                    "{\"params\":{\"relay_2_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                    publishFinishCb,"send relay_2_out stat 0")
                                end
                            elseif json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_2_out:1\"" then
                                openRelay(2)
                                openLed(2)
                                if aliyun.ready() then
                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                    "{\"params\":{\"relay_2_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                    publishFinishCb,"send relay_2_out stat 1")
                                end
                            end

                            if json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_3_out:0\"" then
                                closeRelay(3)
                                closeLed(3)
                                if aliyun.ready() then
                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                    "{\"params\":{\"relay_3_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                    publishFinishCb,"send relay_3_out stat 0")
                                end
                            elseif json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_3_out:1\"" then
                                openRelay(3)
                                openLed(3)
                                if aliyun.ready() then
                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                    "{\"params\":{\"relay_3_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                    publishFinishCb,"send relay_3_out stat 1")
                                end
                            end

                            if json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_4_out:0\"" then
                                closeRelay(4)
                                closeLed(4)
                                if aliyun.ready() then
                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                    "{\"params\":{\"relay_4_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                    publishFinishCb,"send relay_4_out stat 0")
                                end
                            elseif json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_4_out:1\"" then
                                openRelay(4)
                                openLed(4)
                                if aliyun.ready() then
                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                    "{\"params\":{\"relay_4_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                    publishFinishCb,"send relay_4_out stat 1")
                                end
                            end

                            jsonData["DeviceTimer"][i]["Y"] = 0 -- 设置当前组定时无效,定时任务的删除在设备端接收到定时任务时，会自动删除配置无效的定时
                            timerList = json.encode(jsonData)   -- 重新写入定时组

                            local tempString = '{"method":"thing.service.property.set","version":"1.0.0"}'  -- 更新云端定时消息
                            local sendJsonData = json.decode(tempString)
                            sendJsonData["method"] = "thing.service.property.set"
                            sendJsonData["version"] = "1.0"
                            sendJsonData["params"] =  json.decode(timerList)

                            if aliyun.ready() then
                                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                json.encode(sendJsonData),
                                publishFinishCb,"send orginal timer table")
                            end
                            print(json.encode(sendJsonData))
                            fskv.set("timerList", timerList)
                            
                        end
                    end
                end

                if  json.encode(jsonData["DeviceTimer"][i]["Y"]) == "2"  and  json.encode(jsonData["DeviceTimer"][i]["E"]) == "1" then         -- 判断定时器是否被配置 2:本地定时     
                    local words = string.split(jsonData["DeviceTimer"][i]["T"],' ') -- 获得时间表中的定时时间 cron格式的各部分
                    if words[5] == '?' then -- 先判断周位置是否为 ? ，此?代表周不指定，逻辑和倒计时定时一致
                        -- print(i,jsonData["DeviceTimer"][i]["A"]) -- 动作
                        -- print(i,jsonData["DeviceTimer"][i]["T"]) -- 时间
                        -- 对于倒计时来说，设置的时间是固定时间,所以直接判断
                        if os.date("%Y", current_time) == words[6]  and os.date("%m", current_time) == words[4] and os.date("%d", current_time) == words[3] then -- 年月日相等
                            if tonumber(os.date("%H", current_time)) >= tonumber(words[2])  and tonumber(os.date("%M", current_time)) >= tonumber(words[1]) then -- 时分相等
                                print("普通定时时间到")
                                
                                if json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_1_out:0\"" then
                                    closeRelay(1)
                                    closeLed(1)
                                    if aliyun.ready() then
                                        aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                        "{\"params\":{\"relay_1_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                        publishFinishCb,"send relay_1_out stat 0")
                                    end
                                elseif json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_1_out:1\"" then
                                    openRelay(1)
                                    openLed(1)
                                    if aliyun.ready() then
                                        aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                        "{\"params\":{\"relay_1_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                        publishFinishCb,"send relay_1_out stat 1")
                                    end
                                end
    
                                if json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_2_out:0\"" then
                                    closeRelay(2)
                                    closeLed(2)
                                    if aliyun.ready() then
                                        aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                        "{\"params\":{\"relay_2_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                        publishFinishCb,"send relay_2_out stat 0")
                                    end
                                elseif json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_2_out:1\"" then
                                    openRelay(2)
                                    openLed(2)
                                    if aliyun.ready() then
                                        aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                        "{\"params\":{\"relay_2_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                        publishFinishCb,"send relay_2_out stat 1")
                                    end
                                end
    
                                if json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_3_out:0\"" then
                                    closeRelay(3)
                                    closeLed(3)
                                    if aliyun.ready() then
                                        aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                        "{\"params\":{\"relay_3_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                        publishFinishCb,"send relay_3_out stat 0")
                                    end
                                elseif json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_3_out:1\"" then
                                    openRelay(3)
                                    openLed(3)
                                    if aliyun.ready() then
                                        aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                        "{\"params\":{\"relay_3_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                        publishFinishCb,"send relay_3_out stat 1")
                                    end
                                end
    
                                if json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_4_out:0\"" then
                                    closeRelay(4)
                                    closeLed(4)
                                    if aliyun.ready() then
                                        aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                        "{\"params\":{\"relay_4_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                        publishFinishCb,"send relay_4_out stat 0")
                                    end
                                elseif json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_4_out:1\"" then
                                    openRelay(4)
                                    openLed(4)
                                    if aliyun.ready() then
                                        aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                        "{\"params\":{\"relay_4_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                        publishFinishCb,"send relay_4_out stat 1")
                                    end
                                end

                                jsonData["DeviceTimer"][i]["Y"] = 0 -- 设置当前组定时无效,定时任务的删除在设备端接收到定时任务时，会自动删除配置无效的定时
                                timerList = json.encode(jsonData)   
    
                                local tempString = '{"method":"thing.service.property.set","version":"1.0.0"}'
                                local sendJsonData = json.decode(tempString)
                                sendJsonData["method"] = "thing.service.property.set"
                                sendJsonData["version"] = "1.0"
                                sendJsonData["params"] =  json.decode(timerList)
    
                                if aliyun.ready() then
                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                    json.encode(sendJsonData),
                                    publishFinishCb,"send orginal timer table")
                                end
                                print(json.encode(sendJsonData))
                                fskv.set("timerList", timerList)
                                
                            end
                        end
                    else    -- 设置了星期循环 此时日为? 不指定日期 
                        if words[3] == '?' then
                            
                            local weekDays = string.split(words[5],',') -- 获取循环的星期
                            local weekday = tonumber(os.date("%w", current_time)) -- 0-6 周天为0 
                            if 0 == weekday then                                  -- 特殊处理 -_-
                                weekday = 1
                            else 
                                weekday = weekday+1
                            end
                            
                            for j=1,#weekDays do
                                if tonumber(weekDays[j]) == weekday then
                                    
                                    -- 星期确定了之后，逻辑和倒计时定时逻辑一致
                                    if tonumber(os.date("%H", current_time)) == tonumber(words[2])  and tonumber(os.date("%M", current_time)) == tonumber(words[1]) then -- 时分相等
                                        -- 这种循环定时不用删除定时记录
                                        if false == oneceFlag[i] then
                                            oneceFlag[i] = true
                                            -- 执行动作

                                            if json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_1_out:0\"" then
                                                closeRelay(1)
                                                closeLed(1)
                                                if aliyun.ready() then
                                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                    "{\"params\":{\"relay_1_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                    publishFinishCb,"send relay_1_out stat 0")
                                                end
                                            elseif json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_1_out:1\"" then
                                                openRelay(1)
                                                openLed(1)
                                                if aliyun.ready() then
                                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                    "{\"params\":{\"relay_1_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                    publishFinishCb,"send relay_1_out stat 1")
                                                end
                                            end
                
                                            if json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_2_out:0\"" then
                                                closeRelay(2)
                                                closeLed(2)
                                                if aliyun.ready() then
                                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                    "{\"params\":{\"relay_2_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                    publishFinishCb,"send relay_2_out stat 0")
                                                end
                                            elseif json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_2_out:1\"" then
                                                openRelay(2)
                                                openLed(2)
                                                if aliyun.ready() then
                                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                    "{\"params\":{\"relay_2_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                    publishFinishCb,"send relay_2_out stat 1")
                                                end
                                            end
                
                                            if json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_3_out:0\"" then
                                                closeRelay(3)
                                                closeLed(3)
                                                if aliyun.ready() then
                                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                    "{\"params\":{\"relay_3_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                    publishFinishCb,"send relay_3_out stat 0")
                                                end
                                            elseif json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_3_out:1\"" then
                                                openRelay(3)
                                                openLed(3)
                                                if aliyun.ready() then
                                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                    "{\"params\":{\"relay_3_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                    publishFinishCb,"send relay_3_out stat 1")
                                                end
                                            end
                
                                            if json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_4_out:0\"" then
                                                closeRelay(4)
                                                closeLed(4)
                                                if aliyun.ready() then
                                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                    "{\"params\":{\"relay_4_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                    publishFinishCb,"send relay_4_out stat 0")
                                                end
                                            elseif json.encode(jsonData["DeviceTimer"][i]["A"]) == "\"relay_4_out:1\"" then
                                                openRelay(4)
                                                openLed(4)
                                                if aliyun.ready() then
                                                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                    "{\"params\":{\"relay_4_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                    publishFinishCb,"send relay_4_out stat 1")
                                                end
                                            end

                                            print("循环定时（普通定时）定时时间到")
                                        end
                                    else
                                        oneceFlag[i] = false
                                    end

                                end
                            end
                        end
                    end
                end

                if  json.encode(jsonData["DeviceTimer"][i]["Y"]) == "3"  and  json.encode(jsonData["DeviceTimer"][i]["E"]) == "1" then         -- 判断定时器是否被配置 3:本地循环定时
                    local words = string.split(jsonData["DeviceTimer"][i]["T"],' ') -- 获得时间表中的定时时间 cron格式的各部分
                    -- 循环定时仅仅只有周循环
                    if words[3] == '?' then
                        local weekDays = string.split(words[5],',') -- 获取循环的星期
                        local weekday = tonumber(os.date("%w", current_time)) -- 0-6 周天为0 
                        if 0 == weekday then                                  -- 特殊处理 -_-
                            weekday = 1
                        else 
                            weekday = weekday+1
                        end
                        
                        for j=1,#weekDays do
                            if tonumber(weekDays[j]) == weekday then
                                -- 星期确定了之后 处理时间逻辑
                                local startH = tonumber(words[2])
                                local startM = tonumber(words[1])

                                local currentH = tonumber(os.date("%H", current_time))
                                local currentM = tonumber(os.date("%M", current_time))

                                local endTime = string.split(jsonData["DeviceTimer"][i]["N"],':')
                                local endH = tonumber(endTime[1])
                                local endM = tonumber(endTime[2])

                                -- print(string.format("本地循环定时 定时开始时间: %d:%d 结束时间: %d:%d 当前时间:%d:%d", startH, startM,
                                --                                                                     endH, endM,
                                --                                                                     currentH, currentM))

                                local all_minutes = get_minutes_difference(startH, startM, endH, endM) -- 循环定时的总共时间 分钟数差值
                                -- print(string.format("定时时间的总共分钟数差值 all_minutes = %d", all_minutes))

                                local current_minutes = get_minutes_difference(startH, startM, currentH, currentM) -- 计算当前时间距离开始时间的分钟数差值 
                                -- print(string.format("当前的分钟差值 current_minutes = %d", current_minutes))

                                if current_minutes > 0 and current_minutes <= all_minutes then -- 分钟数小于0代表当前时间小于开始时间 当前分钟数差值肯定也是要小于等于定时所需的分钟数差值
                                    -- print("当前时间在定时时间段")
                                    -- 首先是先对当前的总循环时间取余数
                                    local R = tonumber(jsonData["DeviceTimer"][i]["R"])
                                    local S = tonumber(jsonData["DeviceTimer"][i]["S"])
                                    local needMinutes = R + S

                                    local remainderMinutes = current_minutes % needMinutes

                                    -- print(string.format("循环的总分钟数 needMinutes = %d remainderMinutes = %d", needMinutes, remainderMinutes))

                                    local actionWords = string.split(jsonData["DeviceTimer"][i]["A"],'|')

                                    if remainderMinutes < R then -- 小于 因为0-1计算为一分钟 余数为0的时候是执行关闭

                                        if actionWords[1] == "relay_1_out:1" and loopTimeOneceFlag[i] == 0 then
                                            openRelay(1)
                                            openLed(1)
                                            if aliyun.ready() then
                                                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                "{\"params\":{\"relay_1_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                publishFinishCb,"send relay_1_out stat 1")
                                            end
                                            loopTimeOneceFlag[i] = 1
                                        end

                                        if actionWords[1] == "relay_2_out:1" and loopTimeOneceFlag[i] == 0 then
                                            openRelay(2)
                                            openLed(2)
                                            if aliyun.ready() then
                                                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                "{\"params\":{\"relay_2_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                publishFinishCb,"send relay_2_out stat 1")
                                            end
                                            loopTimeOneceFlag[i] = 1
                                        end

                                        if actionWords[1] == "relay_3_out:1" and loopTimeOneceFlag[i] == 0 then
                                            openRelay(3)
                                            openLed(3)
                                            if aliyun.ready() then
                                                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                "{\"params\":{\"relay_3_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                publishFinishCb,"send relay_3_out stat 1")
                                            end
                                            loopTimeOneceFlag[i] = 1
                                        end

                                        if actionWords[1] == "relay_4_out:1" and loopTimeOneceFlag[i] == 0 then
                                            openRelay(4)
                                            openLed(4)
                                            if aliyun.ready() then
                                                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                "{\"params\":{\"relay_4_out\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                publishFinishCb,"send relay_4_out stat 1")
                                            end
                                            loopTimeOneceFlag[i] = 1
                                        end

                                    else

                                        if actionWords[2] == "relay_1_out:0" and loopTimeOneceFlag[i] == 1 then
                                            closeRelay(1)
                                            closeLed(1)
                                            if aliyun.ready() then
                                                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                "{\"params\":{\"relay_1_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                publishFinishCb,"send relay_1_out stat 0")
                                            end
                                            loopTimeOneceFlag[i] = 0
                                        end

                                        if actionWords[2] == "relay_2_out:0" and loopTimeOneceFlag[i] == 1 then
                                            closeRelay(2)
                                            closeLed(2)
                                            if aliyun.ready() then
                                                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                "{\"params\":{\"relay_2_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                publishFinishCb,"send relay_2_out stat 0")
                                            end
                                            loopTimeOneceFlag[i] = 0
                                        end

                                        if actionWords[2] == "relay_3_out:0" and loopTimeOneceFlag[i] == 1 then
                                            closeRelay(3)
                                            closeLed(3)
                                            if aliyun.ready() then
                                                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                "{\"params\":{\"relay_3_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                publishFinishCb,"send relay_3_out stat 0")
                                            end
                                            loopTimeOneceFlag[i] = 0
                                        end

                                        if actionWords[2] == "relay_4_out:0" and loopTimeOneceFlag[i] == 1 then
                                            closeRelay(4)
                                            closeLed(4)
                                            if aliyun.ready() then
                                                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                                                "{\"params\":{\"relay_4_out\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                                                publishFinishCb,"send relay_4_out stat 0")
                                            end
                                            loopTimeOneceFlag[i] = 0
                                        end

                                    end

                                end
                                
                            end
                        end
                    end
                end

            end
        else
            print("json erro:",errinfo)
        end

        sys.wait(200) --0.2s定时
    end
end)

