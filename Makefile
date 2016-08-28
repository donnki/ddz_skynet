SKYNET_PATH = skynet
TARGET = cservice/package.so

$(TARGET) : src/service_package.c
	gcc -Wall -O2 --shared -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup -o $@ $^ -I$(SKYNET_PATH)/skynet-src

socket :
	cd lsocket && $(MAKE) LUA_INCLUDE=../skynet/3rd/lua

clean :
	rm $(TARGET)