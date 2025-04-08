
local rtos_bsp = rtos.bsp()
function adc_pin() -- 根据不同开发板，设置ADC编号
    if rtos_bsp == "AIR101" then -- Air101开发板ADC编号
        return 0,1,255,255,adc.CH_CPU ,adc.CH_VBAT 
    elseif rtos_bsp == "AIR103" then -- Air103开发板ADC编号
        return 0,1,2,3,adc.CH_CPU ,adc.CH_VBAT 
    elseif rtos_bsp == "AIR105" then -- Air105开发板ADC编号
        -- 默认不开启分压,范围是0-1.8v精度高
        -- 设置分压要在adc.open之前设置，否则无效!!
        -- adc.setRange(adc.ADC_RANGE_3_6)
        return 0,5,6,255,255,255
    elseif rtos_bsp == "ESP32C3" then -- ESP32C3开发板ADC编号
        return 0,1,2,3,adc.CH_CPU , 255
    elseif rtos_bsp == "ESP32C2" then -- ESP32C2开发板ADC编号
        return 0,1,2,3,adc.CH_CPU , 255
    elseif rtos_bsp == "ESP32S3" then -- ESP32S3开发板ADC编号
        return 0,1,2,3,adc.CH_CPU , 255
    elseif rtos_bsp == "EC618" then --Air780E开发板ADC编号
        -- 默认不开启分压,范围是0-1.2v精度高
        -- 设置分压要在adc.open之前设置，否则无效!!
        -- adc.setRange(adc.ADC_RANGE_3_8)
        return 0,1,2255,255,adc.CH_CPU ,adc.CH_VBAT 
    elseif rtos_bsp == "Air780EP" then --Air780EP开发板ADC编号
        -- 默认不开启分压,范围是0-1.6v精度高
        -- 开启分压后，外部输入最大不可超过3.3V
        -- 设置分压要在adc.open之前设置，否则无效!!
        adc.setRange(adc.ADC_RANGE_1_2)
        print(rtos_bsp)
        return 0,1,2,3,adc.CH_CPU ,adc.CH_VBAT 
    elseif rtos_bsp == "UIS8850BM" then 
        return 0,255,255,255, adc.CH_CPU ,adc.CH_VBAT 
    else
        log.info("main", "define ADC pin in main.lua", rtos_bsp)
        return 255,255,255,255, adc.CH_CPU ,adc.CH_VBAT 
    end
end
local adc_pin_0,adc_pin_1,adc_pin_2,adc_pin_3,adc_pin_temp,adc_pin_vbat=adc_pin()

local lastTime = 0
local currentTime = 0
local adcChannel_A = 0
local adcChannel_B = 0
local reflectionChannel_1_Value = 0 
local reflectionChannel_1_Value = 0
local last_reflectionChannel_1_Value = 0
local last_reflectionChannel_2_Value = 0

sys.taskInit(function()
    
    if adc_pin_0 and adc_pin_0 ~= 255 then adc.open(adc_pin_0) end
    if adc_pin_1 and adc_pin_1 ~= 255 then adc.open(adc_pin_1) end
    if adc_pin_2 and adc_pin_2 ~= 255 then adc.open(adc_pin_2) end
    if adc_pin_3 and adc_pin_3 ~= 255 then adc.open(adc_pin_3) end
    if adc_pin_temp and adc_pin_temp ~= 255 then adc.open(adc_pin_temp) end
    if adc_pin_vbat and adc_pin_vbat ~= 255 then adc.open(adc_pin_vbat) end

    sys.waitUntil("aliyun_ready") -- 等待阿里云任务创建成功

    if aliyun.ready() then
        aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        "{\"params\":{\"I_channel_1_value\":"..tostring(4)..
                        ",\"reflectionChannel_1_Value\":".. tostring(0)..
                        "},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                        publishFinishCb,"上传 电流通道1的映射值")
    end
    if aliyun.ready() then
        aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                        "{\"params\":{\"I_channel_2_value\":".. tostring(4)..
                        ",\"reflectionChannel_2_Value\":".. tostring(0)..
                        "},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                        publishFinishCb,"上传 电流通道2的映射值")
    end

    lastTime = os.time()
    currentTime = lastTime

    while true do
        adcChannel_A = adc.get(2);
        adcChannel_B = adc.get(3);

        if adcChannel_A/50.0 >= 4.0 then
            reflectionChannel_1_Value = (adcChannel_A/50.0 - 4) / 16.0 * reflectionScale_A
        else
            reflectionChannel_1_Value = 0
        end

        if adcChannel_B/50.0 >= 4.0 then
            reflectionChannel_2_Value = (adcChannel_B/50.0 - 4) / 16.0 * reflectionScale_B
        else
            reflectionChannel_2_Value = 0
        end

        if  updateRule ~= 0 then
            if math.abs(reflectionChannel_1_Value - last_reflectionChannel_1_Value) > updateRule then
                last_reflectionChannel_1_Value = reflectionChannel_1_Value
                if aliyun.ready() then
                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                    "{\"params\":{\"I_channel_1_value\":"..tostring(adcChannel_A/50.0)..
                                    ",\"reflectionChannel_1_Value\":".. tostring(reflectionChannel_1_Value)..
                                    "},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                    publishFinishCb,"上传 电流通道1的映射值")
                    log.debug("adc", "mV", adcChannel_A)
                end
            end
            if math.abs(reflectionChannel_2_Value - last_reflectionChannel_2_Value) > updateRule then
                last_reflectionChannel_2_Value = reflectionChannel_2_Value
                if aliyun.ready() then
                    aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                    "{\"params\":{\"I_channel_2_value\":".. tostring(adcChannel_B/50.0)..
                                    ",\"reflectionChannel_2_Value\":".. tostring(reflectionChannel_2_Value)..
                                    "},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                    publishFinishCb,"上传 电流通道2的映射值")
                    log.debug("adc", "mV", adcChannel_B)
                end
            end
        end
        sys.wait(500)
    end

    -- 若不再读取, 可关掉adc, 降低功耗, 非必须
    if adc_pin_0 and adc_pin_0 ~= 255 then adc.close(adc_pin_0) end
    if adc_pin_1 and adc_pin_1 ~= 255 then adc.close(adc_pin_1) end
    if adc_pin_2 and adc_pin_2 ~= 255 then adc.close(adc_pin_2) end
    if adc_pin_3 and adc_pin_3 ~= 255 then adc.close(adc_pin_3) end
    if adc_pin_temp and adc_pin_temp ~= 255 then adc.close(adc_pin_temp) end
    if adc_pin_vbat and adc_pin_vbat ~= 255 then adc.close(adc_pin_vbat) end

end)

function timeLoop()
    currentTime = os.time()
    if updateTime ~= 0 then
        if(currentTime - lastTime) > updateTime then
            lastTime = currentTime
            if aliyun.ready() then
                aliyun.publish("/sys/"..aliyun.opts.ProductKey.."/"..aliyun.opts.DeviceName.."/thing/event/property/post",1,
                                "{\"params\":{\"I_channel_1_value\":"..tostring(adcChannel_A/50.0)..
                                ",\"reflectionChannel_1_Value\":".. tostring(reflectionChannel_1_Value)..
                                ",\"I_channel_2_value\":".. tostring(adcChannel_B/50.0)..
                                ",\"reflectionChannel_2_Value\":".. tostring(reflectionChannel_2_Value)..
                                "},\"version\":\"1.0\",\"method\":\"thing.event.property.post\"}",
                                publishFinishCb,"定时上传 电流通道 的映射值")
            end
        end
    end

end

sys.timerLoopStart(timeLoop, 500)