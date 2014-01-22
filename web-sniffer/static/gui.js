
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

        var handle_details = function (val) {
            var json = val[0]
            var hexdiv = document.getElementById("hexoutput")
            clear_element(hexdiv)
            var list = document.createElement("ul")
            var hexdump = json.hex
            for (var i = 0; i < hexdump.length; i++) {
                var ele = document.createElement("li")
                ele.innerHTML = hexdump[i]
                list.appendChild(ele)
            }
            hexdiv.appendChild(list)

            var layers = json.tree
            var tree = document.getElementById("tree")
            clear_element(tree)
            var ul = document.createElement("ul")

            var handle_treedetails = function (parent, val) {
                var chi = parent.childNodes
                if (chi.length > 1)
                    for (var i = 1; i < chi.length; i++)
                        parent.removeChild(chi[i])
                else {
                    var json = val[0]
                    var ul = document.createElement("ul")
                    for (var i = 0; i < json.fields.length; i++) {
                        var ele = document.createElement("li")
                        ele.innerHTML = json.fields[i]
                        ul.appendChild(ele)
                    }
                    parent.appendChild(ul)
                }
            }

            for (var i = 0; i < layers.length; i++) {
                var ele = document.createElement("li")
                ele.innerHTML = layers[i]
                function cb (id, packet, cont) {
                    executeCommand("treedetails", ("treedetails/" + packet + "/" + id), cont)
                }
                ele.onclick = cb.curry(i, json.packetid, handle_treedetails.curry(ele))
                ul.appendChild(ele)
            }
            tree.appendChild(ul)
        }

        function cb () {
            var out = document.getElementById("details")
            executeCommand("details" , ("details/" + res.packetid), handle_details)
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
        var cont = function (res) {
            clear_element(output)
            var list = document.createElement("ul")
            for (var i = 0; i < res.length; i++) {
                var ele = document.createElement("li")
                ele.innerHTML = res[i]
                list.appendChild(ele)
            }
            output.appendChild(list)
            inputfield.value = ""
        }
        var cmd = val.split(" ")
        executeCommand(cmd[0], cmd.join("/"), cont)
        break
    case 191: //?
        var cont = function (res) {
            clear_element(output)
            var table = document.createElement("table")
            for (var i = 0; i < res.length; i++) {
                var tr = document.createElement("tr")
                var json = res[i]

                var nametd = document.createElement("td")
                nametd.innerHTML = json.name
                tr.appendChild(nametd)

                var descriptiontd = document.createElement("td")
                descriptiontd.innerHTML = json.description
                tr.appendChild(descriptiontd)

                var signaturetd = document.createElement("td")
                signaturetd.innerHTML = json.signature
                tr.appendChild(signaturetd)

                table.appendChild(tr)
            }
            output.appendChild(table)
            inputfield.value = ""
        }
        executeCommand("help", "help", cont)
        break
    default:
        debug.innerHTML = "unknown key " + keyCode
    }
}

function executeCommand (command, req, cont) {
    if (command == "clear") {
        clear_element(document.getElementById("packets"))
        if (cont)
            cont()
    } else {
        function reqListener () {
            var value = this.responseText
            var res = eval(value)
            var output = document.getElementById("output")
            var json = res
            if (res.length == 1)
                json = res[0]
            if (json.error) {
                output.className = "error"
                output.innerHTML = json.error
            } else {
                output.className = "success"
                output.innerHTML = "Success!: " + json
                if (cont)
                    cont(res)
            }
        }
        var oReq = new XMLHttpRequest()
        oReq.onload = reqListener
        oReq.open("get", ("/execute/" + req), true)
        oReq.send()
    }
}

function clear_element (element) {
    while (element.hasChildNodes())
        element.removeChild(element.firstChild)
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
