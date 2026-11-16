class_name SealCodec
extends RefCounted
## Native binary WebSocket gzip frames reduce free-host outbound traffic.
static func decode(bytes: PackedByteArray) -> Dictionary:
 if bytes.size()>131072:return {}
 if bytes.size()>2 and bytes[0]==31 and bytes[1]==139:
  bytes=bytes.decompress_dynamic(131072,FileAccess.COMPRESSION_GZIP)
  if bytes.is_empty():return {}
 var value=JSON.parse_string(bytes.get_string_from_utf8())
 return value if value is Dictionary else {}
