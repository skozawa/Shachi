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
            if ('content-type' in options)
                req.setRequestHeader('Content-Type', options['content-type']);
            if (method === 'POST' && 'body' in options)
                req.setRequestHeader('Content-Type', options['content-type'] || 'application/x-www-form-urlencoded');
            req.send(('body' in options) ? options.body : null);
            return req;
        }
    }
}
