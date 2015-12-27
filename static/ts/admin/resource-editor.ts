/// <reference path="xhr.ts" />

module Shachi {
    class ResourceEditor {
        container;
        metadataEditors;
        constructor(container: HTMLElement) {
            this.container = container;
            this.metadataEditors = [];
        }
        metadataEditor(metadata: HTMLElement, metadataLanguage?:string): ResourceMetadataEditorBase {
            if ( metadataLanguage === undefined ) metadataLanguage = 'eng';
            var inputType = metadata.getAttribute('data-input-type') || '';
            if (inputType == 'textarea')    return new ResourceMetadataTextareaEditor(metadata, metadataLanguage);
            if (inputType == 'select')      return new ResourceMetadataSelectEditor(metadata, metadataLanguage);
            if (inputType == 'select_only') return new ResourceMetadataSelectOnlyEditor(metadata, metadataLanguage);
            if (inputType == 'relation')    return new ResourceMetadataRelationEditor(metadata, metadataLanguage);
            if (inputType == 'language')    return new ResourceMetadataLanguageEditor(metadata, metadataLanguage);
            if (inputType == 'date')        return new ResourceMetadataDateEditor(metadata, metadataLanguage);
            if (inputType == 'range')       return new ResourceMetadataRangeEditor(metadata, metadataLanguage);
            return new ResourceMetadataTextEditor(metadata, metadataLanguage);
        }
    }

    export class ResourceCreateEditor extends ResourceEditor {
        constructor(container: HTMLElement) {
            super(container);
            this.setup();
        }
        setup() {
            var self = this;
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
            this.startRequest();
            Shachi.XHR.request('POST', '/admin/resources/create', {
                body: JSON.stringify(values),
                'content-type': 'application/json',
                completeHandler: function(req) { self.createComplete(req) },
            });
        }
        startRequest() {
            var submitButton = this.container.querySelector('#resource-create-submit');
            if (submitButton) {
                submitButton.disabled = true;
            }
            var loadingElem = this.container.querySelector('.loading');
            if (loadingElem) {
                loadingElem.style.display = 'inline-block';
            }
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
            var languages = this.container.querySelectorAll('.resource-metadata-language input');
            Array.prototype.forEach.call(languages, function(language) {
                if ( ! language.checked ) return;
                values['metadata_language'] = language.value;
            });
            return values;
        }
    }

    export class ResourceUpdateEditor extends ResourceEditor {
        annotatorEditor;
        statusEditor;
        editStatusEditor;
        constructor(container: HTMLElement) {
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
            var resourceMetadataLanguage = this.container.querySelector('.resource-metadata-language');
            var metadataLanguage = resourceMetadataLanguage ?
                resourceMetadataLanguage.getAttribute('data-metadata-language') : 'eng';
            var metadataList = this.container.querySelectorAll('.resource-metadata');
            Array.prototype.forEach.call(metadataList, function(metadata) {
                self.metadataEditors.push(self.metadataEditor(metadata, metadataLanguage));
            });
        }
    }

    class ResourceMetadataEditorBase {
        container;
        name;
        listSelector;
        metadataLanguage;
        constructor(container: HTMLElement, metadataLanguage: string) {
            this.container = container;
            this.name = container.getAttribute('data-name');
            this.listSelector = 'li.resource-metadata-item';
            this.metadataLanguage = metadataLanguage;
            this.setup();
        }
        setup() {
            var self = this;
            var addButton = this.container.querySelector('.btn.add');
            if (addButton) {
                addButton.addEventListener('click', function() {
                    self.addItem();
                });
            }
            var deleteButton = this.container.querySelector('.btn.delete');
            if (deleteButton) {
                deleteButton.addEventListener('click', function() {
                    self.deleteItem();
                });
            }
        }
        addItem() {
            var item = this.container.querySelector(this.listSelector);
            var newItem = item.cloneNode(true);
            Array.prototype.forEach.call(newItem.querySelectorAll('input, textarea'), function(elem) {
                elem.value = "";
            });
            item.parentNode.appendChild(newItem);
            return newItem;
        }
        deleteItem() {
            var items = this.container.querySelectorAll(this.listSelector);
            if ( items.length < 2 ) return;
            var removeItem = items[items.length - 1];
            removeItem.parentNode.removeChild(removeItem);
        }
        toValues() {
            var self = this;
            var items = this.container.querySelectorAll(this.listSelector);
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

    class ResourceMetadataEditorEditBase extends ResourceMetadataEditorBase {
        editButton;
        addDeleteButton;
        dataContainer;
        editor;
        resourceId;
        updating;
        loadingElem;
        submitButton;
        constructor(container: HTMLElement, metadataLanguage: string) {
            super(container, metadataLanguage);
        }
        setup() {
            super.setup();
            var self = this;
            this.editButton = this.container.querySelector('.metadata-edit-button');
            if ( !this.editButton ) return;
            this.editButton.addEventListener('click', function () {
                self.showEditor();
            });
            this.addDeleteButton = this.container.querySelector('.resource-metadata-add-delete');
            this.dataContainer = this.container.querySelector('.resource-metadata-data');
            this.editor = this.container.querySelector('.resource-metadata-editor');
            this.resourceId = this.container.getAttribute('data-resource-id');
            this.updating = false;
            this.loadingElem = this.container.querySelector('.loading');
            var cancelButton = this.container.querySelector('.cancel');
            if (cancelButton) {
                cancelButton.addEventListener('click', function () {
                    self.hideEditor();
                });
            }
            this.submitButton = this.container.querySelector('.submit');
            if (this.submitButton) {
                this.submitButton.addEventListener('click', function () {
                    self.update();
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
            var oldItemLength = listContainer.children.length;
            var self = this;
            Array.prototype.forEach.call(values, function(value) {
                self.addItemWithValue(value);
            });
            if (values.length === 0) {
                this.addItem();
            }
            for (var i = 0; i < oldItemLength; i++) {
                listContainer.removeChild(listContainer.firstElementChild);
            }
        }
        hideEditor() {
            this.addDeleteButton.style.display = 'none';
            this.editor.style.display = 'none';
            this.dataContainer.style.display = 'inline-block';
            this.editButton.style.display = 'inline-block';
        }
        update() {
            var self = this;
            if ( this.updating ) return;
            this.startUpdate();
            var values = this.toValues();
            var json = {};
            json[this.name] = values;
            json['metadata_language'] = this.metadataLanguage;
            Shachi.XHR.request('POST', '/admin/resources/' + this.resourceId + '/metadata', {
                body: JSON.stringify(json),
                'content-type': 'application/json',
                completeHandler: function(req) { self.updateComplete(req) }
            });
        }
        startUpdate() {
            this.updating = true;
            if ( this.loadingElem ) {
                this.loadingElem.style.display = 'inline-block';
            }
            if ( this.submitButton ) {
                this.submitButton.disabled = true;
            }
        }
        updateComplete(res) {
            try {
                var json = JSON.parse(res.responseText);
                this.updateData(json);
            } catch (err) { /* ignore */ }
            this.updating = false;
            if ( this.loadingElem ) {
                this.loadingElem.style.display = 'none';
            }
            if ( this.submitButton ) {
                this.submitButton.disabled = false;
            }
            this.hideEditor();
        }
        updateData(json) {
            var self = this;
            while(this.dataContainer.firstChild) {
                this.dataContainer.removeChild(this.dataContainer.firstChild);
            }
            var values = json[this.name] || [];
            values.forEach(function(value) {
                var elem = self.toDataFromHash(value);
                if (elem) self.dataContainer.appendChild(elem);
            });
        }
        toDataFromHash(value) {
            return undefined;
        }
        toValuesFromData() {
            var self = this;
            var items = this.dataContainer.querySelectorAll('li');
            var values = [];
            Array.prototype.forEach.call(items, function(item) {
                var hash = self.toHashFromData(item);
                if ( hash ) values.push(hash);
            });
            return values;
        }
        toHashFromData(item: HTMLElement) {
            return undefined;
        }
        addItemWithValue(value) {
            return this.addItem();
        }
    }

    class ResourceMetadataEditorWithPopup extends ResourceMetadataEditorEditBase {
        currentQuery;
        enableRequest;
        targetSelector;
        popupSelector;
        constructor(container: HTMLElement, metadataLanguage: string, targetSelector: string) {
            super(container, metadataLanguage);
            this.currentQuery = '';
            this.enableRequest = true;
            this.targetSelector = targetSelector;
        }
        setup() {
            super.setup();
        }
        registerEvent(item) {
            var self = this;
            item.addEventListener('keyup', function() { self.changeInput(item) });
            if ( self.popupSelector ) {
                item.addEventListener('blur', function() {
                    // popupSelectorのclickを取るため少し遅らせて非表示にする
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
            if (!this.enableRequest) return;
            if (this.currentQuery === query) {
                this.popupSelector.show();
                return;
            }

            var self = this;
            this.enableRequest = false;
            Shachi.XHR.request('GET', this.requestURI(query), {
                completeHandler: function(req) { self.complete(req, elem) }
            });
        }
        requestURI(query) {
            return '';
        }
        complete(res, elem) {
            try {
                var json = JSON.parse(res.responseText);
                this.popup(elem, json);
            } catch (err) { /* ignore */ }
            this.enableRequest = true;
        }
        popup(elem, json) {}
    }


    class ResourceMetadataTextEditor extends ResourceMetadataEditorEditBase {
        toHash(elem) {
            var content = elem.querySelector('.content');
            if (!content || content.value === '') return undefined;
            return { content: content.value };
        }
        toHashFromData(elem) {
            var content = elem.querySelector('.content');
            if (!content) return undefined;
            return { content: content.textContent };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            newItem.querySelector('.content').value = value.content;
            return newItem;
        }
        toDataFromHash(value) {
            var elem = document.createElement('li');
            var content = document.createElement('span');
            content.setAttribute('class', 'content');
            content.textContent = value.content;
            elem.appendChild(content);
            return elem;
        }
    }
    class ResourceMetadataTextareaEditor extends ResourceMetadataEditorEditBase {
        toHash(elem) {
            var content = elem.querySelector('.content');
            if (!content || content.value === '') return undefined;
            return { content: content.value };
        }
        toHashFromData(elem) {
            var content = elem.querySelector('.content');
            if (!content) return undefined;
            return { content: content.textContent };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            newItem.querySelector('.content').value = value.content;
            return newItem;
        }
        toDataFromHash(value) {
            var elem = document.createElement('li');
            var content = document.createElement('span');
            content.setAttribute('class', 'content');
            content.textContent = value.content;
            elem.appendChild(content);
            return elem;
        }
    }
    class ResourceMetadataSelectEditor extends ResourceMetadataEditorEditBase {
        toHash(elem) {
            var select = elem.querySelector('select');
            var description = elem.querySelector('.description');
            var selectValue = select ? select.value : '';
            var descriptionValue = description ? description.value : '';
            if (selectValue === '' && descriptionValue === '') return undefined;
            return { value_id: selectValue, description: descriptionValue };
        }
        toHashFromData(elem) {
            var value = elem.querySelector('.value');
            var description = elem.querySelector('.description');
            var valueId = value.getAttribute('data-value-id');
            var descriptionValue = description ? description.textContent : '';
            return { value_id: valueId, description: descriptionValue };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            if (value.value_id) {
                var options = newItem.querySelectorAll('option');
                Array.prototype.forEach.call(options, function(option) {
                    if (option.value === value.value_id) {
                        option.selected = true;
                    }
                });
            }
            newItem.querySelector('.description').value = value.description;
            return newItem;
        }
        toDataFromHash(value) {
            var elem = document.createElement('li');
            var content = document.createElement('span');
            content.setAttribute('class', 'label value');
            content.setAttribute('data-value-id', value.value_id);
            content.textContent = value.value;
            elem.appendChild(content);
            var description = document.createElement('span');
            description.setAttribute('class', 'description');
            description.textContent = value.description;
            elem.appendChild(description);
            return elem;
        }
    }
    class ResourceMetadataSelectOnlyEditor extends ResourceMetadataEditorEditBase {
        toHash(elem) {
            var select = elem.querySelector('select');
            if (!select || select.value === '') return undefined;
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
                Array.prototype.forEach.call(options, function(option) {
                    if (option.value === value.value_id) {
                        option.selected = true;
                    }
                });
            }
            return newItem;
        }
        toDataFromHash(value) {
            var elem = document.createElement('li');
            var content = document.createElement('span');
            content.setAttribute('class', 'label value');
            content.setAttribute('data-value-id', value.value_id);
            content.textContent = value.value;
            elem.appendChild(content);
            return elem;
        }
    }
    class ResourceMetadataRelationEditor extends ResourceMetadataEditorWithPopup {
        constructor(container: HTMLElement, metadataLanguage: string) {
            super(container, metadataLanguage, '.description');
            this.setup();
        }
        setup() {
            if ( !this.targetSelector ) return;
            super.setup();
            var items = this.container.querySelectorAll(this.listSelector + ' ' + this.targetSelector);
            var self = this;
            var popup = this.container.querySelector('.relation-popup-selector');
            if (popup) {
                this.popupSelector = new RelationPopupSelector(popup);
            }
            Array.prototype.forEach.call(items, function(item) {
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
            if (selectValue === '' && descriptionValue === '') return undefined;
            return { value_id: selectValue, description: descriptionValue };
        }
        toHashFromData(elem) {
            var value = elem.querySelector('.value');
            var description = elem.querySelector('.description');
            var valueId = value.getAttribute('data-value-id');
            var descriptionValue = description ? description.textContent : '';
            return { value_id: valueId, description: descriptionValue };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            if (value.value_id) {
                var options = newItem.querySelectorAll('option');
                Array.prototype.forEach.call(options, function(option) {
                    if (option.value === value.value_id) {
                        option.selected = true;
                    }
                });
            }
            newItem.querySelector('.description').value = value.description;
            return newItem;
        }
        toDataFromHash(value) {
            var elem = document.createElement('li');
            var content = document.createElement('span');
            content.setAttribute('class', 'label value');
            content.setAttribute('data-value-id', value.value_id);
            content.textContent = value.value;
            elem.appendChild(content);
            var description = document.createElement('span');
            description.setAttribute('class', 'description');
            description.textContent = value.description;
            elem.appendChild(description);
            return elem;
        }
    }
    class ResourceMetadataLanguageEditor extends ResourceMetadataEditorWithPopup {
        constructor(container: HTMLElement, metadataLanguage: string) {
            super(container, metadataLanguage, '.content');
            this.setup();
        }
        setup() {
            if ( !this.targetSelector ) return;
            super.setup();
            var items = this.container.querySelectorAll(this.listSelector + ' ' + this.targetSelector);
            var self = this;
            var popup = this.container.querySelector('.language-popup-selector');
            if (popup) {
                this.popupSelector = new LanguagePopupSelector(popup);
            }
            Array.prototype.forEach.call(items, function(item) {
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
            if (contentValue === '' && descriptionValue === '') return undefined;
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
        toDataFromHash(value) {
            var elem = document.createElement('li');
            var content = document.createElement('span');
            content.setAttribute('class', 'label value');
            content.setAttribute('data-value-id', value.value_id);
            content.textContent = value.value;
            elem.appendChild(content);
            var description = document.createElement('span');
            description.setAttribute('class', 'description');
            description.textContent = value.description;
            elem.appendChild(description);
            return elem;
        }
    }
    class ResourceMetadataDateEditor extends ResourceMetadataEditorEditBase {
        toHash(elem) {
            var date = this.getDate(elem, '');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.value : '';
            if (date === '' && descriptionValue === '') return undefined;
            return { content: date, description: descriptionValue };
        }
        toHashFromData(elem) {
            var content = elem.querySelector('.content');
            var date = content.textContent.split('-');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.textContent : '';
            return { year: date[0], month: date[1], day: date[2], description: descriptionValue };
        }
        addItemWithValue(value) {
            var newItem = this.addItem();
            newItem.querySelector('.year').value = value.year;
            newItem.querySelector('.month').value = value.month;
            newItem.querySelector('.day').value = value.day;
            newItem.querySelector('.description').value = value.description;
            return newItem;
        }
        toDataFromHash(value) {
            var elem = document.createElement('li');
            var content = document.createElement('span');
            content.setAttribute('class', 'content');
            content.textContent = value.content;
            elem.appendChild(content);
            var description = document.createElement('span');
            description.setAttribute('class', 'description');
            description.textContent = value.description;
            elem.appendChild(description);
            return elem;
        }
    }
    class ResourceMetadataRangeEditor extends ResourceMetadataEditorEditBase {
        toHash(elem) {
            var fromDate = this.getDate(elem, 'from-');
            var toDate = this.getDate(elem, 'to-');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.value : '';
            if (fromDate === '' && toDate === '' && descriptionValue === '') return undefined;
            if (fromDate === '' && toDate === '') return { content: '', description: descriptionValue };
            var defaultDate = '0000-00-00';
            var date = (fromDate === '' ? defaultDate : fromDate) + ' ' +
                (toDate === '' ? defaultDate : toDate);
            return { content: date, description: descriptionValue };
        }
        toHashFromData(elem) {
            var content = elem.querySelector('.content');
            var range = content.textContent.split(' ');
            var from = (range[0] || '').split('-');
            var to = (range[1] || '').split('-');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.textContent : '';
            return {
                fromYear: from[0], fromMonth: from[1] || '', fromDay: from[2] || '',
                toYear: to[0], toMonth: to[1] || '', toDay: to[2] || '',
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
        toDataFromHash(value) {
            var elem = document.createElement('li');
            var content = document.createElement('span');
            content.setAttribute('class', 'content');
            content.textContent = value.content;
            elem.appendChild(content);
            var description = document.createElement('span');
            description.setAttribute('class', 'description');
            description.textContent = value.description;
            elem.appendChild(description);
            return elem;
        }
    }


    class PopupSelector {
        container;
        currentElem;
        positionTop;
        positionLeft;
        constructor(container: HTMLElement) {
            this.container = container;
            this.positionTop = 0;
            this.positionLeft = 0;
        }
        replace(dataList) {
            var container = this.container.querySelector('ul');
            var oldItems = this.container.querySelectorAll('li');
            var newItems = [];
            var self = this;
            dataList.forEach(function(data) {
                var newItem = self.createItem(data);
                newItems.push(newItem);
                container.appendChild(newItem);
            });
            Array.prototype.forEach.call(oldItems, function(item) {
                item.parentNode.removeChild(item);
            });
            newItems.forEach(function(item) {
                item.style.display = 'block';
            });
        }
        createItem(data) {}
        showAndMove(elem: HTMLElement) {
            this.currentElem = elem;
            this.container.style.top = (elem.offsetTop + this.positionTop) + 'px';
            this.container.style.left = (elem.offsetLeft + this.positionLeft) + 'px';
            this.show();
        }
        show() {
            var items = this.container.querySelectorAll('li');
            if ( items.length === 0 ) {
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
        constructor(container: HTMLElement) {
            super(container);
            this.positionTop  = 20;
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
            elem.addEventListener('click', function () { self.changeValue(elem) });
        }
        changeValue(elem) {
            if ( !this.currentElem ) return;
            this.currentElem.value= elem.getAttribute('data-value');
        }
    }
    class LanguagePopupSelector extends PopupSelector {
        constructor(container: HTMLElement) {
            super(container);
            this.positionTop  = 0;
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
            elem.addEventListener('click', function () { self.changeValue(elem) });
        }
        changeValue(elem) {
            if ( !this.currentElem ) return;
            this.currentElem.value= elem.getAttribute('data-name');
        }
    }

}
