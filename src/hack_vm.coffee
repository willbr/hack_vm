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

window.vm = vm = {}
window.app = app = {}

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
        when 'argument', 'local', 'pointer', 'temp'
            offset = vm.symbols[segment] + index
            v = vm.ram[offset]
        when 'this', 'that'
            offset = vm.ram[vm.symbols[segment]] + index
            v = vm.ram[offset]
        when "static"
            0
        else
            throw 'segment not implemented'

    vm.push v

vm.commandPop = (segment, index) ->
    switch segment
        when 'argument', 'local', 'pointer', 'temp'
            offset = vm.symbols[segment] + index
        when 'this', 'that'
            a = vm.symbols[segment]
            b = vm.ram[a]
            offset = b + index
        when "static"
            0
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
        else
            throw "unknown command #{token[0]}"

    vm.currentLine += 1

vm.stop = ->
    0

vm.reset = ->
    vm.stop()
    ramBuffer = ArrayBuffer 1024
    vm.ram = Int16Array ramBuffer
    vm.ram[0] = 256
    vm.r = Int16Array ArrayBuffer(4)

vm.parseCode = ->
    vm.labels = {}
    for line, i in vm.code
        tokens = line.split ' '
        if tokens[0] == "label"
            vm.labels[tokens[1]] = i
    0

app.init = ->
    vm.reset()

    $('#step').click app.step
    $('#run').click app.run
    $('#stop').click app.stop
    $('#reset').click app.reset

    app.dom = {}
    app.dom.code = $('#code')
    app.dom.stack = $('#stack')
    app.dom.ram = $('#ram')

    app.started = false
    app.codeEditable true
    app.updateDebugGui()

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
        jElem = $(elem)
        app.code.push jElem
        vm.code.push jElem.text()
    vm.currentLine = 0
    vm.currentFile = "boot.vm"
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

