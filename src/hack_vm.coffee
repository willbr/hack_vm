#     0 - 15    Virtual Registers
#    16 - 255   Static variables
#   256 - 2047  Stack
#  2048 - 16383 Heap
# 16384 - 24575 Memory mapped I/O

window.vm = vm = {}
window.app = app = {}

vm.push = (n) ->
    vm.ram[vm.ram[0]] = n
    vm.ram[0] += 1

vm.pop = () ->
    vm.ram[--vm.ram[0]]

vm.commandPush = (segment, index) ->
    ram = vm.ram
    switch segment
        when 'constant'
            vm.push index
        else
            throw 'segment not implemented'

vm.commandPop = (segment, index) ->
    0

vm.commandAdd = ->
    vm.a[0] = vm.pop()
    vm.b[0] = vm.pop()
    vm.a[0] += vm.b[0]
    vm.push vm.a[0]

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
            vm.commandPush(tokens[1], tokens[2])
        when "pop"
            vm.commandPop(tokens[1], tokens[2])
        when "add"
            vm.commandAdd()
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
    vm.a = Int16Array ArrayBuffer(2)
    vm.b = Int16Array ArrayBuffer(2)


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

app.codeEditable = (b) ->
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

