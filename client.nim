import asyncdispatch, asynchttpserver, ws
import std/locks
import std/strformat
import std/json

proc senderWrapper*(nick: string) =
    proc sender() {.async.} =
        var ws = await newWebSocket("ws://127.0.0.1:9001/ws")
        while true:
            var json = %* {
                    "data": stdin.readLine(),
                    "nick": nick
                }
            await ws.send(fmt"{json}")

    var future = sender()
    waitFor future
    echo future.finished 

proc receiverWrapper*(nick: string) =
    proc receiver() {.async.} =
        var ws = await newWebSocket("ws://127.0.0.1:9001/ws")
        var json = %* {
            "data": "",
            "command": ">>register<<",
            "nick": nick
        }
        await ws.send(fmt"{json}")

        while true:
            var data = await ws.receiveStrPacket()
            var json = parseJson(data)
            var user = json["nick"]
            var msg = json["data"]

            echo fmt">>> {user}: {msg}"

    var future = receiver()
    waitFor future
    echo future.finished

proc start*()  = 
    var senderThread: Thread[string]
    var senderL: Lock

    var receiverThread: Thread[string]
    var receiverL: Lock

    initLock(senderL)
    initLock(receiverL)

    echo "Set a username"
    var username = stdin.readLine()

    createThread(senderThread, senderWrapper, (username))
    createThread(receiverThread, receiverWrapper, (username))
    joinThread(senderThread)
    joinThread(receiverThread)

    deinitLock(senderL)
    deinitLock(receiverL)


    echo stdin.readLine()
