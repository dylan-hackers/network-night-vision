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
                console.log("putting root at ", x, ", ", y)
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
