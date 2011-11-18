arcabouco = require '../../main.js'

config =
    baseDirectory: __dirname

app = new arcabouco config

app.assemble __dirname + '/pieces'
app.build()

server = app.createServer()
server.listen 8888
