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
                req.setRequestHeader('Content-Type', options['content-type'] || 'application/x-www-form-urlencoded');
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
                completeHandler: function (req) { self.complete(req) },
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

module Shachi {
    export class ResourceEditor {
        container;
        metadataEditors;
        constructor(container: HTMLElement) {
            this.container = container;
            this.setup();
        }
        setup() {
            var self = this;
            self.metadataEditors = [];
            var metadataList = this.container.querySelectorAll('.resource-metadata');
            Array.prototype.forEach.call(metadataList, function(metadata) {
                self.metadataEditors.push(self.metadataEditor(metadata));
            });
            this.container.addEventListener('submit', function (evt) {
                evt.preventDefault();
                self.create();
                return false;
            });
        }
        metadataEditor(metadata: HTMLElement): ResourceMetadataEditorBase {
            var inputType = metadata.getAttribute('data-input-type') || '';
            if (inputType == 'textarea')    return new ResourceMetadataTextareaEditor(metadata);
            if (inputType == 'select')      return new ResourceMetadataSelectEditor(metadata);
            if (inputType == 'select_only') return new ResourceMetadataSelectOnlyEditor(metadata);
            if (inputType == 'relation')    return new ResourceMetadataRelationEditor(metadata);
            if (inputType == 'language')    return new ResourceMetadataLanguageEditor(metadata);
            if (inputType == 'date')        return new ResourceMetadataDateEditor(metadata);
            if (inputType == 'relation')    return new ResourceMetadataRangeEditor(metadata);
            return new ResourceMetadataTextEditor(metadata);
        }
        create() {
            var values = this.getValues();
            if (!values['annotator_id'] || values['annotator_id'] === '') {
                alert('Require Annotator');
                return;
            }
            if (!values['title'] || values['title'] === '') {
                alert('Require Title');
                return;
            }
            var self = this;
            Shachi.XHR.request('POST', '/admin/resources/create', {
                body: JSON.stringify(values),
                'content-type': 'application/json',
                completeHandler: function(req) { self.createComplete(req) },
            });
        }
        createComplete(res) {
            try {
                var json = JSON.parse(res.responseText);
                if ( json.resource_id ) {
                    location.href = '/admin/resources/' + json.resource_id;
                }
            } catch (err) {
                location.href = '/admin/';
            }
        }
        getValues() {
            var values = {};
            Array.prototype.forEach.call(this.metadataEditors, function(editor) {
                var metadataValues = editor.toValues();
                if ( metadataValues && metadataValues.length > 0 ) {
                    values[editor.name] = metadataValues;
                }
            });
            var annotator = this.container.querySelector('.annotator');
            values['annotator_id'] = annotator.value;
            var statuses = this.container.querySelectorAll('.resource-status input');
            Array.prototype.forEach.call(statuses, function(status) {
                if ( ! status.checked ) return;
                values['status'] = status.value;
            });
            return values;
        }
    }

    class ResourceMetadataEditorBase {
        container;
        name;
        constructor(container: HTMLElement) {
            this.container = container;
            this.name = container.getAttribute('data-name');
        }
        toValues() {
            var self = this;
            var items = this.container.querySelectorAll('li.resource-metadata-item');
            var values = [];
            Array.prototype.forEach.call(items, function(item) {
                var hash = self.toHash(item);
                if ( hash ) values.push(hash);
            });
            return values;
        }
        toHash(item: HTMLElement) {
            return undefined;
        }
        getDate(elem, prefix: string) {
            var year  = elem.querySelector('.' + prefix +'year');
            if (!year || year.value === '') return '';
            var month = elem.querySelector('.' + prefix + 'month');
            if (!month || month.value === '') return year.value + '-00-00';
            var ym = year.value + '-' + month.value;
            var day   = elem.querySelector('.' + prefix + 'day');
            if (!day || day.value === '') return ym + '-00';
            return ym + '-' + day.value;
        }
    }

    class ResourceMetadataTextEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var content = elem.querySelector('.content');
            if (!content || content.value === '') return undefined;
            return { content: content.value };
        }
    }

    class ResourceMetadataTextareaEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var content = elem.querySelector('.content');
            if (!content || content.value === '') return undefined;
            return { content: content.value };
        }
    }

    class ResourceMetadataSelectEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var select = elem.querySelector('select');
            var description = elem.querySelector('.description');
            var selectValue = select ? select.value : '';
            var descriptionValue = description ? description.value : '';
            if (selectValue === '' && descriptionValue === '') return undefined;
            return { value_id: selectValue, description: descriptionValue };
        }
    }

    class ResourceMetadataSelectOnlyEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var select = elem.querySelector('select');
            if (!select || select.value === '') return undefined;
            return { value_id: select.value };
        }
    }

    class ResourceMetadataRelationEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var select = elem.querySelector('select');
            var description = elem.querySelector('.description');
            var selectValue = select ? select.value : '';
            var descriptionValue = description ? description.value : '';
            if (selectValue === '' && descriptionValue === '') return undefined;
            return { value_id: selectValue, description: descriptionValue };
        }
    }

    class ResourceMetadataLanguageEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var content = elem.querySelector('.content');
            var description = elem.querySelector('.description');
            var contentValue = content ? content.value : '';
            var descriptionValue = description ? description.value : '';
            if (contentValue === '' && descriptionValue === '') return undefined;
            return { content: contentValue, description: descriptionValue };
        }
    }

    class ResourceMetadataDateEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var date = this.getDate(elem, '');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.value : '';
            if (date === '' && descriptionValue === '') return undefined;
            return { content: date, description: descriptionValue };
        }
    }

    class ResourceMetadataRangeEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var fromDate = this.getDate(elem, 'from-');
            var toDate = this.getDate(elem, 'to-');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.value : '';
            if (fromDate === '' && toDate === '' && descriptionValue === '') return undefined;
            var defaultDate = '0000-00-00';
            var date = (fromDate === '' ? defaultDate : fromDate) + ' ' +
                (toDate === '' ? defaultDate : toDate);
            return { content: date, description: descriptionValue };
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


    var form = <HTMLElement>document.querySelector('#resource-create-form');
    if (form) {
        var editor = new Shachi.ResourceEditor(form);
    }
});
