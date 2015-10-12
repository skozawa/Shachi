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
    class AnnotatorPopupEditor extends PopupEditor {
        constructor(cssSelector, buttonSelector) {
            super(cssSelector, buttonSelector);
        }
        change(elem) {
            var newAnnotatorId = elem.getAttribute('data-annotator-id');
            if (!this.resourceId || !this.currentElem ||
                this.currentElem.getAttribute('data-annotator-id') === newAnnotatorId) {
                this.hide();
                return;
            }
            var self = this;
            Shachi.XHR.request('POST', '/admin/resources/' + this.resourceId + '/annotator', {
                body: "annotator_id=" + newAnnotatorId,
                completeHandler: function (req) { self.complete(req); }
            });
        }
        complete(res) {
            try {
                var json = JSON.parse(res.responseText);
                var annotator = json.annotator;
                this.currentElem.setAttribute('data-annotator-id', annotator.id);
                this.currentElem.textContent = 'Annotator: ' + annotator.name;
            }
            catch (err) { }
            this.hide();
        }
    }
    Shachi.AnnotatorPopupEditor = AnnotatorPopupEditor;
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
                'content-type': 'application/json',
                completeHandler: function (req) { self.complete(req); }
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
            this.metadataEditors = [];
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
    }
    class ResourceCreateEditor extends ResourceEditor {
        constructor(container) {
            super(container);
            this.setup();
        }
        setup() {
            var self = this;
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
    Shachi.ResourceCreateEditor = ResourceCreateEditor;
    class ResourceUpdateEditor extends ResourceEditor {
        constructor(container) {
            super(container);
            this.setup();
        }
        setup() {
            this.annotatorEditor = new Shachi.AnnotatorPopupEditor('.annotator-popup-editor', 'li.annotator');
            this.statusEditor = new Shachi.StatusPopupEditor('.status-popup-editor', 'li.status');
            this.editStatusEditor = new Shachi.EditStatusPopupEditor('.edit-status-popup-editor', 'li.edit-status');
            var self = this;
            var annotatorElem = this.container.querySelector('span.annotator');
            var annotatorEditButton = this.container.querySelector('.annotator-edit-button');
            if (annotatorElem && annotatorEditButton) {
                annotatorEditButton.addEventListener('click', function () {
                    self.annotatorEditor.showWithSet(self.container, annotatorElem);
                });
            }
            var statusElem = this.container.querySelector('.status');
            if (statusElem) {
                statusElem.addEventListener('click', function () {
                    self.statusEditor.showWithSet(self.container, statusElem);
                });
            }
            var editStatusElem = this.container.querySelector('.edit-status');
            if (editStatusElem) {
                editStatusElem.addEventListener('click', function () {
                    self.editStatusEditor.showWithSet(self.container, editStatusElem);
                });
            }
            var metadataList = this.container.querySelectorAll('.resource-metadata');
            Array.prototype.forEach.call(metadataList, function (metadata) {
                self.metadataEditors.push(self.metadataEditor(metadata));
            });
        }
    }
    Shachi.ResourceUpdateEditor = ResourceUpdateEditor;
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
    class ResourceMetadataEditorEditBase extends ResourceMetadataEditorBase {
        constructor(container) {
            super(container);
        }
        setup() {
            super.setup();
            var self = this;
            this.editButton = this.container.querySelector('.metadata-edit-button');
            if (!this.editButton)
                return;
            this.editButton.addEventListener('click', function () {
                self.showEditor();
            });
            this.addDeleteButton = this.container.querySelector('.resource-metadata-add-delete');
            this.dataContainer = this.container.querySelector('.resource-metadata-data');
            this.editor = this.container.querySelector('.resource-metadata-editor');
            var cancelButton = this.container.querySelector('.cancel');
            if (cancelButton) {
                cancelButton.addEventListener('click', function () {
                    self.hideEditor();
                });
            }
            var submitButton = this.container.querySelector('.submit');
            if (submitButton) {
                submitButton.addEventListener('click', function () {
                });
            }
        }
        showEditor() {
            this.editButton.style.display = 'none';
            this.dataContainer.style.display = 'none';
            this.createForm();
            this.addDeleteButton.style.display = 'inline-block';
            this.editor.style.display = 'inline-block';
        }
        createForm() {
            var values = this.toValuesFromData();
            var item = this.container.querySelector(this.listSelector);
            var listContainer = item.parentNode;
            var self = this;
            Array.prototype.forEach.call(values, function (value) {
                self.addItemWithValue(value);
            });
            var oldItemLength = listContainer.children.length - values.length;
            if (values.length === 0) {
                this.addItem();
            }
            for (var i = 0; i <= oldItemLength; i++) {
                listContainer.removeChild(listContainer.firstChild);
            }
        }
        hideEditor() {
            this.addDeleteButton.style.display = 'none';
            this.editor.style.display = 'none';
            this.dataContainer.style.display = 'inline-block';
            this.editButton.style.display = 'inline-block';
        }
        toValuesFromData() {
            var self = this;
            var items = this.dataContainer.querySelectorAll('li');
            var values = [];
            Array.prototype.forEach.call(items, function (item) {
                var hash = self.toHashFromData(item);
                if (hash)
                    values.push(hash);
            });
            return values;
        }
        toHashFromData(item) {
            return undefined;
        }
        addItemWithValue(value) {
            return this.addItem();
        }
    }
    class ResourceMetadataEditorWithPopup extends ResourceMetadataEditorEditBase {
        constructor(container, targetSelector) {
            super(container);
            this.currentQuery = '';
            this.enableRequest = true;
            this.targetSelector = targetSelector;
        }
        setup() {
            super.setup();
        }
        registerEvent(item) {
            var self = this;
            item.addEventListener('keyup', function () { self.changeInput(item); });
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
            var item = newItem.querySelector(this.targetSelector);
            this.registerEvent(item);
            return newItem;
        }
        changeInput(elem) {
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
            Shachi.XHR.request('GET', this.requestURI(query), {
                completeHandler: function (req) { self.complete(req, elem); }
            });
        }
        requestURI(query) {
            return '';
        }
        complete(res, elem) {
            try {
                var json = JSON.parse(res.responseText);
                this.popup(elem, json);
            }
            catch (err) { }
            this.enableRequest = true;
        }
        popup(elem, json) { }
    }
    class ResourceMetadataTextEditor extends ResourceMetadataEditorEditBase {
        toHash(elem) {
            var content = elem.querySelector('.content');
            if (!content || content.value === '')
                return undefined;
            return { content: content.value };
        }
        toHashFromData(elem) {
            var content = elem.querySelector('.content');
            if (!content)
                return undefined;
            return { content: content.textContent };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            newItem.querySelector('.content').value = value.content;
            return newItem;
        }
    }
    class ResourceMetadataTextareaEditor extends ResourceMetadataEditorEditBase {
        toHash(elem) {
            var content = elem.querySelector('.content');
            if (!content || content.value === '')
                return undefined;
            return { content: content.value };
        }
        toHashFromData(elem) {
            var content = elem.querySelector('.content');
            if (!content)
                return undefined;
            return { content: content.textContent };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            newItem.querySelector('.content').value = value.content;
            return newItem;
        }
    }
    class ResourceMetadataSelectEditor extends ResourceMetadataEditorEditBase {
        toHash(elem) {
            var select = elem.querySelector('select');
            var description = elem.querySelector('.description');
            var selectValue = select ? select.value : '';
            var descriptionValue = description ? description.value : '';
            if (selectValue === '' && descriptionValue === '')
                return undefined;
            return { value_id: selectValue, description: descriptionValue };
        }
        toHashFromData(elem) {
            var value = elem.querySelector('.value');
            var description = elem.querySelector('.desciption');
            var valueId = value.getAttribute('data-value-id');
            var descriptionValue = description ? description.textContent : '';
            return { value_id: valueId, description: descriptionValue };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            if (value.value_id) {
                var options = newItem.querySelectorAll('option');
                Array.prototype.forEach.call(options, function (option) {
                    if (option.value === value.value_id) {
                        option.selected = true;
                    }
                });
            }
            newItem.querySelector('.description').value = value.description;
            return newItem;
        }
    }
    class ResourceMetadataSelectOnlyEditor extends ResourceMetadataEditorEditBase {
        toHash(elem) {
            var select = elem.querySelector('select');
            if (!select || select.value === '')
                return undefined;
            return { value_id: select.value };
        }
        toHashFromData(elem) {
            var value = elem.querySelector('.value');
            var valueId = value.getAttribute('data-value-id');
            return { value_id: valueId };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            if (value.value_id) {
                var options = newItem.querySelectorAll('option');
                Array.prototype.forEach.call(options, function (option) {
                    if (option.value === value.value_id) {
                        option.selected = true;
                    }
                });
            }
            return newItem;
        }
    }
    class ResourceMetadataRelationEditor extends ResourceMetadataEditorWithPopup {
        constructor(container) {
            super(container, '.description');
            this.setup();
        }
        setup() {
            if (!this.targetSelector)
                return;
            super.setup();
            var items = this.container.querySelectorAll(this.listSelector + ' ' + this.targetSelector);
            var self = this;
            var popup = this.container.querySelector('.relation-popup-selector');
            if (popup) {
                this.popupSelector = new RelationPopupSelector(popup);
            }
            Array.prototype.forEach.call(items, function (item) {
                self.registerEvent(item);
            });
        }
        requestURI(query) {
            return '/admin/resources/search?query=' + query;
        }
        popup(elem, json) {
            this.popupSelector.replace(json.resources);
            this.popupSelector.showAndMove(elem);
        }
        toHash(elem) {
            var select = elem.querySelector('select');
            var description = elem.querySelector('.description');
            var selectValue = select ? select.value : '';
            var descriptionValue = description ? description.value : '';
            if (selectValue === '' && descriptionValue === '')
                return undefined;
            return { value_id: selectValue, description: descriptionValue };
        }
        toHashFromData(elem) {
            var value = elem.querySelector('.value');
            var description = elem.querySelector('.desciption');
            var valueId = value.getAttribute('data-value-id');
            var descriptionValue = description ? description.textContent : '';
            return { value_id: valueId, description: descriptionValue };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            if (value.value_id) {
                var options = newItem.querySelectorAll('option');
                Array.prototype.forEach.call(options, function (option) {
                    if (option.value === value.value_id) {
                        option.selected = true;
                    }
                });
            }
            newItem.querySelector('.description').value = value.description;
            return newItem;
        }
    }
    class ResourceMetadataLanguageEditor extends ResourceMetadataEditorWithPopup {
        constructor(container) {
            super(container, '.content');
            this.setup();
        }
        setup() {
            if (!this.targetSelector)
                return;
            super.setup();
            var items = this.container.querySelectorAll(this.listSelector + ' ' + this.targetSelector);
            var self = this;
            var popup = this.container.querySelector('.language-popup-selector');
            if (popup) {
                this.popupSelector = new LanguagePopupSelector(popup);
            }
            Array.prototype.forEach.call(items, function (item) {
                self.registerEvent(item);
            });
        }
        requestURI(query) {
            return '/admin/languages/search?query=' + query;
        }
        popup(elem, json) {
            this.popupSelector.replace(json.languages);
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
        toHashFromData(elem) {
            var content = elem.querySelector('.content');
            var description = elem.querySelector('.description');
            var contentValue = content ? content.textContent : '';
            var descriptionValue = description ? description.textContent : '';
            return { content: contentValue, description: descriptionValue };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            newItem.querySelector('.content').value = value.content;
            newItem.querySelector('.description').value = value.description;
            return newItem;
        }
    }
    class ResourceMetadataDateEditor extends ResourceMetadataEditorEditBase {
        toHash(elem) {
            var date = this.getDate(elem, '');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.value : '';
            if (date === '' && descriptionValue === '')
                return undefined;
            return { content: date, description: descriptionValue };
        }
        toHashFromData(elem) {
            var content = elem.querySelector('.content');
            var date = content.textContent.split('-');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.textContent : '';
            return { year, date: [0], month: data[1], day: date[2], description: descriptionValue };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            newItem.querySelector('.year').value = value.year;
            newItem.querySelector('.month').value = value.month;
            newItem.querySelector('.day').value = value.day;
            newItem.querySelector('.description').value = value.description;
            return newItem;
        }
    }
    class ResourceMetadataRangeEditor extends ResourceMetadataEditorEditBase {
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
        toHashFromData(elem) {
            var content = elem.querySelector('.content');
            var range = content.textContent.split(' ');
            var from = (range[0] || '').split('-');
            ;
            var to = (range[1] || '').split('-');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.textContent : '';
            return {
                fromYear: from[0], fromMonth: from[1], fromDay: from[2],
                toYear: to[0], toMonth: to[1], toDay: to[2],
                description: descriptionValue
            };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            newItem.querySelector('.from-year').value = value.fromYear;
            newItem.querySelector('.from-month').value = value.fromMonth;
            newItem.querySelector('.from-day').value = value.fromDay;
            newItem.querySelector('.to-year').value = value.toYear;
            newItem.querySelector('.to-month').value = value.toMonth;
            newItem.querySelector('.to-day').value = value.toDay;
            newItem.querySelector('.description').value = value.description;
            return newItem;
        }
    }
    class PopupSelector {
        constructor(container) {
            this.container = container;
            this.positionTop = 0;
            this.positionLeft = 0;
        }
        replace(dataList) {
            var container = this.container.querySelector('ul');
            var oldItems = this.container.querySelectorAll('li');
            var newItems = [];
            var self = this;
            dataList.forEach(function (data) {
                var newItem = self.createItem(data);
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
        createItem(data) { }
        showAndMove(elem) {
            this.currentElem = elem;
            this.container.style.top = (elem.offsetTop + this.positionTop) + 'px';
            this.container.style.left = (elem.offsetLeft + this.positionLeft) + 'px';
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
    class RelationPopupSelector extends PopupSelector {
        constructor(container) {
            super(container);
            this.positionTop = 20;
            this.positionLeft = 0;
        }
        createItem(data) {
            var item = document.createElement('li');
            var value = data.shachi_id + ': ' + data.title;
            item.textContent = value;
            item.setAttribute('data-shachi_id', data.shachi_id);
            item.setAttribute('data-title', data.title);
            item.setAttribute('data-value', value);
            item.style.display = 'none';
            this.registerEvent(item);
            return item;
        }
        registerEvent(elem) {
            var self = this;
            elem.addEventListener('click', function () { self.changeValue(elem); });
        }
        changeValue(elem) {
            if (!this.currentElem)
                return;
            this.currentElem.value = elem.getAttribute('data-value');
        }
    }
    class LanguagePopupSelector extends PopupSelector {
        constructor(container) {
            super(container);
            this.positionTop = 0;
            this.positionLeft = 265;
        }
        createItem(data) {
            var item = document.createElement('li');
            item.textContent = data.code + ': ' + data.name;
            item.setAttribute('data-code', data.code);
            item.setAttribute('data-name', data.name);
            item.style.display = 'none';
            this.registerEvent(item);
            return item;
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
    }
})(Shachi || (Shachi = {}));
document.addEventListener("DOMContentLoaded", function (event) {
    var resources = document.querySelectorAll('li.annotator-resource[data-resource-id]');
    if (resources && resources.length > 0) {
        var statusEditor = new Shachi.StatusPopupEditor('.status-popup-editor', 'li.status');
        var editStatusEditor = new Shachi.EditStatusPopupEditor('.edit-status-popup-editor', 'li.edit-status');
        Array.prototype.forEach.call(resources, function (resource) {
            new Shachi.ResourceListEditor(resource, statusEditor, editStatusEditor);
        });
    }
    var form = document.querySelector('#resource-create-form');
    var detail = document.querySelector('.resource-detail-container');
    if (form) {
        var createEditor = new Shachi.ResourceCreateEditor(form);
    }
    else if (detail) {
        var updateEditor = new Shachi.ResourceUpdateEditor(detail);
    }
});
