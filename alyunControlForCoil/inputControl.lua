local inputTimerTimeout = 10 -- 输入检测的定时器的超时时间

local input_channel_1_state = false
local input_channel_2_state = false
local input_channel_3_state = false
local input_channel_4_state = false
local input_channel_1_pin = 34
local input_channel_2_pin = 35
local input_channel_3_pin = 38
local input_channel_4_pin = 37


-- 若固件支持防抖, 启用防抖
if gpio.debounce then
    print("支持防抖")
    gpio.debounce(input_channel_1_pin, 100)
    gpio.debounce(input_channel_2_pin, 100)
    gpio.debounce(input_channel_3_pin, 100)
    gpio.debounce(input_channel_4_pin, 100)
end

--通道1 输入 引脚 初始化
gpio.setup(input_channel_1_pin, function() 
        if gpio.get(input_channel_1_pin) == 0 then
            input_channel_1_state = true
            if aliyun.ready() then
                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                "{\"params\":{\"channel_1_in\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                publishFinishCb,"上传 输入通道 1 联通")
            end
        else
            input_channel_1_state = false
            if aliyun.ready() then
                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                "{\"params\":{\"channel_1_in\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                publishFinishCb,"上传 输入通道 1 断开")
            end
        end
    end, 
    gpio.PULLUP,
    gpio.BOTH)
--通道2 输入 引脚 初始化
gpio.setup(input_channel_2_pin, function() 
        if gpio.get(input_channel_2_pin) == 0 then
            input_channel_2_state = true
            if aliyun.ready() then
                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                "{\"params\":{\"channel_2_in\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                publishFinishCb,"上传 输入通道 2 联通")
            end
        else
            input_channel_2_state = false
            if aliyun.ready() then
                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                "{\"params\":{\"channel_2_in\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                publishFinishCb,"上传 输入通道 2 断开")
            end
        end
    end, 
    gpio.PULLUP,
    gpio.BOTH)
--通道3 输入 引脚 初始化
gpio.setup(input_channel_3_pin, function() 
        if gpio.get(input_channel_3_pin) == 0 then
            input_channel_3_state = true
            if aliyun.ready() then
                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                "{\"params\":{\"channel_3_in\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                publishFinishCb,"上传 输入通道 3 联通")
            end
        else
            input_channel_3_state = false
            if aliyun.ready() then
                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                "{\"params\":{\"channel_3_in\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                publishFinishCb,"上传 输入通道 3 断开")
            end
        end
    end, 
    gpio.PULLUP,
    gpio.BOTH)
--通道4 输入 引脚 初始化
gpio.setup(input_channel_4_pin, function() 
        if gpio.get(input_channel_4_pin) == 0 then
            input_channel_4_state = true
            if aliyun.ready() then
                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                "{\"params\":{\"channel_4_in\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                publishFinishCb,"上传 输入通道 4 联通")
            end
        else
            input_channel_4_state = false
            if aliyun.ready() then
                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                "{\"params\":{\"channel_4_in\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                publishFinishCb,"上传 输入通道 4 断开")
            end
        end
    end, 
    gpio.PULLUP,
    gpio.BOTH)

sys.taskInit(function ()
    -- 等待网络连接成功
    sys.waitUntil("aliyun_ready", 30000)
    if aliyun.ready() then
        aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        "{\"params\":{\"channel_1_in\":0,\"channel_2_in\":0,\"channel_3_in\":0,\"channel_4_in\":0,\"channel_1_in\":0"..
                        ",\"relay_1_out\":0,\"relay_2_out\":0,\"relay_2_out\":0,\"relay_3_out\":0,\"relay_4_out\":0"..
                        "},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                        publishFinishCb,"上传 输入通道 1 2 3 4 无效")
    end
end)


local key1OutTrgFlag = false -- 按键翻转标志
local key2OutTrgFlag = false -- 按键翻转标志
local key3OutTrgFlag = false -- 按键翻转标志
local key4OutTrgFlag = false -- 按键翻转标志

sys.timerLoopStart(function()

    -- -- 输入通道1 状态判断
    -- if input_channel_1_state then 
    --     print("输入通道 1 联通")
    --     if aliyun.ready() then
    --         aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                         "{\"params\":{\"channel_1_in\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                         publishFinishCb,"上传 输入通道 1 联通")
    --     end
    -- else
    --     print("输入通道 1 断开")
    --     if aliyun.ready() then
    --         aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                         "{\"params\":{\"channel_1_in\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                         publishFinishCb,"上传 输入通道 1 断开")
    --     end
    -- end
    -- -- 输入通道2 状态判断
    -- if input_channel_2_state then 
    --     print("输入通道 2 联通")
    --     if aliyun.ready() then
    --         aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                         "{\"params\":{\"channel_2_in\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                         publishFinishCb,"上传 输入通道 2 联通")
    --     end
    -- else
    --     print("输入通道 2 断开")
    --     if aliyun.ready() then
    --         aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                         "{\"params\":{\"channel_2_in\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                         publishFinishCb,"上传 输入通道 2 断开")
    --     end
    -- end
    -- -- 输入通道3 状态判断
    -- if input_channel_3_state then 
    --     print("输入通道 3 联通")
    --     if aliyun.ready() then
    --         aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                         "{\"params\":{\"channel_3_in\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                         publishFinishCb,"上传 输入通道 3 联通")
    --     end
    -- else
    --     print("输入通道 3 断开")
    --     if aliyun.ready() then
    --         aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                         "{\"params\":{\"channel_3_in\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                         publishFinishCb,"上传 输入通道 3 断开")
    --     end
    -- end
    --     -- 输入通道4 状态判断
    -- if input_channel_4_state then 
    --     print("输入通道 4 联通")
    --     if aliyun.ready() then
    --         aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                         "{\"params\":{\"channel_4_in\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                         publishFinishCb,"上传 输入通道 41 联通")
    --     end
    -- else
    --     print("输入通道 4 断开")
    --     if aliyun.ready() then
    --         aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                         "{\"params\":{\"channel_4_in\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                         publishFinishCb,"上传 输入通道 4 断开")
    --     end
    -- end

    -- 点动模式
    -- 输入通道1 状态判断
    -- if input_channel_1_state then 
    --     if not key1OutTrgFlag then
    --         key1OutTrgFlag = true
    --         print("输入通道 1 联通")
    --         if aliyun.ready() then
    --             aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                             "{\"params\":{\"channel_1_in\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                             publishFinishCb,"上传 输入通道 1 联通")
    --         end
    --     else
    --         key1OutTrgFlag = false
    --         print("输入通道 1 断开")
    --         if aliyun.ready() then
    --             aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                             "{\"params\":{\"channel_1_in\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                             publishFinishCb,"上传 输入通道 1 断开")
    --         end
    --     end
    --     input_channel_1_state = false
    -- end
    -- -- 输入通道2 状态判断
    -- if input_channel_2_state then 
    --     if not key2OutTrgFlag then
    --         key2OutTrgFlag = true
    --         print("输入通道 2 联通")
    --         if aliyun.ready() then
    --             aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                             "{\"params\":{\"channel_2_in\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                             publishFinishCb,"上传 输入通道 1 联通")
    --         end
    --     else
    --         key2OutTrgFlag = false
    --         print("输入通道 2 断开")
    --         if aliyun.ready() then
    --             aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                             "{\"params\":{\"channel_2_in\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                             publishFinishCb,"上传 输入通道 1 断开")
    --         end
    --     end
    --     input_channel_2_state = false
    -- end
    -- -- 输入通道3 状态判断
    -- if input_channel_3_state then 
    --     if not key3OutTrgFlag then
    --         key3OutTrgFlag = true
    --         print("输入通道 3 联通")
    --         if aliyun.ready() then
    --             aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                             "{\"params\":{\"channel_3_in\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                             publishFinishCb,"上传 输入通道 1 联通")
    --         end
    --     else
    --         key3OutTrgFlag = false
    --         print("输入通道 3 断开")
    --         if aliyun.ready() then
    --             aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                             "{\"params\":{\"channel_3_in\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                             publishFinishCb,"上传 输入通道 1 断开")
    --         end
    --     end
    --     input_channel_3_state = false
    -- end
    -- -- 输入通道4 状态判断
    -- if input_channel_4_state then 
    --     if not key4OutTrgFlag then
    --         key4OutTrgFlag = true
    --         print("输入通道 4 联通")
    --         if aliyun.ready() then
    --             aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                             "{\"params\":{\"channel_4_in\":1},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                             publishFinishCb,"上传 输入通道 1 联通")
    --         end
    --     else
    --         key4OutTrgFlag = false
    --         print("输入通道 4 断开")
    --         if aliyun.ready() then
    --             aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
    --                             "{\"params\":{\"channel_4_in\":0},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
    --                             publishFinishCb,"上传 输入通道 1 断开")
    --         end
    --     end
    --     input_channel_4_state = false
    -- end
end,inputTimerTimeout) 

