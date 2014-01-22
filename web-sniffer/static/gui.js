
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

    evtSource.onmessage = handle_event

    function handle_event (event) {
        var val = event.data
        var res = eval(val)[0]
        function cb () {
            var out = document.getElementById("details")
            executeCommand("details" , ("details/" + res.packetid), null, out)
        }
        var newElement = document.createElement("tr")

        var td1 = document.createElement("td")
        td1.innerHTML = res.packetid
        td1.onclick = cb
        newElement.appendChild(td1)

        var td2 = document.createElement("td")
        td2.innerHTML = res.source
        td2.onclick = cb
        newElement.appendChild(td2)

        var td3 = document.createElement("td")
        td3.innerHTML = res.destination
        td3.onclick = cb
        newElement.appendChild(td3)

        var td4 = document.createElement("td")
        td4.innerHTML = res.protocol
        td4.onclick = cb
        newElement.appendChild(td4)

        var td5 = document.createElement("td")
        td5.innerHTML = res.content
        td5.onclick = cb
        newElement.appendChild(td5)

        document.getElementById("packets").appendChild(newElement)
    }

    var shell = document.getElementById("shell")
    var output = document.getElementById("output")
    var debug = document.getElementById("debug")
    var filter = document.getElementById("filter")
    filter.onkeyup = handle_filterkey.curry(debug, output, filter)
    shell.onkeyup = handle_keypress.curry(debug, output, shell)
}

function handle_filterkey (debug, output, filter, event) {
    var keyCode = ('which' in event) ? event.which : event.keyCode
    var val = filter.value
    switch (keyCode) {
    case 13: //return
        executeCommand("clear")
        if (val == "")
            executeCommand("filter", "filter/delete", null, output)
        else
            executeCommand("filter", "filter/" + val, null, output)
        break
    default:
        debug.innerHTML = "unknown filterkey " + keyCode
    }
}


function handle_keypress (debug, output, inputfield, event) {
    var keyCode = ('which' in event) ? event.which : event.keyCode
    var val = inputfield.value
    switch (keyCode) {
    case 32: //space
        debug.innerHTML = "space: " + val; break
    case 13: //return
        var cmd = val.split(" ")
        executeCommand(cmd[0], cmd.join("/"), inputfield, output)
        break
    case 191: //?
        getHelp(val, output)
        inputfield.value = ""
        break
    default:
        debug.innerHTML = "unknown key " + keyCode
    }
}

function executeCommand (command, req, inputfield, output) {
    if (command == "clear") {
        var lst = document.getElementById("packets")
        while (lst.hasChildNodes())
            lst.removeChild(lst.childNodes[0])
        if (inputfield)
            inputfield.value = ""
    } else {
        function reqListener () {
            var value = this.responseText
            var res = eval(value)
            var list = document.createElement("ul")
            for (var i = 0; i < res.length; i++) {
                var x = res[i]
                handle_command(command, list, x)
            }
            output.appendChild(list)
            if (inputfield)
                inputfield.value = ""
        }

        if (output)
            while (output.hasChildNodes())
                output.removeChild(output.childNodes[0])
        var oReq = new XMLHttpRequest()
        oReq.onload = reqListener
        oReq.open("get", ("/execute/" + req), true)
        oReq.send()
    }
}

function handle_command (command, list, json) {
    if (json.error) {
        var ele = document.createElement("div")
        ele.className = "error"
        ele.innerHTML = json.error
        list.appendChild(ele)
    } else {
        switch (command) {
        case 'list':
            var ele = document.createElement("li")
            ele.innerHTML = json.name + " running? " + json.open
            list.appendChild(ele)
            break
        case 'details':
            var hexdump = json.hex
            for (var i = 0; i < hexdump.length; i++) {
                var ele = document.createElement("li")
                ele.innerHTML = hexdump[i]
                list.appendChild(ele)
            }
            var layers = json.tree
            var tree = document.getElementById("tree")
            while (tree.hasChildNodes())
                tree.removeChild(tree.firstChild)
            var ul = document.createElement("ul")
            for (var i = 0; i < layers.length; i++) {
                var ele = document.createElement("li")
                ele.innerHTML = layers[i]
                function cb (id, packet, ele) {
                    executeCommand("treedetails", ("treedetails/" + packet + "/" + id), null, ele)
                }
                ele.onclick = cb.curry(i, json.packetid, ele)
                ul.appendChild(ele)
            }
            tree.appendChild(ul)
            break
        case 'treedetails':
            var ul = document.createElement("ul")
            for (var i = 0; i < json.fields.length; i++) {
                var ele = document.createElement("li")
                ele.innerHTML = json.fields[i]
                ul.appendChild(ele)
            }
            list.appendChild(ul)
            break
        default:
            var ele = document.createElement("li")
            ele.innerHTML = json
            list.appendChild(ele)
        }
    }
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
