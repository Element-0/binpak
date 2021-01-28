import std/macros
import ./types

proc isVariantType(sym: NimNode): bool {.compileTime.} =
  sym.expectKind nnkObjectTy
  sym[2].expectKind nnkRecList
  for item in sym[2]:
    if item.kind == nnkRecCase:
      return true
  return false

iterator varargTypes(list: NimNode): tuple[name, impl: NimNode] =
  for i in list:
    let name = getTypeImpl(i)[1]
    let impl = getTypeImpl(name)
    yield (name: name, impl: impl)

# A workaround nim bug, can also improve compile performance
type ImmList[T] = ref object
  idx: int
  cur: T
  next: ImmList[T]

proc len[T](self: ImmList[T]): int =
  if self == nil:
    0
  else:
    self.idx

proc prepend[T](self: ImmList[T], single: T): ImmList[T] =
  result = new ImmList[T]
  result.cur = single
  result.next = self
  result.idx = self.len + 1

proc prepend[T](self: ImmList[T], multi: ImmList[T]): ImmList[T] =
  if multi == nil:
    return self
  var tmp = new ImmList[T]
  result = tmp
  result.idx = self.len + multi.len
  tmp.cur = multi.cur
  var cursor = multi.next
  while cursor != nil:
    tmp.next = new ImmList[T]
    tmp = tmp.next
    tmp.cur = cursor.cur
    cursor = cursor.next
  tmp.next = self

proc prepend[T](self: ImmList[T], multi: seq[T]): ImmList[T] =
  if multi.len == 0:
    return self
  var tmp = new ImmList[T]
  result = tmp
  result.idx = self.len + multi.len
  tmp.cur = multi[0]
  for idx in 1..<multi.len:
    tmp.next = new ImmList[T]
    tmp = tmp.next
    tmp.cur = multi[idx]
  tmp.next = self

proc toImmList[T](multi: seq[T]): ImmList[T] = prepend[T](nil, multi)

iterator pairs[T](self: ImmList[T]): tuple[key: int; val: T] =
  var tmp = self
  var idx = 0
  while tmp != nil:
    yield (key: idx, val: tmp.cur)
    idx += 1
    tmp = tmp.next

macro genBinPak*(a: varargs[typed]{nkSym}): untyped =
  result = newStmtList()
  let io = ident "io"
  let x = ident "x"
  let darrow = ident"<~>"
  let rarrow = ident"~>"
  let larrow = ident"<~"

  proc genArrowExpr(right: NimNode): NimNode =
    nnkInfix.newTree(darrow, io, right)

  proc processInputVariant(base: NimNode; defs: ImmList[NimNode]; stack: ImmList[tuple[local, field: NimNode]] = nil): NimNode =
    if defs == nil:
      let constr = nnkObjConstr.newTree(base)
      var revseq = newSeq[NimNode](stack.len)
      for i, (local, field) in stack:
        revseq[stack.len - i - 1] = nnkExprColonExpr.newTree(field, local)
      for item in revseq:
        constr.add item
      return quote do:
        `x` = `constr`

    let first = defs.cur
    let rest = defs.next
    case first.kind:
    of nnkIdentDefs:
      let field = first[0]
      let local = nskVar.genSym($field)
      let ftyp = first[1]
      let op = genArrowExpr(local)
      result = quote do:
        var `local`: `ftyp`
        `op`
      result.add base.processInputVariant(rest, stack.prepend @[(local: local, field: field)])
    of nnkRecCase:
      result = newStmtList()
      let casevar = first[0]
      let casefield = casevar[0]
      let caselocal = nskVar.genSym($casefield)
      let casefixed = nskLet.genSym($casefield)
      let caseftyp = casevar[1]
      let casestmt = nnkCaseStmt.newTree(casefixed)
      let next = stack.prepend @[(local: casefixed, field: casefield)]
      for caseitem in first[1..^1]:
        case caseitem.kind:
        of nnkOfBranch:
          let branch = nnkOfBranch.newTree()
          for choose in caseitem[0..^2]:
            branch.add choose
          branch.add base.processInputVariant(rest.prepend caseitem[^1][0..^1], next)
          casestmt.add branch
        of nnkElse:
          let branch = nnkElse.newTree()
          branch.add base.processInputVariant(rest.prepend caseitem[0][0..^1], next)
          casestmt.add branch
        else:
          error "invalid case branch"
      let op = genArrowExpr(caselocal)
      result.add quote do:
        var `caselocal`: `caseftyp`
        `op`
        let `casefixed` = `caselocal`
        `casestmt`
    else:
      error "invalid object definition"

  proc processOutputVariant(defs: seq[NimNode]): NimNode =
    if defs.len == 0:
      return newEmptyNode()
    let first = defs[0]
    let rest = defs[1..^1]
    case first.kind:
    of nnkIdentDefs:
      let name = first[0]
      let op = genArrowExpr(newDotExpr(x, name))
      result = newStmtList(op)
      result.add processOutputVariant(rest)
    of nnkRecCase:
      result = newStmtList()
      let casevar = first[0]
      let casename = casevar[0]
      let casestmt = nnkCaseStmt.newTree(newDotExpr(x, casename))
      for caseitem in first[1..^1]:
        case caseitem.kind:
        of nnkOfBranch:
          let branch = nnkOfBranch.newTree()
          for choose in caseitem[0..^2]:
            branch.add choose
          branch.add processOutputVariant(caseitem[^1][0..^1] & rest)
          casestmt.add branch
        of nnkElse:
          let branch = nnkElse.newTree()
          branch.add processOutputVariant(caseitem[0][0..^1] & rest)
          casestmt.add branch
        else:
          error "invalid case branch"
      let op = genArrowExpr(newDotExpr(x, casename))
      result.add quote do:
        `op`
        `casestmt`
    else:
      error "invalid object definition"

  for (name, impl) in varargTypes(a):
    result.add quote do:
      func `rarrow`*(`io`: BinaryInput; `x`: var `name`) {.inline.}
      func `larrow`*(`io`: BinaryOutput; `x`: `name`) {.inline.}

  for (name, impl) in varargTypes(a):
    let variant = isVariantType impl
    if variant:
      let cache = impl[2][0..^1]
      let inpbody = processInputVariant(name, toImmList cache)
      let outbody = processOutputVariant(cache)
      result.add quote do:
        func `rarrow`*(`io`: BinaryInput; `x`: var `name`) = `inpbody`
        func `larrow`*(`io`: BinaryOutput; `x`: `name`) = `outbody`
    else:
      let xbody = newStmtList()
      for item in impl[2]:
        let name = item[0]
        xbody.add nnkInfix.newTree(
          darrow,
          io,
          newDotExpr(x, name)
        )
      result.add quote do:
        func `rarrow`*(`io`: BinaryInput; `x`: var `name`) = `xbody`
        func `larrow`*(`io`: BinaryOutput; `x`: `name`) = `xbody`
    discard