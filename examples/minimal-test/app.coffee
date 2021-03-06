arcabouco = require '../../main.js'

config =
    baseDirectory: __dirname
    nodeStatic:
      assets:
        cdn:
          config:
            cache: 0
          directory: __dirname + '/cdn'

app = new arcabouco config

app.work require 'screw-node-static'

server = app.createServer()
server.listen 8888

