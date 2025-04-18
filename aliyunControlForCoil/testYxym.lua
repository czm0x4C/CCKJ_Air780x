
require "sys"
aliyun = require "aliyun"

-- 注意当设备被激活后不可再被激活，当前代码的连接逻辑中，将动态注册的参数保存在flash中，如果被删除只能是再注册一次，但是使用一机一密连接也是可以的
-- 想要再次注册 您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。
-- 阿里云说明文档:https://help.aliyun.com/zh/iot/developer-reference/api-v0rd66?spm=a2c4g.11186623.0.0.30eb7bf6ZKJEBo#doc-api-Iot-ResetThing

--根据自己的服务器修改以下参数
-- 阿里云资料：https://help.aliyun.com/document_detail/147356.htm?spm=a2c4g.73742.0.0.4782214ch6jkXb#section-rtu-6kn-kru
tPara = {
    -- 一型一密 - ProductSecret要填产品secret
    -- 一型一密 分2种: 预注册和免预注册
    -- 公共实例只支持 预注册, Registration 填false
    -- 企业实例支持 预注册 和 免预注册, 如需使用免预注册, Registration 填true, 否则填false
    Registration = false,
    -- 设备名名称, 必须唯一
    DeviceName = "",
    -- 产品key, 在产品详情页面
    ProductKey = "a1kZREUyx5p",     --产品key
    --产品secret,一型一密就需要填
    ProductSecret = "YQmurG7a47AhMeCg",
    -- 填写实例id，在实例详情页面, 如果是旧的公共实例, 请填host参数
    InstanceId = "",
    RegionId = "cn-shanghai",
    --是否使用ssl加密连接
    mqtt_isssl = false,
}

--根据掉电不消失的kv文件区来储存的deviceSecret,clientid,deviceToken来判断是进行正常连接还是掉电重连
sys.taskInit(function()
    sys.waitUntil("IP_READY")
    log.info("已联网", "开始初始化aliyun库")
    -- 设置设备的名字
    print("mobile.iccid",mobile.imei())
    tPara.DeviceName = mobile.imei()

    local store = aliyun.store()

    --判断是否是同一三元组，不是的话就重新连接
    if store.deviceName ~= tPara.DeviceName or store.productKey ~= tPara.ProductKey then
        -- 清除fskv区的注册信息
        print(store.productKey,tPara.ProductKey,store.deviceName ,tPara.DeviceName )
        if fskv then
            fskv.del("DeviceName")
            fskv.del("ProductKey")
            fskv.del("deviceToken")
            fskv.del("deviceSecret")
            fskv.del("clientid")
        else
            os.remove("/alireg.json")
        end
        store = {}
    end

    if store.clientid and store.deviceToken and #store.clientid > 0 and #store.deviceToken > 0 then
        tPara.clientId = store.clientid
        tPara.deviceToken = store.deviceToken
        tPara.reginfo = true
    elseif store.deviceSecret and #store.deviceSecret > 0 then
        tPara.deviceSecret = store.deviceSecret
        tPara.reginfo = true
    end
    aliyun.setup(tPara)
end)

