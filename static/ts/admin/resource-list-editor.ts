/// <reference path="xhr.ts" />

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
            var deleteButton = this.resource.querySelector('li.delete');
            if ( deleteButton ) {
                deleteButton.addEventListener('click', function () {
                    self.delete();
                });
            }
        }
        delete() {
            var resourceId = this.resource.getAttribute('data-resource-id');
            var titleElem = this.resource.querySelector('li.title');
            var message = 'Delete "' + (titleElem ? titleElem.textContent : resourceId) + '" ?';
            if ( ! window.confirm(message) ) {
                return;
            }
            var self = this;
            Shachi.XHR.request('DELETE', '/admin/resources/' + resourceId, {
                'content-type': 'application/json',
                completeHandler: function (req) { self.complete(req) }
            });
        }
        complete(res) {
            try {
                var json = JSON.parse(res.responseText);
                if ( json.success ) {
                    this.resource.parentNode.removeChild(this.resource);
                }
            } catch (err) { /* ignore */ }
        }
    }
}
