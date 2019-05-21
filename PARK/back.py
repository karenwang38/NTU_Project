# -*- coding: utf-8 -*-
from wsgiref.simple_server import make_server
import json
from cgi import parse_qs, escape
html = """
<html>
<body>
   <form method="get" action="">
        <p>
           ID: <input type="text" name="id" value="%(id)s">
        </p>
        <p>
           Name: <input type="text" name="name" value="%(name)s">
        </p>
        <p>
           Location: <input type="text" name="location" value="%(location)s">
        </p>
        <p>
           Price: <input type="text" name="price" value="%(price)s">
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
        ID: %(id)s<br>
        Name: %(name)s<br>
        Location: %(location)s<br>
        Price: %(price)s<br>
        State: %(state)s
    </p>
</body>
</html>
"""
park=[]
def application (environ, start_response):

    # 解析QUERY_STRING
    d = parse_qs(environ['QUERY_STRING'])
    id = d.get('id', [''])[0] # 返回id對應的值
    name = d.get('name', [''])[0] # 返回name對應的值
    location = d.get('location', [''])[0] # 返回location對應的值
    price = d.get('price', [''])[0] # 返回price對應的值
    state = d.get('state', []) # 返回state對應的值
    if len(state)==1 and id.isdigit() and name!='' and location!='' and price.isdigit():
        new_park={}
        new_park["id"]=id
        new_park["name"]=name
        new_park["location"]=location
        new_park["price"]=price
        new_park["state"]=state[0]
        for i in range(len(park)):
            if park[i]["id"] == id:
                del park[i]
        park.append(new_park)
    
    json_park = json.dumps(park)
    with open('data.json', 'w') as f:
        json.dump(json_park, f)
    print (park)
    # 防止腳本注入
    id = escape(id)
    name = escape(name)    
    location = escape(location)
    price = escape(price)
    state = [escape(st) for st in state]

    response_body = html % { 
        'checked-close': ('', 'checked')['close' in state],
        'checked-open': ('', 'checked')['open' in state],
        'id': id or '',
        'name': name or '',
        'location': location or '',
        'price': price or '',
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
