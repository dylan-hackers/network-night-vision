function Node () {
}

Node.prototype = {
    constructor: Node,
    position: null,
    edge: null,
    fillStyle: "orange",
    textStyle: "black",

    redraw: function (context, graph) {
        console.log("this better not happen")
    },

    intersects: function (polar) {
        console.log("also better not happen here")
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
    this.height = 17
    this.focalpoint1 = null
    this.focalpoint2 = null
}
EllipseNode.prototype = {
    constructor: EllipseNode,
    __proto__ : Node.prototype,
    redraw: function (ctx, graph) {
        var pos = this.position.toComplex()
        var size = ctx.measureText(this.value)
        var width = size.width + (size.width / 10)
        this.width = width
        var height = this.height
        if (height > width)
            console.log("ALL WRONG!!!!")
        var fp = Math.sqrt(width / 2 * width / 2 - height / 2 * height / 2)
        this.focalpoint1 = this.position.follow(new PolarPoint(0, fp))
        this.focalpoint2 = this.position.follow(new PolarPoint(Math.PI, fp))
        ctx.beginPath()
        var kappa = .5522848
        var xm = pos[0]                // x center
        var ym = pos[1]                // y center
        var xs = xm - width / 2        // x start
        var ys = ym - height / 2       // y start
        var ox = (width / 2) * kappa   // control point offset horizontal
        var oy = (height / 2) * kappa  // control point offset vertical
        var xe = xm + width / 2        // x end
        var ye = ym + height / 2       // y end

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

        if (this.isselected) {
            var old = ctx.strokeStyle
            ctx.strokeStyle = "red"

            ctx.moveTo(xs, ym)
            ctx.bezierCurveTo(xs, ym - oy, xm - ox, ys, xm, ys)
            ctx.bezierCurveTo(xm + ox, ys, xe, ym - oy, xe, ym)
            ctx.bezierCurveTo(xe, ym + oy, xm + ox, ye, xm, ye)
            ctx.bezierCurveTo(xm - ox, ye, xs, ym + oy, xs, ym)
            ctx.moveTo(xs + 1, ym)
            ctx.bezierCurveTo(xs + 1, ym - oy, xm - ox, ys, xm + 1, ys)
            ctx.bezierCurveTo(xm + ox, ys, xe - 1, ym - oy, xe - 1, ym)
            ctx.bezierCurveTo(xe - 1, ym + oy, xm + ox, ye, xm, ye)
            ctx.bezierCurveTo(xm - ox, ye, xs + 1, ym + oy, xs + 1, ym)
            ctx.stroke()
            ctx.closePath()
            ctx.strokeStyle = old
        }


    },

    intersects: function (polar) {
        //distance between ''polar'' and focal points is < 2*(width/2)
        var d = this.focalpoint1.distance(polar) + this.focalpoint2.distance(polar)
        if (d < this.width)
            console.log("d " + d + " < " + this.width + " width")
        return d < this.width
    }
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

    intersects: function (polar) {
        var nums = this.position.toComplex()
        var nums2 = polar.toComplex()
        if (nums[0] - this.radius < nums2[0] && nums[0] + this.radius > nums2[0])
            if (nums[1] - this.radius < nums2[1] && nums[1] + this.radius > nums2[1])
                return true
    },
}

