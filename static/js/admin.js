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
                req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.send(('body' in options) ? options.body : null);
            return req;
        }
        XHR.request = request;
    })(XHR = Shachi.XHR || (Shachi.XHR = {}));
})(Shachi || (Shachi = {}));
var Shachi;
(function (Shachi) {
    class PopupEditor {
        constructor(cssSelector) {
            this.container = document.querySelector(cssSelector);
            if (!this.container)
                return;
            this.closeButton = this.container.querySelector('.close');
            this.registerEvent();
        }
        registerEvent() {
            var self = this;
            if (self.closeButton) {
                self.closeButton.addEventListener('click', function () {
                    self.hide();
                });
            }
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
        constructor(cssSelector) {
            super(cssSelector);
            if (!this.container)
                return;
            this.statusButtons = this.container.querySelectorAll('li.status');
            this.register();
        }
        register() {
            var self = this;
            if (this.statusButtons) {
                Array.prototype.forEach.call(this.statusButtons, function (button) {
                    button.addEventListener('click', function () {
                        self.changeStatus(button.getAttribute('data-status'));
                    });
                });
            }
        }
        showWithSet(resource, elem) {
            this.resourceId = resource.getAttribute('data-resource-id');
            if (!this.resourceId) {
                this.hide();
                return;
            }
            this.currentElem = elem;
            super.showAndMove(elem);
        }
        changeStatus(newStatus) {
            console.log(newStatus);
        }
    }
    Shachi.StatusPopupEditor = StatusPopupEditor;
    class EditStatusPopupEditor extends PopupEditor {
        constructor(cssSelector) {
            super(cssSelector);
            if (!this.container)
                return;
            this.statusButtons = this.container.querySelectorAll('li.edit-status');
            this.register();
        }
        register() {
            var self = this;
            if (this.statusButtons) {
                Array.prototype.forEach.call(this.statusButtons, function (button) {
                    button.addEventListener('click', function () {
                        self.changeEditStatus(button.getAttribute('data-edit-status'));
                    });
                });
            }
        }
        showWithSet(resource, elem) {
            this.resourceId = resource.getAttribute('data-resource-id');
            if (!this.resourceId) {
                this.hide();
                return;
            }
            this.currentElem = elem;
            super.showAndMove(elem);
        }
        changeEditStatus(newStatus) {
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
document.addEventListener("DOMContentLoaded", function (event) {
    var editStatusEditor = new Shachi.EditStatusPopupEditor('.edit-status-popup-editor');
    var statusEditor = new Shachi.StatusPopupEditor('.status-popup-editor');
    var resources = document.querySelectorAll('li.annotator-resource[data-resource-id]');
    Array.prototype.forEach.call(resources, function (resource) {
        var editStatus = resource.querySelector('li.edit-status');
        if (editStatus) {
            editStatus.addEventListener('click', function () {
                editStatusEditor.showWithSet(resource, editStatus);
            });
        }
        var status = resource.querySelector('li.status');
        if (status) {
            status.addEventListener('click', function () {
                statusEditor.showWithSet(resource, status);
            });
        }
    });
});
