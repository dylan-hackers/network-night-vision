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
