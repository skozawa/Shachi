"use strict";
var Shachi;
(function (Shachi) {
    class PopupEditor {
        constructor(cssSelector) {
            this.container = document.querySelector(cssSelector);
            if (!this.container)
                return;
            this.closeButton = this.container.querySelector('.close');
            this.registerEvent();
        }
        registerEvent() {
            var self = this;
            if (self.closeButton) {
                self.closeButton.addEventListener('click', function () {
                    self.hide();
                });
            }
        }
        showAndMove(elem) {
            this.container.style.top = (elem.offsetTop + 20) + 'px';
            this.container.style.left = elem.offsetLeft + 'px';
            this.show();
        }
        show() {
            this.container.style.display = 'block';
        }
        hide() {
            this.container.style.display = 'none';
        }
    }
    class EditStatusPopupEditor extends PopupEditor {
        constructor(cssSelector) {
            super(cssSelector);
            if (!this.container)
                return;
            this.statusButtons = this.container.querySelectorAll('li.edit-status');
            this.register();
        }
        register() {
            var self = this;
            if (this.statusButtons) {
                Array.prototype.forEach.call(this.statusButtons, function (button) {
                    button.addEventListener('click', function () {
                        self.changeEditStatus(button.getAttribute('data-edit-status'));
                    });
                });
            }
        }
        changeEditStatus(newStatus) {
            console.log(newStatus);
            this.hide();
        }
        showWithSet(resource, elem) {
            super.showAndMove(elem);
        }
    }
    Shachi.EditStatusPopupEditor = EditStatusPopupEditor;
})(Shachi || (Shachi = {}));
document.addEventListener("DOMContentLoaded", function (event) {
    var editStatusEditor = new Shachi.EditStatusPopupEditor('.edit-status-editor');
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
