"use strict";
/// <reference path="xhr.ts" />
/// <reference path="popup-editor.ts" />
/// <reference path="resource-list-editor.ts" />
/// <reference path="resource-editor.ts" />
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
            if ('content-type' in options)
                req.setRequestHeader('Content-Type', options['content-type']);
            if (method === 'POST' && 'body' in options)
                req.setRequestHeader('Content-Type', options['content-type'] || 'application/x-www-form-urlencoded');
            req.send(('body' in options) ? options.body : null);
            return req;
        }
        XHR.request = request;
    })(XHR = Shachi.XHR || (Shachi.XHR = {}));
})(Shachi || (Shachi = {}));
/// <reference path="xhr.ts" />
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var Shachi;
(function (Shachi) {
    var PopupEditor = (function () {
        function PopupEditor(cssSelector, buttonSelector) {
            this.container = document.querySelector(cssSelector);
            if (!this.container)
                return;
            this.closeButton = this.container.querySelector('.close');
            this.buttons = this.container.querySelectorAll(buttonSelector);
            this.registerEvent();
            this.requesting = false;
            this.loadingElem = this.container.querySelector('.loading');
        }
        PopupEditor.prototype.registerEvent = function () {
            var self = this;
            if (self.closeButton) {
                self.closeButton.addEventListener('click', function () {
                    self.hide();
                });
            }
            if (self.buttons) {
                Array.prototype.forEach.call(self.buttons, function (button) {
                    button.addEventListener('click', function () {
                        if (this.requesting)
                            return;
                        self.change(button);
                    });
                });
            }
        };
        PopupEditor.prototype.change = function (elem) { };
        PopupEditor.prototype.showWithSet = function (resource, elem) {
            this.resourceId = resource.getAttribute('data-resource-id');
            if (!this.resourceId) {
                this.hide();
                return;
            }
            this.currentElem = elem;
            this.showAndMove(elem);
        };
        PopupEditor.prototype.showAndMove = function (elem) {
            this.container.style.top = (elem.offsetTop + 20) + 'px';
            this.container.style.left = elem.offsetLeft + 'px';
            this.show();
        };
        PopupEditor.prototype.show = function () {
            this.container.style.display = 'block';
        };
        PopupEditor.prototype.hide = function () {
            this.container.style.display = 'none';
        };
        PopupEditor.prototype.startRequest = function () {
            this.requesting = true;
            if (this.loadingElem) {
                this.loadingElem.style.display = 'block';
            }
        };
        PopupEditor.prototype.completeRequest = function () {
            this.requesting = false;
            if (this.loadingElem) {
                this.loadingElem.style.display = 'none';
            }
            this.hide();
        };
        return PopupEditor;
    })();
    var StatusPopupEditor = (function (_super) {
        __extends(StatusPopupEditor, _super);
        function StatusPopupEditor(cssSelector, buttonSelector) {
            _super.call(this, cssSelector, buttonSelector);
        }
        StatusPopupEditor.prototype.change = function (elem) {
            var newStatus = elem.getAttribute('data-status');
            if (!this.resourceId || !this.currentElem || !newStatus ||
                this.currentElem.getAttribute('data-status') === newStatus) {
                this.hide();
                return;
            }
            var self = this;
            this.startRequest();
            Shachi.XHR.request('POST', '/admin/resources/' + this.resourceId + '/status', {
                body: 'status=' + newStatus,
                completeHandler: function (req) { self.complete(req); },
            });
        };
        StatusPopupEditor.prototype.complete = function (res) {
            try {
                var json = JSON.parse(res.responseText);
                var status = json.status;
                this.currentElem.setAttribute('data-status', status);
                var label = this.currentElem.querySelector('.label');
                label.textContent = status;
            }
            catch (err) { }
            this.completeRequest();
        };
        return StatusPopupEditor;
    })(PopupEditor);
    Shachi.StatusPopupEditor = StatusPopupEditor;
    var EditStatusPopupEditor = (function (_super) {
        __extends(EditStatusPopupEditor, _super);
        function EditStatusPopupEditor(cssSelector, buttonSelector) {
            _super.call(this, cssSelector, buttonSelector);
        }
        EditStatusPopupEditor.prototype.change = function (elem) {
            var newStatus = elem.getAttribute('data-edit-status');
            if (!this.resourceId || !this.currentElem ||
                this.currentElem.getAttribute('data-edit-status') === newStatus) {
                this.hide();
                return;
            }
            var self = this;
            this.startRequest();
            Shachi.XHR.request('POST', '/admin/resources/' + this.resourceId + '/edit_status', {
                body: "edit_status=" + newStatus,
                completeHandler: function (req) { self.complete(req); },
            });
        };
        EditStatusPopupEditor.prototype.complete = function (res) {
            try {
                var json = JSON.parse(res.responseText);
                var editStatus = json.edit_status;
                this.currentElem.setAttribute('data-edit-status', editStatus);
                var img = this.currentElem.querySelector('img');
                img.src = '/images/admin/' + editStatus + '.png';
            }
            catch (err) { }
            this.completeRequest();
        };
        return EditStatusPopupEditor;
    })(PopupEditor);
    Shachi.EditStatusPopupEditor = EditStatusPopupEditor;
    var AnnotatorPopupEditor = (function (_super) {
        __extends(AnnotatorPopupEditor, _super);
        function AnnotatorPopupEditor(cssSelector, buttonSelector) {
            _super.call(this, cssSelector, buttonSelector);
        }
        AnnotatorPopupEditor.prototype.change = function (elem) {
            var newAnnotatorId = elem.getAttribute('data-annotator-id');
            if (!this.resourceId || !this.currentElem ||
                this.currentElem.getAttribute('data-annotator-id') === newAnnotatorId) {
                this.hide();
                return;
            }
            var self = this;
            this.startRequest();
            Shachi.XHR.request('POST', '/admin/resources/' + this.resourceId + '/annotator', {
                body: "annotator_id=" + newAnnotatorId,
                completeHandler: function (req) { self.complete(req); }
            });
        };
        AnnotatorPopupEditor.prototype.complete = function (res) {
            try {
                var json = JSON.parse(res.responseText);
                var annotator = json.annotator;
                this.currentElem.setAttribute('data-annotator-id', annotator.id);
                this.currentElem.textContent = 'Annotator: ' + annotator.name;
            }
            catch (err) { }
            this.completeRequest();
        };
        return AnnotatorPopupEditor;
    })(PopupEditor);
    Shachi.AnnotatorPopupEditor = AnnotatorPopupEditor;
})(Shachi || (Shachi = {}));
/// <reference path="xhr.ts" />
var Shachi;
(function (Shachi) {
    var ResourceEditor = (function () {
        function ResourceEditor(container) {
            this.container = container;
            this.metadataEditors = [];
        }
        ResourceEditor.prototype.metadataEditor = function (metadata, metadataLanguage) {
            if (metadataLanguage === undefined)
                metadataLanguage = 'eng';
            var inputType = metadata.getAttribute('data-input-type') || '';
            if (inputType == 'textarea')
                return new ResourceMetadataTextareaEditor(metadata, metadataLanguage);
            if (inputType == 'select')
                return new ResourceMetadataSelectEditor(metadata, metadataLanguage);
            if (inputType == 'select_only')
                return new ResourceMetadataSelectOnlyEditor(metadata, metadataLanguage);
            if (inputType == 'relation')
                return new ResourceMetadataRelationEditor(metadata, metadataLanguage);
            if (inputType == 'language')
                return new ResourceMetadataLanguageEditor(metadata, metadataLanguage);
            if (inputType == 'date')
                return new ResourceMetadataDateEditor(metadata, metadataLanguage);
            if (inputType == 'range')
                return new ResourceMetadataRangeEditor(metadata, metadataLanguage);
            return new ResourceMetadataTextEditor(metadata, metadataLanguage);
        };
        return ResourceEditor;
    })();
    var ResourceCreateEditor = (function (_super) {
        __extends(ResourceCreateEditor, _super);
        function ResourceCreateEditor(container) {
            _super.call(this, container);
            this.setup();
        }
        ResourceCreateEditor.prototype.setup = function () {
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
        };
        ResourceCreateEditor.prototype.create = function () {
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
                completeHandler: function (req) { self.createComplete(req); },
            });
        };
        ResourceCreateEditor.prototype.startRequest = function () {
            var submitButton = this.container.querySelector('#resource-create-submit');
            if (submitButton) {
                submitButton.disabled = true;
            }
            var loadingElem = this.container.querySelector('.loading');
            if (loadingElem) {
                loadingElem.style.display = 'inline-block';
            }
        };
        ResourceCreateEditor.prototype.createComplete = function (res) {
            try {
                var json = JSON.parse(res.responseText);
                if (json.resource_id) {
                    location.href = '/admin/resources/' + json.resource_id;
                }
            }
            catch (err) {
                location.href = '/admin/';
            }
        };
        ResourceCreateEditor.prototype.getValues = function () {
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
            var languages = this.container.querySelectorAll('.resource-metadata-language input');
            Array.prototype.forEach.call(languages, function (language) {
                if (!language.checked)
                    return;
                values['metadata_language'] = language.value;
            });
            return values;
        };
        return ResourceCreateEditor;
    })(ResourceEditor);
    Shachi.ResourceCreateEditor = ResourceCreateEditor;
    var ResourceUpdateEditor = (function (_super) {
        __extends(ResourceUpdateEditor, _super);
        function ResourceUpdateEditor(container) {
            _super.call(this, container);
            this.setup();
        }
        ResourceUpdateEditor.prototype.setup = function () {
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
            Array.prototype.forEach.call(metadataList, function (metadata) {
                self.metadataEditors.push(self.metadataEditor(metadata, metadataLanguage));
            });
        };
        return ResourceUpdateEditor;
    })(ResourceEditor);
    Shachi.ResourceUpdateEditor = ResourceUpdateEditor;
    var ResourceMetadataEditorBase = (function () {
        function ResourceMetadataEditorBase(container, metadataLanguage) {
            this.container = container;
            this.name = container.getAttribute('data-name');
            this.listSelector = 'li.resource-metadata-item';
            this.metadataLanguage = metadataLanguage;
            this.setup();
        }
        ResourceMetadataEditorBase.prototype.setup = function () {
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
        };
        ResourceMetadataEditorBase.prototype.addItem = function () {
            var item = this.container.querySelector(this.listSelector);
            var newItem = item.cloneNode(true);
            Array.prototype.forEach.call(newItem.querySelectorAll('input, textarea'), function (elem) {
                elem.value = "";
            });
            item.parentNode.appendChild(newItem);
            return newItem;
        };
        ResourceMetadataEditorBase.prototype.deleteItem = function () {
            var items = this.container.querySelectorAll(this.listSelector);
            if (items.length < 2)
                return;
            var removeItem = items[items.length - 1];
            removeItem.parentNode.removeChild(removeItem);
        };
        ResourceMetadataEditorBase.prototype.toValues = function () {
            var self = this;
            var items = this.container.querySelectorAll(this.listSelector);
            var values = [];
            Array.prototype.forEach.call(items, function (item) {
                var hash = self.toHash(item);
                if (hash)
                    values.push(hash);
            });
            return values;
        };
        ResourceMetadataEditorBase.prototype.toHash = function (item) {
            return undefined;
        };
        ResourceMetadataEditorBase.prototype.getDate = function (elem, prefix) {
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
        };
        return ResourceMetadataEditorBase;
    })();
    var ResourceMetadataEditorEditBase = (function (_super) {
        __extends(ResourceMetadataEditorEditBase, _super);
        function ResourceMetadataEditorEditBase(container, metadataLanguage) {
            _super.call(this, container, metadataLanguage);
        }
        ResourceMetadataEditorEditBase.prototype.setup = function () {
            _super.prototype.setup.call(this);
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
        };
        ResourceMetadataEditorEditBase.prototype.showEditor = function () {
            this.editButton.style.display = 'none';
            this.dataContainer.style.display = 'none';
            this.createForm();
            this.addDeleteButton.style.display = 'inline-block';
            this.editor.style.display = 'inline-block';
        };
        ResourceMetadataEditorEditBase.prototype.createForm = function () {
            var values = this.toValuesFromData();
            var item = this.container.querySelector(this.listSelector);
            var listContainer = item.parentNode;
            var oldItemLength = listContainer.children.length;
            var self = this;
            Array.prototype.forEach.call(values, function (value) {
                self.addItemWithValue(value);
            });
            if (values.length === 0) {
                this.addItem();
            }
            for (var i = 0; i < oldItemLength; i++) {
                listContainer.removeChild(listContainer.firstElementChild);
            }
        };
        ResourceMetadataEditorEditBase.prototype.hideEditor = function () {
            this.addDeleteButton.style.display = 'none';
            this.editor.style.display = 'none';
            this.dataContainer.style.display = 'inline-block';
            this.editButton.style.display = 'inline-block';
        };
        ResourceMetadataEditorEditBase.prototype.update = function () {
            var self = this;
            if (this.updating)
                return;
            this.startUpdate();
            var values = this.toValues();
            var json = {};
            json[this.name] = values;
            json['metadata_language'] = this.metadataLanguage;
            Shachi.XHR.request('POST', '/admin/resources/' + this.resourceId + '/metadata', {
                body: JSON.stringify(json),
                'content-type': 'application/json',
                completeHandler: function (req) { self.updateComplete(req); }
            });
        };
        ResourceMetadataEditorEditBase.prototype.startUpdate = function () {
            this.updating = true;
            if (this.loadingElem) {
                this.loadingElem.style.display = 'inline-block';
            }
            if (this.submitButton) {
                this.submitButton.disabled = true;
            }
        };
        ResourceMetadataEditorEditBase.prototype.updateComplete = function (res) {
            try {
                var json = JSON.parse(res.responseText);
                this.updateData(json);
            }
            catch (err) { }
            this.updating = false;
            if (this.loadingElem) {
                this.loadingElem.style.display = 'none';
            }
            if (this.submitButton) {
                this.submitButton.disabled = false;
            }
            this.hideEditor();
        };
        ResourceMetadataEditorEditBase.prototype.updateData = function (json) {
            var self = this;
            while (this.dataContainer.firstChild) {
                this.dataContainer.removeChild(this.dataContainer.firstChild);
            }
            var values = json[this.name] || [];
            values.forEach(function (value) {
                var elem = self.toDataFromHash(value);
                if (elem)
                    self.dataContainer.appendChild(elem);
            });
        };
        ResourceMetadataEditorEditBase.prototype.toDataFromHash = function (value) {
            return undefined;
        };
        ResourceMetadataEditorEditBase.prototype.toValuesFromData = function () {
            var self = this;
            var items = this.dataContainer.querySelectorAll('li');
            var values = [];
            Array.prototype.forEach.call(items, function (item) {
                var hash = self.toHashFromData(item);
                if (hash)
                    values.push(hash);
            });
            return values;
        };
        ResourceMetadataEditorEditBase.prototype.toHashFromData = function (item) {
            return undefined;
        };
        ResourceMetadataEditorEditBase.prototype.addItemWithValue = function (value) {
            return this.addItem();
        };
        return ResourceMetadataEditorEditBase;
    })(ResourceMetadataEditorBase);
    var ResourceMetadataEditorWithPopup = (function (_super) {
        __extends(ResourceMetadataEditorWithPopup, _super);
        function ResourceMetadataEditorWithPopup(container, metadataLanguage, targetSelector) {
            _super.call(this, container, metadataLanguage);
            this.currentQuery = '';
            this.enableRequest = true;
            this.targetSelector = targetSelector;
        }
        ResourceMetadataEditorWithPopup.prototype.setup = function () {
            _super.prototype.setup.call(this);
        };
        ResourceMetadataEditorWithPopup.prototype.registerEvent = function (item) {
            var self = this;
            item.addEventListener('keyup', function () { self.changeInput(item); });
            if (self.popupSelector) {
                item.addEventListener('blur', function () {
                    setTimeout(function () {
                        self.popupSelector.hide();
                    }, 200);
                });
            }
        };
        ResourceMetadataEditorWithPopup.prototype.addItem = function () {
            var newItem = _super.prototype.addItem.call(this);
            var item = newItem.querySelector(this.targetSelector);
            this.registerEvent(item);
            return newItem;
        };
        ResourceMetadataEditorWithPopup.prototype.changeInput = function (elem) {
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
        };
        ResourceMetadataEditorWithPopup.prototype.requestURI = function (query) {
            return '';
        };
        ResourceMetadataEditorWithPopup.prototype.complete = function (res, elem) {
            try {
                var json = JSON.parse(res.responseText);
                this.popup(elem, json);
            }
            catch (err) { }
            this.enableRequest = true;
        };
        ResourceMetadataEditorWithPopup.prototype.popup = function (elem, json) { };
        return ResourceMetadataEditorWithPopup;
    })(ResourceMetadataEditorEditBase);
    var ResourceMetadataTextEditor = (function (_super) {
        __extends(ResourceMetadataTextEditor, _super);
        function ResourceMetadataTextEditor() {
            _super.apply(this, arguments);
        }
        ResourceMetadataTextEditor.prototype.toHash = function (elem) {
            var content = elem.querySelector('.content');
            if (!content || content.value === '')
                return undefined;
            return { content: content.value };
        };
        ResourceMetadataTextEditor.prototype.toHashFromData = function (elem) {
            var content = elem.querySelector('.content');
            if (!content)
                return undefined;
            return { content: content.textContent };
        };
        ResourceMetadataTextEditor.prototype.addItemWithValue = function (value) {
            var newItem = this.addItem();
            newItem.querySelector('.content').value = value.content;
            return newItem;
        };
        ResourceMetadataTextEditor.prototype.toDataFromHash = function (value) {
            var elem = document.createElement('li');
            var content = document.createElement('span');
            content.setAttribute('class', 'content');
            content.textContent = value.content;
            elem.appendChild(content);
            return elem;
        };
        return ResourceMetadataTextEditor;
    })(ResourceMetadataEditorEditBase);
    var ResourceMetadataTextareaEditor = (function (_super) {
        __extends(ResourceMetadataTextareaEditor, _super);
        function ResourceMetadataTextareaEditor() {
            _super.apply(this, arguments);
        }
        ResourceMetadataTextareaEditor.prototype.toHash = function (elem) {
            var content = elem.querySelector('.content');
            if (!content || content.value === '')
                return undefined;
            return { content: content.value };
        };
        ResourceMetadataTextareaEditor.prototype.toHashFromData = function (elem) {
            var content = elem.querySelector('.content');
            if (!content)
                return undefined;
            return { content: content.textContent };
        };
        ResourceMetadataTextareaEditor.prototype.addItemWithValue = function (value) {
            var newItem = this.addItem();
            newItem.querySelector('.content').value = value.content;
            return newItem;
        };
        ResourceMetadataTextareaEditor.prototype.toDataFromHash = function (value) {
            var elem = document.createElement('li');
            var content = document.createElement('span');
            content.setAttribute('class', 'content');
            content.innerHTML = value.formatted_content;
            elem.appendChild(content);
            return elem;
        };
        return ResourceMetadataTextareaEditor;
    })(ResourceMetadataEditorEditBase);
    var ResourceMetadataSelectEditor = (function (_super) {
        __extends(ResourceMetadataSelectEditor, _super);
        function ResourceMetadataSelectEditor() {
            _super.apply(this, arguments);
        }
        ResourceMetadataSelectEditor.prototype.toHash = function (elem) {
            var select = elem.querySelector('select');
            var description = elem.querySelector('.description');
            var selectValue = select ? select.value : '';
            var descriptionValue = description ? description.value : '';
            if (selectValue === '' && descriptionValue === '')
                return undefined;
            return { value_id: selectValue, description: descriptionValue };
        };
        ResourceMetadataSelectEditor.prototype.toHashFromData = function (elem) {
            var value = elem.querySelector('.value');
            var description = elem.querySelector('.description');
            var valueId = value ? value.getAttribute('data-value-id') : '';
            var descriptionValue = description ? description.textContent : '';
            return { value_id: valueId, description: descriptionValue };
        };
        ResourceMetadataSelectEditor.prototype.addItemWithValue = function (value) {
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
        };
        ResourceMetadataSelectEditor.prototype.toDataFromHash = function (value) {
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
        };
        return ResourceMetadataSelectEditor;
    })(ResourceMetadataEditorEditBase);
    var ResourceMetadataSelectOnlyEditor = (function (_super) {
        __extends(ResourceMetadataSelectOnlyEditor, _super);
        function ResourceMetadataSelectOnlyEditor() {
            _super.apply(this, arguments);
        }
        ResourceMetadataSelectOnlyEditor.prototype.toHash = function (elem) {
            var select = elem.querySelector('select');
            if (!select || select.value === '')
                return undefined;
            return { value_id: select.value };
        };
        ResourceMetadataSelectOnlyEditor.prototype.toHashFromData = function (elem) {
            var value = elem.querySelector('.value');
            var valueId = value ? value.getAttribute('data-value-id') : '';
            return { value_id: valueId };
        };
        ResourceMetadataSelectOnlyEditor.prototype.addItemWithValue = function (value) {
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
        };
        ResourceMetadataSelectOnlyEditor.prototype.toDataFromHash = function (value) {
            var elem = document.createElement('li');
            var content = document.createElement('span');
            content.setAttribute('class', 'label value');
            content.setAttribute('data-value-id', value.value_id);
            content.textContent = value.value;
            elem.appendChild(content);
            return elem;
        };
        return ResourceMetadataSelectOnlyEditor;
    })(ResourceMetadataEditorEditBase);
    var ResourceMetadataRelationEditor = (function (_super) {
        __extends(ResourceMetadataRelationEditor, _super);
        function ResourceMetadataRelationEditor(container, metadataLanguage) {
            _super.call(this, container, metadataLanguage, '.description');
            this.setup();
        }
        ResourceMetadataRelationEditor.prototype.setup = function () {
            if (!this.targetSelector)
                return;
            _super.prototype.setup.call(this);
            var items = this.container.querySelectorAll(this.listSelector + ' ' + this.targetSelector);
            var self = this;
            var popup = this.container.querySelector('.relation-popup-selector');
            if (popup) {
                this.popupSelector = new RelationPopupSelector(popup);
            }
            Array.prototype.forEach.call(items, function (item) {
                self.registerEvent(item);
            });
        };
        ResourceMetadataRelationEditor.prototype.requestURI = function (query) {
            return '/admin/resources/search?query=' + query;
        };
        ResourceMetadataRelationEditor.prototype.popup = function (elem, json) {
            this.popupSelector.replace(json.resources);
            this.popupSelector.showAndMove(elem);
        };
        ResourceMetadataRelationEditor.prototype.toHash = function (elem) {
            var select = elem.querySelector('select');
            var description = elem.querySelector('.description');
            var selectValue = select ? select.value : '';
            var descriptionValue = description ? description.value : '';
            if (selectValue === '' && descriptionValue === '')
                return undefined;
            return { value_id: selectValue, description: descriptionValue };
        };
        ResourceMetadataRelationEditor.prototype.toHashFromData = function (elem) {
            var value = elem.querySelector('.value');
            var description = elem.querySelector('.description');
            var valueId = value ? value.getAttribute('data-value-id') : '';
            var descriptionValue = description ? description.textContent : '';
            return { value_id: valueId, description: descriptionValue };
        };
        ResourceMetadataRelationEditor.prototype.addItemWithValue = function (value) {
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
        };
        ResourceMetadataRelationEditor.prototype.toDataFromHash = function (value) {
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
        };
        return ResourceMetadataRelationEditor;
    })(ResourceMetadataEditorWithPopup);
    var ResourceMetadataLanguageEditor = (function (_super) {
        __extends(ResourceMetadataLanguageEditor, _super);
        function ResourceMetadataLanguageEditor(container, metadataLanguage) {
            _super.call(this, container, metadataLanguage, '.content');
            this.setup();
        }
        ResourceMetadataLanguageEditor.prototype.setup = function () {
            if (!this.targetSelector)
                return;
            _super.prototype.setup.call(this);
            var items = this.container.querySelectorAll(this.listSelector + ' ' + this.targetSelector);
            var self = this;
            var popup = this.container.querySelector('.language-popup-selector');
            if (popup) {
                this.popupSelector = new LanguagePopupSelector(popup);
            }
            Array.prototype.forEach.call(items, function (item) {
                self.registerEvent(item);
            });
        };
        ResourceMetadataLanguageEditor.prototype.requestURI = function (query) {
            return '/admin/languages/search?query=' + query;
        };
        ResourceMetadataLanguageEditor.prototype.popup = function (elem, json) {
            this.popupSelector.replace(json.languages);
            this.popupSelector.showAndMove(elem);
        };
        ResourceMetadataLanguageEditor.prototype.toHash = function (elem) {
            var content = elem.querySelector('.content');
            var description = elem.querySelector('.description');
            var contentValue = content ? content.value : '';
            var descriptionValue = description ? description.value : '';
            if (contentValue === '' && descriptionValue === '')
                return undefined;
            return { content: contentValue, description: descriptionValue };
        };
        ResourceMetadataLanguageEditor.prototype.toHashFromData = function (elem) {
            var content = elem.querySelector('.content');
            var description = elem.querySelector('.description');
            var contentValue = content ? content.textContent : '';
            var descriptionValue = description ? description.textContent : '';
            return { content: contentValue, description: descriptionValue };
        };
        ResourceMetadataLanguageEditor.prototype.addItemWithValue = function (value) {
            var newItem = this.addItem();
            newItem.querySelector('.content').value = value.content;
            newItem.querySelector('.description').value = value.description;
            return newItem;
        };
        ResourceMetadataLanguageEditor.prototype.toDataFromHash = function (value) {
            var elem = document.createElement('li');
            var content = document.createElement('span');
            content.setAttribute('class', 'label content');
            content.textContent = value.value;
            elem.appendChild(content);
            var description = document.createElement('span');
            description.setAttribute('class', 'description');
            description.textContent = value.description;
            elem.appendChild(description);
            return elem;
        };
        return ResourceMetadataLanguageEditor;
    })(ResourceMetadataEditorWithPopup);
    var ResourceMetadataDateEditor = (function (_super) {
        __extends(ResourceMetadataDateEditor, _super);
        function ResourceMetadataDateEditor() {
            _super.apply(this, arguments);
        }
        ResourceMetadataDateEditor.prototype.toHash = function (elem) {
            var date = this.getDate(elem, '');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.value : '';
            if (date === '' && descriptionValue === '')
                return undefined;
            return { content: date, description: descriptionValue };
        };
        ResourceMetadataDateEditor.prototype.toHashFromData = function (elem) {
            var content = elem.querySelector('.content');
            var date = content.textContent.split('-');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.textContent : '';
            return { year: date[0], month: date[1] || '', day: date[2] || '', description: descriptionValue };
        };
        ResourceMetadataDateEditor.prototype.addItemWithValue = function (value) {
            var newItem = this.addItem();
            newItem.querySelector('.year').value = value.year;
            newItem.querySelector('.month').value = value.month;
            newItem.querySelector('.day').value = value.day;
            newItem.querySelector('.description').value = value.description;
            return newItem;
        };
        ResourceMetadataDateEditor.prototype.toDataFromHash = function (value) {
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
        };
        return ResourceMetadataDateEditor;
    })(ResourceMetadataEditorEditBase);
    var ResourceMetadataRangeEditor = (function (_super) {
        __extends(ResourceMetadataRangeEditor, _super);
        function ResourceMetadataRangeEditor() {
            _super.apply(this, arguments);
        }
        ResourceMetadataRangeEditor.prototype.toHash = function (elem) {
            var fromDate = this.getDate(elem, 'from-');
            var toDate = this.getDate(elem, 'to-');
            var description = elem.querySelector('.description');
            var descriptionValue = description ? description.value : '';
            if (fromDate === '' && toDate === '' && descriptionValue === '')
                return undefined;
            if (fromDate === '' && toDate === '')
                return { content: '', description: descriptionValue };
            var defaultDate = '0000-00-00';
            var date = (fromDate === '' ? defaultDate : fromDate) + ' ' +
                (toDate === '' ? defaultDate : toDate);
            return { content: date, description: descriptionValue };
        };
        ResourceMetadataRangeEditor.prototype.toHashFromData = function (elem) {
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
        };
        ResourceMetadataRangeEditor.prototype.addItemWithValue = function (value) {
            var newItem = this.addItem();
            newItem.querySelector('.from-year').value = value.fromYear;
            newItem.querySelector('.from-month').value = value.fromMonth;
            newItem.querySelector('.from-day').value = value.fromDay;
            newItem.querySelector('.to-year').value = value.toYear;
            newItem.querySelector('.to-month').value = value.toMonth;
            newItem.querySelector('.to-day').value = value.toDay;
            newItem.querySelector('.description').value = value.description;
            return newItem;
        };
        ResourceMetadataRangeEditor.prototype.toDataFromHash = function (value) {
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
        };
        return ResourceMetadataRangeEditor;
    })(ResourceMetadataEditorEditBase);
    var PopupSelector = (function () {
        function PopupSelector(container) {
            this.container = container;
            this.positionTop = 0;
            this.positionLeft = 0;
        }
        PopupSelector.prototype.replace = function (dataList) {
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
        };
        PopupSelector.prototype.createItem = function (data) { };
        PopupSelector.prototype.showAndMove = function (elem) {
            this.currentElem = elem;
            this.container.style.top = (elem.offsetTop + this.positionTop) + 'px';
            this.container.style.left = (elem.offsetLeft + this.positionLeft) + 'px';
            this.show();
        };
        PopupSelector.prototype.show = function () {
            var items = this.container.querySelectorAll('li');
            if (items.length === 0) {
                this.hide();
                return;
            }
            this.container.style.display = 'block';
        };
        PopupSelector.prototype.hide = function () {
            this.container.style.display = 'none';
        };
        return PopupSelector;
    })();
    var RelationPopupSelector = (function (_super) {
        __extends(RelationPopupSelector, _super);
        function RelationPopupSelector(container) {
            _super.call(this, container);
            this.positionTop = 20;
            this.positionLeft = 0;
        }
        RelationPopupSelector.prototype.createItem = function (data) {
            var item = document.createElement('li');
            var value = data.shachi_id + ': ' + data.title;
            item.textContent = value;
            item.setAttribute('data-shachi_id', data.shachi_id);
            item.setAttribute('data-title', data.title);
            item.setAttribute('data-value', value);
            item.style.display = 'none';
            this.registerEvent(item);
            return item;
        };
        RelationPopupSelector.prototype.registerEvent = function (elem) {
            var self = this;
            elem.addEventListener('click', function () { self.changeValue(elem); });
        };
        RelationPopupSelector.prototype.changeValue = function (elem) {
            if (!this.currentElem)
                return;
            this.currentElem.value = elem.getAttribute('data-value');
        };
        return RelationPopupSelector;
    })(PopupSelector);
    var LanguagePopupSelector = (function (_super) {
        __extends(LanguagePopupSelector, _super);
        function LanguagePopupSelector(container) {
            _super.call(this, container);
            this.positionTop = 0;
            this.positionLeft = 265;
        }
        LanguagePopupSelector.prototype.createItem = function (data) {
            var item = document.createElement('li');
            item.textContent = data.code + ': ' + data.name;
            item.setAttribute('data-code', data.code);
            item.setAttribute('data-name', data.name);
            item.style.display = 'none';
            this.registerEvent(item);
            return item;
        };
        LanguagePopupSelector.prototype.registerEvent = function (elem) {
            var self = this;
            elem.addEventListener('click', function () { self.changeValue(elem); });
        };
        LanguagePopupSelector.prototype.changeValue = function (elem) {
            if (!this.currentElem)
                return;
            this.currentElem.value = elem.getAttribute('data-name');
        };
        return LanguagePopupSelector;
    })(PopupSelector);
})(Shachi || (Shachi = {}));
/// <reference path="xhr.ts" />
var Shachi;
(function (Shachi) {
    var ResourceListEditor = (function () {
        function ResourceListEditor(resource, statusEditor, editStatusEditor) {
            this.resource = resource;
            this.statusEditor = statusEditor;
            this.editStatusEditor = editStatusEditor;
            this.registerEvent();
        }
        ResourceListEditor.prototype.registerEvent = function () {
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
        };
        ResourceListEditor.prototype.delete = function () {
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
        };
        ResourceListEditor.prototype.complete = function (res) {
            try {
                var json = JSON.parse(res.responseText);
                if (json.success) {
                    this.resource.parentNode.removeChild(this.resource);
                }
            }
            catch (err) { }
        };
        return ResourceListEditor;
    })();
    Shachi.ResourceListEditor = ResourceListEditor;
})(Shachi || (Shachi = {}));
