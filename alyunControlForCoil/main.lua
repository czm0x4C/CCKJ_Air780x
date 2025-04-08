PROJECT = "aliyun"
VERSION = "1.0.0"
PRODUCT_KEY = "sZGJsiVz2NxXksIwinlwd06dKTpr4k7q"

sys = require "sys"
libfota = require "libfota"

-- 一型一密优先使用fskv存储密钥
if fskv then
    fskv.init()
end

require "netready"
-- 一型一密
require "testYxym"
-- 阿里云事件处理函数
require "testEvt"
-- 输入控制
require "inputControl"
-- 按键控制
require "keyControl"
-- 继电器控制
require "relayControl"
-- LED控制
require "ledControl"
-- adc控制
require "adcControl"
-- 定时时间表
timerList = '{"DeviceTimer":[{"E":0,"Y":0},{"E":0,"Y":0},{"E":0,"Y":0},{"E":0,"Y":0},{"E":0,"Y":0},{"E":0,"Y":0},{"E":0,"Y":0},{"E":0,"Y":0},{"E":0,"Y":0},{"E":0,"Y":0},{"E":0,"Y":0},{"E":0,"Y":0}]}'
-- 设置默认时间 
local targetTime = {
    year = 2015,
    month = 6,
    day = 10,
    hour = 12,
    min = 0,
    sec = 0
}
-- 映射A的映射比率
reflectionScale_A = 16
-- 映射B的映射比率
reflectionScale_B = 16
-- 范围变化上报
updateRule = 0
-- 时间变化上报
updateTime = 0

if fskv.get("reflectionScale_A") then
    reflectionScale_A = fskv.get("reflectionScale_A")
    print("读取的 reflectionScale_A",fskv.get("reflectionScale_A"))
else
    fskv.set("reflectionScale_A", reflectionScale_A)
    print("初始化 reflectionScale_A",fskv.get("reflectionScale_A"))
end

if fskv.get("reflectionScale_B") then
    reflectionScale_B = fskv.get("reflectionScale_B")
    print("读取的 reflectionScale_B",fskv.get("reflectionScale_B"))
else
    fskv.set("reflectionScale_B", reflectionScale_B)
    print("初始化 reflectionScale_B",fskv.get("reflectionScale_B"))
end

if fskv.get("updateRule") then
    updateRule = fskv.get("updateRule")
    print("读取的updateRule",fskv.get("updateRule"))
else
    fskv.set("updateRule", updateRule)
    print("初始化updateRule",fskv.get("updateRule"))
end

if fskv.get("updateTime") then
    updateTime = fskv.get("updateTime")
    print("读取的updateTime",fskv.get("updateTime"))
else
    fskv.set("updateTime", updateTime)
    print("初始化updateRule",fskv.get("updateTime"))
end

if fskv.get("timerList") then
    timerList = fskv.get("timerList")
    print("读取的timerList",fskv.get("timerList"))
else
    fskv.set("timerList", timerList)
    print("初始化timerList",fskv.get("timerList"))
end

if fskv.get("recordTime") then
    local timestamp = fskv.get("recordTime")
    print("读取的时间戳",fskv.get("timerList"))
    rtc.set(tonumber(timestamp))--rtc时间设置
    log.info("设置的系统时间戳", os.date())--打印时间
else
    log.info("系统时间，修改前", os.date())--打印时间
    local t = rtc.get()--获取RTC时间
    log.info("系统时间，修改前(RTC)", json.encode(t))--打印RTC时间
    local timestamp = os.time(targetTime)
    rtc.set(timestamp)--rtc时间设置
    log.info("os.date()", os.date())--打印时间
    fskv.set("recordTime", timestamp)
end

-- 时间校准
socket.sntp()
sys.subscribe("NTP_UPDATE", function()
    log.info("sntp", "time", os.date())
end)
sys.subscribe("NTP_ERROR", function()
    log.info("socket", "sntp error")
    socket.sntp()
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





-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!
