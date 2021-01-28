import std/unittest
import binpak

type MyEnum = enum
  A,
  B

type MyObj = object
  en: MyEnum
  key: string
  vals: seq[int]

genBinPak MyObj

suite "Simple Test":
  test "output":
    let simpl = MyObj(en: A, key: "test", vals: @[1, 2, 3])
    checkpoint "generating"
    let data = ~>$ simpl
    checkpoint "generated"
    check data == "\0\4test\3\2\4\6"

  test "input":
    checkpoint "parsing"
    let rep = MyObj <<- "\2\4test\3\2\4\6"
    checkpoint "parsed"
    check rep.en == B
    check rep.key == "test"
    check rep.vals.len == 3
    check rep.vals[0] == 1
    check rep.vals[1] == 2
    check rep.vals[2] == 3
