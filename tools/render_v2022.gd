extends SceneTree
## 2.0.22 상점 검수 렌더: 20:9(갤럭시 2340×1080) / 16:9(1920×1080).
## 사용: Xvfb :99 & DISPLAY=:99 godot --path . --script res://tools/render_v2022.gd
const App=preload("res://scenes/survival.tscn")
var game: Node
func _initialize() -> void:run.call_deferred()
func frames(n: int=4) -> void:
 for i in range(n):await process_frame
func capture(path: String) -> void:
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 image.save_png(path)
 print("RENDER SAVED ",path," ",image.get_size())
func run() -> void:
 root.size=Vector2i(2340,1080)
 game=App.instantiate();root.add_child(game);await frames(10)
 game.storage.data.coins=2400
 game.build("market");await frames(10)
 var items: Array=game.shop._items()
 for item in items:
  if String(item.id).ends_with("yeonhwa"):game.shop.select_item(String(item.id))
 await frames(10)
 await capture("/workspace/downloads/v2022_shop_wide.png")
 root.size=Vector2i(1920,1080)
 await frames(16)
 await capture("/workspace/downloads/v2022_shop_16x9.png")
 # 미보유 캐릭터: 해금하기 CTA 확인
 root.size=Vector2i(2340,1080)
 await frames(12)
 game.shop.select_item("daoist:muyeong");await frames(10)
 await capture("/workspace/downloads/v2022_shop_locked_wide.png")
 # 스킨·칭호 탭도 같은 톤인지 확인
 game.shop.set_tab("skin");await frames(10)
 await capture("/workspace/downloads/v2022_shop_skin_wide.png")
 game.shop.set_tab("aura");await frames(10)
 await capture("/workspace/downloads/v2022_shop_aura_wide.png")
 print("V2022 RENDER DONE")
 quit()
