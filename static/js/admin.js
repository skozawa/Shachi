"use strict";
class EditStatusEditor {
    constructor(cssSelector) {
        this.container = document.querySelector(cssSelector);
        if (!this.container)
            return;
        this.closeButton = this.container.querySelector('.close');
        this.statusButtons = this.container.querySelectorAll('li.edit-status');
        this.register();
    }
    register() {
        var self = this;
        if (this.closeButton) {
            this.closeButton.addEventListener('click', function () {
                self.hide();
            });
        }
        if (this.statusButtons) {
            Array.prototype.forEach.call(this.statusButtons, function (button) {
                button.addEventListener('click', function () {
                    self.changeEditStatus(button.getAttribute('data-edit-status'));
                });
            });
        }
    }
    changeEditStatus(newStatus) {
        this.hide();
    }
    showWithSet(resource, elem) {
        var rect = elem.getBoundingClientRect();
        this.container.style.top = (rect.top + 20) + 'px';
        this.container.style.left = rect.left + 'px';
        this.show();
    }
    show() {
        this.container.style.display = 'block';
    }
    hide() {
        this.container.style.display = 'none';
    }
}
document.addEventListener("DOMContentLoaded", function (event) {
    var editStatusEditor = new EditStatusEditor('.edit-status-editor');
    var resources = document.querySelectorAll('li.annotator-resource[data-id]');
    Array.prototype.forEach.call(resources, function (resource) {
        var editStatus = resource.querySelector('li.edit-status');
        if (editStatus) {
            editStatus.addEventListener('click', function () {
                editStatusEditor.showWithSet(resource, editStatus);
            });
        }
    });
});
