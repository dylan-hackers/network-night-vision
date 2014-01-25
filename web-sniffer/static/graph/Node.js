function Node (value) {
    this.value = value
    this.position = null
    this.fillStyle = "orange"
    this.textStyle = "black"
    this.radius = 15
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
        //var width = ctx.measureText(this.value).width
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

