#!/usr/bin/env python3
"""Free hosting HTTP health + transparent WebSocket tunnel; no game authority here."""
import asyncio, json, os

async def handle(reader, writer):
    upstream = None
    try:
        headers = await asyncio.wait_for(reader.readuntil(b'\r\n\r\n'), 8)
        if len(headers) > 8192:
            return
        if b'upgrade: websocket' not in headers.lower():
            try:
                check_reader, check_writer = await asyncio.open_connection('127.0.0.1', int(os.environ.get('UPSTREAM_PORT', '10001')))
                check_writer.close()
                await check_writer.wait_closed()
                status = b'200 OK'
            except OSError:
                status = b'503 Service Unavailable'
            body = json.dumps({'service': 'seal-night', 'protocol': 3, 'status': status.decode()}).encode()
            writer.write(b'HTTP/1.1 ' + status + b'\r\nContent-Type: application/json\r\nContent-Length: ' + str(len(body)).encode() + b'\r\nConnection: close\r\n\r\n' + body)
            await writer.drain()
            return
        remote_reader, upstream = await asyncio.open_connection('127.0.0.1', int(os.environ.get('UPSTREAM_PORT', '10001')))
        upstream.write(headers)
        await upstream.drain()
        async def relay(src, dst):
            try:
                while chunk := await src.read(32768):
                    dst.write(chunk)
                    await dst.drain()
            finally:
                dst.close()
        await asyncio.gather(relay(reader, upstream), relay(remote_reader, writer))
    except (asyncio.IncompleteReadError, asyncio.LimitOverrunError, asyncio.TimeoutError, ConnectionError, OSError):
        pass
    finally:
        writer.close()
        if upstream:
            upstream.close()

async def main():
    listener = await asyncio.start_server(handle, '0.0.0.0', int(os.environ.get('PORT', '10000')), limit=16384)
    async with listener:
        await listener.serve_forever()

if __name__ == '__main__':
    asyncio.run(main())
