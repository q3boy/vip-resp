path = require 'path'
os = require 'options-stream'
http = require 'http'
net = require 'net'
fs = require 'fs'

class VipStatus
  constructor : (options={}) ->
    @options = os
      check_health: (cb)-> process.nextTick cb
      sock_path: "#{path.dirname process.mainModule.filename}/run/#{path.basename process.mainModule.filename}-vr.sock"
      status_url: '/status.taobao'
      success_body : 'success'
      timeout : 2000
    , options
    @status.bind @
    @force = 'auto'
    @net = null
    @listen()

  listen : ->
    fs.unlinkSync @options.sock_path if fs.existsSync @options.sock_path
    @net = net.createServer (conn) =>
      conn.on 'data', (data) =>
        @force = data.toString().trim().toLowerCase()
        @force = 'auto' if @force isnt 'on' and @force isnt 'off'
    .listen @options.sock_path

  close : ->
    return if not @net
    @net.close()
    try fs.unlink @options.sock_path

  response = (resp, code, phrase) ->
    resp.setHeader 'Content-Type', 'text/plain'
    resp.statusCode = code
    resp.end phrase
    return


  status : (req, resp, next) ->
    end = false
    if req.url isnt @options.status_url
      if resp._hasConnectPatch then next() else next req, resp
      return

    if @force is 'on' # always ok
      response resp, 200, @options.success_body
    else if @force is 'off' # always off
      response resp, 503, 'Service Unavailable'
    else
      # check health timeout
      timeout = setTimeout =>
        return if end
        response resp, 504, 'Gateway Timeout'
        end = true
        return
      , @options.timeout
      # check health
      @options.check_health (err) =>
        return if end
        if err # error
          response resp, 500, "Internal Server Error\r\n#{err}"
        else # ok
          response resp, 200, @options.success_body
        end = true
        clearTimeout timeout
        return
    return


module.exports = (options) ->
  new VipStatus options
