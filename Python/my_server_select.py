#! /usr/bin/env python

import socket
from selectors import DefaultSelector, EVENT_READ, EVENT_WRITE


class Server(object):

    def __init__(self):
        self.address = ('127.0.0.1', 8080)
        self.selector = DefaultSelector()
        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    def start(self):
        self.server.bind(self.address)
        self.server.listen(50)
        self.server.setblocking(False)
        # 注册ACCEPT事件
        self.selector.register(self.server.fileno(), EVENT_READ, (self.connected, self.server))
        self.loop()

    def connected(self, key, mask):
        client, addr = self.server.accept()
        print('接收客户端{}连接...'.format(addr))
        client.setblocking(False)
        # 注册读写事件
        self.selector.register(client.fileno(), EVENT_READ | EVENT_WRITE,  (self.read_write, client))

    def read_write(self, key, mask):
        if mask & EVENT_READ:  # 读事件
            self.recv(key)
        if mask & EVENT_WRITE:  # 写事件
            self.send(key)

    def recv(self, key):
        client = key.data[1]
        data = client.recv(1024)
        print('读取数据:{}'.format(data))
        self.selector.modify(client.fileno(), EVENT_READ | EVENT_WRITE,  (self.read_write, client))

    def send(self, key):
        client = key.data[1]
        print('发送数据...')
        client.send(b'\r\nHello Python\r\n')
        self.selector.modify(client.fileno(), EVENT_READ,  (self.read_write, client))

    def loop(self):
        while True:
            print('执行select...')
            data = self.selector.select()  # timeout 单位秒
            for key, mask in data:
                key.data[0](key, mask)


if __name__ == '__main__':

    server = Server()
    server.start()
