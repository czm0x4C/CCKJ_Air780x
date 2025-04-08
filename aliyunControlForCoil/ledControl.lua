-- 继电器控制引脚
local ledChannel_1_pin = 28
local ledChannel_2_pin = 4
local ledChannel_3_pin = 6
local ledChannel_4_pin = 3
-- 初始化各个引脚
gpio.setup(ledChannel_1_pin, 0, gpio.PULLUP, nil)
gpio.setup(ledChannel_2_pin, 0, gpio.PULLUP, nil)
gpio.setup(ledChannel_3_pin, 0, gpio.PULLUP, nil)
gpio.setup(ledChannel_4_pin, 0, gpio.PULLUP, nil)

function openLed(channel)
    if channel == 1 then
        gpio.set(ledChannel_1_pin, 1)
    elseif channel == 2 then
        gpio.set(ledChannel_2_pin, 1)
    elseif channel == 3 then
        gpio.set(ledChannel_3_pin, 1)
    elseif channel == 4 then
        gpio.set(ledChannel_4_pin, 1)
    end
end

function closeLed(channel)
    if channel == 1 then
        gpio.set(ledChannel_1_pin, 0)
    elseif channel == 2 then
        gpio.set(ledChannel_2_pin, 0)
    elseif channel == 3 then
        gpio.set(ledChannel_3_pin, 0)
    elseif channel == 4 then
        gpio.set(ledChannel_4_pin, 0)
    end
end

