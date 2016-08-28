# ddz_skynet
simple implemetation of doudizhu(斗地主), based on [skynet](https://github.com/cloudwu/skynet)

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
```make
```
