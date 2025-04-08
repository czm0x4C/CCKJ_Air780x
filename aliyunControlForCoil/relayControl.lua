-- 继电器控制引脚
local relayChannel_1_pin = 22
local relayChannel_2_pin = 24 
local relayChannel_3_pin = 36
local relayChannel_4_pin = 1
-- 初始化各个引脚
gpio.setup(relayChannel_1_pin, 0, gpio.PULLUP, nil)
gpio.setup(relayChannel_2_pin, 0, gpio.PULLUP, nil)
gpio.setup(relayChannel_3_pin, 0, gpio.PULLUP, nil)
gpio.setup(relayChannel_4_pin, 0, gpio.PULLUP, nil)

function openRelay(channel)
    if channel == 1 then
        gpio.set(relayChannel_1_pin, 1)
    elseif channel == 2 then
        gpio.set(relayChannel_2_pin, 1)
    elseif channel == 3 then
        gpio.set(relayChannel_3_pin, 1)
    elseif channel == 4 then
        gpio.set(relayChannel_4_pin, 1)
    end
end

function closeRelay(channel)
    if channel == 1 then
        gpio.set(relayChannel_1_pin, 0)
    elseif channel == 2 then
        gpio.set(relayChannel_2_pin, 0)
    elseif channel == 3 then
        gpio.set(relayChannel_3_pin, 0)
    elseif channel == 4 then
        gpio.set(relayChannel_4_pin, 0)
    end
end

