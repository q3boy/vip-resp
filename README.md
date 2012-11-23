# Node Vip Status Responser
![travis build info](https://api.travis-ci.org/q3boy/vip-resp.png)

vip status check responser

* 支持原生 http module 与 connect middleware
* 提供命令行工具可强制指定vip状态开关

## Example

```javascript
var vip = new require('vip-resp')({
	// health check function
	check_health: function(done){
		... // do health check
		err = gotError ? new Error() : null
		done(err)
	},
	// listen stat switch sock for command line
	sock_path: "http-vr.sock"
	// health check timeout ms
	timeout : 500
})
// with http
var http = http.createServer(function(req, resp){
	vip.status(req, resp, function(req, resp){
		// you own codes
	})
})

// with connect
app.use vip.status
```

## bin

Usage: `vip [auto|on|off] [socks...]`

* auto: 返回内置健康检查结果
* on: 始终返回服务可用
* off: 始终返回服务不可用
* socks...: vip-resp监听sock地址列表(默认搜索当前目录下所有以-nv.sock为结尾的sock文件)


```shell
./node_modules/.bin/vip on
./node_modules/.bin/vip off
./node_modules/.bin/vip auto ./run/a-nv.sock ./run/b-nv.sock
```


