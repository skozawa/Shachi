"use strict";
module Shachi {
    export module XHR {
        export function request(method:string, url:string, options):XMLHttpRequest {
            var req = new XMLHttpRequest();
            req.onreadystatechange = function (evt) {
                if ( req.readyState == 4 ) {
                    if (req.status == 200) {
                        if (options.completeHandler) options.completeHandler(req);
                    } else {
                        if (options.errorHandler) options.errorHandler(req);
                    }
                }
            }
            req.open(method, url, true);
            if (method === 'POST' && 'body' in options)
                req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.send(('body' in options) ? options.body : null);
            return req;
        }
    }
}

module Shachi {
    class PopupEditor {
        container;
        closeButton;
        buttons;
        resourceId;
        currentElem;
        constructor(cssSelector: string, buttonSelector: string) {
            this.container = <HTMLElement>document.querySelector(cssSelector);
            if ( !this.container ) return;
            this.closeButton = <HTMLElement>this.container.querySelector('.close');
            this.buttons = this.container.querySelectorAll(buttonSelector);
            this.registerEvent();
        }
        registerEvent() {
            var self = this;
            if ( self.closeButton ) {
                self.closeButton.addEventListener('click', function () {
                    self.hide();
                });
            }
            if ( self.buttons ) {
                Array.prototype.forEach.call(self.buttons, function (button) {
                    button.addEventListener('click', function () {
                        self.change(button);
                    });
                });
            }
        }
        change(elem: HTMLElement) {}
        showWithSet(resource: HTMLElement, elem: HTMLElement) {
            this.resourceId = resource.getAttribute('data-resource-id');
            if ( ! this.resourceId ) {
                this.hide();
                return;
            }
            this.currentElem = elem;
            this.showAndMove(elem);
        }
        showAndMove(elem: HTMLElement) {
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

    export class StatusPopupEditor extends PopupEditor {
        constructor(cssSelector: string, buttonSelector: string) {
            super(cssSelector, buttonSelector);
        }
        change(elem: HTMLElement) {
            var newStatus = elem.getAttribute('data-status');
            if ( ! this.resourceId || ! this.currentElem || ! newStatus ||
                 this.currentElem.getAttribute('data-status') === newStatus ) {
                this.hide();
                return;
            }
            var self = this;
            Shachi.XHR.request('POST', '/admin/resources/' + this.resourceId + '/status', {
                body: 'status=' + newStatus,
                completeHandler: function (req) { self.complete(req) },
            });
        }
        complete(res) {
            try {
                var json = JSON.parse(res.responseText);
                var status = json.status;
                this.currentElem.setAttribute('data-status', status);
                var label = this.currentElem.querySelector('.label');
                label.textContent = status;
            } catch (err) { /* ignore */ }
            this.hide();
        }
    }

    export class EditStatusPopupEditor extends PopupEditor {
        constructor(cssSelector: string, buttonSelector: string) {
            super(cssSelector, buttonSelector);
        }
        change(elem: HTMLElement) {
            var newStatus = elem.getAttribute('data-edit-status');
            if ( ! this.resourceId || ! this.currentElem ||
                 this.currentElem.getAttribute('data-edit-status') === newStatus ) {
                this.hide();
                return;
            }
            var self = this;
            Shachi.XHR.request('POST', '/admin/resources/' + this.resourceId + '/edit_status', {
                body: "edit_status=" + newStatus,
                completeHandler: function (req) { self.complete(req) },
            });
        }
        complete(res) {
            try {
                var json = JSON.parse(res.responseText);
                var editStatus = json.edit_status;
                this.currentElem.setAttribute('data-edit-status', editStatus);
                var img = this.currentElem.querySelector('img');
                img.src = '/images/admin/' + editStatus + '.png';
            } catch (err) { /* ignore */ }
            this.hide();
        }
    }
}

module Shachi {
    export class ResourceListEditor {
        resource;
        statusEditor;
        editStatusEditor;
        constructor(resource: HTMLElement,
                    statusEditor: StatusPopupEditor,
                    editStatusEditor: EditStatusPopupEditor) {
            this.resource = resource;
            this.statusEditor = statusEditor;
            this.editStatusEditor = editStatusEditor;
            this.registerEvent();
        }
        registerEvent() {
            var self = this;
            var statusElem = this.resource.querySelector('li.status');
            if ( statusElem && this.statusEditor ) {
                statusElem.addEventListener('click', function () {
                    self.statusEditor.showWithSet(self.resource, statusElem);
                });
            }
            var editStatusElem = this.resource.querySelector('li.edit-status');
            if ( editStatusElem && this.editStatusEditor ) {
                editStatusElem.addEventListener('click', function () {
                    self.editStatusEditor.showWithSet(self.resource, editStatusElem);
                });
            }
        }
    }
}

document.addEventListener("DOMContentLoaded", function(event) {
    var statusEditor = new Shachi.StatusPopupEditor('.status-popup-editor', 'li.status');
    var editStatusEditor = new Shachi.EditStatusPopupEditor('.edit-status-popup-editor', 'li.edit-status');

    var resources = document.querySelectorAll('li.annotator-resource[data-resource-id]');
    Array.prototype.forEach.call(resources, function(resource) {
        new Shachi.ResourceListEditor(resource, statusEditor, editStatusEditor);
    });
});
