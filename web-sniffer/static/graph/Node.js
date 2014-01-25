function Node () {
}

Node.prototype = {
    constructor: Node,
    position: null,
    edge: null,
    fillStyle: "orange",
    textStyle: "black",

    redraw: function () {
        console.log("this better not happen")
    },

    place: function (graph) {
        var childs = graph.children(this)
        for (var i = 0; i < childs.length; i++) {
            //that's all not good here yet...
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

                var vec = new PolarPoint(stat + (i + 1) * (variance / fact), 90)
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

function EllipseNode (val) {
    this.value = val
    this.width = 0
    this.height = 0
    this.focalpoints = []
}
EllipseNode.prototype = {
    constructor: EllipseNode,
    __proto__ : Node.prototype,
    redraw: function (ctx, graph) {
        var pos = this.position.toComplex()
        var size = ctx.measureText(this.value)
        var width = size.width + (size.width / 10)
        var height = 17
        this.radius = (height / 2)
        ctx.beginPath()
        var kappa = .5522848
        var xs = pos[0] - width / 2    // x start
        var ys = pos[1] - height / 2   // y start
        var ox = (width / 2) * kappa   // control point offset horizontal
        var oy = (height / 2) * kappa  // control point offset vertical
        var xe = xs + width            // x end
        var ye = ys + height           // y end
        var xm = xs + width / 2        // x middle
        var ym = ys + height / 2       // y middle

        ctx.moveTo(xs, ym)
        ctx.bezierCurveTo(xs, ym - oy, xm - ox, ys, xm, ys)
        ctx.bezierCurveTo(xm + ox, ys, xe, ym - oy, xe, ym)
        ctx.bezierCurveTo(xe, ym + oy, xm + ox, ye, xm, ye)
        ctx.bezierCurveTo(xm - ox, ye, xs, ym + oy, xs, ym)
        ctx.fillStyle = this.fillStyle
        ctx.fill()
        ctx.closePath()
        ctx.fillStyle = this.textStyle
        ctx.fillText(this.value, xs + (size.width / 20), ym + height / 6)

/*        if (this.isselected) {
            var old = ctx.strokeStyle
            ctx.strokeStyle = "red"
            ctx.arc(pos[0], pos[1], this.radius - 0.5, 0, Math.PI * 2, true)
            ctx.arc(pos[0], pos[1], this.radius - 1.5, 0, Math.PI * 2, true)
            ctx.closePath()
            ctx.stroke()
            ctx.strokeStyle = old
        } */


    },

}

function CircleNode (val) {
    this.value = val
    this.radius = 15
}
CircleNode.prototype = {
    constructor: CircleNode,
    __proto__ : Node.prototype,
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
}

