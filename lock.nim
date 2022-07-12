import std/os
import std/strformat

const path = "./build/.crownlock"

proc lock*(): bool =
    var exists = fileExists(path)
    if not exists:
        writeFile(path, fmt"{getCurrentProcessId()}")
    exists

proc unlock*() =
    removeFile(path)
