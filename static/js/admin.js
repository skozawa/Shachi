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
                self.create();
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
            var self = this;
            Shachi.XHR.request('POST', '/admin/resources/create', {
                body: JSON.stringify(values),
                'content-type': 'application/json',
                completeHandler: function (req) { self.createComplete(req); },
            });
        }
        createComplete(res) {
            try {
                var json = JSON.parse(res.responseText);
                if (json.resource_id) {
                    location.href = '/admin/resources/' + json.resource_id;
                }
            }
            catch (err) {
                location.href = '/admin/';
            }
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
            this.listSelector = 'li.resource-metadata-item';
            this.setup();
        }
        setup() {
            var self = this;
            var addButton = this.container.querySelector('.btn.add');
            if (addButton) {
                addButton.addEventListener('click', function () {
                    self.addItem();
                });
            }
            var deleteButton = this.container.querySelector('.btn.delete');
            if (deleteButton) {
                deleteButton.addEventListener('click', function () {
                    self.deleteItem();
                });
            }
        }
        addItem() {
            var item = this.container.querySelector(this.listSelector);
            var newItem = item.cloneNode(true);
            Array.prototype.forEach.call(newItem.querySelectorAll('input, textarea'), function (elem) {
                elem.value = "";
            });
            item.parentNode.appendChild(newItem);
            return newItem;
        }
        deleteItem() {
            var items = this.container.querySelectorAll(this.listSelector);
            if (items.length < 2)
                return;
            var removeItem = items[items.length - 1];
            removeItem.parentNode.removeChild(removeItem);
        }
        toValues() {
            var self = this;
            var items = this.container.querySelectorAll(this.listSelector);
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
        getDate(elem, prefix) {
            var year = elem.querySelector('.' + prefix + 'year');
            if (!year || year.value === '')
                return '';
            var month = elem.querySelector('.' + prefix + 'month');
            if (!month || month.value === '')
                return year.value + '-00-00';
            var ym = year.value + '-' + month.value;
            var day = elem.querySelector('.' + prefix + 'day');
            if (!day || day.value === '')
                return ym + '-00';
            return ym + '-' + day.value;
        }
    }
    class ResourceMetadataTextEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var content = elem.querySelector('.content');
            if (!content || content.value === '')
                return undefined;
            return { content: content.value };
        }
    }
    class ResourceMetadataTextareaEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var content = elem.querySelector('.content');
            if (!content || content.value === '')
                return undefined;
            return { content: content.value };
        }
    }
    class ResourceMetadataSelectEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var select = elem.querySelector('select');
            var description = elem.querySelector('.description');
            var selectValue = select ? select.value : '';
            var descriptionValue = description ? description.value : '';
            if (selectValue === '' && descriptionValue === '')
                return undefined;
            return { value_id: selectValue, description: descriptionValue };
        }
    }
    class ResourceMetadataSelectOnlyEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var select = elem.querySelector('select');
            if (!select || select.value === '')
                return undefined;
            return { value_id: select.value };
        }
    }
    class ResourceMetadataRelationEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var select = elem.querySelector('select');
            var description = elem.querySelector('.description');
            var selectValue = select ? select.value : '';
            var descriptionValue = description ? description.value : '';
            if (selectValue === '' && descriptionValue === '')
                return undefined;
            return { value_id: selectValue, description: descriptionValue };
        }
    }
    class ResourceMetadataLanguageEditor extends ResourceMetadataEditorBase {
        constructor(container) {
            super(container);
            this.currentQuery = '';
            this.enableRequest = true;
        }
        setup() {
            super.setup();
            var items = this.container.querySelectorAll(this.listSelector + ' .content');
            var self = this;
            var popup = this.container.querySelector('.language-popup-selector');
            if (popup) {
                this.popupSelector = new LanguagePopupSelector(popup);
            }
            Array.prototype.forEach.call(items, function (item) {
                self.registerEvent(item);
            });
        }
        registerEvent(item) {
            var self = this;
            item.addEventListener('keyup', function () { self.changeLanguage(item); });
            if (self.popupSelector) {
                item.addEventListener('blur', function () {
                    setTimeout(function () {
                        self.popupSelector.hide();
                    }, 200);
                });
            }
        }
        addItem() {
            var newItem = super.addItem();
            var item = newItem.querySelector('.content');
            this.registerEvent(item);
        }
        changeLanguage(elem) {
            var query = elem.value;
            if (query.length < 3) {
                this.popupSelector.hide();
                return;
            }
            if (!this.enableRequest)
                return;
            if (this.currentQuery === query) {
                this.popupSelector.show();
                return;
            }
            var self = this;
            this.enableRequest = false;
            Shachi.XHR.request('GET', '/admin/languages/search?query=' + query, {
                completeHandler: function (req) { self.complete(req, elem); }
            });
        }
        complete(res, elem) {
            try {
                var json = JSON.parse(res.responseText);
                if (json.languages) {
                    this.popup(elem, json.languages);
                }
            }
            catch (err) { }
            this.enableRequest = true;
        }
        popup(elem, languages) {
            this.popupSelector.replace(languages);
            this.popupSelector.showAndMove(elem);
        }
        toHash(elem) {
            var content = elem.querySelector('.content');
            var description = elem.querySelector('.description');
            var contentValue = content ? content.value : '';
            var descriptionValue = description ? description.value : '';
            if (contentValue === '' && descriptionValue === '')
                return undefined;
            return { content: contentValue, description: descriptionValue };
        }
    }
    class ResourceMetadataDateEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var date = this.getDate(elem, '');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.value : '';
            if (date === '' && descriptionValue === '')
                return undefined;
            return { content: date, description: descriptionValue };
        }
    }
    class ResourceMetadataRangeEditor extends ResourceMetadataEditorBase {
        toHash(elem) {
            var fromDate = this.getDate(elem, 'from-');
            var toDate = this.getDate(elem, 'to-');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.value : '';
            if (fromDate === '' && toDate === '' && descriptionValue === '')
                return undefined;
            var defaultDate = '0000-00-00';
            var date = (fromDate === '' ? defaultDate : fromDate) + ' ' +
                (toDate === '' ? defaultDate : toDate);
            return { content: date, description: descriptionValue };
        }
    }
    class LanguagePopupSelector {
        constructor(container) {
            this.container = container;
        }
        replace(languages) {
            var container = this.container.querySelector('ul');
            var oldItems = this.container.querySelectorAll('li');
            var newItems = [];
            var self = this;
            languages.forEach(function (language) {
                var newItem = document.createElement('li');
                newItem.textContent = language.code + ': ' + language.name;
                newItem.setAttribute('data-code', language.code);
                newItem.setAttribute('data-name', language.name);
                newItem.style.display = 'none';
                self.registerEvent(newItem);
                newItems.push(newItem);
                container.appendChild(newItem);
            });
            Array.prototype.forEach.call(oldItems, function (item) {
                item.parentNode.removeChild(item);
            });
            newItems.forEach(function (item) {
                item.style.display = 'block';
            });
        }
        registerEvent(elem) {
            var self = this;
            elem.addEventListener('click', function () { self.changeValue(elem); });
        }
        changeValue(elem) {
            if (!this.currentElem)
                return;
            this.currentElem.value = elem.getAttribute('data-name');
        }
        showAndMove(elem) {
            this.currentElem = elem;
            this.container.style.top = elem.offsetTop + 'px';
            this.container.style.left = (elem.offsetLeft + 265) + 'px';
            this.show();
        }
        show() {
            var items = this.container.querySelectorAll('li');
            if (items.length === 0) {
                this.hide();
                return;
            }
            this.container.style.display = 'block';
        }
        hide() {
            this.container.style.display = 'none';
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
    if (form) {
        var editor = new Shachi.ResourceEditor(form);
    }
});
