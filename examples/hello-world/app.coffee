arcabouco = require '../../main.js'

config =
    baseDirectory: __dirname

app = new arcabouco config

server = app.createServer()
server.listen 8888

