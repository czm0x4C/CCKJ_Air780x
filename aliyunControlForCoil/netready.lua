local sys = require "sys"
aliyun = require "aliyun"

-- 将时间表转换为时间戳
local timestamp = os.time(targetTime)


-- 检测网络状态
local function checkNetwork()
    local ip = socket.localIP()
    if ip and ip ~= "" then
        -- 记录网络时间
        -- print("当前时间:", os.date("%Y-%m-%d %H:%M:%S"))
        fskv.set("recordTime", os.time())
    else

    end
end

 -- 统一联网函数
sys.taskInit(function()

    -- Air780E/Air600E系列
    sim_id = mobile.simid(0) -- 0:固定使用SIM0 2:自动识别SIM0, SIM1, 优先级看具体平台
    -- 默认都等到联网成功
    local trgFlag = false
    -- NET_STATUS
    gpio.setup(27, 0, gpio.PULLUP)
    gpio.set(27, gpio.LOW)
    while true do
        local ret = sys.waitUntil("IP_READY",500)
        if ret then
            gpio.set(27, 1)
            print("wait net ok ")
            break
        end
        if trgFlag then
            gpio.set(27, 0)
            trgFlag = false
        else
            gpio.set(27, 1)
            trgFlag = true
        end
        print("wait net")
    end
    -- 每 60 秒检查一次网络状态
    sys.timerLoopStart(checkNetwork, 10*60*1000)
    sys.publish("net_ready")
end)



