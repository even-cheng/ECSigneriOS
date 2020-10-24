# ECSigner签名iphone客户端

## v3.3新增:
#### 1，增加签名时设置规则拦截APP的网络请求
#### 2，增加默认加锁选项
#### 3，修改分享后缀名与其他平台统一

## v3.2新增:
#### 1，适配导航栏ios10遮挡和滑动操作无效问题
#### 2，适配ipad弹框无法显示问题
#### 3，修复改名弹窗无法取消问题
#### 4，切换签名方式主动清空已选证书
#### 5，增加文件首次打开操作提示
#### 6，修复修改压缩率无效的问题
#### 7，修复特殊字符路径下包签名失败问题
#### 8，增加网页第三方分发平台安装包自动下载
#### 9, 修复部分G3证书签名异常问题

## v3.1新增:
#### 1，导入压缩包自动解压并取出文件进行分类
#### 2，适配越狱机型
#### 3，签名完成自动刷新已签名列表
#### 4，增加网页浏览和网页内下载
#### 5，获取设备号自动刷新显示
#### 6，支持自签版本的第三方应用直接分享文件到ECSigner APP
#### 7, 记录上一次签名的证书并自动选中
#### 8，增加原包重命名功能

## v3.0新增：
#### 1, 新增开发者后台管理，支持在线创建证书，描述文件，APPID，添加设备等操作
#### 2，优化签名注入，新增同时注入多个依赖库，支持注入和加锁同时进行
#### 3，增加本地获取设备UDID
#### 4，优化本地文件存取和展示逻辑
#### 5，优化外部导入文件后缀为.ipa.rename的识别

## v2.0新增：
#### 账号签（超级签）
#### 证书详情和状态读取
#### 包详情和证书文件读取
#### 下载中心（支持自动下载并分类，支持plist地址自动解析IPA下载）

![ sign.png](https://github.com/even-cheng/ECSignerForiOS/blob/master/sign1.png)
![ sign.png](https://github.com/even-cheng/ECSignerForiOS/blob/master/sign2.png)
![ sign.png](https://github.com/even-cheng/ECSignerForiOS/blob/master/sign3.png)
![ sign.png](https://github.com/even-cheng/ECSignerForiOS/blob/master/sign4.png)
![ sign.png](https://github.com/even-cheng/ECSignerForiOS/blob/master/sign5.png)
![ sign.png](https://github.com/even-cheng/ECSignerForiOS/blob/master/sign6.png)

### ECSigner使用说明：
##### 1、本工具仅供内部合法使用，请勿使用本工具签名非法APP，否则开发者有权终止您的使用权限，所产生一切后果均与开发者无关。
##### 2、本工具Mac端已开源免费使用，请前往GitHub下载：https://github.com/even-cheng/ECSigner
##### 3、本工具不偷书！不偷书！不偷书！官方下载渠道为官方QQ群，开发者QQ号，GitHub主页，其它地方下载或者分享的请勿使用！！！
##### 4、关于时间锁，工具默认使用第三方云服务器Leancloud, 因为它基础功能免费可以满足您的基本需求（账号请自行申请和客户端内配置），加锁不会上传您的证书，您的数据都在您自己手上，登录您的leanclud后台就能看的，也可以自行控制，所有数据与开发者无关。
##### 5、如果只使用基础签名功能，而且您还不放心，那您可以关闭APP的网络权限（关闭后部分功能受限）。

### 使用细节：
##### 1、官方签名版用户您可以在其他APP选择想要导入ECSigner的文件，点击分享到ECSigner打开。自己签名的用户请在应用内-文件-右上角点击导入。
##### 2、导入p12之后请前往文件-证书详情修改密码-保存。
##### 3、如需加锁管理，请先注册您的Leancloud账号，并创建一个APP，然后将您的APPID和key等信息添加到ECSigner的服务器选项。
##### 4、如需在线安装，请在leancloud后台配置文件-设置，服务器改为https。
### 5、其他问题，请联系开发者QQ492293215或在QQ"ECSigner签名交流群(837459998)"里提问。



