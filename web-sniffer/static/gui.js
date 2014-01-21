Function.prototype.curry = function () {
  // wir merken uns f
  var f = this
  if (arguments.length < 1) {
    return f //nothing to curry with - return function
  }
  var a = toArray(arguments)
  return function () {
    var b = toArray(arguments)
    return f.apply(this, a.concat(b))
  }
}

function toArray (xs) {
  return Array.prototype.slice.call(xs)
}

function initialize () {
    var evtSource = new EventSource("events")

    evtSource.onmessage = function (e) {
        var newElement = document.createElement("li")
        newElement.innerHTML = "message: " + e.data
        document.getElementById("list").appendChild(newElement)
    }

    var shell = document.getElementById("shell")
    var output = document.getElementById("output")
    var debug = document.getElementById("debug")
    shell.onkeyup = handle_keypress.curry(debug, output, shell)
}


function mouseX (evt) {
    if (evt.pageX) return evt.pageX;
    else if (evt.clientX)
        return evt.clientX + (document.documentElement.scrollLeft ?
                              document.documentElement.scrollLeft :
                              document.body.scrollLeft);
    else return null;
}

function mouseY (evt) {
    if (evt.pageY) return evt.pageY;
    else if (evt.clientY)
        return evt.clientY + (document.documentElement.scrollTop ?
                              document.documentElement.scrollTop :
                              document.body.scrollTop);
    else return null;
}

function handle_keypress (debug, output, inputfield, event) {
    var keyCode = ('which' in event) ? event.which : event.keyCode
    var val = inputfield.value
    switch (keyCode) {
    case 32: //space
        debug.innerHTML = "space: " + val; break
    case 13: //return
        executeCommand(val, output); break
    case 191: //?
        getHelp(val, output); break
    default:
        debug.innerHTML = "unknown key " + keyCode
    }
}

function executeCommand (command, output) {
    function reqListener () {
        var value = this.responseText
        if (! value)
            output.innerHTML = "RECEIVED error"
        var res = eval(value)
        var list = document.createElement("ul")
        for (var i = 0; i < res.length; i++) {
            var x = res[i]
            var ele = document.createElement("li")
            ele.innerHTML = x
            list.appendChild(ele)
        }
        var old = output.firstChild
        if (old)
            output.replaceChild(list, old)
        else
            output.appendChild(list)
    }

    var eles = command.split(" ")
    var req = eles.join("/")

    var oReq = new XMLHttpRequest();
    oReq.onload = reqListener;
    oReq.open("get", ("/execute/" + req), true);
    oReq.send();
}

function getHelp (partialinput, output) {
    function reqListener () {
        var value = this.responseText
        if (! value)
            output.innerHTML = "RECEIVED error"
        var res = eval(value)
        var list = document.createElement("ul")
        for (var i = 0; i < res.length; i++) {
            var x = res[i]
            var ele = document.createElement("li")
            ele.innerHTML = x["name"] + ": " + x["description"]
            list.appendChild(ele)
        }
        var old = output.firstChild
        if (old)
            output.replaceChild(list, old)
        else
            output.appendChild(list)
    }

    var oReq = new XMLHttpRequest()
    oReq.onload = reqListener
    oReq.open("get", ("/help/" + partialinput), true)
    oReq.send()
}

function create_context_menu (ele) {
    ele.onmouseover = function (event) {
        document.getElementById("contextmenu").className = "show"
        document.getElementById("contextmenu").style.top =  mouseY(event)
        document.getElementById("contextmenu").style.left = mouseX(event)
    }
    ele.onmouseout = function (event) {
        document.getElementById("contextmenu").className = "hide"
    }
}
