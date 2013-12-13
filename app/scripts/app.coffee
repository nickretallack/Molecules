define ['vector2', 'jquery', 'hand'], (V,$,hand) ->
	"use strict"

	class Positionable
		constructor: ({@position}) ->

	class Element
		constructor: ({@proton_count, @symbol}) ->

	class ValenceElectron
		constructor: ({@atom}) ->
			@node = $ """<div class="electron"><div class="electron-dot"></div></div>"""
			@node.on 'mousedown', ((event)=> @draw_bond(event))
			@node.on 'mouseup', ((event) => @finish_bond(event))

		draw_bond: (event) ->
			event.stopPropagation()
			@atom.level.draw_bond
				item: @

		finish_bond: (event) ->
			event.stopPropagation()
			@atom.level.finish_bond @

		get_position: -> V.from_css @node.offset()

	class DrawingTarget
		constructor: ({@position}) ->
		get_position: -> @position

	class Bond
		constructor: ({@left, @right, @type}) ->
			@node = $ """<div class="bond #{@type}"></div>"""
			@set_position()

		set_position: ->
			left = @left.get_position()
			right = @right.get_position()
			delta = right.minus left
			angle = delta.angle()
			@node.css left.as_css()
			@node.css
				transform: "rotate(#{angle}rad)"
				width: "#{delta.magnitude()}px"

	class Atom extends Positionable
		constructor: ({@element}) ->
			super arguments[0]
			@node = $ """<div class="atom">#{@element.symbol}</div>"""
			@set_position @position

			@electron_cloud = $ """<div class="electron_cloud"></div>"""
			@node.append @electron_cloud

			# create valence electrons
			@valence_electrons = for electron_index in [0...@element.proton_count]
				electron = new ValenceElectron atom:@
				@electron_cloud.append electron.node
				electron

			@position_valence_electrons()
			@node.on 'mousedown', ((event)=> @start_drag(event))

		start_drag: (event) ->
			event.stopPropagation()
			@level.start_drag
				item: @
				offset: (V.from_event event).minus(@position)

		set_position: (@position) ->
			@node.css @position.as_css()

		position_valence_electrons: ->
			count = @valence_electrons.length
			degree_step = 360 / count
			start_angle = -90
			for electron,index in @valence_electrons
				angle = degree_step * index + start_angle
				electron.node.css 'transform', "rotate(#{angle}deg)"


	Hydrogen = new Element proton_count:1, symbol:'H'
	Oxygen = new Element proton_count:6, symbol:'O'

	in_bounds = (value) -> 0 <= value <= 1
	remove_from_array = (array, item) ->
		index = array.indexOf item
		array.splice index, 1
		undefined

	class Level
		constructor: ({@atoms, @bonds}) ->
			@atoms ?= []
			@bonds ?= []
			@node = $ """<div class="level"></div>"""
			for atom in @atoms
				@node.append atom.node
				atom.level = @
			for bond in @bonds
				@node.append bond.node
				bond.level = @

			stop_drag = =>
				console.log "WTF"

			@node.on 'mousedown', ((event)=> @cut_bonds(event))
			window.addEventListener 'mouseup', ((event)=>@stop_drag(event)), false
			window.addEventListener 'mousemove', ((event)=>@drag(event)), false

		update: ->
			for bond in @bonds
				bond.set_position()

		remove_bond: (bond) ->
			bond.node.remove()
			remove_from_array @bonds, bond

		stop_drag: ->
			console.log "UP"
			@dragging = null
			if @drawing
				@drawing.node.remove()
				@drawing = null
			if @cutting #q
				cut_bonds = []
				cut_left = @cutting.left.get_position()
				cut_delta = @cutting.right.get_position().minus cut_left #s
				for bond in @bonds #p
					bond_left = bond.left.get_position()
					bond_delta = bond.right.get_position().minus bond_left #r
					left_delta = cut_left.minus bond_left #q-p
					delta_cross = bond_delta.cross2d cut_delta #r x s
					if delta_cross
						cut_cross = left_delta.cross2d cut_delta #q-p x s
						bond_cross = left_delta.cross2d bond_delta #q-p x r
						cut_intercept = cut_cross / delta_cross
						bond_intercept = bond_cross / delta_cross
						if (in_bounds cut_intercept) and (in_bounds bond_intercept)
							cut_bonds.push bond
				for bond in cut_bonds
					@remove_bond bond
				@cutting.node.remove()
				@cutting = null

		drag: (event) ->
			if @dragging
				mouse = V.from_event event
				@dragging.item.set_position mouse.minus @dragging.offset
				@update()
			if @drawing
				mouse = V.from_event event
				@drawing.right.position = mouse
				@drawing.set_position()
			if @cutting
				mouse = V.from_event event
				@cutting.right.position = mouse
				@cutting.set_position()

		cut_bonds: (event) ->
			mouse = V.from_event event
			@cutting = new Bond
				left: new DrawingTarget position:mouse
				right: new DrawingTarget position:mouse
				type: 'cutter'
			@node.append @cutting.node

		start_drag: (@dragging) ->
		draw_bond: ({item}) ->
			@drawing = new Bond
				left: item
				right: new DrawingTarget position: item.get_position()
			@node.append @drawing.node

		finish_bond: (item) ->
			if @drawing
				@drawing.right = item
				@bonds.push @drawing
				@drawing = null
				@update()


	H1 = new Atom element:Hydrogen, position:V(100,200)
	H2 = new Atom element:Hydrogen, position:V(200,200)
	O1 = new Atom element:Oxygen, position:V(150,100)
	Level1 = new Level
		atoms:[H1, H2, O1]
		bonds:[
			(new Bond left:H1.valence_electrons[0], right:O1.valence_electrons[4])
			(new Bond left:H2.valence_electrons[0], right:O1.valence_electrons[2])
		] 

	class Game


	return Level1