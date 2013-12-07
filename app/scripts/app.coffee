define ['vector2', 'jquery'], (V,$) ->
	"use strict"

	class Positionable
		constructor: ({@position}) ->

	class ValenceElectron

	class Element
		constructor: ({@protons, @symbol}) ->


	class Atom extends Positionable
		constructor: ({@element}) ->
			super arguments[0]
			@node = $ """<div class="atom">#{@element.symbol}</div>"""
			@node.css @position.as_css()

	class Bond
		constructor: ({@left, @right, @type}) ->

	Hydrogen = new Element protons:1, symbol:'H'
	Oxygen = new Element protons:6, symbol:'O'

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