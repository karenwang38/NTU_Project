# -*- coding: utf-8 -*-
from wsgiref.simple_server import make_server

'''
class MyApplication():

    def __init__(self, environ, start_response):
        self.start_response = start_response
        self.path = environ['PATH_INFO']
        self.request_method = environ['REQUEST_METHOD']

    def __iter__(self):
        if self.path == '/':
            status = '200 OK'
            response_headers = [('Content-type', 'text/plain')]
            self.start_response(status, response_headers)
            yield "I'm in the home"

        elif self.path == '/aljun':
            status = '200 OK'
            response_headers = [('Content-type', 'text/plain')]
            self.start_response(status, response_headers)
            yield "I'm in the aljun's home,it's pretty"

        else:
            status = '404 NOT FOUND'
            response_headers = [('Content-type', 'text/plain')]
            self.start_response(status, response_headers)
            yield "404 NOT FOUND"

if __name__ == "__main__":
    app = make_server('127.0.0.1', 8000, MyApplication)
    app.serve_forever()
'''
from cgi import parse_qs, escape

# html中form的method是get，action是当前页面
html = """
<html>
<body>
   <form method="get" action="">
        <p>
           Name: <input type="text" name="name" value="%(name)s">
        </p>
        <p>
            State:
            <input
                name="state" type="checkbox" value="close"
                %(checked-close)s
            > close
            <input
                name="state" type="checkbox" value="open"
                %(checked-open)s
            > open
        </p>
        <p>
            <input type="submit" value="Submit">
        </p>
    </form>
    <p>
        Name: %(name)s<br>
        State: %(state)s
    </p>
</body>
</html>
"""
park={}
def application (environ, start_response):

    # 解析QUERY_STRING
    d = parse_qs(environ['QUERY_STRING'])

    name = d.get('name', [''])[0] # 返回name對應的值
    state = d.get('state', []) # 返回state對應的值
    if len(state):
        park[name]=state[0]
        print park
    # 防止腳本注入
    name = escape(name)
    state = [escape(st) for st in state]

    response_body = html % { 
        'checked-close': ('', 'checked')['close' in state],
        'checked-open': ('', 'checked')['open' in state],
        'name': name or 'Empty',
        'state': ', '.join(state or ['No state?'])
    }

    status = '200 OK'

    # content type是text/html
    response_headers = [
        ('Content-Type', 'text/html'),
        ('Content-Length', str(len(response_body)))
    ]

    start_response(status, response_headers)
    return [response_body]

httpd = make_server('localhost', 8051, application)

# 一直處理請求
httpd.serve_forever()

print 'end'
