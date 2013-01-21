#mocha
e = require 'expect.js'
os = require 'options-stream'
exec = require('child_process').exec
mock =
  send : ''
  headers : {}
  req :
    url : '/'
  resp :
    write : (data)-> mock.send += data.toString()
    end : (data)-> mock.send += data.toString()
    statusCode : 0
    _hasConnectPatch : null
    setHeader : (name, value) -> mock.headers[name.toLowerCase()] = value
  clean : ->
    mock.send = ''
    mock.headers = {}
    mock.resp.statusCode = 0
    mock.resp._hasConnectPatch = null
    mock.req.url = '/'
  setConnect : (flag)->
    mock.resp._hasConnectPatch = flag

describe 'Node Vip StatusCode Responser', ->
  vip = require '../lib/vip-resp'
  flag = 0
  s = null
  beforeEach ->
    s = null
    flag = 0
    mock.clean()
  afterEach (done)->
    s.close(done) if s and s.close
  sock = __dirname + "/test-vr.sock"
  options =
    check_health: (cb)->
      flag++
      cb();
    sock_path: sock
    status_url: '/u'
    success_body : 'ok'
    timeout : 10

  describe 'pass request to next', ->
    it 'with http', ->
      s = vip options
      mock.req.url = '/u2'
      s.status mock.req, mock.resp, (req, resp)->
        e(flag).to.be 0
        e(req.url).to.be '/u2'
    it 'with connect', ()->
      s = vip options
      mock.req.url = '/u3'
      mock.setConnect true
      s.status mock.req, mock.resp, (req, resp)->
        e(flag).to.be 0
        e(req).to.be undefined
  describe 'check health ok', ->
    it 'sync', (done)->
      mock.req.url = '/u'
      s = vip options
      s.status mock.req, mock.resp, ->

      setTimeout ->
        e(flag).to.be 1
        e(mock.send).to.be 'ok'
        e(mock.headers).to.eql 'content-type': 'text/plain'
        e(mock.resp.statusCode).to.be 200
        done()
      , 100

    it 'async', (done)->
      mock.req.url = '/u'
      s = vip os options, check_health: (cb)->
        flag++
        process.nextTick cb
      s.status mock.req, mock.resp, ->
      setTimeout ->
        e(flag).to.be 1
        e(mock.send).to.be 'ok'
        e(mock.headers).to.eql 'content-type': 'text/plain'
        e(mock.resp.statusCode).to.be 200
        done()
      , 100
  describe 'check health error', ->
    it 'timeout', (done)->
      mock.req.url = '/u'
      s = vip os options, check_health: (cb)->
        flag++
        setTimeout cb, 50
      s.status mock.req, mock.resp, ->
      setTimeout ->
        e(flag).to.be 1
        e(mock.send).to.be 'Gateway Timeout'
        e(mock.headers).to.eql 'content-type': 'text/plain'
        e(mock.resp.statusCode).to.be 504
        done()
      , 100
    it 'server down', (done)->
      mock.req.url = '/u'
      s = vip os options, check_health: (cb)->
        flag++
        cb(new Error('some error'))
      s.status mock.req, mock.resp, ->

      setTimeout ->
        e(flag).to.be 1
        e(mock.send).to.match /^Internal Server Error/i
        e(mock.send).to.match /some error/i
        e(mock.headers).to.eql 'content-type': 'text/plain'
        e(mock.resp.statusCode).to.be 500
        done()
      , 100
  describe 'work with command line', ->
    it 'set off', (done)->
      mock.req.url = '/u'
      s = vip os options

      s.status mock.req, mock.resp, ->
      setTimeout ->
        e(flag).to.be 1
        e(mock.resp.statusCode).to.be 200
      , 30
      setTimeout ->
        exec "bin/vip off #{sock}"
      , 50
      setTimeout (-> s.status mock.req, mock.resp, ->), 100

      setTimeout ->
        e(flag).to.be 1
        e(mock.resp.statusCode).to.be 503
      , 150
      setTimeout ->
        e(flag).to.be 1
        done();
      , 200
    it 'set on', (done)->
      mock.req.url = '/u'
      s = vip os options, check_health: (cb)->
        flag++
        cb(new Error('some error'))

      s.status mock.req, mock.resp, ->
      setTimeout ->
        e(flag).to.be 1
        e(mock.resp.statusCode).to.be 500
      , 30
      setTimeout ->
        exec "bin/vip on #{sock}"
      , 50
      setTimeout (-> s.status mock.req, mock.resp, ->), 100

      setTimeout ->
        e(mock.resp.statusCode).to.be 200
        e(flag).to.be 1
      , 150
      setTimeout ->
        e(flag).to.be 1
        done();
      , 200

    it 'set auto', (done)->
      mock.req.url = '/u'
      s = vip os options
      s.status mock.req, mock.resp, ->
      setTimeout ->
        e(flag).to.be 1
        e(mock.resp.statusCode).to.be 200
      , 30
      setTimeout ->
        exec "bin/vip off"
      , 50
      setTimeout (-> s.status mock.req, mock.resp, ->), 100
      setTimeout ->
        e(flag).to.be 1
        e(mock.resp.statusCode).to.be 503
      , 150
      setTimeout ->
        exec "bin/vip auto"
      , 200
      setTimeout (-> s.status mock.req, mock.resp, ->), 250
      setTimeout ->
        e(flag).to.be 2
        e(mock.resp.statusCode).to.be 200
        s.options.check_health = (cb)->
          flag++
          cb(new Error('some error'))
      , 300
      setTimeout (-> s.status mock.req, mock.resp, ->), 350
      setTimeout ->
        e(flag).to.be 3
        e(mock.resp.statusCode).to.be 500
      , 400

      setTimeout ->
        e(flag).to.be 3
        done();
      , 450
