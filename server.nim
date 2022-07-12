import lock
import std/json
import ws, asyncdispatch, asynchttpserver

type User = ref object of RootObj
    ws: WebSocket
    nick: string

#var connections = newSeq[WebSocket]()
var connections = newSeq[User]()

proc cb(req: Request) {.gcsafe, async.} =
    if req.url.path == "/ws":
        try:
            var ws = await newWebSocket(req)
            await ws.send("{\"data\": \"Welcome\", \"nick\": \"server\"}")
            while ws.readyState == Open:
                let packet = await ws.receiveStrPacket()
                echo packet
                let data = parseJson(packet)
                let usr = User(ws:ws, nick:data["nick"].str)
                if not connections.contains(usr):
                    connections.add(usr)
                if "command" in data:
                    continue
                for other in connections:
                    if other.nick != data["nick"].str:
                        if other.ws.readyState == Open:
                            asyncCheck other.ws.send(packet)

            
        except WebSocketError:
            echo "socket closed:", getCurrentExceptionMsg()
    else:
        await req.respond(Http404, "Not found")


proc stop() {.noconv.} =
    lock.unlock()
    quit()

proc start*() = 
    setControlCHook(stop)
    echo "Server!"
    var server = newAsyncHttpServer()
    waitFor server.serve(Port(9001), cb)
    echo stdin.readLine()
