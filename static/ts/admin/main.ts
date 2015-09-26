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
        constructor(cssSelector: string) {
            this.container = <HTMLElement>document.querySelector(cssSelector);
            if ( !this.container ) return;
            this.closeButton = <HTMLElement>this.container.querySelector('.close');
            this.registerEvent();
        }
        registerEvent() {
            var self = this;
            if ( self.closeButton ) {
                self.closeButton.addEventListener('click', function () {
                    self.hide();
                });
            }
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

    export class EditStatusPopupEditor extends PopupEditor {
        statusButtons;
        resourceId;
        currentElem;
        constructor(cssSelector: string) {
            super(cssSelector);
            if ( !this.container ) return;
            this.statusButtons = this.container.querySelectorAll('li.edit-status');
            this.register();
        }
        register() {
            var self = this;
            if ( this.statusButtons ) {
                Array.prototype.forEach.call(this.statusButtons, function (button) {
                    button.addEventListener('click', function () {
                        self.changeEditStatus(button.getAttribute('data-edit-status'));
                    });
                });
            }
        }
        showWithSet(resource: HTMLElement, elem: HTMLElement) {
            this.resourceId = resource.getAttribute('data-resource-id');
            if ( ! this.resourceId ) {
                this.hide();
                return;
            }
            this.currentElem = elem;
            super.showAndMove(elem);
        }
        changeEditStatus(newStatus) {
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

document.addEventListener("DOMContentLoaded", function(event) {
    var editStatusEditor = new Shachi.EditStatusPopupEditor('.edit-status-editor');

    var resources = document.querySelectorAll('li.annotator-resource[data-resource-id]');
    Array.prototype.forEach.call(resources, function(resource) {
        var editStatus= resource.querySelector('li.edit-status');
        if ( editStatus ) {
            editStatus.addEventListener('click', function () {
                 editStatusEditor.showWithSet(resource, editStatus);
            });
        }
    });
});
