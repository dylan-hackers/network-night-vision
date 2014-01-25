
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
        return new PolarPoint(this.theta, this.rho * number)
    },

    copy: function () {
        return new PolarPoint(this.theta, this.rho)
    },

    distance: function (other) {
        return Math.sqrt(this.rho * this.rho + other.rho * other.rho - 2 * this.rho * other.rho * Math.cos(this.theta - other.theta))
    },

    interpolate: function (other, delta) {
        var pi = Math.PI, pi2 = pi * 2
        var ch = function (t) {
            return (t < 0)? (t % pi2) + pi2 : t % pi2
        }
        var tt = this.theta, et = other.theta
        var sum, diff = Math.abs(tt - et)
        if (diff == pi) {
            if(tt > et) {
                sum = ch((et + ((tt - pi2) - et) * delta))
            } else {
                sum = ch((et - pi2 + (tt - (et)) * delta))
            }
        } else if(diff >= pi) {
            if(tt > et) {
                sum = ch((et + ((tt - pi2) - et) * delta))
            } else {
                sum = ch((et - pi2 + (tt - (et - pi2)) * delta))
            }
        } else {
            sum = ch((et + (tt - et) * delta))
        }
        var r = (this.rho - other.rho) * delta + other.rho
        return new PolarPoint(sum, r)
    },

}


function Edge (source, destination) {
    this.source = source
    this.destination = destination
    this.strokeStyle = "blue"
    this.directed = true
    this.theta = null
    this.invvec = null
    this.startpos = null
    this.endpos = null
}

Edge.prototype = {
    place: function (graph) {
        var sour = this.source.position
        var dest = this.destination.position

        var spos = sour.toComplex()
        var dpos = dest.toComplex()
        var dx = dpos[0] - spos[0]
        var dy = dpos[1] - spos[1]
        this.theta = toPolar(dx, dy).theta

        this.startpos = sour.follow(new PolarPoint(this.theta, this.source.radius))

        var mytheta = this.theta
        if (Math.abs(dpos[0] - spos[0]) < 0.1) {
            if (dy > 0) {
                mytheta = Math.PI / 2
            } else {
                mytheta = - Math.PI / 2
            }
        }
        var invvec = Math.PI + mytheta
        //console.log("node " + this.source.value + " to " + this.destination.value + " dx " + dx + " dy " + dy + " theta " + theta + " invvec " + invvec)
        this.invvec = invvec
        this.endpos = dest.follow(new PolarPoint(invvec, this.destination.radius))
        this.destination.edge = this
    },


    draw: function (ctx, graph) {
        ctx.beginPath()
        var start = this.startpos.toComplex()
        var end = this.endpos.toComplex()

        ctx.strokeStyle = this.strokeStyle
        ctx.moveTo(start[0], start[1])
        ctx.lineTo(end[0], end[1])
        ctx.closePath()
        ctx.stroke()

        if (this.directed) {
            var arrowsize = 5
            var oneend = this.endpos.follow(new PolarPoint(this.invvec + Math.PI / 8, arrowsize)).toComplex()
            var otherend = this.endpos.follow(new PolarPoint(this.invvec - Math.PI / 8, arrowsize)).toComplex()

            ctx.beginPath()
            ctx.moveTo(end[0], end[1])
            ctx.lineTo(oneend[0], oneend[1])
            ctx.moveTo(end[0], end[1])
            ctx.lineTo(otherend[0], otherend[1])
            ctx.closePath()
            ctx.stroke()
        }
    },
}

function Node (value) {
    this.value = value
    this.position = null
    this.fillStyle = "orange"
    this.textStyle = "black"
    this.radius = 10
    this.edge = null
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
                var fact = childs.length
                if (fact % 2 == 0)
                    fact++

                var stat = 0
                var variance = Math.PI * 2
                if (this.edge) {
                    variance = Math.PI
                    stat = this.edge.theta - (Math.PI / 2)
                }

                var vec = new PolarPoint(stat + (i + 1) * (variance / fact), 50)
                //console.log("setting position of " + childs[i].value + " to ", vec.toComplex())
                childs[i].position = this.position.follow(vec)
            }
        }
        graph.outEdges(this).forEach(function (x) { x.place(graph) })
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
    this.allroots = []
}

Graph.prototype = {
    clear: function () {
        this.nodes = []
        this.edges = []
        this.selectNode = null
        this.allroots = []
    },

    layout: function (canvas) {
        //console.log("laying out " + this.nodes.length)
        this.nodes.forEach(function (x) { x.edge = null ; x.position = null })
        var subgraphs = this.findsubgraphs()
        for (var i = 0; i < subgraphs.length; i++) {
            var roots = this.getRoots(subgraphs[i])
            for (var r = 0; r < roots.length; r++) {
                var root = roots[r]
                var x = canvas.width / (2 * subgraphs.length) + (canvas.width * i / subgraphs.length)
                var y = canvas.height / (2 * roots.length) + (canvas.height * r / roots.length)
                root.position = toPolar(x, y)
                this.allroots.push(root)
            }
        }
        //console.log("set " + this.allroots.length + "positions")
        var cb = function (graph, x) { x.place(graph) }
        this.visit(cb.curry(this), 'down')
    },

    draw: function (ctx) {
        ctx.clearRect(0, 0, 800, 300)
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
        //console.log("connecting " + node1.value + " with " + node2.value + " (already? " + this.children(node1).filter(eq.curry(node2)).length)
        if (this.children(node1).filter(eq.curry(node2)).length == 0)
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

    findNodeOrInsert: function (val) {
        var node = this.findNode(val)
        if (node)
            return node
        var n = new Node(val)
        this.insert(n)
        return n
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
        var subgraphs = []
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
        subgraphs.push(subgraph)

        //find remaining, disconnected nodes
        for (var i = 0; i < this.nodes.length; i++)
            if (visited.filter(eq.curry(this.nodes[i])).length == 0) {
                //console.log("disconnected graph!")
                subgraph = []
                todo.push(this.nodes[i])
                doVisit(this)
                subgraphs.push(subgraph)
            }
        return subgraphs
    },

    getRoots: function (nodelist) {
        var roots = []
        var cb = function (graph, x) {
            if (graph.inEdges(x).length == 0)
                roots.push(x)
        }
        nodelist.filter(cb.curry(this))
        if (roots.length == 0)
            roots.push(nodelist[0])
        return roots
    },

    visit: function (callback, direction) {
        //implements a breadth-first search
        var todo = []
        this.allroots.forEach(function (r) { todo.push(r) })
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

var graph = new Graph()
