;
(function(window) {
    var doc = document,
        $body = doc.querySelector('body'),
        $html = doc.querySelector('html'),
        inited = false,
        DOMGenerated = false,
        idCounter = 1,
        idPrefix = 'wheel-menu-',
        transformProp = '',
        $el,
        $ring,
        $cursor,
        $pointer,

        // Default params
        defaults = {
            size: 100,
            classes: '',
            borderWidth: 20, // Need for correct cursor positioning inside the ring
            inActiveRadius: 20,
            pointerOffset: 10,
            pointerFixed: true,
            pointerSize: 50,
            rotateRing: true, // If ring must be rotated according to active item or not
            transitionDuration: 400,
            customKey: 72,

            // On change callback. Called when mouseup event is triggered,
            // and if active item exists. It receives item array element as parameter.
            onChange: '',

            // Item element can be either string or object.
            // Object must contain 'content' field, it will be used as item's html.
            items: [
                'Hello',
                'Set your',
                'Menu items',
                'Here'
            ]
        };

    function getTransform() {
        var styles = getComputedStyle(document.documentElement),
            names = ['transform', 'msTransform', 'mozTransform', 'webkitTransform'];

        names.forEach(function(name) {
            if (transformProp) return;
            if (name in styles) transformProp = name;
        })
    }

    getTransform();

    window.WheelMenu = function(el, params) {
        this.inited = false;
        this.el = doc.querySelector(el);

        this.opts = extend({}, defaults, params);

        if (!DOMGenerated) {
            this.createDOM();
        }

        this.init();
    };

    WheelMenu.prototype = {
        init: function() {
            this.inited = true;

            this.cache = [];
            this.cacheInited = false;
            this.currentActive = '';

            this.createItemsDOM();
            this._saveCursorDimensions();

            this.triggeredWheel = false;
            this.el.addEventListener('keydown', this.onMouseDown.bind(this));
            $html.addEventListener('keyup', this.onMouseUp.bind(this));
            $html.addEventListener('mousemove', this.onMouseMove.bind(this));
        },

        /**
         * Show menu
         */
        show: function() {
            this.visible = true;

            if (this.opts.classes) {
                $el.classList.add(this.opts.classes);
                this._saveCursorDimensions();
            }

            this.disable(); // Disable previous active item if exist

            this.$itemsConteiner.style.left = this.currentX - this.opts.size / 2 + 'px';
            this.$itemsConteiner.style.top = this.currentY - this.opts.size / 2 + 'px';

            this.setMenuItemsPosition();
            $el.classList.add('active');
            $ring.classList.add('active');
            $cursor.classList.add('active');
            this.$itemsConteiner.classList.add('active');
            $html.classList.add('-wheel-menu-visible-');


            this.setCursorPosition();
            this.setRingRotation(this.getVector(this.cache[0].x, this.cache[0].y, true));

            this.setPiePosition();
        },

        /**
         * Hide menu
         */
        hide: function() {
            var _this = this;

            this.visible = false;

            $el.classList.remove('active');
            $ring.classList.remove('active');
            $cursor.classList.remove('active');
            $pointer.classList.remove('active');
            this.$itemsConteiner.classList.remove('active');
            $html.classList.remove('-wheel-menu-visible-', '-wheel-menu-moving-');

            if (this.opts.classes) {

            }

            $ring.style.transform = '';

            $ring.style.top = 0 + 'px';
            $ring.style.left = 0 + 'px';

            // Reset item cache
            this.cache = [];
            this.cacheInited = false;
        },

        /**
         * Activates received item.
         * @param {Object} item - Cached menu item from this.cache
         */
        activate: function(item) {
            if (this.currentActive && this.currentActive == item) return;

            if (this.currentActive) {
                this.disable(this.currentActive);
            }

            var vector = this.getVector(item.x, item.y, true);

            this.setPointerPosition(vector);
            item.item.classList.add('active');

            $pointer.classList.add('active');
            $el.classList.add('-item-activated-');
            this.setPointerPosition(vector);
            this.setRingRotation(vector);
            this.currentActive = item;

            // Refresh items position, because of style changes may happen
            this.setMenuItemsPosition();
        },


        /**
         * Disables received item.
         *  @param {Object} [item] - Cached menu item from this.cache
         */
        disable: function(item) {
            item = item ? item : this.currentActive;

            if (!item) return;

            $pointer.classList.remove('active');

            item.item.classList.remove('active');
            $el.classList.remove('-item-activated-');
            this.setMenuItemsPosition();
            this.currentActive = ''
        },

        /**
         * Sets circle position
         */
        setPiePosition: function() {
            var x = this.centerX - this.opts.size / 2,
                y = this.centerY - this.opts.size / 2;

            $ring.style.top = y + 'px';
            $ring.style.left = x + 'px';
        },

        /**
         * Loops through each menu item and sets its position.
         * Refreshes items cache array.
         */
        setMenuItemsPosition: function(pos) {
            var step = Math.PI * 2 / this.opts.items.length,
                angle = Math.PI / 2,
                opts = this.opts,
                range,
                _this = this,
                position;



            Array.prototype.forEach.call(this.$items, function($item, i) {
                position = _this.getItemPosition($item, angle);

                if (!pos) {
                    $item.style.left = position.x + 'px';
                    $item.style.top = position.y + 'px';
                } else {
                    $item.style.left = position.fromX + 'px';
                    $item.style.top = position.fromY + 'px';
                }

                if (!_this.cacheInited) {
                    _this.cache.push({
                        item: $item,
                        correctedX: position.x,
                        correctedY: position.y,
                        x: position.originalX,
                        y: position.originalY,
                        fromX: position.fromX,
                        fromY: position.fromY,
                        range: position.range
                    });
                }

                angle -= step;
            });

            this.cacheInited = true;
        },

        getX: function(angle, size) {
            return Math.cos(angle) * (size || this.opts.size + this.opts.pointerSize) / 2 + this.opts.size / 2
        },

        getY: function(angle, size) {
            return -Math.sin(angle) * (size || this.opts.size + this.opts.pointerSize) / 2 + this.opts.size / 2
        },

        /**
         * Computes correct 'x' and 'y' item position
         * @param {Object} item - DOM item object
         * @param {Number} angle - Angle at which item should be positioned
         * @returns {{x: *, y: *}}
         */
        getItemPosition: function(item, angle) {
            var width = item.offsetWidth,
                height = item.offsetHeight,
                opts = this.opts,
                degrees = angle * 180 / Math.PI,
                range = this.getAngleRange(angle),
                x, y,
                fromX, fromY,
                originalX, originalY;

            x = originalX = this.getX(angle);
            y = originalY = this.getY(angle);
            fromX = this.getX(angle, this.opts.size / 4);
            fromY = this.getY(angle, this.opts.size / 4);

            // Correct x position
            switch (true) {
                case degrees == 90 || degrees == -90:
                    x = x - width / 2;
                    fromX = fromX - width / 2;
                    break;
                case degrees <= -90 && degrees >= -270:
                    x = x - width;
                    fromX = fromX - width;
                    break;
                default:
                    break;
            }

            // Correct y position
            switch (true) {
                case degrees == 90:
                    y = y - height;
                    fromY = fromY - height;
                    break;
                case degrees == -90:
                    break;
                case degrees == 0 || degrees == -180:
                    y = y - height / 2;
                    fromY = fromY - height / 2;
                    break;
                default:
                    y = y - height / 2;
                    fromY = fromY - height / 2;
                    break;
            }

            return {
                x: x,
                y: y,
                originalX: originalX,
                originalY: originalY,
                fromX: fromX,
                fromY: fromY,
                range: range
            }
        },

        /**
         * Defines to what angle range item is belong to. Need for activating proper item
         * @param {Number} angle - Angle in radians to compute range from.
         * @returns {Array} - Range array [from, to] in degrees. 'from' can be larger then 'to'
         */
        getAngleRange: function(angle) {
            var range = [],
                opts = this.opts,
                halfStep = (Math.PI * 2 / this.opts.items.length) / 2,
                from = angle - halfStep,
                to = angle + halfStep,
                fromX, fromY,
                toX, toY;

            fromX = this.getX(from);
            fromY = this.getY(from);

            toX = this.getX(to);
            toY = this.getY(to);

            range[0] = -Math.atan2(-(fromY - this.opts.size / 2), -(fromX - this.opts.size / 2)) * 180 / Math.PI + 180;

            range[1] = -Math.atan2(-(toY - this.opts.size / 2), -(toX - this.opts.size / 2)) * 180 / Math.PI + 180;

            return range;
        },

        /**
         * Defines and saves menu's center position
         * @param {Event} e - Mousedown event
         */
        defineCoordsCenter: function(e) {
            this.centerX = e.pageX;
            this.centerY = e.pageY;
        },

        /**
         * Creates base elements and appends them to the body.
         */
        createDOM: function() {
            DOMGenerated = true;

            var html = '' +
                '<div class="wheel-menu--ring"></div>' +
                '<div class="wheel-menu--pointer"></div>' +
                '<div class="wheel-menu--cursor"></div>';

            $el = doc.createElement('div');
            $el.classList.add('wheel-menu-container');

            $el.innerHTML = html;

            $ring = $el.querySelector('.wheel-menu--ring');
            $pointer = $el.querySelector('.wheel-menu--pointer');
            $cursor = $el.querySelector('.wheel-menu--cursor');

            $ring.style.width = this.opts.size + 'px';
            $ring.style.height = this.opts.size + 'px';

            $body.appendChild($el);
        },

        /**
         * Creates menu items html and appends it to the menu container
         */
        createItemsDOM: function() {
            var $itemsContainer = doc.createElement('div'),
                itemHtml,
                items = '';

            $itemsContainer.classList.add('wheel-menu--items');
            $itemsContainer.setAttribute('id', idPrefix + idCounter++);
            $itemsContainer.style.width = this.opts.size + 'px';
            $itemsContainer.style.height = this.opts.size + 'px';

            this.opts.items.forEach(function(item) {
                if (typeof item == 'string') {
                    itemHtml = item;
                } else {
                    itemHtml = item.content ? item.content : 'undefined'
                }
                items += '<span class="wheel-menu--item">' + itemHtml + '</span>';
            });

            $itemsContainer.innerHTML = items;

            $el.appendChild($itemsContainer);

            this.$itemsConteiner = $itemsContainer;
            this.$items = $itemsContainer.querySelectorAll('.wheel-menu--item');
        },

        saveCurrentMousePosition: function(event) {
            this.currentX = event.pageX;
            this.currentY = event.pageY;
        },

        defineVector: function() {
            this.vector = this.getVector(this.currentX, this.currentY);
        },

        getVector: function(x, y, isItem) {
            var _x = x - this.centerX,
                _y = y - this.centerY;

            if (isItem) {
                _x = x - this.opts.size / 2;
                _y = y - this.opts.size / 2;
            }


            var length = Math.sqrt(_x * _x + _y * _y);

            return {
                x: _x,
                y: _y,
                length: length
            };
        },

        /**
         * Calculates angle between vector point and circle center in degrees
         * Begins from 0 to 360
         * @param {Object} [vector] - Vector to calculate from. 'this.vector' by default.
         * @returns {number} - Angle in degrees
         */
        getCursorAngle: function(vector) {
            vector = vector ? vector : this.vector;

            return -Math.atan2(-vector.y, -vector.x) * 180 / Math.PI + 180;
        },

        setPointerPosition: function(vector) {
            vector = vector ? vector : this.vector;

            var width = $pointer.offsetWidth,
                height = $pointer.offsetHeight;

            var x = vector.x / vector.length * (this.opts.size / 2 + this.opts.pointerOffset) + this.centerX - width / 2,
                y = vector.y / vector.length * (this.opts.size / 2 + this.opts.pointerOffset) + this.centerY - height / 2,
                angle = this.getCursorAngle(vector);

            $pointer.style.left = x + 'px';
            $pointer.style.top = y + 'px';
            $pointer.style[transformProp] = 'rotate(' + -angle.toFixed(1) + 'deg)'
        },

        setCursorPosition: function() {
            var x = this.currentX - this.cursorDims.width / 2,
                y = this.currentY - this.cursorDims.height / 2,
                dims = this.cursorDims,
                vector = this.vector;

            if (this.vector.length > this.opts.size / 2 - this.opts.borderWidth - dims.width / 2) {
                x = vector.x / vector.length * (this.opts.size / 2 - this.opts.borderWidth - dims.width / 2) + this.centerX - dims.width / 2;
                y = vector.y / vector.length * (this.opts.size / 2 - this.opts.borderWidth - dims.height / 2) + this.centerY - dims.height / 2;
            }

            this.cursorDims.x = x;
            this.cursorDims.y = y;

            $cursor.style.left = x + 'px';
            $cursor.style.top = y + 'px';
        },

        setRingRotation: function(vector) {
            var active = this.currentActive,
                angle;

            vector = vector || this.getVector(active.x, active.y);
            angle = this.getCursorAngle(vector);

            $ring.style[transformProp] = 'rotate(' + -angle.toFixed(1) + 'deg)';
        },

        /**
         * Detects intersection between mouse cursor (vector from center to mouse position)
         * and menu item. If detects, activates this item.
         */
        intersection: function() {
            var tan = this.vector.y / this.vector.x,
                _this = this,
                from, to,
                cursorDegree = -Math.atan2(-this.vector.y, -this.vector.x) * 180 / Math.PI + 180;


            for (var i = 0, max = this.cache.length; i < max; i++) {
                var item = _this.cache[i];

                from = item.range[0];
                to = item.range[1];

                // If one of item's sides area is on the edge state. For example
                // when we have item which 'from' begins from 157 and ends to -157, when all
                // 'cursorDegree' values are appear hear. To not let this happen, we compare
                // 'from' and 'to' and reverse comparing operations.
                if (from > to) {
                    if (cursorDegree <= from && cursorDegree <= to || cursorDegree >= from && cursorDegree >= to) {
                        _this.activate(item);
                    }
                } else {
                    if (cursorDegree >= from && cursorDegree <= to) {
                        _this.activate(item);
                    }
                }
            }
            this.cache.forEach(function(item) {

            })
        },

        /**
         * Defines if mouse cursor is in inActive radius
         * @returns {boolean} - True if so
         * @private
         */
        _isInactive: function() {
            return this.vector.length < this.opts.inActiveRadius
        },

        _saveCursorDimensions: function() {
            this.cursorDims = {
                width: $cursor.offsetWidth,
                height: $cursor.offsetHeight
            }
        },

        //  Events
        // -------------------------------------------------

        onMouseDown: function(e) {
            if (e.keyCode == this.opts.customKey && this.triggeredWheel == false) {
                this.triggeredWheel = true
                var x = window.innerWidth / 2;
                var y = window.innerHeight / 2;
                let position = {
                    pageX: x,
                    pageY: y
                }

                this.defineCoordsCenter(position);
                this.saveCurrentMousePosition(position);
                this.defineVector();
                this.show();
            }
        },

        onMouseUp: function(e) {
            if (!this.visible) return;
            if (e.keyCode == this.opts.customKey) {
                if (this.currentActive && this.opts.onChange) {
                    var index = this.cache.indexOf(this.currentActive);
                    this.opts.onChange(this.opts.items[index]);
                }
                this.hide();
                this.triggeredWheel = false
                exit({ exit: true })
            }
        },

        onMouseMove: function(e) {
            if (this.visible) {
                e.preventDefault();

                this.saveCurrentMousePosition(e);
                this.defineVector();
                this.setCursorPosition();

                if (!this.opts.pointerFixed) {
                    this.setPointerPosition();
                }
                if (this._isInactive()) {
                    this.disable();
                } else {
                    $html.classList.add('-wheel-menu-moving-');
                    this.intersection();
                }
            }
        }

    };

})(window);

function exit(data = {}, cb = () => {}) {
    fetch(`https://keep-companion/exit`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    }).then(resp => resp.json()).then(resp => cb(resp));
}