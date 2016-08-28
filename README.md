# ddz_skynet
simple implemetation of doudizhu(斗地主), based on [skynet](https://github.com/cloudwu/skynet)

这是在空闲时研究云风的skynet写的一个demo，实现一个C/S的斗地主的基本逻辑，接口包括：
* 自动注册，已注册时自动登录
* 自动创建房间
* 进入房间或离开房间
* 准备或取消准备游戏
* 游戏开始时叫地主&抢地主的基本逻辑
* 斗地主玩法的全部规则实现

大概是花了3天左右时间写的，功能还比较不完善，主要的时间也花在了斗地主的规则上。而像复用game、room这几个skynet service，以及一些网络处理细节上还未来得及做，留待后续有时间处理吧。

使用sproto，具体协议见proto目录。

##如何编译
clone 下本仓库。
更新 submodule ，服务器部分需要用到 skynet ；客户端部分需要用到 lsocket 。
```
git submodule update --init
```

编译 skynet
```
cd skynet
make linux
```

编译 lsocket（如果你需要客户端）
```
make socket
```

编译 skynet package 模块
```
make
```
