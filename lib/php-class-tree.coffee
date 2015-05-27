{XRegExp} = require './xregexp'
{Point} = require 'atom'
TreeView = require './views/tree-view'

phpRegExp = '[a-zA-Z_\\x7f-\\xff][a-zA-Z0-9_\\x7f-\\xff]*'
classRegExp = new XRegExp '(?:(?<abstract>abstract)\\s+)?(?<type>class|interface)\\s+(?<name>' + phpRegExp + ')(?:\\s+extends\\s+(?<extends>' + phpRegExp + ')|\\s+implements\\s+(?<implements>' + phpRegExp + '))*\\s*{', 'i'
methodRegExp = new XRegExp '(?:(?<abstract>abstract)\\s+)?(?:(?<access>private|protected|public)\\s+)?(?:(?<static>static)\\s+)?function\\s+(?<name>' + phpRegExp + ')\\s*\\(', 'i'
argumentRegExp = new XRegExp '(?:(?<type>' + phpRegExp + ')\\s+)?\\$(?<name>' + phpRegExp + ')', 'i'

ClassEntry = (name, type, abstract, extending, implementing, point) ->
  @methods = []
  @icons = ['icon-' + type]
  @point = point
  @name = name
  @type = type
  if abstract?
    @abstract = true
    @icons.push 'icon-abstract'
  else
    @abstract = false
  if extending?
    @extending = extending
    @icons.push 'icon-extends'
  else
    @extending = false
  if implementing?
    @implementing = implementing
    @icons.push 'icon-implements'
  else
    @implementing = false
  return

MethodEntry = (name, abstract, access, isStatic, point) ->
  @arguments = []
  @icons = ['icon-method']
  @point = point
  @name = name
  if abstract?
    @abstract = true
    @icons.push 'icon-abstract'
  else
    @abstract = false
  if access?
    @access = access
    @icons.push 'icon-' + access
  else
    @access = 'public'
  if isStatic?
    @isStatic = true
    @icons.push 'icon-static'
  else
    @isStatic = false
  return

ArgumentEntry = (name, type, point) ->
  @icons = ['icon-argument']
  @point = point
  @name = name
  @type = if type? then type else 'var'
  return

getPoint = (text, index) ->
  cursor = 0
  row = 0
  lastLineCursor = 0
  while cursor < index
    if text[cursor] == '\n'
      row++
      lastLineCursor = cursor
    cursor++
  column = index - lastLineCursor
  return new Point row, column

matchBracket = (text, index, bracket) ->
  switch bracket
    when '(', ')'
      openBracket = '('
      closeBracket = ')'
    else
      openBracket = '{'
      closeBracket = '}'
  openedBrackets = 1
  closedBrackets = 0

  while index < text.length
    if text[index] == openBracket
      openedBrackets++
    if text[index] == closeBracket
      closedBrackets++
    if openedBrackets == closedBrackets
      return index
    index++

scanText = (text) ->
  classIndex = 0
  classes = []
  while classResult = XRegExp.exec text, classRegExp, classIndex
    classIndex = classResult.index + classResult[0].length
    classEnd = matchBracket text, classIndex
    classEntry = new ClassEntry classResult.name, classResult.type, classResult.abstract, classResult.extends, classResult.implements, getPoint text, classResult.index
    methodIndex = classIndex
    while methodResult = XRegExp.exec text, methodRegExp, methodIndex
      if methodResult.index > classEnd
        break
      methodIndex = methodResult.index + methodResult[0].length
      methodEnd = matchBracket text, methodIndex, ')'
      methodEntry = new MethodEntry methodResult.name, methodResult.abstract, methodResult.access, methodResult.static, getPoint text, methodResult.index
      argumentIndex = methodIndex
      while argumentResult = XRegExp.exec text, argumentRegExp, argumentIndex
        if argumentResult.index > methodEnd
          break
        argumentIndex = argumentResult.index + argumentResult[0].length
        methodEntry.arguments.push new ArgumentEntry argumentResult.name, argumentResult.type, getPoint text, argumentResult.index
      classEntry.methods.push methodEntry
    classes.push classEntry
  return classes

module.exports =
  activate: ->
    @build()
    atom.commands.add 'atom-workspace', 'php-class-tree:build', => @build()
    atom.commands.add 'atom-workspace', 'php-class-tree:toggle', => @toggle()
    return

  build: ->
    editor = atom.workspace.getActiveTextEditor()
    text = editor.getText()
    matches = scanText text
    console.log matches
    if @treeView?
      @treeView.detach()
    @treeView = new TreeView matches
    @treeView.attach()
    return

  toggle: ->
    if @treeView?
      @treeView.toggle()
    return
