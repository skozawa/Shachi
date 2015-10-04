"use strict";
var Shachi;
(function (Shachi) {
    var XHR;
    (function (XHR) {
        function request(method, url, options) {
            var req = new XMLHttpRequest();
            req.onreadystatechange = function (evt) {
                if (req.readyState == 4) {
                    if (req.status == 200) {
                        if (options.completeHandler)
                            options.completeHandler(req);
                    }
                    else {
                        if (options.errorHandler)
                            options.errorHandler(req);
                    }
                }
            };
            req.open(method, url, true);
            if (method === 'POST' && 'body' in options)
                req.setRequestHeader('Content-Type', options['content-type'] || 'application/x-www-form-urlencoded');
            req.send(('body' in options) ? options.body : null);
            return req;
        }
        XHR.request = request;
    })(XHR = Shachi.XHR || (Shachi.XHR = {}));
})(Shachi || (Shachi = {}));
var Shachi;
(function (Shachi) {
    class PopupEditor {
        constructor(cssSelector, buttonSelector) {
            this.container = document.querySelector(cssSelector);
            if (!this.container)
                return;
            this.closeButton = this.container.querySelector('.close');
            this.buttons = this.container.querySelectorAll(buttonSelector);
            this.registerEvent();
        }
        registerEvent() {
            var self = this;
            if (self.closeButton) {
                self.closeButton.addEventListener('click', function () {
                    self.hide();
                });
            }
            if (self.buttons) {
                Array.prototype.forEach.call(self.buttons, function (button) {
                    button.addEventListener('click', function () {
                        self.change(button);
                    });
                });
            }
        }
        change(elem) { }
        showWithSet(resource, elem) {
            this.resourceId = resource.getAttribute('data-resource-id');
            if (!this.resourceId) {
                this.hide();
                return;
            }
            this.currentElem = elem;
            this.showAndMove(elem);
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
    class StatusPopupEditor extends PopupEditor {
        constructor(cssSelector, buttonSelector) {
            super(cssSelector, buttonSelector);
        }
        change(elem) {
            var newStatus = elem.getAttribute('data-status');
            if (!this.resourceId || !this.currentElem || !newStatus ||
                this.currentElem.getAttribute('data-status') === newStatus) {
                this.hide();
                return;
            }
            var self = this;
            Shachi.XHR.request('POST', '/admin/resources/' + this.resourceId + '/status', {
                body: 'status=' + newStatus,
                completeHandler: function (req) { self.complete(req); },
            });
        }
        complete(res) {
            try {
                var json = JSON.parse(res.responseText);
                var status = json.status;
                this.currentElem.setAttribute('data-status', status);
                var label = this.currentElem.querySelector('.label');
                label.textContent = status;
            }
            catch (err) { }
            this.hide();
        }
    }
    Shachi.StatusPopupEditor = StatusPopupEditor;
    class EditStatusPopupEditor extends PopupEditor {
        constructor(cssSelector, buttonSelector) {
            super(cssSelector, buttonSelector);
        }
        change(elem) {
            var newStatus = elem.getAttribute('data-edit-status');
            if (!this.resourceId || !this.currentElem ||
                this.currentElem.getAttribute('data-edit-status') === newStatus) {
                this.hide();
                return;
            }
            var self = this;
            Shachi.XHR.request('POST', '/admin/resources/' + this.resourceId + '/edit_status', {
                body: "edit_status=" + newStatus,
                completeHandler: function (req) { self.complete(req); },
            });
        }
        complete(res) {
            try {
                var json = JSON.parse(res.responseText);
                var editStatus = json.edit_status;
                this.currentElem.setAttribute('data-edit-status', editStatus);
                var img = this.currentElem.querySelector('img');
                img.src = '/images/admin/' + editStatus + '.png';
            }
            catch (err) { }
            this.hide();
        }
    }
    Shachi.EditStatusPopupEditor = EditStatusPopupEditor;
})(Shachi || (Shachi = {}));
var Shachi;
(function (Shachi) {
    class ResourceListEditor {
        constructor(resource, statusEditor, editStatusEditor) {
            this.resource = resource;
            this.statusEditor = statusEditor;
            this.editStatusEditor = editStatusEditor;
            this.registerEvent();
        }
        registerEvent() {
            var self = this;
            var statusElem = this.resource.querySelector('li.status');
            if (statusElem && this.statusEditor) {
                statusElem.addEventListener('click', function () {
                    self.statusEditor.showWithSet(self.resource, statusElem);
                });
            }
            var editStatusElem = this.resource.querySelector('li.edit-status');
            if (editStatusElem && this.editStatusEditor) {
                editStatusElem.addEventListener('click', function () {
                    self.editStatusEditor.showWithSet(self.resource, editStatusElem);
                });
            }
            var deleteButton = this.resource.querySelector('li.delete');
            if (deleteButton) {
                deleteButton.addEventListener('click', function () {
                    self.delete();
                });
            }
        }
        delete() {
            var resourceId = this.resource.getAttribute('data-resource-id');
            var titleElem = this.resource.querySelector('li.title');
            var message = 'Delete "' + (titleElem ? titleElem.textContent : resourceId) + '" ?';
            if (!window.confirm(message)) {
                return;
            }
            var self = this;
            Shachi.XHR.request('DELETE', '/admin/resources/' + resourceId, {
                completeHandler: function (req) { self.complete(req); },
            });
        }
        complete(res) {
            try {
                var json = JSON.parse(res.responseText);
                if (json.success) {
                    this.resource.parentNode.removeChild(this.resource);
                }
            }
            catch (err) { }
        }
    }
    Shachi.ResourceListEditor = ResourceListEditor;
})(Shachi || (Shachi = {}));
var Shachi;
(function (Shachi) {
    class ResourceEditor {
        constructor(container) {
            this.container = container;
            this.setup();
        }
        setup() {
            var self = this;
            self.metadataEditors = [];
            var metadataList = this.container.querySelectorAll('.resource-metadata');
            Array.prototype.forEach.call(metadataList, function (metadata) {
                self.metadataEditors.push(self.metadataEditor(metadata));
            });
            this.container.addEventListener('submit', function (evt) {
                evt.preventDefault();
                self.create(evt);
                return false;
            });
        }
        metadataEditor(metadata) {
            var inputType = metadata.getAttribute('data-input-type') || '';
            if (inputType == 'textarea')
                return new ResourceMetadataTextareaEditor(metadata);
            if (inputType == 'select')
                return new ResourceMetadataSelectEditor(metadata);
            if (inputType == 'select_only')
                return new ResourceMetadataSelectOnlyEditor(metadata);
            if (inputType == 'relation')
                return new ResourceMetadataRelationEditor(metadata);
            if (inputType == 'language')
                return new ResourceMetadataLanguageEditor(metadata);
            if (inputType == 'date')
                return new ResourceMetadataDateEditor(metadata);
            if (inputType == 'relation')
                return new ResourceMetadataRangeEditor(metadata);
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
            Shachi.XHR.request('POST', '/admin/resources/create', {
                body: JSON.stringify(values),
                'content-type': 'application/json',
                completeHandler: function (req) { self.createComplete(req); },
            });
        }
        createComplete(res) {
            console.log("created");
        }
        getValues() {
            var values = {};
            Array.prototype.forEach.call(this.metadataEditors, function (editor) {
                var metadataValues = editor.toValues();
                if (metadataValues && metadataValues.length > 0) {
                    values[editor.name] = metadataValues;
                }
            });
            var annotator = this.container.querySelector('.annotator');
            values['annotator_id'] = annotator.value;
            var statuses = this.container.querySelectorAll('.resource-status input');
            Array.prototype.forEach.call(statuses, function (status) {
                if (!status.checked)
                    return;
                values['status'] = status.value;
            });
            return values;
        }
    }
    Shachi.ResourceEditor = ResourceEditor;
    class ResourceMetadataEditorBase {
        constructor(container) {
            this.container = container;
            this.name = container.getAttribute('data-name');
        }
        toValues() {
            var self = this;
            var items = this.container.querySelectorAll('li.resource-metadata-item');
            var values = [];
            Array.prototype.forEach.call(items, function (item) {
                var hash = self.toHash(item);
                if (hash)
                    values.push(hash);
            });
            return values;
        }
        toHash(item) {
            return undefined;
        }
        getDate(prefix) {
            var year = this.container.querySelector('.' + prefix + 'year');
            if (!year || year.value === '')
                return '';
            var month = this.container.querySelector('.' + prefix + 'month');
            if (!month || month.value === '')
                return year.value + '-00-00';
            var ym = year.value + '-' + month.value;
            var day = this.container.querySelector('.' + prefix + 'day');
            if (!day || day.value === '')
                return ym + '-00';
            return ym + '-' + day.value;
        }
    }
    class ResourceMetadataTextEditor extends ResourceMetadataEditorBase {
        toHash() {
            var content = this.container.querySelector('.content');
            if (!content || content.value === '')
                return undefined;
            return { content: content.value };
        }
    }
    class ResourceMetadataTextareaEditor extends ResourceMetadataEditorBase {
        toHash() {
            var content = this.container.querySelector('.content');
            if (!content || content.value === '')
                return undefined;
            return { content: content.value };
        }
    }
    class ResourceMetadataSelectEditor extends ResourceMetadataEditorBase {
        toHash() {
            var select = this.container.querySelector('select');
            var description = this.container.querySelector('.description');
            var selectValue = select ? select.value : '';
            var descriptionValue = description ? description.value : '';
            if (selectValue === '' && descriptionValue === '')
                return undefined;
            return { value_id: selectValue, description: descriptionValue };
        }
    }
    class ResourceMetadataSelectOnlyEditor extends ResourceMetadataEditorBase {
        toHash() {
            var select = this.container.querySelector('select');
            if (!select || select.value === '')
                return undefined;
            return { value_id: select.value };
        }
    }
    class ResourceMetadataRelationEditor extends ResourceMetadataEditorBase {
        toHash() {
            var select = this.container.querySelector('select');
            var description = this.container.querySelector('.description');
            var selectValue = select ? select.value : '';
            var descriptionValue = description ? description.value : '';
            if (selectValue === '' && descriptionValue === '')
                return undefined;
            return { value_id: selectValue, description: descriptionValue };
        }
    }
    class ResourceMetadataLanguageEditor extends ResourceMetadataEditorBase {
        toHash() {
            var content = this.container.querySelector('.content');
            var description = this.container.querySelector('.description');
            var contentValue = content ? content.value : '';
            var descriptionValue = description ? description.value : '';
            if (contentValue === '' && descriptionValue === '')
                return undefined;
            return { content: contentValue, description: descriptionValue };
        }
    }
    class ResourceMetadataDateEditor extends ResourceMetadataEditorBase {
        toHash() {
            var date = this.getDate('');
            var description = this.container.querySelector('.description');
            var descriptionValue = description ? description.value : '';
            if (date === '' && descriptionValue === '')
                return undefined;
            return { content: date, description: descriptionValue };
        }
    }
    class ResourceMetadataRangeEditor extends ResourceMetadataEditorBase {
        toHash() {
            var fromDate = this.getDate('from-');
            var toDate = this.getDate('to-');
            var description = this.container.querySelector('.description');
            var descriptionValue = description ? description.value : '';
            if (fromDate === '' && toDate === '' && descriptionValue === '')
                return undefined;
            var defaultDate = '0000-00-00';
            var date = (fromDate === '' ? defaultDate : fromDate) + ' ' +
                (toDate === '' ? defaultDate : toDate);
            return { content: date, description: descriptionValue };
        }
    }
})(Shachi || (Shachi = {}));
document.addEventListener("DOMContentLoaded", function (event) {
    var statusEditor = new Shachi.StatusPopupEditor('.status-popup-editor', 'li.status');
    var editStatusEditor = new Shachi.EditStatusPopupEditor('.edit-status-popup-editor', 'li.edit-status');
    var resources = document.querySelectorAll('li.annotator-resource[data-resource-id]');
    Array.prototype.forEach.call(resources, function (resource) {
        new Shachi.ResourceListEditor(resource, statusEditor, editStatusEditor);
    });
    var form = document.querySelector('#resource-create-form');
    var editor = new Shachi.ResourceEditor(form);
});
