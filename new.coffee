findClasses = (text) ->
  classIndex = 0
  classes = []
  classRanges = []
  while classResult = XRegExp.exec text, classRegExp, classIndex
    classIndex = classResult.index + classResult[0].length
    classEnd = matchBracket text, classIndex
    classEntry = new ClassEntry classResult.name, classResult.type, classResult.abstract, classResult.extends, classResult.implements, getPoint text, classResult.index
    classes.push classEntry
    classRanges.push {start: classIndex, end: classEnd}
  methodIndex = 0
  methods = []
  while methodResult = XRegExp.exec text, methodRegExp, methodIndex
    methodIndex = methodResult.index + methodResult[0].length
    methodEnd = matchBracket text, methodIndex, ')'
    methodEntry = new MethodEntry methodResult.name, methodResult.abstract, methodResult.access, methodResult.static, getPoint text, methodResult.index
    argumentIndex = methodIndex
    while argumentResult = XRegExp.exec text, argumentRegExp, argumentIndex
      if argumentResult.index > methodEnd
        break
      argumentIndex = argumentResult.index + argumentResult[0].length
      methodEntry.arguments.push new ArgumentEntry argumentResult.name, argumentResult.type, getPoint text, argumentResult.index
    methods.push methodEntry
  #use for
  for range in classRanges
    for method in methods
      if method.index > range.start && method.index < range.end
        classes[index].methods.push method
