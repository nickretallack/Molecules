define ['vector2', 'jquery'], (V,$) ->
	"use strict"

	class Positionable
		constructor: ({@position}) ->

	class Element
		constructor: ({@proton_count, @symbol}) ->
			@desired_valence = if @proton_count <= 2 then 2 else 8
			@initial_valence = if @proton_count <= 2 then @proton_count else @proton_count - 2

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
			@node.css left.minus(V(1,1)).as_css()
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
			@valence_electrons = for electron_index in [0...@element.initial_valence]
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

		update_valence: ->
			@valence_is_satisfied = @valence_satisfied()
			@node.toggleClass "valence-satisfied", @valence_is_satisfied

		valence_satisfied: ->
			bond_count = @level.count_bonds @
			@valence_electrons.length + bond_count == @element.desired_valence


	Hydrogen = new Element proton_count:1, symbol:'H'
	Oxygen = new Element proton_count:8, symbol:'O'
	Nitrogen = new Element proton_count:7, symbol:'N'
	Carbon = new Element proton_count:6, symbol:'C'

	in_bounds = (value) -> 0 <= value <= 1
	remove_from_array = (array, item) ->
		index = array.indexOf item
		array.splice index, 1
		undefined

	class Level
		constructor: ({@atoms, @bonds, molecules, @instructions}) ->
			@won = false
			@atoms ?= []
			@bonds ?= []

			# import from molecules
			if molecules
				for molecule in molecules
					@atoms = @atoms.concat molecule.atoms
					@bonds = @bonds.concat molecule.bonds

			@node = $ """<div class="level">#{@instructions}</div>"""
			for atom in @atoms
				@node.append atom.node
				atom.level = @
			for bond in @bonds
				@node.append bond.node
				bond.level = @

			@node.on 'mousedown', ((event)=> @cut_bonds(event))
			@update_molecules()

		update_bonds: ->
			for bond in @bonds
				bond.set_position()

		update_molecules: ->
			@molecules = @get_molecules()

			for atom in @atoms
				atom.update_valence()

			if not @won and @win_condition()
				@won = true
				@game.won_level()

		remove_bond: (bond) ->
			bond.node.remove()
			remove_from_array @bonds, bond

		stop_drag: ->
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
				@update_molecules()

		drag: (event) ->
			if @dragging
				mouse = V.from_event event
				delta = @dragging.position.minus mouse
				@dragging.position = mouse
				for atom in @dragging.molecule
					atom.set_position atom.position.minus delta
				# @dragging.item.set_position @dragging.item.position  mouse.minus @dragging.offset
				@update_bonds()
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
			mouse = V.from_event event
			@dragging.position = mouse

			# what's this molecule?
			@dragging.molecule = @get_molecule @dragging.item

		draw_bond: ({item}) ->
			@drawing = new Bond
				left: item
				right: new DrawingTarget position: item.get_position()
			@node.append @drawing.node

		count_duo_bonds: (atom1, atom2) ->
			counter = 0
			atoms = [atom1, atom2]
			for bond in @bonds
				if bond.left.atom in atoms and bond.right.atom in atoms
					counter += 1
			counter

		finish_bond: (electron) ->
			if @drawing
				if electron.atom is @drawing.left.atom
					# warn the player
					console.log "Can't bond an atom to itself"
					@drawing.node.remove()
				else
					@drawing.right = electron
					if (@count_duo_bonds @drawing.right.atom, @drawing.left.atom) >= 3
						# warn the player
						console.log "Can't make quadruple bonds"
						@drawing.node.remove()
					else
						# Remove conflicting bonds
						bonds_to_remove = []
						drawing_sides = [@drawing.left, @drawing.right]
						for bond in @bonds
							if bond.left in drawing_sides or bond.right in drawing_sides
								bonds_to_remove.push bond
						for bond in bonds_to_remove
							@remove_bond bond

						# Update
						@bonds.push @drawing
						@update_bonds()
						@update_molecules()

				@drawing = null

		count_bonds: (atom) ->
			counter = 0
			for bond in @bonds
				if bond.left.atom is atom or bond.right.atom is atom
					counter += 1
			return counter

		get_atom_neigbors: (atom) ->
			results = []
			for bond in @bonds
				if bond.right.atom is atom
					results.push bond.left.atom
				else if bond.left.atom is atom
					results.push bond.right.atom
			return results

		get_molecule: (atom) ->
			for molecule in @molecules
				if atom in molecule
					return molecule

		# Obsolete, but nifty
		get_molecule_from_atom: (atom) ->
			found = [atom]
			queue = [atom]
			while queue.length
				atom = queue.pop()
				for neighbor in @get_atom_neigbors atom
					if neighbor not in found
						found.push neighbor
						queue.push neighbor
			return found

		get_molecules: ->
			found = []
			molecules = []
			for atom in @atoms
				if atom not in found
					molecule = [atom]
					molecules.push molecule
					found.push atom

					queue = [atom]
					while queue.length
						atom = queue.pop()
						for neighbor in @get_atom_neigbors atom
							if neighbor not in found
								found.push neighbor
								queue.push neighbor
								molecule.push neighbor
			return molecules

		win_condition: ->
			return @molecules_in_harmony()

		molecules_in_harmony: ->
			for atom in @atoms
				return false unless atom.valence_is_satisfied
			return true

	# Molecules

	class Molecule
		constructor: ({position}) ->
			for atom in @atoms
				atom.set_position atom.position.plus position

	class HydrogenMolecule extends Molecule
		constructor: ->
			@H1 = new Atom element:Hydrogen, position:V(-50,0)
			@H2 = new Atom element:Hydrogen, position:V(50,0)
			@atoms = [@H1, @H2]
			@bonds = [
				(new Bond left:@H1.valence_electrons[0], right:@H2.valence_electrons[0])
			]
			super arguments[0]

	class OxygenMolecule extends Molecule
		constructor: ->
			@O1 = new Atom element:Oxygen, position:V(-50,0)
			@O2 = new Atom element:Oxygen, position:V(50,0)
			@atoms = [@O1, @O2]
			@bonds = [
				(new Bond left:@O1.valence_electrons[1], right:@O2.valence_electrons[5])
				(new Bond left:@O1.valence_electrons[2], right:@O2.valence_electrons[4])
			]
			super arguments[0]

	class WaterMolecule extends Molecule
		constructor: ->
			@H1 = new Atom element:Hydrogen, position:V(-50,50)
			@H2 = new Atom element:Hydrogen, position:V(50,50)
			@O1 = new Atom element:Oxygen, position:V(0,-50)
			@atoms = [@H1, @H2, @O1]
			@bonds = [
				(new Bond left:@H1.valence_electrons[0], right:@O1.valence_electrons[4])
				(new Bond left:@H2.valence_electrons[0], right:@O1.valence_electrons[2])
			]
			super arguments[0]

	# Levels

	class DiatomicLevel extends Level
		win_condition: ->
			return @molecules_in_harmony() and @only_double_molecules()

		only_double_molecules: ->
			for molecule in @molecules
				return false unless (
					molecule.length is 2 and
					molecule[0].element is molecule[1].element
				)
			return true


	class BondHydrogenLevel extends DiatomicLevel
		constructor: ->
			super
				atoms: [
					new Atom element:Hydrogen, position: V(200, 100)
					new Atom element:Hydrogen, position: V(400, 150)
				]
				instructions: """
				Hydrogen atoms have one valence electron, but they want to have two!
				Draw a line between two electrons to make them share.
				"""

	class BondMultilpeHydrogenLevel extends DiatomicLevel
		constructor: ->
			super
				atoms: [
					new Atom element:Hydrogen, position: V(200, 100)
					new Atom element:Hydrogen, position: V(400, 150)
					new Atom element:Hydrogen, position: V(180, 200)
					new Atom element:Hydrogen, position: V(300, 350)
					new Atom element:Hydrogen, position: V(100, 100)
					new Atom element:Hydrogen, position: V(500, 450)
				]
				instructions: """
				When atoms share valence electrons it's called a co-valent bond.
				This is how molecules are formed.
				Try bonding some more hydrogen atoms into H2 molecules.
				"""

	class BondOxygenLevel extends DiatomicLevel
		constructor: ->
			super
				atoms: [
					new Atom element:Oxygen, position: V(200, 100)
					new Atom element:Oxygen, position: V(400, 150)
				]
				instructions: """
				Oxygen atoms have six valence electrons, but they want to have eight.
				Make them share two electrons so they can both be happy.
				"""

	class BondMultilpeOxygenLevel extends DiatomicLevel
		constructor: ->
			super
				atoms: [
					new Atom element:Oxygen, position: V(200, 100)
					new Atom element:Oxygen, position: V(400, 150)
					new Atom element:Oxygen, position: V(300, 350)
					new Atom element:Oxygen, position: V(400, 250)
				]
				instructions: """
				Make some more O2 molecules.
				"""

	class CuttingLevel extends Level
		win_condition: ->
			@bonds.length is 0

	class CutHydrogenLevel extends CuttingLevel
		constructor: ->
			super
				molecules: [
					new HydrogenMolecule position: V(200,200)
				]
				instructions: """
				Swipe across a bond to break it.
				"""

	class CutThingsLevel extends CuttingLevel
		constructor: ->
			super
				molecules: [
					new HydrogenMolecule position: V(150,100)
					new HydrogenMolecule position: V(400,120)
					new OxygenMolecule position: V(100,250)
					new WaterMolecule position: V(300,300)
				]
				instructions: """
				Break all the bonds!
				"""

	class CutWaterLevel extends DiatomicLevel
		constructor: ->
			super
				molecules: [
					new WaterMolecule position: V(100,200)
					new WaterMolecule position: V(300,300)
				]
				instructions: """
				Here's some water, aka H2O.  Take it apart and turn it into H2 and O2 molecules.
				"""

	class MakeWaterLevel extends Level
		constructor: ->
			super
				molecules: [
					new HydrogenMolecule position: V(150,150)
					new HydrogenMolecule position: V(400,200)
					new OxygenMolecule position: V(200,400)
				]
				instructions: """
				Now make these molecules back into water again.
				"""

		win_condition: ->
			return @molecules_in_harmony() and @only_water_molecules()

		only_water_molecules: ->
			for molecule in @molecules
				return false unless molecule.length is 3
				proton_counts = (atom.element.proton_count for atom in molecule)
				proton_counts.sort()
				return false unless (
					proton_counts[0] is proton_counts[1] is 1 and
					proton_counts[2] is 8
				)
			return true

	class BondNitrogenLevel extends DiatomicLevel
		constructor: ->
			super
				atoms: [
					new Atom element:Nitrogen, position: V(200, 100)
					new Atom element:Nitrogen, position: V(400, 150)
				]
				instructions: """
				Nitrogen atoms have five valence electrons.  How many bonds will they need?
				"""

	class BondCarbonLevel extends Level
		constructor: ->
			super
				atoms: [
					new Atom element:Carbon, position: V(200, 100)
					new Atom element:Carbon, position: V(400, 150)
					new Atom element:Hydrogen, position: V(300, 350)
					new Atom element:Hydrogen, position: V(400, 250)
				]
				instructions: """
				Carbon atoms have four valence electrons.  That means you need four covalent bonds to make them happy, right?
				Unfortunately, quadruple bonds don't exist!  Use these Hydrogen atoms to pick up the slack.  
				"""

	class ThatsAllLevel extends Level
		constructor: ->
			super
				instructions: """That's all the levels in the demo!  In the full game you'll learn to create other compounds such as amino acids."""

		win_condition: -> false

	class Game
		constructor: ({@levels}) ->
			@node = $ """<div class="game"></div>"""

			@win_message = $ """<div>You win! </div>"""
			@node.append @win_message

			@advance_button = $ """<button>Next Level</button>"""
			@win_message.append @advance_button

			@advance_button.on 'click', => @advance()
			@advance_button.hide
			for level in @levels
				level.game = @

			@advance()

		advance: ->
			@win_message.hide()
			@current_level?.node.remove()
			@current_level = @levels.shift()
			@node.append @current_level.node
			setTimeout @current_level.update_bonds(), 0

		won_level: ->
			@win_message.show()

	game = new Game levels:[
		new BondHydrogenLevel
		new BondMultilpeHydrogenLevel
		new BondOxygenLevel
		new BondMultilpeOxygenLevel
		new CutHydrogenLevel
		new CutThingsLevel
		new CutWaterLevel
		new MakeWaterLevel
		new BondNitrogenLevel
		new BondCarbonLevel
		new ThatsAllLevel
	]

	window.addEventListener 'mouseup', ((event) -> game.current_level.stop_drag(event)), false
	window.addEventListener 'mousemove', ((event) -> game.current_level.drag(event)), false

	return game