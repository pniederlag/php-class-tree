var __hasProp = {}.hasOwnProperty,
	__extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	$ = require('atom-space-pen-views').$,
	ClassView = require('./class-view'),
	ScrollView = require('atom-space-pen-views').ScrollView;

module.exports = TreeView = (function (parent) {
	__extends(TreeView, parent);

	var phpClassTree;

	function TreeView (arguments) {
		phpClassTree = arguments
		TreeView.__super__.constructor.apply(this, arguments);
	}

	TreeView.content = function () {
		return this.div({
			'class': 'php-class-tree-view tree-view-resizer tool-panel',
			'data-show-on-right-side': atom.config.get('php-class-tree.displayOnRight')
		}, function () {
			this.div({
				'class': 'scroller',
				'outlet': 'scroller'
			}, function () {
				this.ol({
					'class': 'full-menu list-tree has-collapsable-children focusable-panel',
					'tabindex': -1,
					'outlet': 'list'
				})
			}.bind(this));
			this.div({
				'class': 'resize-handle',
				'outlet': 'horizontalResize'
			});
			this.div({
				'class': 'queue tool-panel panel-bottom',
				'tabindex': -1,
				'outlet': 'queue'
			}, function () {
				return this.div({
					'class': 'resize-handle',
					'outlet': 'verticalResize'
				})
			}.bind(this));
			this.div({
				'class': 'contents',
				'tabindex': -1,
				'outlet': 'contents'
			});
		}.bind(this));
	}

	TreeView.prototype.initialize = function (state) {
		TreeView.__super__.initialize.apply(this, arguments);

		var self = this;

		self.list.show();

		for (var i = 0; i < phpClassTree.length; i++) {
			var element = new ClassView(phpClassTree[i]);
			self.list.append(element);
		}

		// Events
		atom.config.onDidChange('php-class-tree.displayOnRight', function () {
			if (self.isVisible()) {
				setTimeout(function () {
					self.detach();
					self.attach();
				}, 1)
			}
		});

		self.contents.on('click', '[role="toggle"]', function (e) {
			self.toggle();
		});

		self.horizontalResize.on('dblclick', function (e) { self.resizeToFitContent(e); });
		self.horizontalResize.on('mousedown', function (e) { self.resizeHorizontalStarted(e); });
		self.verticalResize.on('mousedown', function (e) { self.resizeVerticalStarted(e); });
	};

	TreeView.prototype.attach = function () {
		if (atom.config.get('php-class-tree.displayOnRight')) {
			this.panel = atom.workspace.addRightPanel({item: this});
		} else {
			this.panel = atom.workspace.addLeftPanel({item: this});
		}
	}

	TreeView.prototype.detach = function () {
		TreeView.__super__.detach.apply(this, arguments);

		if (this.panel) {
			this.panel.destroy();
			this.panel = null;
		}
	}

	TreeView.prototype.toggle = function () {
		if (this.isVisible()) {
			this.detach();
			return false;
		} else {
			this.attach();
			return true;
		}
	}

	TreeView.prototype.resolve = function (path) {
		var view = $('.php-class-tree-view [data-path="'+ path +'"]').map(function () {
				var v = $(this).view();
				return v ? v : null
			}).get(0);

		return view;
	}

	TreeView.prototype.getSelected = function () {
		var views = $('.php-class-tree-view .selected').map(function () {
				var v = $(this).view();
				return v ? v : null
			}).get();

		return views;
	}

	TreeView.prototype.resizeVerticalStarted = function (e) {
		e.preventDefault();

		this.resizeHeightStart = this.queue.height();
		this.resizeMouseStart = e.pageY;
		$(document).on('mousemove', this.resizeVerticalView.bind(this));
		$(document).on('mouseup', this.resizeVerticalStopped);
	}

	TreeView.prototype.resizeVerticalStopped = function () {
		delete this.resizeHeightStart;
		delete this.resizeMouseStart;
		$(document).off('mousemove', this.resizeVerticalView);
		$(document).off('mouseup', this.resizeVerticalStopped);
	}

	TreeView.prototype.resizeVerticalView = function (e) {
		if (e.which !== 1)
			return this.resizeStopped();

		var delta = e.pageY - this.resizeMouseStart,
			height = Math.max(26, this.resizeHeightStart - delta);

		this.queue.height(height);
		this.scroller.css('bottom', height + 'px');
	}

	TreeView.prototype.resizeHorizontalStarted = function (e) {
		e.preventDefault();

		this.resizeWidthStart = this.width();
		this.resizeMouseStart = e.pageX;
		$(document).on('mousemove', this.resizeHorizontalView.bind(this));
		$(document).on('mouseup', this.resizeHorizontalStopped);
	}

	TreeView.prototype.resizeHorizontalStopped = function () {
		delete this.resizeWidthStart;
		delete this.resizeMouseStart;
		$(document).off('mousemove', this.resizeHorizontalView);
		$(document).off('mouseup', this.resizeHorizontalStopped);
	}

	TreeView.prototype.resizeHorizontalView = function (e) {
		if (e.which !== 1)
			return this.resizeStopped();

		var delta = e.pageX - this.resizeMouseStart,
			width = Math.max(50, this.resizeWidthStart + delta);

		this.width(width);
	}

	TreeView.prototype.resizeToFitContent = function (e) {
		e.preventDefault();

		this.width(1);
		// 25px for extend or implement icon width
		this.width(this.list.outerWidth() + 25);
	}

	return TreeView;

})(ScrollView)
