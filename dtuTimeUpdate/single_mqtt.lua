require("task")
require("common")
require("queue")
-- A MQTT 服务器 链接 上海皋翰自动化设备有限公司 TLINK 平台
-- B MQTT 服务器 链接 崇成云 平台
local mqtt_server_A_host = "1883.dtuip.com"
local mqtt_server_B_host = "203.0.104.111" -- 49.7.227.121 203.0.104.111
local mqtt_server_A_port = 1883
local mqtt_server_B_port = 1883
local mqtt_server_A_isssl = false
local mqtt_server_B_isssl = false
local mqtt_server_A_client_id = ""
local mqtt_server_B_client_id = ""
local mqtt_server_A_user_name = "13982281612"
local mqtt_server_B_user_name = ""
local mqtt_server_A_password = "Gh123456"
local mqtt_server_B_password = "123456"
local mqtt_server_A_reconnect_count = 0
local mqtt_server_B_reconnect_count = 0
-- mqtt 平台连接成功标志
local mqtt_server_A_connected_flag = false
local mqtt_server_B_connected_flag = false
-- 平台A发布主题
mqtt_server_A_pub_topic = ""
-- 平台A订阅主题
mqtt_server_A_sub_topic = ""
-- 平台B发布主题
mqtt_server_B_pub_topic = ""
mqtt_server_B_pub_topic_location = ""
-- 平台B订阅主题
mqtt_server_B_sub_topic = ""

-- MQTT链接对象
local mqtt_server_A_mqttc = nil
local mqtt_server_B_mqttc = nil

-- 统一联网函数
sys.taskInit(function()
    local device_id = mcu.unique_id():toHex()
    -----------------------------
    -- 统一联网函数, 可自行删减
    ----------------------------
    if wlan and wlan.connect then
        -- wifi 联网, ESP32系列均支持
        local ssid = "luatos1234"
        local password = "12341234"
        log.info("wifi", ssid, password)
        -- TODO 改成自动配网
        -- LED = gpio.setup(12, 0, gpio.PULLUP)
        wlan.init()
        wlan.setMode(wlan.STATION) -- 默认也是这个模式,不调用也可以
        device_id = wlan.getMac()
        wlan.connect(ssid, password, 1)
    elseif mobile then
        -- Air780E/Air600E系列
        mobile.simid(0) -- 自动切换SIM卡
        -- LED = gpio.setup(27, 0, gpio.PULLUP)
        device_id = mobile.imei()
    elseif w5500 then
        -- w5500 以太网, 当前仅Air105支持
        w5500.init(spi.HSPI_0, 24000000, pin.PC14, pin.PC01, pin.PC00)
        w5500.config() --默认是DHCP模式
        w5500.bind(socket.ETH0)
        -- LED = gpio.setup(62, 0, gpio.PULLUP)
    elseif socket or mqtt then
        -- 适配的socket库也OK
        -- 没有其他操作, 单纯给个注释说明
    else
        -- 其他不认识的bsp, 循环提示一下吧
        while 1 do
            sys.wait(1000)
            log.info("bsp", "本bsp可能未适配网络层, 请查证")
        end
    end
    -- 默认都等到联网成功
    sys.waitUntil("IP_READY")
    sys.publish("net_ready", device_id)
end)

sys.taskInit(function()
    -- 等待联网
    local ret, device_id = sys.waitUntil("net_ready")
    -- 联网成功后获取iccid
    device_iccid = mobile.iccid()
    
    log.info("提示：", "网络连接成功", "imei", device_id, "iccid", device_iccid)

    -- 下面的是mqtt的参数均可自行修改
    mqtt_server_A_client_id = device_id
    mqtt_server_B_client_id = device_id

    mqtt_server_B_user_name = device_id

    mqtt_server_A_pub_topic = tostring(device_id).."0"

    mqtt_server_A_sub_topic = tostring(device_id).."0".."/+"

    log.info("提示：", "MQTT A 服务器发布:", mqtt_server_A_pub_topic)
    log.info("提示：", "MQTT A 服务器订阅:", mqtt_server_A_sub_topic)

    mqtt_server_B_pub_topic          = "bodazl/" .. device_id .. "/lastdp"
    mqtt_server_B_pub_topic_info     = "bodazl/" .. device_id .. "/info"
    mqtt_server_B_pub_topic_location = "bodazl/" .. device_id .. "/location"

    mqtt_server_B_sub_topic          = "bodazl/" .. device_id .. "/put"

    log.info("提示：", "MQTT B 服务器发布:", mqtt_server_B_pub_topic)
    log.info("提示：", "MQTT B 服务器发布:", mqtt_server_B_pub_topic_info)
    log.info("提示：", "MQTT B 服务器发布:", mqtt_server_B_pub_topic_location)
    log.info("提示：", "MQTT B 服务器订阅:", mqtt_server_B_sub_topic)

    -- 打印一下支持的加密套件, 通常来说, 固件已包含常见的99%的加密套件
    -- if crypto.cipher_suites then
    --     log.info("cipher", "suites", json.encode(crypto.cipher_suites()))
    -- end

    if mqtt == nil then
        while 1 do
            sys.wait(1000)
            log.info("bsp", "本bsp未适配mqtt库, 请查证")
        end
    end

    log.info("提示：", "网络连接成功", "imei", device_id, "iccid", device_iccid)

    mqtt_server_A_mqttc = mqtt.create(nil, mqtt_server_A_host, mqtt_server_A_port, mqtt_server_A_isssl, mqtt_server_A_ca_file)
    mqtt_server_B_mqttc = mqtt.create(nil, mqtt_server_B_host, mqtt_server_B_port, mqtt_server_B_isssl, mqtt_server_B_ca_file)

    mqtt_server_A_client_id = mqtt_server_A_client_id.."0"

    mqtt_server_A_mqttc:auth(mqtt_server_A_client_id, mqtt_server_A_user_name, mqtt_server_A_password) -- client_id必填,其余选填
    mqtt_server_B_mqttc:auth(mqtt_server_B_client_id, mqtt_server_B_user_name, mqtt_server_B_password)
    mqtt_server_A_mqttc:keepalive(60)
    mqtt_server_B_mqttc:keepalive(60)
    mqtt_server_A_mqttc:autoreconn(true, 3000) -- 自动重连机制
    mqtt_server_B_mqttc:autoreconn(true, 3000) -- 自动重连机制

    mqtt_server_A_mqttc:on(function(mqtt_client, event, data, payload)
        -- 用户自定义代码
        log.info("mqtt", "event", event, mqtt_client, data, payload)
        if event == "conack" then
            -- 联上了
            mqtt_server_A_mqttc:autoreconn(true, 3000)
            sys.publish("mqtt_conack")
            log.info("设备已经连接服务器A")
            mqtt_server_A_connected_flag = true

            mqtt_client:subscribe(mqtt_server_A_sub_topic)--单主题订阅

        elseif event == "recv" then
            enqueue(mqtt_A_PayloadQueue, payload)
            
        elseif event == "sent" then
            -- log.info("mqtt", "sent", "pkgid", data)
        elseif event == "disconnect" then
            -- 非自动重连时,按需重启mqttc
            if mqtt_server_A_reconnect_count < 3 then
                mqtt_server_A_reconnect_count = mqtt_server_A_reconnect_count + 1
                log.info("mqtt", "mqtt_server_A_reconnect_count = ", mqtt_server_A_reconnect_count)
            else
                mqtt_server_A_mqttc:close()
                log.info("mqtt", "重连失败,退出")
            end
        end
    end)

    mqtt_server_B_mqttc:on(function(mqtt_client, event, data, payload)
        -- 用户自定义代码
        log.info("mqtt", "event", event, mqtt_client, data, payload)
        if event == "conack" then
            -- 联上了
            mqtt_server_B_mqttc:autoreconn(true, 3000)
            sys.publish("mqtt_conack")
            log.info("设备已经连接服务器B")
            mqtt_server_B_connected_flag = true

            mqtt_client:subscribe(mqtt_server_B_sub_topic)--单主题订阅

            -- MQTT连接成功上传一次设备信息
            local tempPubTopic = "bodazl/" .. device_id .. "/info"
            local tempPubData = '{"iccid":0,"csq":0}'

            local jsonDecodeData = json.decode(tempPubData)
            jsonDecodeData.iccid = device_iccid
            jsonDecodeData.csq = mobile.csq()
            local jsonEncodedData = json.encode(jsonDecodeData)
            mqtt_server_B_mqttc:publish(tempPubTopic, jsonEncodedData, 0)
            
        elseif event == "recv" then
            enqueue(mqtt_B_PayloadQueue, payload)
        elseif event == "sent" then
            -- log.info("mqtt", "sent", "pkgid", data)
        elseif event == "disconnect" then
            -- 非自动重连时,按需重启mqttc
            if mqtt_server_B_reconnect_count < 3 then
                mqtt_server_B_reconnect_count = mqtt_server_B_reconnect_count + 1
                log.info("mqtt", "mqtt_server_B_reconnect_count = ", mqtt_server_B_reconnect_count)
            else
                mqtt_server_B_mqttc:close()
                log.info("mqtt", "重连失败,退出")
            end
        end
    end)

    -- mqttc自动处理重连, 除非自行关闭
    mqtt_server_A_mqttc:connect()
    mqtt_server_B_mqttc:connect()

	sys.waitUntil("mqtt_conack")
    while true do
        -- 演示等待其他task发送过来的上报信息
        local ret, targetServer, topic, data, qos = sys.waitUntil("mqtt_pub", 300000)
        if ret then
            -- 提供关闭本while循环的途径, 不需要可以注释掉
            if topic == "close" then break end

            if targetServer == "A" and ((updateServerFlag == 1) or (updateServerFlag == 3)) then
                if mqtt_server_A_mqttc:state() == 3 then
                    log.info("目标服务器A,发布topic:", topic, "发送内容", data)
                    mqtt_server_A_mqttc:publish(topic, data, qos)
                end
            end
            if targetServer == "B" and ((updateServerFlag == 2) or (updateServerFlag == 3)) then
                if mqtt_server_B_mqttc:state() == 3 then
                    log.info("目标服务器B,发布topic:", topic, "发送内容", data)
                    mqtt_server_B_mqttc:publish(topic, data, qos)
                end
            end
            
        end
        -- 如果没有其他task上报, 可以写个空等待
        --sys.wait(60000000)
    end

    mqtt_server_A_mqttc:close()
    mqtt_server_B_mqttc:close()
    mqtt_server_A_mqttc = nil
    mqtt_server_B_mqttc = nil
end)

function mqttDataProcessing()
    while not isEmpty(mqtt_B_PayloadQueue) do
        local payload = dequeue(mqtt_B_PayloadQueue)
        log.info("解析B服务器接收的json串", payload)

        if payload == "[]" then
            readAllRegFlag = true
        end

        local jsonDecode = json.decode(payload)

        for k, v in pairs(jsonDecode) do
            log.info("当前数据点:", k, "数据点内容:", v)
            sys.wait(50)
            if k == "c_d_1" then
                modbus_send_32bitFloat("0x01","0x10","0",v)
            elseif k == "c_d_2" then
                modbus_send_32bitFloat("0x01","0x10","2",v)
            elseif k == "c_d_3" then
                modbus_send_32bitFloat("0x01","0x10","4",v)
            elseif k == "c_d_4" then
                modbus_send_32bitFloat("0x01","0x10","6",v)
            elseif k == "c_d_5" then
                modbus_send_32bitFloat("0x01","0x10","8",v)
            elseif k == "c_d_6" then
                modbus_send_32bitFloat("0x01","0x10","10",v)
            elseif k == "c_d_7" then
                modbus_send_32bitFloat("0x01","0x10","12",v)
            elseif k == "c_d_8" then
                modbus_send_32bitInt("0x01","0x10","14",v)
            elseif k == "c_d_9" then
                modbus_send_32bitFloat("0x01","0x10","16",v)
            elseif k == "c_d_10" then
                modbus_send_32bitFloat("0x01","0x10","18",v)
            elseif k == "c_d_11" then
                modbus_send_32bitFloat("0x01","0x10","20",v)
            elseif k == "c_d_12" then
                modbus_send_32bitFloat("0x01","0x10","22",v)
            elseif k == "c_d_13" then
                modbus_send_32bitFloat("0x01","0x10","24",v)
            elseif k == "c_d_14" then
                modbus_send_32bitFloat("0x01","0x10","26",v)
            elseif k == "c_d_15" then
                modbus_send("0x01","0x06","28",v)
            elseif k == "c_d_16" then
                modbus_send("0x01","0x06","30",v)
            elseif k == "c_d_17" then
                modbus_send("0x01","0x06","32",v)
            elseif k == "c_d_18" then
                modbus_send("0x01","0x06","34",v)
            elseif k == "c_d_19" then
                modbus_send("0x01","0x06","36",v)
            elseif k == "c_d_20" then
                modbus_send("0x01","0x06","38",v)
            elseif k == "c_d_21" then
                modbus_send("0x01","0x06","40",v)
            elseif k == "c_d_22" then
                modbus_send("0x01","0x06","42",v)
            elseif k == "c_d_23" then
                modbus_send_32bitFloat("0x01","0x10","50",v)
            elseif k == "c_d_24" then
                updateServerFlag = v
                fskv.set("updateServerFlag", updateServerFlag)
            elseif k == "c_d_25" then
                reportingRule = v
                fskv.set("reportingRule", reportingRule)
            elseif k == "c_d_26" then
                reportingTime = v
                fskv.set("reportingTime", reportingTime)
            elseif k == "c_d_27" then
                rtos.reboot()
            end
            sys.wait(50)
        end
        readAllRegFlag = true
    end

    while not isEmpty(mqtt_A_PayloadQueue) do
        local payload = dequeue(mqtt_A_PayloadQueue)
        log.info("解析A服务器接收的json串", payload)

        local jsonDecode = json.decode(payload)
        local sensorDatas = jsonDecode.sensorDatas
        for i, sensor in ipairs(sensorDatas) do
            log.info("子对象:", i, "flag = ", sensor.flag, "sensorsId = ", sensor.sensorsId, "value = ", sensor.value)
            if sensor.flag == "c_d_1" then
                modbus_send_32bitFloat("0x01","0x10","0",sensor.value)
            elseif sensor.flag == "c_d_2" then
                modbus_send_32bitFloat("0x01","0x10","2",sensor.value)
            elseif sensor.flag == "c_d_3" then
                modbus_send_32bitFloat("0x01","0x10","4",sensor.value)
            elseif sensor.flag == "c_d_4" then
                modbus_send_32bitFloat("0x01","0x10","6",sensor.value)
            elseif sensor.flag == "c_d_5" then
                modbus_send_32bitFloat("0x01","0x10","8",sensor.value)
            elseif sensor.flag == "c_d_6" then
                modbus_send_32bitFloat("0x01","0x10","10",sensor.value)
            elseif sensor.flag == "c_d_7" then
                modbus_send_32bitFloat("0x01","0x10","12",sensor.value)
            elseif sensor.flag == "c_d_8" then
                modbus_send_32bitInt("0x01","0x10","14",sensor.value)
            elseif sensor.flag == "c_d_9" then
                modbus_send_32bitFloat("0x01","0x10","16",sensor.value)
            elseif sensor.flag == "c_d_10" then
                modbus_send_32bitFloat("0x01","0x10","18",sensor.value)
            elseif sensor.flag == "c_d_11" then
                modbus_send_32bitFloat("0x01","0x10","20",sensor.value)
            elseif sensor.flag == "c_d_12" then
                modbus_send_32bitFloat("0x01","0x10","22",sensor.value)
            elseif sensor.flag == "c_d_13" then
                modbus_send_32bitFloat("0x01","0x10","24",sensor.value)
            elseif sensor.flag == "c_d_14" then
                modbus_send_32bitFloat("0x01","0x10","26",sensor.value)
            elseif sensor.flag == "c_d_15" then
                modbus_send("0x01","0x06","28",sensor.value)
            elseif sensor.flag == "c_d_16" then
                modbus_send("0x01","0x06","30",sensor.value)
            elseif sensor.flag == "c_d_17" then
                modbus_send("0x01","0x06","32",sensor.value)
            elseif sensor.flag == "c_d_18" then
                modbus_send("0x01","0x06","34",sensor.value)
            elseif sensor.flag == "c_d_19" then
                modbus_send("0x01","0x06","36",sensor.value)
            elseif sensor.flag == "c_d_20" then
                modbus_send("0x01","0x06","38",sensor.value)
            elseif sensor.flag == "c_d_21" then
                modbus_send("0x01","0x06","40",sensor.value)
            elseif sensor.flag == "c_d_22" then
                modbus_send("0x01","0x06","42",sensor.value)
            elseif sensor.flag == "c_d_23" then
                modbus_send_32bitFloat("0x01","0x10","50",sensor.value)
            elseif sensor.flag == "c_d_24" then
                updateServerFlag = sensor.value
                fskv.set("updateServerFlag", updateServerFlag)
            elseif sensor.flag == "c_d_25" then
                reportingRule = sensor.value
                fskv.set("reportingRule", reportingRule)
            elseif sensor.flag == "c_d_26" then
                reportingTime = sensor.value
                fskv.set("reportingTime", reportingTime)
            elseif sensor.flag == "c_d_27" then
                rtos.reboot()
            end
            sys.wait(100)
        end
        readAllRegFlag = true
    end
end