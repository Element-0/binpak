import std/[streams, unittest, tables]
import binpak

type VariantKind = enum
  vk_void
  vk_int
  vk_string
  vk_map

type Variant = object
  case kind: VariantKind
  of vk_void:
    discard
  of vk_int:
    vInt: int
  of vk_string:
    vString: string
  of vk_map:
    vMap: Table[string, Variant]

genBinPak Variant

suite "Variant Test":
  test "output int":
    let simpl = Variant(kind: vk_int, vInt: 2)
    let xout = BinaryOutput.init()
    checkpoint "generating"
    xout <~> simpl
    checkpoint "generated"
    check xout.data == "\2\4"
  test "output string":
    let simpl = Variant(kind: vk_string, vString: "test")
    let xout = BinaryOutput.init()
    checkpoint "generating"
    xout <~> simpl
    checkpoint "generated"
    check xout.data == "\4\4test"
  test "output table":
    let simpl = Variant(kind: vk_map, vMap: {"hello": Variant(kind: vk_string, vString: "world")}.toTable)
    let xout = BinaryOutput.init()
    checkpoint "generating"
    xout <~> simpl
    checkpoint "generated"
    check xout.data == "\6\1\5hello\4\5world"
  test "parse table":
    let xin = BinaryInput.init("\6\1\5hello\4\5world")
    var rep = Variant(kind: vk_void)
    checkpoint "parsing"
    xin <~> rep
    checkpoint "parsed"
    check rep.kind == vk_map
    check "hello" in rep.vMap
    let hello = rep.vMap["hello"]
    check hello.kind == vk_string
    check hello.vString == "world"
