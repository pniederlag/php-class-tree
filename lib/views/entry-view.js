var __hasProp = {}.hasOwnProperty,
	__extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	$ = require('atom').$,
	View = require('atom').View;

module.exports = EntryView = (function (parent) {

	__extends(EntryView, parent);

	function EntryView (file) {
		EntryView.__super__.constructor.apply(this, arguments);
	}

	EntryView.content = function () {
		return this.li({
			'class': 'file entry list-item'
		}, function () {
			return this.span({
				'class': 'name icon',
				'outlet': 'name'
			});
		}.bind(this));
	};

	EntryView.prototype.initialize = function (file) {
		var self = this;

		self.item = file;
		self.name.text(self.item.name);
		self.name.attr('data-name', self.item.name);
		self.name.attr('data-path', self.item.remote);

		switch (self.item.type) {
			case 'binary':		self.name.addClass('icon-file-binary'); break;
			case 'compressed':	self.name.addClass('icon-file-zip'); break;
			case 'image':		self.name.addClass('icon-file-media'); break;
			case 'pdf':			self.name.addClass('icon-file-pdf'); break;
			case 'readme':		self.name.addClass('icon-book'); break;
			case 'text':		self.name.addClass('icon-file-text'); break;
		}

		// Events
		self.on('mousedown', function (e) {
			e.stopPropagation();

			var view = $(this).view(),
				button = e.originalEvent ? e.originalEvent.button : 0;

			if (!view)
				return;

			switch (button) {
				case 2:
					if (view.is('.selected'))
						return;
				default:
					if (!e.ctrlKey)
						$('.php-class-tree-view .selected').removeClass('selected');
					view.toggleClass('selected');
			}
		});
		self.on('dblclick', function (e) {
			e.stopPropagation();

			var view = $(this).view();
			if (!view)
				return;

			view.open();
		});
	}

	EntryView.prototype.destroy = function () {
		this.item = null;

		this.remove();
	}

	EntryView.prototype.open = function () {
		this.item.open();
	}

	return EntryView;

})(View);
