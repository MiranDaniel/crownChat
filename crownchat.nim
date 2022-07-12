import lock
import client
import server
import asyncdispatch

let clientType = lock.lock()

if clientType == true: # running as client
    echo "Starting a client"
    client.start()
else:
    echo "Starting a server"
    server.start()
    lock.unlock()
