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

