#     0 - 15    Virtual Registers
#    16 - 255   Static variables
#   256 - 2047  Stack
#  2048 - 16383 Heap
# 16384 - 24575 Memory mapped I/O

# RAM[0]     SP
# RAM[1]     LCL
# RAM[2]     ARG
# RAM[3]     THIS
# RAM[4]     THAT
# RAM[5-12]  TEMP segment
# RAM[13-15] General purpose registers

# TODO
# flow control
#   function
#   call

window.vm = vm = {}
window.app = app = {}

vm.init = ->
    vm.symbols =
        "local":     1
        "argument":  2
        "this":      3
        "that":      4
        "temp":      5
        "pointer":   3

vm.push = (n) ->
    vm.ram[vm.ram[0]] = n
    vm.ram[0] += 1

vm.pop = () ->
    vm.ram[--vm.ram[0]]

vm.commandPush = (segment, index) ->
    switch segment
        when 'constant'
            v = index
        when 'pointer', 'temp'
            offset = vm.symbols[segment] + index
            v = vm.ram[offset]
        when 'this', 'that', 'argument', 'local'
            offset = vm.ram[vm.symbols[segment]] + index
            v = vm.ram[offset]
        when "static"
            offset = vm.getStaticVariable(index)
            v = vm.ram[offset]
        else
            throw 'segment not implemented'

    vm.push v

vm.commandPop = (segment, index) ->
    switch segment
        when 'pointer', 'temp'
            offset = vm.symbols[segment] + index
        when 'this', 'that', 'argument', 'local'
            a = vm.symbols[segment]
            b = vm.ram[a]
            offset = b + index
        when "static"
            offset = vm.getStaticVariable(index)
        else
            throw 'segment not implemented'

    vm.ram[offset] = vm.pop()

vm.commandAdd = ->
    vm.r[0] = vm.pop()
    vm.r[1] = vm.pop()
    vm.r[0] += vm.r[1]
    vm.push vm.r[0]

vm.commandSub = ->
    vm.r[0] = vm.pop()
    vm.r[1] = vm.pop()
    vm.r[1] -= vm.r[0]
    vm.push vm.r[1]

vm.commandNegate = ->
    vm.r[0] = -vm.pop()
    vm.push vm.r[0]

vm.commandEqual = ->
    vm.r[0] = vm.pop()
    vm.r[1] = vm.pop()
    vm.r[0] = if vm.r[1] == vm.r[0] then -1 else 0
    vm.push vm.r[0]

vm.commandGreaterThan = ->
    vm.r[0] = vm.pop()
    vm.r[1] = vm.pop()
    vm.r[0] = if vm.r[1] > vm.r[0] then -1 else 0
    vm.push vm.r[0]

vm.commandLessThan = ->
    vm.r[0] = vm.pop()
    vm.r[1] = vm.pop()
    vm.r[0] = if vm.r[1] < vm.r[0] then -1 else 0
    vm.push vm.r[0]

vm.commandAnd = ->
    vm.r[0] = vm.pop()
    vm.r[1] = vm.pop()
    vm.r[0] = vm.r[0] & vm.r[1]
    vm.push vm.r[0]

vm.commandOr = ->
    vm.r[0] = vm.pop()
    vm.r[1] = vm.pop()
    vm.r[0] = vm.r[0] | vm.r[1]
    vm.push vm.r[0]

vm.commandNot = ->
    vm.r[0] = ~vm.pop()
    vm.push vm.r[0]

vm.commandGoto = (label) ->
    vm.currentLine = vm.labels[label]

vm.commandIfGoto = (label) ->
    if vm.pop() != 0
        vm.currentLine = vm.labels[label]

vm.hasMoreCode = ->
    vm.currentLine < vm.code.length

vm.step = ->
    if vm.hasMoreCode()
        vm.evalLine()

vm.evalLine = ->
    line = vm.code[vm.currentLine]
    tokens = line.split ' '
    switch tokens[0]
        when "push"
            vm.commandPush tokens[1], parseInt(tokens[2], 10)
        when "pop"
            vm.commandPop tokens[1], parseInt(tokens[2], 10)
        when "add"
            vm.commandAdd()
        when "sub"
            vm.commandSub()
        when "neg"
            vm.commandNegate()
        when "eq"
            vm.commandEqual()
        when "gt"
            vm.commandGreaterThan()
        when "lt"
            vm.commandLessThan()
        when "and"
            vm.commandAnd()
        when "or"
            vm.commandOr()
        when "not"
            vm.commandNot()
        when 'label'
            0
        when 'goto'
            vm.commandGoto tokens[1]
        when 'if-goto'
            vm.commandIfGoto tokens[1]
        else
            throw "unknown command #{tokens[0]}"

    vm.currentLine += 1

vm.stop = ->
    0

vm.reset = ->
    vm.stop()
    ramBuffer = ArrayBuffer 1024
    vm.ram = Int16Array ramBuffer
    vm.ram[0] = 256
    vm.r = Int16Array ArrayBuffer(4)

vm.getStaticVariable = (i) ->
    alias = "#{vm.currentFile}.#{i}"
    vm.staticVariables[alias]
    
vm.parseCode = ->
    vm.staticVariables = {}
    currentStaticVariable = 16
    createStaticVariable = (i) ->
        alias = "#{vm.currentFile}.#{i}"
        if alias not of vm.staticVariables
            vm.staticVariables[alias] = currentStaticVariable++
        0

    vm.functions = {}
    vm.labels = {}
    for line, i in vm.code
        tokens = line.split ' '
        switch tokens[0]
            when 'label'
                vm.labels[tokens[1]] = i
            when 'push', 'pop'
                if tokens[1] == 'static'
                    createStaticVariable(tokens[2])
            else
                0
    0


app.init = ->
    vm.init()

    $('#step').click app.step
    $('#run').click app.run
    $('#stop').click app.stop
    $('#reset').click app.reset

    app.dom = {}
    app.dom.code = $('#code')
    app.dom.stack = $('#stack')
    app.dom.ram = $('#ram')

    app.setCode """
    call Main.main 0
    label loop
    goto loop
    function Main.add 0
    add
    return
    function Main.main 0
    push 1
    push 2
    call Main.add 2
    pop static 0
    return
    """

    app.reset()

app.setCode = (code) ->
    app.dom.code.html('')
    for line, i in code.split('\n')
        line.replace /^\s+/, ''
        app.dom.code.append "<p>#{line}</p>"
    0

app.updateDebugGui = ->
    app.dom.ram.html("")
    app.dom.stack.html("")
    for value, index in vm.ram
        app.dom.ram.append "<p>#{index}: #{value}</p>"
        if 256 <= index <= 2047
            app.dom.stack.append "<p>#{index}: #{value}</p>"
    0

app.codeEditable = (b) ->
    app.dom.code.attr "contenteditable", b
    if b
        app.dom.code.removeClass 'lockCode'
    else
        app.dom.code.addClass 'lockCode'

app.step = ->
    app.codeEditable false

    if not app.started
        app.getCode()
        app.started = true
        $('.currentLine').removeClass('currentLine')
        app.code[vm.currentLine].addClass('currentLine')
    else

        if vm.hasMoreCode()
            vm.step()
            $('.currentLine').removeClass('currentLine')
            if vm.hasMoreCode()
                app.code[vm.currentLine].addClass('currentLine')

        app.updateDebugGui()

app.getCode = ->
    vm.code = []
    app.code = []
    app.dom.code.find('p').each (index, elem) ->
        $elem = $(elem)
        app.code.push $elem
        vm.code.push $elem.text()
    vm.currentLine = 0
    vm.currentFile = "_none"
    vm.parseCode()

app.run = ->
    0

app.stop = vm.stop

app.reset = ->
    vm.reset()
    app.started = false
    app.codeEditable true
    app.updateDebugGui()
    $('.currentLine').removeClass('currentLine')


$ ->
    app.init()

