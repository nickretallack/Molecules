define ['underscore'], (_) ->
    css_properties = ['top','left']

    class Vector
        constructor: ->
            if typeof arguments[0] is 'object'
                object = arguments[0]
                if object.x? and object.y?
                    {@x, @y} = object
                else if object.left? and object.top?
                    {left:@x, top:@y} = object
            else
                [@x, @y] = arguments

        components: -> [@x,@y]

        reduce: (initial, action) ->
            _.reduce @components(), action, initial

        fmap: (action) ->
            new Vector (_.map @components(), action)...

        vmap: (vector, action) ->
            new Vector (_.map _.zip(@components(), vector.components()), (components) -> action components...)...

        magnitude: ->
            Math.sqrt @reduce 0, (accumulator, component) -> accumulator + component*component

        scale: (factor) ->
            @fmap (component) -> component * factor

        invert: ->
            @scale -1

        add: (vector) ->
            @vmap vector, (c1, c2) -> c1 + c2
        
        subtract: (vector) ->
            @add(vector.invert())

        equals: (vector) ->
            _.all _.zip(@components(), vector.components()), (item) -> item[0] == item[1]

        distance: (vector) ->
            @minus(vector).magnitude()

        unit: ->
            @scale 1/@magnitude()

        angle: ->
            Math.atan2 @y, @x

        as_css: ->
            left:@x
            top:@y

        as_px: -> "#{@x}px #{@y}px"

    Vector::plus = Vector::add
    Vector::minus = Vector::subtract
    V = -> new Vector arguments...

    V.from_event = (event) -> V event.clientX, event.clientY
    V.from_css = (css) -> V css.left, css.top

    return V
