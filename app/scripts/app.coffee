define ['vector2', 'jquery', 'hand'], (V,$,hand) ->
	"use strict"

	class Positionable
		constructor: ({@position}) ->

	class ValenceElectron
		constructor: ({}) ->
			@node = $ """<div class="electron"><div class="electron-dot"></div></div>"""
			# @node.css V(30,0).as_css()

	class Element
		constructor: ({@proton_count, @symbol}) ->


	class Atom extends Positionable
		constructor: ({@element}) ->
			super arguments[0]
			@node = $ """<div class="atom">#{@element.symbol}</div>"""
			@node.css @position.as_css()

			@electron_cloud = $ """<div class="electron_cloud"></div>"""
			@node.append @electron_cloud

			# create valence electrons
			@valence_electrons = for electron_index in [0...@element.proton_count]
				electron = new ValenceElectron
				@electron_cloud.append electron.node
				electron

			@position_valence_electrons()

			@node.addEventListener 'pointerdown', (-> console.log "YEAH"), false

		position_valence_electrons: ->
			count = @valence_electrons.length
			degree_step = 360 / count
			start_angle = -90
			for electron,index in @valence_electrons
				angle = degree_step * index + start_angle
				electron.node.css 'transform', "rotate(#{angle}deg)"


	class Bond
		constructor: ({@left, @right, @type}) ->

	Hydrogen = new Element proton_count:1, symbol:'H'
	Oxygen = new Element proton_count:6, symbol:'O'

	class Level
		constructor: ({@atoms, @bonds}) ->
			@atoms ?= []
			@bonds ?= []
			@node = $ """<div class="level"></div>"""
			for atom in @atoms
				@node.append atom.node
			for bond in @bonds
				@node.append bond.node

	Level1 = new Level atoms:[
			(new Atom element:Hydrogen, position:V(100,100))
			(new Atom element:Hydrogen, position:V(200,100))
			(new Atom element:Oxygen, position:V(150,200))
		]

	return Level1