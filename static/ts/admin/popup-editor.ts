/// <reference path="xhr.ts" />

module Shachi {
    class PopupEditor {
        container;
        closeButton;
        buttons;
        resourceId;
        currentElem;
        requesting;
        loadingElem;
        constructor(cssSelector: string, buttonSelector: string) {
            this.container = <HTMLElement>document.querySelector(cssSelector);
            if ( !this.container ) return;
            this.closeButton = <HTMLElement>this.container.querySelector('.close');
            this.buttons = this.container.querySelectorAll(buttonSelector);
            this.registerEvent();
            this.requesting = false;
            this.loadingElem = <HTMLElement>this.container.querySelector('.loading');
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
                        if ( this.requesting ) return;
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
        startRequest() {
            this.requesting = true;
            if ( this.loadingElem ) {
                this.loadingElem.style.display = 'block';
            }
        }
        completeRequest() {
            this.requesting = false;
            if ( this.loadingElem ) {
                this.loadingElem.style.display = 'none';
            }
            this.hide();
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
            this.startRequest();
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
            this.completeRequest();
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
            this.startRequest();
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
            this.completeRequest();
        }
    }

    export class AnnotatorPopupEditor extends PopupEditor {
        constructor(cssSelector: string, buttonSelector: string) {
            super(cssSelector, buttonSelector);
        }
        change(elem: HTMLElement) {
            var newAnnotatorId = elem.getAttribute('data-annotator-id');
            if ( ! this.resourceId || ! this.currentElem ||
                 this.currentElem.getAttribute('data-annotator-id') === newAnnotatorId ) {
                this.hide();
                return;
            }
            var self = this;
            this.startRequest();
            Shachi.XHR.request('POST', '/admin/resources/' + this.resourceId + '/annotator', {
                body: "annotator_id=" + newAnnotatorId,
                completeHandler: function (req) { self.complete(req) }
            });
        }
        complete(res) {
            try {
                var json = JSON.parse(res.responseText);
                var annotator = json.annotator;
                this.currentElem.setAttribute('data-annotator-id', annotator.id);
                this.currentElem.textContent = 'Annotator: ' + annotator.name;
            } catch (err) { /* ignore */ }
            this.completeRequest();
        }
    }
}
