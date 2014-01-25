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

        this.startpos = sour.follow(new PolarPoint(this.theta, this.source.overlapping(this.theta)))

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
        this.endpos = dest.follow(new PolarPoint(invvec, this.destination.overlapping(invvec)))
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
