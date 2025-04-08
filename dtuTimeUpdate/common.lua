
uartid = 1        -- 根据实际设备选取不同的uartid
uartBandrate = 9600
lastUartRecv = {} -- 保存接收的串口数据

-- 数据枚举
-- 定义PLC寄存器地址枚举
PLCRegisters = {
    reg1 = 0,   --  实际显示 PV值
    reg2 = 2,   -- AH
    reg3 = 4,   -- AL
    reg4 = 6,   -- BS
    reg5 = 8,   -- BT
    reg6 = 10,   -- PS
    reg7 = 12,   -- PT
    reg8 = 14,   -- LOCK
    reg9 = 16,   -- DOT
    reg10 = 18,   -- PUL
    reg11 = 20,   -- PUH
    reg12 = 22,   -- SC
    reg13 = 24,   -- K1
    reg14 = 26,   -- H2
    reg15 = 28,   -- PH
    reg16 = 30,   -- BH
    reg17 = 32,   -- CRL
    reg18 = 34,   -- K-B
    reg19 = 36,   -- K-P
    reg20 = 38,   -- BAUD
    reg21 = 40,   -- ADDR
    reg22 = 42,   -- SN
    
    reg26 = 50,   -- TTL发送的PV值

    reg64 = 100,   -- 上报服务器选择
    reg65 = 101,   -- 本地端变化上报
    reg66 = 102,   -- 定时上报
}

-- 可以根据需要访问特定的寄存器地址，例如：
-- print(PLCRegisters.Relay1)

-- 定义一个表来存储寄存器的值
plcRegistersValues = {
    [1] = 0,   --  实际显示 PV值
    [2] = 0,   -- AH
    [3] = 0,   -- AL
    [4] = 0,   -- BS
    [5] = 0,   -- BT
    [6] = 0,   -- PS
    [7] = 0,   -- PT
    [8] = 0,   -- LOCK
    [9] = 0,   -- DOT
    [10] = 0,   -- PUL
    [11] = 0,   -- PUH
    [12] = 0,   -- SC
    [13] = 0,   -- K1
    [14] = 0,   -- H2
    [15] = 0,   -- PH
    [16] = 0,   -- BH
    [17] = 0,   -- CRL
    [18] = 0,   -- K-B
    [19] = 0,   -- K-P
    [20] = 0,   -- BAUD
    [21] = 0,   -- ADDR
    [22] = 0,   -- SN

    [23] = 0,   -- TTL发送的PV值

    [24] = 0,   -- 上报服务器选择
    [25] = 0,   -- 本地端变化上报
    [26] = 0,   -- 定时上报
    [27] = 0,   -- 写入1就重启模块  
    [28] = 0,   -- iccid卡号
    [29] = 0    -- 信号强度上报
} 

-- 可以根据需要访问或设置寄存器的值
-- plcRegistersValues[0] = 1 -- 设置本地和远程切换的值
-- print(plcRegistersValues[0]) -- 访问本地和远程切换的值

lastPlcRegistersValues = {
    [1] = 0,   --  实际显示 PV值
    [2] = 0,   -- AH
    [3] = 0,   -- AL
    [4] = 0,   -- BS
    [5] = 0,   -- BT
    [6] = 0,   -- PS
    [7] = 0,   -- PT
    [8] = 0,   -- LOCK
    [9] = 0,   -- DOT
    [10] = 0,   -- PUL
    [11] = 0,   -- PUH
    [12] = 0,   -- SC
    [13] = 0,   -- K1
    [14] = 0,   -- H2
    [15] = 0,   -- PH
    [16] = 0,   -- BH
    [17] = 0,   -- CRL
    [18] = 0,   -- K-B
    [19] = 0,   -- K-P
    [20] = 0,   -- BAUD
    [21] = 0,   -- ADDR
    [22] = 0,   -- SN

    [23] = 0,   -- TTL发送的PV值

    [24] = 0,   -- 上报服务器选择
    [25] = 0,   -- 本地端变化上报
    [26] = 0,   -- 定时上报
    [27] = 0,   -- 写入1就重启模块  
    [28] = 0,   -- iccid卡号
    [29] = 0    -- 信号强度上报
}

timeNum = {0,0,0,0,0,0} -- 存储年月日时分秒的数值
readAllRegFlag = false
time_1s_out = false
time_60s_out = false
time_1800s_out = false