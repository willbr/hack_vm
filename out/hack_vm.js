// Generated by CoffeeScript 1.4.0
(function() {
  var app, vm;

  window.vm = vm = {};

  window.app = app = {};

  vm.init = function() {
    return vm.symbols = {
      "local": 1,
      "argument": 2,
      "this": 3,
      "that": 4,
      "temp": 5,
      "pointer": 3
    };
  };

  vm.push = function(n) {
    vm.ram[vm.ram[0]] = n;
    return vm.ram[0] += 1;
  };

  vm.pop = function() {
    return vm.ram[--vm.ram[0]];
  };

  vm.commandPush = function(segment, index) {
    var offset, v;
    switch (segment) {
      case 'constant':
        v = index;
        break;
      case 'pointer':
      case 'temp':
        offset = vm.symbols[segment] + index;
        v = vm.ram[offset];
        break;
      case 'this':
      case 'that':
      case 'argument':
      case 'local':
        offset = vm.ram[vm.symbols[segment]] + index;
        v = vm.ram[offset];
        break;
      case "static":
        offset = vm.getStaticVariable(index);
        v = vm.ram[offset];
        break;
      default:
        throw 'segment not implemented';
    }
    return vm.push(v);
  };

  vm.commandPop = function(segment, index) {
    var a, b, offset;
    switch (segment) {
      case 'pointer':
      case 'temp':
        offset = vm.symbols[segment] + index;
        break;
      case 'this':
      case 'that':
      case 'argument':
      case 'local':
        a = vm.symbols[segment];
        b = vm.ram[a];
        offset = b + index;
        break;
      case "static":
        offset = vm.getStaticVariable(index);
        break;
      default:
        throw 'segment not implemented';
    }
    return vm.ram[offset] = vm.pop();
  };

  vm.commandAdd = function() {
    vm.r[0] = vm.pop();
    vm.r[1] = vm.pop();
    vm.r[0] += vm.r[1];
    return vm.push(vm.r[0]);
  };

  vm.commandSub = function() {
    vm.r[0] = vm.pop();
    vm.r[1] = vm.pop();
    vm.r[1] -= vm.r[0];
    return vm.push(vm.r[1]);
  };

  vm.commandNegate = function() {
    vm.r[0] = -vm.pop();
    return vm.push(vm.r[0]);
  };

  vm.commandEqual = function() {
    vm.r[0] = vm.pop();
    vm.r[1] = vm.pop();
    vm.r[0] = vm.r[1] === vm.r[0] ? -1 : 0;
    return vm.push(vm.r[0]);
  };

  vm.commandGreaterThan = function() {
    vm.r[0] = vm.pop();
    vm.r[1] = vm.pop();
    vm.r[0] = vm.r[1] > vm.r[0] ? -1 : 0;
    return vm.push(vm.r[0]);
  };

  vm.commandLessThan = function() {
    vm.r[0] = vm.pop();
    vm.r[1] = vm.pop();
    vm.r[0] = vm.r[1] < vm.r[0] ? -1 : 0;
    return vm.push(vm.r[0]);
  };

  vm.commandAnd = function() {
    vm.r[0] = vm.pop();
    vm.r[1] = vm.pop();
    vm.r[0] = vm.r[0] & vm.r[1];
    return vm.push(vm.r[0]);
  };

  vm.commandOr = function() {
    vm.r[0] = vm.pop();
    vm.r[1] = vm.pop();
    vm.r[0] = vm.r[0] | vm.r[1];
    return vm.push(vm.r[0]);
  };

  vm.commandNot = function() {
    vm.r[0] = ~vm.pop();
    return vm.push(vm.r[0]);
  };

  vm.hasMoreCode = function() {
    return vm.currentLine < vm.code.length;
  };

  vm.step = function() {
    if (vm.hasMoreCode()) {
      return vm.evalLine();
    }
  };

  vm.evalLine = function() {
    var line, tokens;
    line = vm.code[vm.currentLine];
    tokens = line.split(' ');
    switch (tokens[0]) {
      case "push":
        vm.commandPush(tokens[1], parseInt(tokens[2], 10));
        break;
      case "pop":
        vm.commandPop(tokens[1], parseInt(tokens[2], 10));
        break;
      case "add":
        vm.commandAdd();
        break;
      case "sub":
        vm.commandSub();
        break;
      case "neg":
        vm.commandNegate();
        break;
      case "eq":
        vm.commandEqual();
        break;
      case "gt":
        vm.commandGreaterThan();
        break;
      case "lt":
        vm.commandLessThan();
        break;
      case "and":
        vm.commandAnd();
        break;
      case "or":
        vm.commandOr();
        break;
      case "not":
        vm.commandNot();
        break;
      default:
        throw "unknown command " + token[0];
    }
    return vm.currentLine += 1;
  };

  vm.stop = function() {
    return 0;
  };

  vm.reset = function() {
    var ramBuffer;
    vm.stop();
    ramBuffer = ArrayBuffer(1024);
    vm.ram = Int16Array(ramBuffer);
    vm.ram[0] = 256;
    return vm.r = Int16Array(ArrayBuffer(4));
  };

  vm.getStaticVariable = function(i) {
    var alias;
    alias = "" + vm.currentFile + "." + i;
    return vm.staticVariables[alias];
  };

  vm.parseCode = function() {
    var createStaticVariable, currentStaticVariable, i, line, tokens, _i, _len, _ref;
    vm.staticVariables = {};
    currentStaticVariable = 16;
    createStaticVariable = function(i) {
      var alias;
      alias = "" + vm.currentFile + "." + i;
      if (!(alias in vm.staticVariables)) {
        vm.staticVariables[alias] = currentStaticVariable++;
      }
      return 0;
    };
    vm.functions = {};
    vm.labels = {};
    _ref = vm.code;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      line = _ref[i];
      tokens = line.split(' ');
      switch (tokens[0]) {
        case 'label':
          vm.labels[tokens[1]] = i;
          break;
        case 'push':
        case 'pop':
          if (tokens[1] === 'static') {
            createStaticVariable(tokens[2]);
          }
          break;
        default:
          0;

      }
    }
    return 0;
  };

  app.init = function() {
    vm.init();
    $('#step').click(app.step);
    $('#run').click(app.run);
    $('#stop').click(app.stop);
    $('#reset').click(app.reset);
    app.dom = {};
    app.dom.code = $('#code');
    app.dom.stack = $('#stack');
    app.dom.ram = $('#ram');
    app.setCode("push constant 5\npush constant 3\npop static 0\npush constant 1\npush static 0");
    return app.reset();
  };

  app.setCode = function(code) {
    var i, line, _i, _len, _ref;
    app.dom.code.html('');
    _ref = code.split('\n');
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      line = _ref[i];
      line.replace(/^\s+/, '');
      app.dom.code.append("<p>" + line + "</p>");
    }
    return 0;
  };

  app.updateDebugGui = function() {
    var index, value, _i, _len, _ref;
    app.dom.ram.html("");
    app.dom.stack.html("");
    _ref = vm.ram;
    for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
      value = _ref[index];
      app.dom.ram.append("<p>" + index + ": " + value + "</p>");
      if ((256 <= index && index <= 2047)) {
        app.dom.stack.append("<p>" + index + ": " + value + "</p>");
      }
    }
    return 0;
  };

  app.codeEditable = function(b) {
    app.dom.code.attr("contenteditable", b);
    if (b) {
      return app.dom.code.removeClass('lockCode');
    } else {
      return app.dom.code.addClass('lockCode');
    }
  };

  app.step = function() {
    app.codeEditable(false);
    if (!app.started) {
      app.getCode();
      app.started = true;
      $('.currentLine').removeClass('currentLine');
      return app.code[vm.currentLine].addClass('currentLine');
    } else {
      if (vm.hasMoreCode()) {
        vm.step();
        $('.currentLine').removeClass('currentLine');
        if (vm.hasMoreCode()) {
          app.code[vm.currentLine].addClass('currentLine');
        }
      }
      return app.updateDebugGui();
    }
  };

  app.getCode = function() {
    vm.code = [];
    app.code = [];
    app.dom.code.find('p').each(function(index, elem) {
      var $elem;
      $elem = $(elem);
      app.code.push($elem);
      return vm.code.push($elem.text());
    });
    vm.currentLine = 0;
    vm.currentFile = "_none";
    return vm.parseCode();
  };

  app.run = function() {
    return 0;
  };

  app.stop = vm.stop;

  app.reset = function() {
    vm.reset();
    app.started = false;
    app.codeEditable(true);
    app.updateDebugGui();
    return $('.currentLine').removeClass('currentLine');
  };

  $(function() {
    return app.init();
  });

}).call(this);
