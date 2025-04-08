require("common")
require("queue")

function modbus_send(slaveaddr,Instructions,reg,value)
    local data = (string.format("%02x",slaveaddr)..string.format("%02x",Instructions)..string.format("%04x",reg)..string.format("%04x",value)):fromHex()
    local modbus_crc_data = pack.pack('<h', crypto.crc16("MODBUS",data))
    local data_tx = data..modbus_crc_data
    
    uart.write(uartid,data_tx)

end

function modbus_send_32bitInt(slaveaddr,Instructions,reg,value)
    local data = (string.format("%02x",slaveaddr)..string.format("%02x",Instructions)..string.format("%04x",reg)..string.format("%04x",2)..string.format("%02x",4)):fromHex()
    data = data..pack.pack(">I", value)
    local modbus_crc_data = pack.pack('<h', crypto.crc16("MODBUS",data))
    local data_tx = data..modbus_crc_data
    
    uart.write(uartid,data_tx)

end

function modbus_send_32bitFloat(slaveaddr,Instructions,reg,value)
    local data = (string.format("%02x",slaveaddr)..string.format("%02x",Instructions)..string.format("%04x",reg)..string.format("%04x",2)..string.format("%02x",4)):fromHex()
    data = data..pack.pack(">f", value)
    local modbus_crc_data = pack.pack('<h', crypto.crc16("MODBUS",data))
    local data_tx = data..modbus_crc_data
    
    uart.write(uartid,data_tx)

end

-- 这个函数用于将数字转换为一个无符号的16位整数
local function toUnsignedShort(num)
    return num % (2^16)
end

function getBitValue(uShort, bitPosition)
    -- 确保位位置在0到15之间
    if bitPosition < 0 or bitPosition > 15 then
        return nil -- 或者抛出一个错误
    end

    -- 将uShort转换为无符号的16位整数
    uShort = toUnsignedShort(uShort)

    -- 创建一个掩码，只有我们关心的位是1，其他位都是0
    local mask = 2^bitPosition
    -- 使用按位与运算符检查该位
    local result = uShort % (mask * 2) - (uShort % mask)
    -- 如果结果不为0，那么该位是1，否则是0
    return result ~= 0 and 1 or 0
end

-- 设置指定位置的位为1
function setBit(uShort, bitPosition)
    -- uShort = toUnsignedShort(uShort)
    print("uShort", uShort)
    return uShort | (1 << bitPosition)
end

-- 清除指定位置的位（将其设置为0）
function clearBit(uShort, bitPosition)
    -- uShort = toUnsignedShort(uShort)
    print("uShort", uShort)
    return uShort & ~(1 << bitPosition)
end

-- 读取所有寄存器的值
function readMobusRTU_Registers_ALL()
    local reTry = 0 -- 重复读取次数
    sys.wait(25)
    -- 读取 00 - 26
    while reTry<5 do
        modbus_send("0x01", "0x03", "0x00", "0x1C")
        local ret, uartRecvData = sys.waitUntil("RegistersRead", 1000)
        if ret then
            local addr, Instructions, len, rtuCrc = nil
            local floatValue = {}
            _, addr, Instructions, len, 
            floatValue[1], floatValue[2], floatValue[3],
            floatValue[4], floatValue[5], floatValue[6],
            floatValue[7], floatValue[8], floatValue[9], 
            floatValue[10], floatValue[11], floatValue[12],
            floatValue[13], floatValue[14],
            rtuCrc = pack.unpack(uartRecvData, ">bbbfffffffIffffffHH")
            for i = 1, 14 do
                plcRegistersValues[i] = floatValue[i]
            end

            sys.wait(25)

            break
        end
        reTry = reTry + 1
        print("readMobusRTU_Registers_ALL 读取 00 - 26 重试次数：", reTry)
        sys.wait(25)
    end

    -- 读取 28 - 28
    while reTry<5 do
        modbus_send("0x01", "0x03", "0x1C", "0x01")
        local ret, uartRecvData = sys.waitUntil("RegistersRead", 1000)
        if ret then
            local addr, Instructions, len, rtuCrc = nil
            local floatValue = {}
            _, addr, Instructions, len, 
            floatValue[1], 
            rtuCrc = pack.unpack(uartRecvData, ">bbbhHH")
            
            plcRegistersValues[15] = floatValue[1]

            sys.wait(25)

            break
        end
        reTry = reTry + 1
        print("readMobusRTU_Registers_ALL 读取 28 - 28 重试次数：", reTry)
        sys.wait(25)
    end

    -- 读取 30 - 30
    while reTry<5 do
        modbus_send("0x01", "0x03", "0x1E", "0x01")
        local ret, uartRecvData = sys.waitUntil("RegistersRead", 1000)
        if ret then
            local addr, Instructions, len, rtuCrc = nil
            local floatValue = {}
            _, addr, Instructions, len, 
            floatValue[1], 
            rtuCrc = pack.unpack(uartRecvData, ">bbbhHH")
            
            plcRegistersValues[16] = floatValue[1]

            sys.wait(25)

            break
        end
        reTry = reTry + 1
        print("readMobusRTU_Registers_ALL 读取 30 - 30 重试次数：", reTry)
        sys.wait(25)
    end

    -- 读取 32 - 32
    while reTry<5 do
        modbus_send("0x01", "0x03", "0x20", "0x01")
        local ret, uartRecvData = sys.waitUntil("RegistersRead", 1000)
        if ret then
            local addr, Instructions, len, rtuCrc = nil
            local floatValue = {}
            _, addr, Instructions, len, 
            floatValue[1], 
            rtuCrc = pack.unpack(uartRecvData, ">bbbhHH")
            
            plcRegistersValues[17] = floatValue[1]

            sys.wait(25)

            break
        end
        reTry = reTry + 1
        print("readMobusRTU_Registers_ALL 读取 32 - 32 重试次数：", reTry)
        sys.wait(25)
    end

    -- 读取 34 - 34
    while reTry<5 do
        modbus_send("0x01", "0x03", "0x22", "0x01")
        local ret, uartRecvData = sys.waitUntil("RegistersRead", 1000)
        if ret then
            local addr, Instructions, len, rtuCrc = nil
            local floatValue = {}
            _, addr, Instructions, len, 
            floatValue[1], 
            rtuCrc = pack.unpack(uartRecvData, ">bbbhHH")
            
            plcRegistersValues[18] = floatValue[1]

            sys.wait(25)

            break
        end
        reTry = reTry + 1
        print("readMobusRTU_Registers_ALL 读取 34 - 34 重试次数：", reTry)
        sys.wait(25)
    end

    -- 读取 36 - 36
    while reTry<5 do
        modbus_send("0x01", "0x03", "0x24", "0x01")
        local ret, uartRecvData = sys.waitUntil("RegistersRead", 1000)
        if ret then
            local addr, Instructions, len, rtuCrc = nil
            local floatValue = {}
            _, addr, Instructions, len, 
            floatValue[1], 
            rtuCrc = pack.unpack(uartRecvData, ">bbbhHH")
            
            plcRegistersValues[19] = floatValue[1]

            sys.wait(25)

            break
        end
        reTry = reTry + 1
        print("readMobusRTU_Registers_ALL 读取 36 - 36 重试次数：", reTry)
        sys.wait(25)
    end

    -- 读取 38 - 39
    while reTry<5 do
        modbus_send("0x01", "0x03", "0x26", "0x01")
        local ret, uartRecvData = sys.waitUntil("RegistersRead", 1000)
        if ret then
            local addr, Instructions, len, rtuCrc = nil
            local floatValue = {}
            _, addr, Instructions, len, 
            floatValue[1], 
            rtuCrc = pack.unpack(uartRecvData, ">bbbhHH")
            
            plcRegistersValues[20] = floatValue[1]

            sys.wait(25)

            break
        end
        reTry = reTry + 1
        print("readMobusRTU_Registers_ALL 读取 38 - 39 重试次数：", reTry)
        sys.wait(25)
    end

    -- 读取 40 - 41
    while reTry<5 do
        modbus_send("0x01", "0x03", "0x28", "0x01")
        local ret, uartRecvData = sys.waitUntil("RegistersRead", 1000)
        if ret then
            local addr, Instructions, len, rtuCrc = nil
            local floatValue = {}
            _, addr, Instructions, len, 
            floatValue[1], 
            rtuCrc = pack.unpack(uartRecvData, ">bbbhHH")
            
            plcRegistersValues[21] = floatValue[1]

            sys.wait(25)

            break
        end
        reTry = reTry + 1
        print("readMobusRTU_Registers_ALL 读取 38 - 39 重试次数：", reTry)
        sys.wait(25)
    end

    -- 读取 40 - 41
    while reTry<5 do
        modbus_send("0x01", "0x03", "0x28", "0x01")
        local ret, uartRecvData = sys.waitUntil("RegistersRead", 1000)
        if ret then
            local addr, Instructions, len, rtuCrc = nil
            local floatValue = {}
            _, addr, Instructions, len, 
            floatValue[1], 
            rtuCrc = pack.unpack(uartRecvData, ">bbbhHH")
            
            plcRegistersValues[21] = floatValue[1]

            sys.wait(25)

            break
        end
        reTry = reTry + 1
        print("readMobusRTU_Registers_ALL 读取 40 - 41 重试次数：", reTry)
        sys.wait(25)
    end

    -- 读取 42 - 43
    while reTry<5 do
        modbus_send("0x01", "0x03", "0x2A", "0x01")
        local ret, uartRecvData = sys.waitUntil("RegistersRead", 1000)
        if ret then
            local addr, Instructions, len, rtuCrc = nil
            local floatValue = {}
            _, addr, Instructions, len, 
            floatValue[1], 
            rtuCrc = pack.unpack(uartRecvData, ">bbbhHH")
            
            plcRegistersValues[22] = floatValue[1]

            sys.wait(25)

            break
        end
        reTry = reTry + 1
        print("readMobusRTU_Registers_ALL 读取 42 - 43 重试次数：", reTry)
        sys.wait(25)
    end

    -- 读取 50 - 51
    while reTry<5 do
        modbus_send("0x01", "0x03", "0x32", "0x02")
        local ret, uartRecvData = sys.waitUntil("RegistersRead", 1000)
        if ret then
            local addr, Instructions, len, rtuCrc = nil
            local floatValue = {}
            _, addr, Instructions, len, 
            floatValue[1], 
            rtuCrc = pack.unpack(uartRecvData, ">bbbfHH")

            plcRegistersValues[23] = floatValue[1]

            sys.wait(25)
            
            break
        end
        reTry = reTry + 1
        print("readMobusRTU_Registers_ALL 读取 50 - 51 重试次数：", reTry)
        sys.wait(25)
    end

    plcRegistersValues[24] = updateServerFlag
    plcRegistersValues[25] = reportingRule
    plcRegistersValues[26] = reportingTime

    plcRegistersValues[27] = 0
    plcRegistersValues[28] = mobile.iccid()
    plcRegistersValues[29] = mobile.rssi()

end
-- 更新寄存器值
function upDate_Registers_Value()
    if reportingTime ~= 0 then
        local currentTime = os.time()
        if currentTime - lastTime > reportingTime * 60 then
            updateToYun_MobusRTU_Registers_ALL()
            lastTime = os.time()
            return -- 此处返回是因为全部数据已经更新且全部上传 无需后面的比较
        end
    end

    if reportingRule ~= 0 then
        for register, newValue in pairs(plcRegistersValues) do
            if lastPlcRegistersValues[register] ~= newValue then 
                if (newValue >= lastPlcRegistersValues[register] + reportingRule) or (newValue <= lastPlcRegistersValues[register] - reportingRule) then
                    -- 更新变化值
                    print("register = ", register, "newValue", newValue, "\n")
                    lastPlcRegistersValues[register] = newValue
                    -- 上传变化到服务器B
                    local jsonStr = '{'
                    local registerStr = '"c_d_' .. tostring(register) .. '": ' .. tostring(newValue)
                    jsonStr = jsonStr .. registerStr .. '}'
                    sys.publish("mqtt_pub", "B", mqtt_server_B_pub_topic, jsonStr, 0)
                    -- 上传变化到服务器A
                    local original_json = [[{}]]
                    local data_table = json.decode(original_json) or {} 
                    if not data_table.sensorDatas then
                        data_table.sensorDatas = {}  -- 创建空数组
                    end
                    local new_entry = {
                        flag = "c_d_"..tostring(register),
                        value = newValue
                    }
                    table.insert(data_table.sensorDatas, new_entry)
                    local updated_json = json.encode(data_table, { indent = true })
                    sys.publish("mqtt_pub", "A", mqtt_server_A_pub_topic, updated_json, 0)
                end
                -- 特殊的三个寄存器 发生变化就上传
                if register == 24 or register == 25 or register == 26 then
                    lastPlcRegistersValues[register] = newValue

                    fskv.set("serverFlag", updateServerFlag)
                    fskv.set("reportingRule", reportingRule)
                    fskv.set("reportingTime", reportingTime)
                    -- 上传变化到服务器B
                    local jsonStr = '{'
                    local registerStr = '"c_d_' .. tostring(register) .. '": ' .. tostring(newValue)
                    jsonStr = jsonStr .. registerStr .. '}'
                    sys.publish("mqtt_pub", "B", mqtt_server_B_pub_topic, jsonStr, 0)
                    -- 上传变化到服务器A
                    local original_json = [[{}]]
                    local data_table = json.decode(original_json) or {} 
                    if not data_table.sensorDatas then
                        data_table.sensorDatas = {}  -- 创建空数组
                    end
                    local new_entry = {
                        flag = "c_d_"..tostring(register),
                        value = newValue
                    }
                    table.insert(data_table.sensorDatas, new_entry)
                    local updated_json = json.encode(data_table, { indent = true })
                    sys.publish("mqtt_pub", "A", mqtt_server_A_pub_topic, updated_json, 0)
                end
            end
        end
    end
end
-- 设备首次上电时读取所有寄存器一次
function firstReadRegistersValue()
    readMobusRTU_Registers_ALL()    -- 读取所有寄存器数据
    for register, value in pairs(plcRegistersValues) do
        lastPlcRegistersValues[register] = value
    end

    fskv.set("serverFlag", updateServerFlag)
    fskv.set("reportingRule", reportingRule)
    fskv.set("reportingTime", reportingTime)

end
-- 对开启了变化监测的寄存器进行读取
function variationRegistersMonitor()
    readMobusRTU_Registers_ALL() 
end

-- 所有数据上传到云端
function updateToYun_MobusRTU_Registers_ALL()

    for register, value in pairs(plcRegistersValues) do
        lastPlcRegistersValues[register] = value
    end

    local jsonStr = '{'
    local first = true
    for register, value in pairs(plcRegistersValues) do
        -- 为寄存器地址添加前缀'c_d_'并转换为字符串
        local registerStr = ""
        if register == 28 then
            registerStr = '"s_c_d_' .. tostring(register) .. '": ' ..'"'.. tostring(value)..'"'
        else
            registerStr = '"c_d_' .. tostring(register) .. '": ' .. tostring(value)
        end
        -- 如果不是第一个寄存器，添加逗号分隔符
        if not first then
            jsonStr = jsonStr .. ', '
        end
        jsonStr = jsonStr .. registerStr
        first = false
    end
    
    jsonStr = jsonStr .. '}'

    sys.publish("mqtt_pub", "B", mqtt_server_B_pub_topic, jsonStr, 0)
    
    local original_json = [[{}]]  

    -- 解析JSON（处理可能的空/无效情况）
    local data_table = json.decode(original_json) or {}  -- 确保data_table至少是空表

    if not data_table.sensorDatas then
        data_table.sensorDatas = {}  -- 创建空数组
    end
    for register, value in pairs(plcRegistersValues) do
        -- 新传感器条目
        local new_entry
        if register == 28 then
            new_entry =  
            {
                -- sensorsId = 5120700 + register-1,
                flag = "c_d_"..tostring(register),
                str = value
            }
        else
            new_entry =  
            {
                -- sensorsId = 5120700 + register-1,
                flag = "c_d_"..tostring(register),
                value = value
            }
        end
       
        -- 插入新条目
        table.insert(data_table.sensorDatas, new_entry)
    end
    local updated_json = json.encode(data_table, { indent = true })
    sys.publish("mqtt_pub", "A", mqtt_server_A_pub_topic, updated_json, 0)
end

-- 1s的定时任务
function timerCallback1s()
    
    time_1s_out = true
    
end

function createIntervalChecker()
    local lastCallTime = nil  -- 保存上一次调用时间

    return function()
        local currentTime = os.time()  -- 获取当前时间（秒级时间戳）
        local interval = 0

        -- 首次调用时不计算间隔
        if lastCallTime then
            interval = currentTime - lastCallTime
        end

        lastCallTime = currentTime  -- 更新最后一次调用时间
        return interval
    end
end