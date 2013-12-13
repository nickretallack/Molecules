require.config
	paths:
		jquery: "../bower_components/jquery/jquery"
		bootstrapAffix: "../bower_components/sass-bootstrap/js/affix"
		bootstrapAlert: "../bower_components/sass-bootstrap/js/alert"
		bootstrapButton: "../bower_components/sass-bootstrap/js/button"
		bootstrapCarousel: "../bower_components/sass-bootstrap/js/carousel"
		bootstrapCollapse: "../bower_components/sass-bootstrap/js/collapse"
		bootstrapDropdown: "../bower_components/sass-bootstrap/js/dropdown"
		bootstrapPopover: "../bower_components/sass-bootstrap/js/popover"
		bootstrapScrollspy: "../bower_components/sass-bootstrap/js/scrollspy"
		bootstrapTab: "../bower_components/sass-bootstrap/js/tab"
		bootstrapTooltip: "../bower_components/sass-bootstrap/js/tooltip"
		bootstrapTransition: "../bower_components/sass-bootstrap/js/transition"
		underscore: "../bower_components/underscore/underscore"
		hand: "../bower_components/hand/hand-1.2.2"

	shim:
		hand:
			exports: "HANDJS"

		underscore:
			exports: '_'

		bootstrapAffix:
			deps: ["jquery"]

		bootstrapAlert:
			deps: ["jquery"]

		bootstrapButton:
			deps: ["jquery"]

		bootstrapCarousel:
			deps: ["jquery"]

		bootstrapCollapse:
			deps: ["jquery"]

		bootstrapDropdown:
			deps: ["jquery"]

		bootstrapPopover:
			deps: ["jquery"]

		bootstrapScrollspy:
			deps: ["jquery"]

		bootstrapTab:
			deps: ["jquery"]

		bootstrapTooltip:
			deps: ["jquery"]

		bootstrapTransition:
			deps: ["jquery"]

require ["app", "jquery"], (app, $) ->
	"use strict"
	
	$(document.body).append app.node
	setTimeout app.update(), 0

	# use app here
	console.log app
	console.log "Running jQuery %s", $().jquery
