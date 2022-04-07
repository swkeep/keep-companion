function getElement(query) {
    return document.querySelector(query);
}

function extend(target) {
    target = arguments[0];

    var objects = Array.prototype.splice.call(arguments, 1);

    objects.forEach(function(obj) {
        for (var prop in obj) {
            target[prop] = obj[prop]
        }
    });

    return target;
}

function getRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min)) + min;
}