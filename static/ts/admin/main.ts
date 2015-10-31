"use strict";
/// <reference path="xhr.ts" />
/// <reference path="popup-editor.ts" />
/// <reference path="resource-list-editor.ts" />
/// <reference path="resource-editor.ts" />

document.addEventListener("DOMContentLoaded", function(event) {
    // /admin/
    var resources = document.querySelectorAll('li.annotator-resource[data-resource-id]');
    if ( resources && resources.length > 0 ) {
        var statusEditor = new Shachi.StatusPopupEditor('.status-popup-editor', 'li.status');
        var editStatusEditor = new Shachi.EditStatusPopupEditor('.edit-status-popup-editor', 'li.edit-status');

        Array.prototype.forEach.call(resources, function(resource) {
            new Shachi.ResourceListEditor(resource, statusEditor, editStatusEditor);
        });
    }

    // /admin/resources/create
    var form = <HTMLElement>document.querySelector('#resource-create-form');
    // /admin/resources/{id}
    var detail = <HTMLElement>document.querySelector('.resource-detail-container');
    if (form) {
        var createEditor = new Shachi.ResourceCreateEditor(form);
    } else if (detail) {
        var updateEditor = new Shachi.ResourceUpdateEditor(detail);
    }
});
