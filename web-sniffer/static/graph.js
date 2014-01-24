
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
    graph.insert(n5)
    graph.insert(n6)
    graph.insert(n7)
    graph.insert(n8)
    graph.insert(n9)
    graph.connect(n1, n5)
    graph.connect(n1, n6)
    graph.connect(n7, n8)
    //graph.connect(n1, n9)
    graph.connect(n7, n9)
    //graph.connect(n1, n7)
    //graph.visit(function (x) { console.log("[neighbours] callback of " + x.value) })
    //graph.visit(function (x) { console.log("[up] callback of " + x.value) }, 'up')
    //graph.visit(function (x) { console.log("[down] callback of " + x.value) }, 'down')

    var canvas = document.getElementById('canvas')
    canvas.onclick = function (event) {
        var x = event.pageX - canvas.offsetLeft
        var y = event.pageY - canvas.offsetTop
        var node = graph.find(x, y)
        console.log("x: " + x + " y: " + y + " node ", node)
        graph.setselected(node)
    }

    graph.layout(canvas)
    var ctx = canvas.getContext('2d')
    graph.context = ctx
    graph.draw(ctx)
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
    this.directed = true
    if (properties)
        for (var i = 0; i < properties.length; i = i + 2)
            this.properties[i] = properties[i + 1]
}

Edge.prototype.draw = function (ctx, graph) {
    ctx.beginPath()
    var sour = this.source.position
    var dest = this.destination.position

    var spos = sour.toComplex()
    var dpos = dest.toComplex()
    var theta  = toPolar(dpos[0] - spos[0], dpos[1] - spos[1]).theta

    var start = sour.follow(new PolarPoint(theta, this.source.radius)).toComplex()
    if (Math.abs(dpos[0] - spos[0]) < 0.1) {
        theta = Math.PI / 2
        if (spos[1] < dpos[1])
            theta = - theta
    }

    var invvec = Math.PI - theta
    var endp = dest.follow(new PolarPoint(invvec, this.destination.radius))
    var end = endp.toComplex()

    ctx.strokeStyle = this.strokeStyle
    ctx.moveTo(start[0], start[1])
    ctx.lineTo(end[0], end[1])
    ctx.closePath()
    ctx.stroke()

    if (this.directed) {
        var arrowsize = 5
        var oneend = endp.follow(new PolarPoint(invvec + Math.PI / 8, arrowsize)).toComplex()
        var otherend = endp.follow(new PolarPoint(invvec - Math.PI / 8, arrowsize)).toComplex()

        ctx.beginPath()
        ctx.moveTo(end[0], end[1])
        ctx.lineTo(oneend[0], oneend[1])
        ctx.moveTo(end[0], end[1])
        ctx.lineTo(otherend[0], otherend[1])
        ctx.closePath()
        ctx.stroke()
    }
}

function Node (value, properties) {
    this.value = value
    this.position = null
    this.fillStyle = "orange"
    this.textStyle = "black"
    this.radius = 10
    if (properties)
        for (var i = 0; i < properties.length; i = i + 2)
            this.properties[i] = properties[i + 1]
}

Node.prototype = {
    redraw: function (ctx, graph) {
        var pos = this.position.toComplex()
        ctx.beginPath()
        ctx.arc(pos[0], pos[1], this.radius + 0.5, 0, Math.PI * 2, true)
        ctx.fillStyle = this.fillStyle
        ctx.closePath()
        ctx.fill()
        if (this.isselected) {
            var old = ctx.strokeStyle
            ctx.strokeStyle = "red"
            ctx.arc(pos[0], pos[1], this.radius - 0.5, 0, Math.PI * 2, true)
            ctx.arc(pos[0], pos[1], this.radius - 1.5, 0, Math.PI * 2, true)
            ctx.closePath()
            ctx.stroke()
            ctx.strokeStyle = old
        }
        ctx.fillStyle = this.textStyle
        ctx.fillText(this.value, pos[0], pos[1])
    },


    place: function (graph) {
        var childs = graph.children(this)
        for (var i = 0; i < childs.length; i++) {
            if (childs[i].position == null) {
                //that is not entirely true:
                //we need to move a bit if child already has a position
                var vec = new PolarPoint(i * (Math.PI * 2 / childs.length), 50)
                childs[i].position = this.position.follow(vec)
            }
        }
    },

    draw: function (ctx, graph) {
        //we better have a position
        this.redraw(ctx, graph)
        graph.outEdges(this).forEach(function (x) { x.draw(ctx, graph) })
    },
}

function Graph () {
    this.nodes = []
    this.edges = []
    this.selectedNode = null
    this.subgraphs = []
}

Graph.prototype = {
    layout: function (canvas) {
        this.findsubgraphs()
        var subgraphs = this.subgraphs
        for (var i = 0; i < subgraphs.length; i++) {
            var roots = this.getRoots(subgraphs[i])
            roots[0].position = toPolar(canvas.width / (2 * subgraphs.length) + (canvas.width * i / subgraphs.length), canvas.height / 2)
        }
        var cb = function (graph, x) { x.place(graph) }
        this.visit(cb.curry(this), 'down')
    },

    draw: function (ctx) {
        var cb = function (ctx, graph, x) { x.draw(ctx, graph) }
        this.visit(cb.curry(ctx, this))
    },

    find: function (x, y) {
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
    },

    outEdges: function (node) {
        return this.edges.filter(eq.curry(node).compose(getProp.curry("source")))
    },

    children: function (node) {
        return this.outEdges(node).map(getProp.curry("destination"))
    },

    inEdges: function (node) {
        return this.edges.filter(eq.curry(node).compose(getProp.curry("destination")))
    },

    parents: function (node) {
        return this.inEdges(node).map(getProp.curry("source"))
    },

    neighbours: function (node) {
        return this.children(node).concat(this.parents(node))
    },

    connect: function (node1, node2) {
        this.edges.push(new Edge(node1, node2))
    },

    insert: function (node) {
        this.nodes.push(node)
    },

    contains: function (node) {
        return (this.nodes.filter(eq.curry(node)).length > 0)
    },

    findNode: function (val) {
        var nodes = this.nodes.filter(function (x) { return x.value == val })
        if (nodes.length == 1)
            return nodes[0]
        else
            return null
    },

    setselected: function (node) {
        var old = this.selectedNode
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
    },

    findsubgraphs: function () {
        //implements a breadth-first search
        var todo = [this.nodes[0]]
        var visited = []
        var subgraph = []
        function doVisit (graph) {
            while (todo.length > 0) {
                var node = todo.shift()
                if (visited.filter(eq.curry(node)).length == 0) {
                    subgraph.push(node)
                    visited.push(node)
                    graph.neighbours(node).forEach(function (x) { todo.push(x) })
                }
            }
        }

        doVisit(this)
        this.subgraphs.push(subgraph)

        //find remaining, disconnected nodes
        for (var i = 0; i < this.nodes.length; i++)
            if (visited.filter(eq.curry(this.nodes[i])).length == 0) {
                console.log("disconnected graph!")
                subgraph = []
                todo.push(this.nodes[i])
                doVisit(this)
                this.subgraphs.push(subgraph)
            }
    },

    getRoots: function (nodelist) {
        return [nodelist[0]]
    },

    visit: function (callback, direction) {
        //implements a breadth-first search
        var todo = []
        var cb = function (graph, subgraph) {
            graph.getRoots(subgraph).forEach(function (r) { todo.push(r)})
        }
        this.subgraphs.forEach(cb.curry(this))
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
    },

}
