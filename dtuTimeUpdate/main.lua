
PROJECT = "modbus_rtu"
VERSION = "1.0.0"
PRODUCT_KEY = "I5VDLiolEqnPlnNMpPgIelFidgyq2jdn"
-- 引入必要的库文件(lua编写), 内部库不需要require
sys = require("sys")
lbsLoc = require("lbsLoc")
libfota = require "libfota"
require("single_mqtt")
require("task")
require("common")
require("queue")

mqtt_A_PayloadQueue = Queue()
mqtt_B_PayloadQueue = Queue()

if wdt then
    --添加硬狗防止程序卡死，在支持的设备上启用这个功能
    wdt.init(9000)--初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000)--3s喂一次狗
end

log.info("main", "uart demo")

-- 全局变量存储
updateServerFlag = 0    -- 服务器上传标志 1:上传A服务器 2:上传B服务器 3:A、B服务器都上传
reportingRule = 0       -- 上报规则 代表数据变化的量 读取值 1000 reportingRule = 100 则 <900 || >1100 则上报数据
reportingTime = 0       -- 上报时间

lastTime = 0    

sys.taskInit(function ()
    local trgFlag = false
    gpio.setup(12, 1, gpio.PULLUP)
    gpio.setup(13, 1, gpio.PULLUP)
    gpio.setup(14, 1, gpio.PULLUP)
    while true do
        local ret = sys.waitUntil("IP_READY",500)
        if ret then
            gpio.set(12, 1)
            gpio.set(14, 1)
            print("wait net ok ")
            break
        end
        if trgFlag then
            gpio.set(12, 1)
            gpio.set(14, 0)
            trgFlag = false
        else
            gpio.set(12, 0)
            gpio.set(14, 1)
            trgFlag = true
        end
        print("wait net")
    end
end)

--初始化
uart.setup(
    uartid,--串口id
    9600,--波特率
    8,--数据位
    1--停止位
)

uart.on(uartid, "receive", function(id, len)
    local uartRecvData = ""
    repeat
        uartRecvData = uart.read(id, len)
        if #uartRecvData > 0 then -- #s 是取字符串的长度

            -- log.info("uart", "receive", id, #uartRecvData, string.toHex(uartRecvData))

            local uartRecvDataHexString = string.toHex(uartRecvData)
            local data_without_crc = uartRecvDataHexString:sub(1, -5) -- 去掉最后两个字符（CRC校验码）
            -- 计算CRC校验码
            local crc_calculated = string.toHex(pack.pack('<h', crypto.crc16("MODBUS",data_without_crc:fromHex())))
            -- 提取接收到的CRC校验码
            local crc_received = uartRecvDataHexString:sub(-4, -1)
            -- 比较计算出的CRC校验码和接收到的CRC校验码
            if crc_calculated == crc_received then
                if uartRecvDataHexString:sub(3, 4) == "03" then
                    sys.publish("RegistersRead", uartRecvData)
                elseif uartRecvDataHexString:sub(3, 4) == "0x10" then
                    sys.publish("RegistersWrite", uartRecvData)
                end
            else
                log.info("CRC校验失败")
            end
        end
    until uartRecvData == ""
end)

-- FOTA 文档:https://doc.openluat.com/wiki/37?wiki_page_id=4578#__132
function fota_cb(ret)
    log.info("fota", ret)
    if ret == 0 then
        rtos.reboot()
    end
end

-- 使用合宙iot平台进行升级
sys.taskInit(function()
    sys.waitUntil("net_ready")
    libfota.request(fota_cb)
    log.info("fota", "version", VERSION)
end)
sys.timerLoopStart(libfota.request, 3600000, fota_cb)

-- 创建定时任务
sys.taskInit(function ()
    sys.waitUntil("mqtt_conack")                -- 等待MQTT连接
    sys.timerLoopStart(timerCallback1s, 1000)     -- 定时1s
    log.info("timerLoopStart", "定时任务开始运行")
    -- 串口初始化完毕之后开始采集一次数据
    readAllRegFlag = true                 
end)
sys.taskInit(function ()
    sys.waitUntil("mqtt_conack")                        -- 等待MQTT连接

    if fskv.init() then
        log.info("fdb", "kv数据库初始化成功")
    end

    updateServerFlag = fskv.get("serverFlag")
    reportingRule    = fskv.get("reportingRule")
    reportingTime    = fskv.get("reportingTime")

    log.info("fdb", "serverFlag = ", updateServerFlag)
    log.info("fdb", "reportingRule = ", reportingRule)
    log.info("fdb", "reportingTime = ", reportingTime)

    if updateServerFlag == nil then
        updateServerFlag = 3
        fskv.set("serverFlag", updateServerFlag)
    end

    if reportingRule == nil then
        reportingRule = 0
        fskv.set("reportingRule", reportingRule)
    end

    if reportingTime == nil then
        reportingTime = 1
        fskv.set("reportingTime", reportingTime)
    end

    log.info("fdb", "serverFlag = ", updateServerFlag)
    log.info("fdb", "reportingRule = ", reportingRule)
    log.info("fdb", "reportingTime = ", reportingTime)

    lastTime = os.time()

    while true do
        if readAllRegFlag then
            firstReadRegistersValue()                   -- 读取数据，写缓存
            updateToYun_MobusRTU_Registers_ALL()        -- 上报数据点  
            readAllRegFlag = false
        end
        if time_1s_out then
            variationRegistersMonitor()
            upDate_Registers_Value()
            time_1s_out = false
        end
        mqttDataProcessing()
        sys.wait(10)
    end               
end)

function getLocCb(result, lat, lng, addr, time, locType)
    log.info("testLbsLoc.getLocCb", result, lat, lng)
    if result == 0 then
        log.info("lat", lat)
        log.info("lng", lng)
        log.info("服务器返回的时间", time:toHex())
        log.info("定位类型,基站定位成功返回0", locType)

        local locationData = '{"lng":0,"lat":0}'
        local jsonDecodeLocationData = json.decode(locationData)

        jsonDecodeLocationData.lng = tonumber(lng)
        jsonDecodeLocationData.lat = tonumber(lat)

        local jsonEncodedData = json.encode(jsonDecodeLocationData)
        sys.publish("mqtt_pub", "B", mqtt_server_B_pub_topic_location, jsonEncodedData, 0)

        sys.publish("location", lat, lng)
    end
end
sys.taskInit(function()
    sys.waitUntil("IP_READY", 30000)
    while 1 do
        mobile.reqCellInfo(15)
        sys.waitUntil("CELL_INFO_UPDATE", 3000)
        lbsLoc.request(getLocCb)
        sys.wait(1000*60)
    end
end)

-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!
