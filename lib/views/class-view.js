var __hasProp = {}.hasOwnProperty,
	__extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	$ = require('atom-space-pen-views').$,
	View = require('atom-space-pen-views').View;

module.exports = ClassView = (function (parent) {

	__extends(ClassView, parent);

	function ClassView () {
		ClassView.__super__.constructor.apply(this, arguments);
	}

	ClassView.content = function () {
		return this.li({
			'class': 'directory entry list-nested-item collapsed'
		}, function () {
			this.div({
				'class': 'header list-item',
				'outlet': 'header'
			}, function () {
				return this.span({
					'class': 'name icon',
					'outlet': 'name'
				})
			}.bind(this));
			this.ol({
				'class': 'entries list-tree',
				'outlet': 'entries'
			});
		}.bind(this));
	};

	ClassView.prototype.initialize = function (phpClassTree) {
		var self = this;

		self.item = phpClassTree;
		self.name.text(self.item.name);

		self.name.addClass('tree-badges');
		for (var i = 0; i < self.item.icons.length; i++) {
			self.name.addClass(self.item.icons[i]);
		}

		if (self.item.isExpanded || self.item.isRoot)
			self.expand();

		self.setClasses();
		self.repaint();

		// Events
		self.on('click', function (e) {
			e.stopPropagation();

			if (!self.item.isExpanded) {
				self.expand();
			}
			else {
				self.collapse();
			}
			self.setClasses();
		});

		self.on('dblclick', function (e) {
			e.stopPropagation();

			var view = $(this).view();
			if (!view)
				return;

			view.setLine();
		});

		// Remove arrow from arguments
		if (self.item.icons[0] == 'icon-argument') {
			self.removeClass('list-nested-item');
			self.addClass('list-item');
		}
	}

	ClassView.prototype.repaint = function (recursive) {
		var self = this,
			views = self.entries.children().map(function () { return $(this).view(); }).get(),
			items = [];

		self.entries.children().detach();

		if (self.item.type == 'class' || self.item.type == 'interface') {
			if (self.item.methods.length == 0) {
				self.removeClass('list-nested-item');
				self.addClass('list-item');
			}

			self.item.methods.forEach(function(method){
				items.push(new ClassView(method));
			});
		}

		if (self.item.hasOwnProperty('isStatic')) {
			if (self.item.arguments.length == 0) {
				self.removeClass('list-nested-item');
				self.addClass('list-item');
			}

			self.item.arguments.forEach(function(argument){
				items.push(new ClassView(argument));
			});
		}

		views = items;

		views.forEach(function (view) {
			self.entries.append(view);
		});
	}

	ClassView.prototype.setClasses = function () {
		if (this.item.isExpanded) {
			this.addClass('expanded').removeClass('collapsed');
		}
		else {
			this.addClass('collapsed').removeClass('expanded');
		}
	}

	ClassView.prototype.expand = function (recursive) {
		this.item.isExpanded = true;

		if (recursive) {
			this.entries.children().each(function () {
				var view = $(this).view();
				if (view && view instanceof ClassView)
					view.expand(true);
			});
		}
	}

	ClassView.prototype.collapse = function (recursive) {
		this.item.isExpanded = false;

		if (recursive) {
			this.entries.children().each(function () {
				var view = $(this).view();
				if (view && view instanceof ClassView)
					view.collapse(true);
			});
		}
	}

	ClassView.prototype.toggle = function (recursive) {
		if (this.item.isExpanded)
			this.collapse(recursive);
		else
			this.expand(recursive);
	}

	ClassView.prototype.setLine = function () {
		var editor = atom.workspace.getActiveTextEditor();
		editor.setCursorBufferPosition(this.item.point);
		editor.scrollToCursorPosition({center: true});
	}

	return ClassView;

})(View);
