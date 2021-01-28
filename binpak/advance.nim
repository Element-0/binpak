import std/tables
import ./basic, ./types, ./helper, ./nolockstream

proc `~>`*(io: BinaryInput, x: var string) {.inline.} =
  var len: uint
  io ~> len
  x.setLen len
  if len > 0:
    io.stream.readBuffer(x)
proc `<~`*(io: BinaryOutput, x: string) {.inline.} =
  io <~ uint x.len
  if x.len > 0:
    io.stream.writeBuffer(x)

proc `~>`*[T](io: BinaryInput, x: var seq[T]) {.inline.} =
  mixin `<~>`
  var len: uint
  io <~> len
  x = newSeqOfCap[T]len
  for i in 0..<len:
    var tmp: T
    io <~> tmp
    x.add tmp
proc `<~`*[T](io: BinaryOutput, x: seq[T]) {.inline.} =
  mixin `<~>`
  io <~> uint x.len
  for item in x:
    io <~> item

proc `~>`*[K, V](io: BinaryInput, x: var Table[K, V]) {.inline.} =
  mixin `<~>`
  var len: uint
  io <~> len
  x = initTable[K, V](int len)
  for i in 0..<len:
    var key: K
    var val: V
    io <~> key
    io <~> val
    x[key] = val
proc `<~`*[K, V](io: BinaryOutput, x: Table[K, V]) {.inline.} =
  mixin `<~>`
  io <~> uint x.len
  for key, val in x:
    io <~> key
    io <~> val

proc `~>`*[E: enum](io: BinaryInput, x: var E) {.inline.} =
  var tmp: int
  io ~> tmp
  x = E(tmp)
proc `<~`*[E: enum](io: BinaryOutput, x: E) {.inline.} =
  io <~ int x
