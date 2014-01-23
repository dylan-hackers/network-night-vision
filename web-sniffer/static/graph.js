
function canvas_init () {
    var graph = new Graph()
    var n1 = new Node(1)
    graph.insert(n1)
    var n2 = new Node(2)
    graph.insert(n2)
    var n3 = new Node(3)
    graph.insert(n3)
    graph.connect(n1, n2)
    var n4 = new Node(4)
    graph.insert(n4)
    graph.connect(n4, n3)
    graph.connect(n1, n4)
    var n5 = new Node(5)
    var n6 = new Node(6)
    var n7 = new Node(7)
    var n8 = new Node(8)
    var n9 = new Node(9)
    graph.connect(n1, n5)
    graph.connect(n1, n6)
    graph.connect(n7, n8)
    graph.connect(n1, n9)
    graph.connect(n9, n7)
    graph.connect(n1, n7)
    //graph.visit(function (x) { console.log("[neighbours] callback of " + x.value) })
    //graph.visit(function (x) { console.log("[up] callback of " + x.value) }, 'up')
    //graph.visit(function (x) { console.log("[down] callback of " + x.value) }, 'down')

    var canvas = document.getElementById('canvas')
    canvas.onclick = function (event) {
        var x = event.pageX - canvas.offsetLeft
        var y = event.pageY - canvas.offsetTop
        var node = graph.find(x, y)
        console.log("x: " + x + " y: " + y + " node ", node)
        graph.selected(node)
    }

    var ctx = canvas.getContext('2d')
    graph.context = ctx
    graph.draw(canvas, ctx)
}

Function.prototype.compose  = function (argFunction) {
    var invokingFunction = this
    return function () {
        return  invokingFunction.call(this, argFunction.apply(this, arguments))
    }
}
function getProp (property, object) {
    return object[property]
}
function eq (a, b) {
    return a == b
}


function PolarPoint (theta, rho) {
    this.theta = theta || 0
    this.rho = rho || 0
}
function toPolar (x, y) {
    var pp = new PolarPoint()
    pp.setComplex(x, y)
    return pp
}

PolarPoint.prototype = {
    setComplex: function (x, y) {
        this.rho = Math.sqrt(x * x + y * y)
        this.theta = Math.atan2(y, x)
        if (this.theta < 0)
            this.theta += Math.PI * 2
    },

    toComplex: function () {
        var x = Math.cos(this.theta) * this.rho
        var y = Math.sin(this.theta) * this.rho
        return [x, y]
    },

    add: function (polar) {
        return new PolarPoint(this.theta + polar.theta, this.rho + polar.rho)
    },

    follow: function (polar) {
        var n1 = this.toComplex()
        var n2 = polar.toComplex()
        return toPolar(n1[0] + n2[0], n1[1] + n2[1])

    },

    scale: function (number) {
        return new PolarPoint(this.theta, this.rho * number);
    },

    copy: function () {
        return new PolarPoint(this.theta, this.rho)
    },
}


function Edge (source, destination, properties) {
    this.source = source
    this.destination = destination
    this.strokeStyle = "blue"
    if (properties)
        for (var i = 0; i < properties.length; i = i + 2)
            this.properties[i] = properties[i + 1]
}

Edge.prototype.draw = function (ctx, graph) {
    ctx.beginPath()
    var spos = this.source.position.toComplex()
    var dpos = this.destination.position.toComplex()
    ctx.strokeStyle = this.strokeStyle
    ctx.moveTo(spos[0], spos[1])
    ctx.lineTo(dpos[0], dpos[1])
    ctx.closePath()
    ctx.stroke()
}

function Node (value, properties) {
    this.value = value
    this.position = new PolarPoint()
    this.fillStyle = "orange"
    this.textStyle = "black"
    this.radius = 10
    if (properties)
        for (var i = 0; i < properties.length; i = i + 2)
            this.properties[i] = properties[i + 1]
}

Node.prototype.redraw = function (ctx, graph) {
    var pos = this.position.toComplex()
    ctx.beginPath()
    ctx.arc(pos[0], pos[1], this.radius, 0, Math.PI * 2, true)
    ctx.fillStyle = this.fillStyle
    ctx.fill()
    if (this.isselected) {
        var old = ctx.strokeStyle
        ctx.strokeStyle = "red"
        ctx.arc(pos[0], pos[1], this.radius - 1, 0, Math.PI * 2, true)
        ctx.arc(pos[0], pos[1], this.radius - 2, 0, Math.PI * 2, true)
        ctx.closePath()
        ctx.stroke()
        ctx.strokeStyle = old
    }

    ctx.fillStyle = this.textStyle
    ctx.fillText(this.value, pos[0], pos[1])

}


Node.prototype.draw = function (ctx, graph) {
    //we better have a position
    this.redraw(ctx, graph)

    var childs = graph.children(this)
    for (var i = 0; i < childs.length; i++) {
        var vec = new PolarPoint(i * (Math.PI * 2 / childs.length), 50)
        childs[i].position = this.position.follow(vec)
    }

    var old = ctx.globalCompositeOperation
    ctx.globalCompositeOperation = 'destination-over'
    graph.outEdges(this).forEach(function (x) { x.draw(ctx, graph) })
    ctx.globalCompositeOperation = old
}

function Graph () {
    this.nodes = []
    this.edges = []
    this.selectedNode = null
}

Graph.prototype.draw = function (canvas, ctx) {
    this.nodes[0].position = toPolar(canvas.width / 2, canvas.height / 2)
    var cb = function (ctx, graph, x) { x.draw(ctx, graph) }
    this.visit(cb.curry(ctx, this), 'down')
}

Graph.prototype.find = function (x, y) {
    var res = null
    var hit =
        function (nod) {
            var nums = nod.position.toComplex()
            if (nums[0] - 10 < x && nums[0] + 10 > x)
                if (nums[1] - 10 < y && nums[1] + 10 > y)
                    res = nod
        }

    this.visit(hit)
    return res
}

Graph.prototype.outEdges = function (node) {
    return this.edges.filter(eq.curry(node).compose(getProp.curry("source")))
}
Graph.prototype.children = function (node) {
    return this.outEdges(node).map(getProp.curry("destination"))
}

Graph.prototype.inEdges = function (node) {
    return this.edges.filter(eq.curry(node).compose(getProp.curry("destination")))
}
Graph.prototype.parents = function (node) {
    return this.inEdges(node).map(getProp.curry("source"))
}

Graph.prototype.neighbours = function (node) {
    return this.children(node).concat(this.parents(node))
}

Graph.prototype.connect = function (node1, node2) {
    this.edges.push(new Edge(node1, node2))
}

Graph.prototype.insert = function (node) {
    this.nodes.push(node)
}

Graph.prototype.contains = function (node) {
    return (this.nodes.filter(eq.curry(node)).length > 0)
}

Graph.prototype.selected = function (node) {
    var old = this.selectedNode
    console.log("selected with ", old, node)
    if (old && node && old == node) { }
    else {
        if (old) {
            old.isselected = false
            old.redraw(this.context, this)
            this.selectedNode = null
        }

        if (node) {
            this.selectedNode = node
            node.isselected = true
            node.redraw(this.context, this)
        }
    }
}

Graph.prototype.visit = function (callback, direction) {
    //implements a breadth-first search
    var todo = [this.nodes[0]]
    var visited = []
    function doVisit (graph) {
        while (todo.length > 0) {
            var node = todo.shift()
            if (visited.filter(eq.curry(node)).length == 0) {
                callback(node)
                visited.push(node)
                if (direction && direction == 'up')
                    graph.parents(node).forEach(function (x) { todo.push(x) })
                if (direction && direction == 'down')
                    graph.children(node).forEach(function (x) { todo.push(x) })
                if (direction == null)
                    graph.neighbours(node).forEach(function (x) { todo.push(x) })
             }
         }
     }

     doVisit(this)

     //find remaining, disconnected nodes
     for (var i = 0; i < this.nodes.length; i++)
         if (visited.filter(eq.curry(this.nodes[i])).length == 0) {
             console.log("disconnected graph!")
             todo.push(this.nodes[i])
             doVisit(this)
         }
}
