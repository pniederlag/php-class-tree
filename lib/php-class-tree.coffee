{XRegExp} = require 'xregexp'
{Point} = require 'atom'
TreeView = require './views/tree-view'

phpRegExp = '\\\\?[a-zA-Z_\\x7f-\\xff][\\\\a-zA-Z0-9_\\x7f-\\xff]*'
classRegExp = new XRegExp '(?:(?<abstract>abstract)\\s+)?(?<type>class|interface)\\s+(?<name>' + phpRegExp + ')(?:\\s+extends\\s+(?<extends>' + phpRegExp + '))?(?:\\s+implements\\s+(?<implements>' + phpRegExp + '))?\\s*{', 'i'
methodRegExp = new XRegExp '(?:(?<abstract>abstract)\\s+)?(?:(?<access>private|protected|public)\\s+)?(?:(?<static>static)\\s+)?function\\s+(?<name>' + phpRegExp + ')\\s*\\(', 'i'
argumentRegExp = new XRegExp '(?:(?<type>' + phpRegExp + ')\\s+)?\\$(?<name>' + phpRegExp + ')', 'i'

nextTreeId = 1
activeTree = null
toggled = null

class PhpClassTree
  constructor: (textEditor) ->
    unless textEditor?
      throw new Error('You must provide TextEditor')

    @id = nextTreeId++
    @textEditor = textEditor

    matches = @getMatches()

    if matches.length == 0
      return

    # Is it right way sending this arrays to TreeView constructor?
    @treeView = new TreeView matches

  attach: ->
    @treeView.attach()

  detach: ->
    @treeView.detach()

  toggle: ->
    if atom.workspace.getActiveTextEditor().getGrammar().name != 'PHP'
      return
    toggled = @treeView.toggle()

  rebuild: ->
    matches = @getMatches()

    if @treeView?
      @detach()

    @treeView = new TreeView matches
    @attach()

  getMatches: ->
    text = @textEditor.getText()
    matches = @scanText text

  # Returns atom's Point object by text index
  getPoint: (text, index) ->
    cursor = 0
    row = 0
    lastLineCursor = 0
    while cursor < index
      if text[cursor] == '\n'
        row++
        lastLineCursor = cursor
      cursor++
    column = index - lastLineCursor - 1
    return new Point row, column

  # Matching bracket
  # TODO: is it possible to use Atom Bracket Matcher as it much better?
  matchBracket: (text, index, bracket) ->
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

  scanText: (text) ->
    # Number of class
    classIndex = 0
    # Array of classes
    classes = []
    # Array of class start and end indexes
    classRanges = []
    # Array of method start indexes
    methodIndexes = []
    # The final array
    root = []

    # Finding classes
    while classResult = XRegExp.exec text, classRegExp, classIndex
      classIndex = classResult.index + classResult[0].length
      classEnd = @matchBracket text, classIndex
      # Creating class object
      classes.push new ClassEntry classResult.name, classResult.type, classResult.abstract, classResult.extends, classResult.implements, @getPoint text, classResult.index
      classRanges.push {start: classIndex, end: classEnd}
    classIndex = 0
    methodIndex = 0
    methods = []
    # Finding methods
    while methodResult = XRegExp.exec text, methodRegExp, methodIndex
      methodIndex = methodResult.index + methodResult[0].length
      methodEnd = @matchBracket text, methodIndex, ')'
      methodEntry = new MethodEntry methodResult.name, methodResult.abstract, methodResult.access, methodResult.static, @getPoint text, methodResult.index
      methodIndexes.push methodResult.index
      argumentIndex = methodIndex
      while argumentResult = XRegExp.exec text, argumentRegExp, argumentIndex
        if argumentResult.index > methodEnd
          break
        argumentIndex = argumentResult.index + argumentResult[0].length
        methodEntry.arguments.push new ArgumentEntry argumentResult.name, argumentResult.type, @getPoint text, argumentResult.index
      methods.push methodEntry

    methodIndex = 0
    classIndex = 0
    # Putting methods to classes or to the root
    while methodIndex < methods.length or classIndex < classes.length
      if classes[classIndex]? and methods[methodIndex]? and methodIndexes[methodIndex] > classRanges[classIndex].start and methodIndexes[methodIndex] < classRanges[classIndex].end
        classes[classIndex].methods.push methods[methodIndex]
        methods.splice methodIndex, 1
        methodIndexes.splice methodIndex, 1
      else if (classes[classIndex]? and methodIndexes[methodIndex] > classRanges[classIndex].end) or (classes[classIndex]? and !methods[methodIndex]?)
        root.push classes[classIndex]
        classIndex++
      else
        root.push methods[methodIndex]
        methodIndex++
    return root

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

class Main
  config:
    autoToggle:
      type: 'boolean'
      default: true
    displayOnRight:
      type: 'boolean'
      default: false

  active = false

  @phpClassTrees = []

  constructor: ->
    # Events
    atom.workspace.onDidChangeActivePaneItem (paneItem) =>
      if !paneItem?
        return
      if paneItem.constructor.name == 'TextEditor'
        @constructor.getPhpClassTreeByEditor paneItem
      return

    toggled = atom.config.get 'php-class-tree.autoToggle'

  activate: ->
    active = true
    atom.commands.add 'atom-workspace', 'php-class-tree:build', => @build()
    atom.commands.add 'atom-workspace', 'php-class-tree:toggle', => activeTree.toggle()
    atom.commands.add 'atom-workspace', 'php-class-tree:rebuild', => activeTree.rebuild()

    return

  build: ->
    textEditor = atom.workspace.getActiveTextEditor()
    phpClassTree = @constructor.getPhpClassTreeByEditor textEditor

  @getPhpClassTreeByEditor: (textEditor) ->
    unless textEditor?
      throw new Error('You must provide TextEditor')

    if textEditor.getGrammar().name != 'PHP'
      phpClassTree = false

    for tree in @phpClassTrees
      if tree.textEditor == textEditor
        phpClassTree = tree
        break

    if !phpClassTree?
      phpClassTree = new PhpClassTree textEditor
      @phpClassTrees.push phpClassTree

    activeTree?.detach()

    if phpClassTree
      activeTree = phpClassTree
      if !toggled?
        toggled = atom.config.get 'php-class-tree.autoToggle'
      if toggled
        activeTree.attach()

    return phpClassTree

module.exports = new Main
