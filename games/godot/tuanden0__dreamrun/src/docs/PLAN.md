# Dreamrun — Plan và Spec

Nguồn gốc yêu cầu: `PROMPT.md`. Quy ước làm việc: `CLAUDE.md`. Thiết kế game: `docs/GDD.md`.
File này là **bản kế hoạch sống**: mỗi bước có trạng thái, tiêu chí hoàn thành (DoD), lệnh kiểm tra riêng, nên có thể chạy lại hoặc làm tiếp **từng bước** mà không cần làm một lần từ đầu.

Cập nhật lần cuối: 2026-10-25.

## 1. Cách tiếp tục từ bất kỳ bước nào

1. Đọc mục 3 (trạng thái) để biết bước nào xong, bước nào chưa.
2. Chọn bước trong mục 4 (chi tiết từng milestone). Mỗi bước có: file, DoD, lệnh test.
3. Chạy test của riêng bước đó, không cần chạy toàn bộ:
   - `TEST_ONLY=<tên_file_test> tools/test.sh` (ví dụ `TEST_ONLY=playtest`, `TEST_ONLY=interactables`, `TEST_ONLY=chase`).
   - Toàn bộ: `tools/test.sh` (dưới 1 phút nhờ `--fixed-fps 60`; tự cắt sau `TEST_TIMEOUT` giây, mặc định 480).
4. Kiểm tra bằng mắt (không dùng `--headless`):
   - Ảnh tĩnh: `godot --path game --resolution 1280x720 --script ../tools/screenshot.gd -- out.png 150 [start_x]`
   - Dải hoạt hình: `godot --path game --resolution 1280x720 --script ../tools/filmstrip.gd -- out.png <land|climb|rope|push|chase|run>`
5. Cập nhật bảng trạng thái ở mục 3 khi xong một bước.

Thiết lập máy (một lần): Godot 4.7.2 cài bằng `scoop install godot` (bucket `extras`); trong bash dùng `export PATH="$HOME/scoop/shims:$PATH"`. Chạy lần đầu trên checkout mới: `godot --headless --path game --import`.

## 2. Spec

### 2.1 Mục tiêu

Game platformer giải đố 2D không khí ác mộng kiểu Limbo/Inside bằng Godot 4 (GDScript). Đứa trẻ bị quái đuổi, giải đố môi trường, dùng bẫy đẩy lùi quái. Game chạy hoàn toàn offline, không có backend.

### 2.2 Phạm vi milestone 1 (vertical slice)

1 chương, 1 quái, 3 puzzle, 1 màn đuổi, 1 mini-boss bị hạ bằng bẫy, checkpoint, menu pause. **Không thêm gì khác** (`PROMPT.md:48`). Các hạng mục sau thuộc `post-slice`: audio manager, save local, cutscene thức dậy, boss cuối 3 phase.

### 2.3 Tiêu chí nghiệm thu

| # | Tiêu chí | Cách kiểm | Phạm vi |
|---|---|---|---|
| 1 | Chạy test headless, exit 0 | `tools/test.sh` | slice |
| 2 | Nhảy có coyote 100 ms và buffer 100 ms, có test cặp chấp nhận/từ chối ở 80 ms và 120 ms | `TEST_ONLY=jump_timers tools/test.sh` | slice |
| 3 | Mọi giá trị tinh chỉnh animation nằm trong `AnimationTuning` với `@export` | `TEST_ONLY=character_visual tools/test.sh` | slice |
| 4 | Gameplay chỉ nói chuyện với đồ họa qua signal; thay `Visual` bằng node rỗng thì test vẫn pass | `TEST_ONLY=player_controller tools/test.sh` | slice |
| 5 | Chết đến hồi sinh dưới 1 giây (≤ 60 physics frame) | `TEST_ONLY=chase tools/test.sh` | slice |
| 6 | Mọi file asset bên thứ ba có dòng trong `ASSETS.md` | `TEST_ONLY=assets_ledger tools/test.sh` | slice |
| 7 | Hiệu năng: 60 fps ở 1080p, tối đa 4 đèn có bóng trên màn hình, không cấp phát trong `_physics_process` của người chơi | đo bằng `--print-fps`, ghi vào DoD của milestone hình ảnh | slice |
| 8 | Chương chơi được từ đầu đến khi hạ mini-boss | bot ở `tests/test_chapter.gd` (M6) | slice |

### 2.4 Điều khiển

`move_left`, `move_right`, `jump` (Space / gamepad A), `interact` (E / gamepad X), `climb_up` (W, Up), `climb_down` (S, Down), `pause` (Esc / Start). Chạy bộ và chạy nhanh không có phím riêng: tốc độ tăng dần sau `run_ramp_time` giữ phím. Chi tiết tương tác: `docs/GDD.md`.

### 2.5 Quyết định đã chốt (ruling)

- Thứ tự milestone: gộp hai thứ tự trong `PROMPT.md` (player, môi trường, interactable, quái, bẫy).
- Audio, save local, cutscene thức dậy: `post-slice`. Không có backend: game chỉ chơi offline (quyết định 2026-10-25, đã bỏ kế hoạch Go server).
- Mini-boss: 2 phase (3 phase để dành cho boss cuối). Menu pause: chỉ icon, không chữ.
- Không dùng plugin (GUT/gdUnit): test tự viết, bộ chạy ở `game/tests/run_all.gd`.
- Rig nhân vật: cut-out bằng `Polygon2D` gắn `Bone2D`, IK chân giải tích, FABRIK cho xúc tu quái viết tay.
- Ưu tiên của người dùng: hiệu năng, code sạch dễ đọc dễ bảo trì, và hình ảnh **chân thật** (xem quy tắc trong `CLAUDE.md`).

### 2.6 Ràng buộc kiến trúc

- GDScript có kiểu, signal thay vì polling, mỗi script một trách nhiệm.
- Gameplay tham chiếu node bằng tên và signal, không phụ thuộc đồ họa cụ thể. Controller phát `state_changed`, `moved`, `landed`, `climb_progress`, `died`, `respawned`; đồ họa nằm dưới node con `Visual` và chỉ lắng nghe.
- Mọi vật va chạm hoặc đổ bóng dùng đường viền gồ ghề từ `SolidProp`; không hình chữ nhật.
- Mọi vật có trạng thái cần khôi phục khi chết thì vào nhóm `resettable` và có `save_checkpoint()` và `reset_to_checkpoint()`.
- Không commit hay push trừ khi người dùng yêu cầu. Hỏi trước khi thêm asset trả phí, plugin, đổi stack, mở rộng phạm vi.

## 3. Trạng thái

| M | Phạm vi | Trạng thái | Ghi chú |
|---|---|---|---|
| M0 | slice | **Xong** | Khung dự án, bộ chạy test, input map, sổ asset |
| M1 | slice | **Xong** | Player silhouette procedural, controller, phòng test, parallax, đèn, grain/vignette |
| M2 | slice | **Xong** | Sương, tia sáng, làm mờ theo độ sâu, cây chết, vật thể gồ ghề |
| M3 | slice | **Xong** | Thùng, cần gạt, bàn đạp, cửa, dây, ledge (bám mép theo tay, không kích hoạt khi đứng trên platform); xem 4.4 |
| M4 | slice | **Xong** | Quái FABRIK, chết, checkpoint, hồi sinh dưới 1 giây |
| Bot | công cụ | **Xong** | `FlightRecorder`, bot kịch bản, bot ngẫu nhiên, dải ảnh hoạt hình |
| M5 | slice | **Xong** | 5.1 bẫy, 5.2 mini-boss, 5.3 menu pause |
| M6 | slice | **Xong** | Lắp chương: `game/levels/chapter1.tscn` (nhập môn, 3 puzzle, màn đuổi, mini-boss), `docs/level-notes.md`, `test_chapter.gd`; là màn chính của game |
| M8 | post-slice | **Xong** | Boss cuối 3 phase: `Boss` khái quát hoá theo phase, đấu trường cuối to hơn ở cuối chương (`FinalBoss`), lối ra dời tới x=10900 |
| M7 | post-slice | **Xong** | Audio manager (vùng, bước chân, quái), save local, cutscene thức dậy, màn credits; chuỗi chương, thức dậy, credits, chương |

## 4. Chi tiết từng milestone

### 4.1 M0 — Khung dự án (xong)

- `game/project.godot` (Godot 4.7.2, 1920x1080, input map 7 action), `tools/test.sh`, `game/tests/run_all.gd`, `game/tests/test_case.gd`.
- `CLAUDE.md`, `docs/GDD.md`, `docs/level-notes.md`, `ASSETS.md`, `.gitignore`.
- Test: `test_input_map.gd`, `test_assets_ledger.gd`.
- DoD đã đạt: `tools/test.sh` exit 1 khi có lỗi (kể cả `SCRIPT ERROR` hay script không load) và exit 0 khi sạch.

### 4.2 M1 — Player (xong)

- Controller: `scripts/player/player_controller.gd`, `jump_timers.gd` (logic coyote/buffer thuần), `two_bone_ik.gd`.
- Đồ họa: `character_visual.gd`, `rig_def.gd`, `animation_tuning.gd`, `resources/player_*.tres`, `scenes/player.tscn`.
- Test: `test_jump_timers.gd`, `test_two_bone_ik.gd`, `test_player_controller.gd` (kể cả thay `Visual` bằng node rỗng), `test_character_visual.gd`.
- Trạng thái: idle, walk, run, jump, fall, land (kèm animation khuỵu gối khi đáp mạnh).

### 4.3 M2 — Môi trường (xong)

- `scripts/environment/`: `silhouette_layer.gd` (cây chết, gốc loe, cành chia nhánh; chế độ mềm cho tiền cảnh), `light_shaft.gd` (tia sáng là `PointLight2D` có texture), `solid_prop.gd` (viền gồ ghề dùng chung cho hình, va chạm, bóng).
- `shaders/`: `film_post.gdshader` (grain không dùng `sin`, vignette), `fog.gdshader`, `depth_blur.gdshader` (làm mờ theo độ sâu).
- `scenes/test_room.tscn`: bầu trời gradient, 3 lớp parallax chỉ trượt ngang, dải sương giữa các lớp, thân cây tiền cảnh mềm, bóng mềm (PCF13).
- Test: `test_solid_prop.gd`, `test_light_shaft.gd`, `test_scenes.gd`.
- Còn nợ: đo fps sau M2 và M4 (lần đo cuối: 145 fps ở M1, bị vsync giữ).

### 4.4 M3 — Interactable (xong)

Đã làm: `scripts/interactables/` gồm `crate.gd`, `lever.gd`, `pressure_plate.gd`, `door.gd`, `rope.gd`, `ledge.gd`. Trạng thái `push`, `pull`, `climb`, `hang`.

Cơ chế:
- **Thùng:** giữ `interact`, thùng đóng băng và di chuyển bằng `move_and_collide` (đẩy: thùng đi trước, bị chặn thì người dừng; kéo: thùng theo quãng người thật sự đi). Tự buông khi lệch xa hơn 110 px.
- **Cần gạt và bàn đạp:** chỉ phát signal (`toggled`, `pressed_changed`); cửa nhận bằng `set_open`; nối dây trong scene.
- **Dây:** con lắc giải tích, đứng yên cho đến khi bị đu; nhún chỉ tăng đến năng lượng của biên độ 55°; thả bằng `jump` hoặc `interact` thì văng theo đà, không cộng thêm cú nhảy.
- **Ledge:** cửa sổ bám tính theo **tay** (`hand_reach` = 112 px: chân thấp hơn mép khoảng đó thì tay chạm mép), nên nhảy thấp là bám được; đứng trên platform thì không bao giờ khớp. Đường trèo gồm ba pha: bám và treo (t 0 đến 0.3), kéo lên sát tường tới độ cao đầu gối (0.3 đến 0.65), vắt qua mép và đứng dậy (0.65 đến 1). Điều kiện bám: đang ở trên không, ở phía ngoài mép, giữ phím về phía platform (hoặc phím lên).

DoD của bước ledge (đạt ngày 2026-10-25: 3 test pass, dải ảnh `climb` đã xem, cả bộ 48 test pass):
1. `TEST_ONLY=playtest tools/test.sh`, `TEST_ONLY=interactables tools/test.sh`, `TEST_ONLY=room_bugs tools/test.sh` đều pass (bot nhảy thấp bám bằng tay; bot bấm lên khi đứng trên platform không làm gì).
2. Xem dải ảnh `climb`: người bám, treo, kéo, vắt qua, đứng dậy; không trôi ngang ở độ cao thấp.

Test: `test_interactables.gd`, `test_playtest.gd`, `test_room_bugs.gd`.

### 4.5 M4 — Quái, chết, checkpoint (xong)

- `scripts/monster/monster.gd`: thân đen to, mắt phát sáng có `PointLight2D`, đuôi follow-the-leader, 5 xúc tu FABRIK (`fabrik_chain.gd`), ẩn cho đến khi `start()`, đi cố định `speed`, giết khi chạm.
- `scripts/level/`: `checkpoint.gd` (gốc cây có nến), `checkpoint_manager.gd` (chết, mờ đen, khôi phục nhóm `resettable`, hồi sinh trong 0.55 giây), `trigger.gd` (vùng kích hoạt một lần).
- Player: `die()`, `respawn()`, `is_dead`, trạng thái `die` (ngã gục).
- Test: `test_fabrik.gd`, `test_chase.gd`.

### 4.6 Bộ công cụ chơi thử (xong)

- `game/tests/flight_recorder.gd`: ghi mỗi frame, báo dịch chuyển tức thời, bay không đúng trọng lực, rơi xuyên sàn, nhảy cao hơn cho phép, đáp mạnh mà không có sự kiện đáp.
- `game/tests/test_playtest.gd`: bot nhảy, bám mép, đu dây, đẩy thùng vào tường, bot nhấn phím ngẫu nhiên (3 seed) trong `test_room`.
- `tools/screenshot.gd`, `tools/filmstrip.gd`.
- Quy tắc: tính năng mới phải có bot chơi cả đường đúng lẫn đường sai; bot dùng đúng vật trong `test_room.tscn`; lỗi do người dùng báo thành kịch bản bot trước rồi mới sửa.

### 4.7 M5 — Bẫy, mini-boss, menu pause (xong)

Bước 5.1 — Bẫy dùng lại được (**xong 2026-10-25**: `test_traps.gd` 6 test, 3 bot trong `test_playtest.gd`, cả bộ 57 test pass, ảnh đã xem).
- File: `scripts/traps/trap.gd` (lớp cơ sở: `armed`, `trigger()`, phát `sprung`), các bẫy cụ thể: vật rơi (đá hoặc gai rơi lên đường quái), điện và lửa (vùng gây sát thương theo thời gian).
- Nối với cần gạt hoặc bàn đạp bằng signal trong scene.
- Quái nhận hiệu ứng qua API mới: `Monster.stun(seconds)` (dừng lại và phản ứng), `Monster.hit()`.
- Đã làm: `Trap` (vùng `size`, `trigger(on)` nhận trực tiếp signal bàn đạp hoặc cần gạt, dùng một lần, khôi phục theo checkpoint), `DropTrap` (đá rơi, vùng được kiểm tra đúng lúc đá chạm đất nên phải canh thời điểm), `ShockTrap` (điện giữ quái choáng suốt `active_time`), `SolidProp.Kind.ROCK`. Quái choáng thì đứng yên, run, xúc tu co lại và **không giết**. Đá rơi ghìm quái 30 s (hết khi checkpoint khôi phục), nằm lại làm vật cản rắn, và đè chết người đứng dưới lúc chạm đất; bẫy điện không hại người chơi. Trong `test_room`: PlateT (2250) và thùng CrateT bật đá ở 1900; LeverT (2800) bật điện ở 2450. Bẫy có `rearm_after` (nạp lại sau N giây; cần gạt phải tắt rồi bật lại). `Monster.hit()` có sẵn nhưng chưa ai gọi (boss tính đòn khi bị `stun` mới).
- DoD: bẫy kích hoạt thì quái dừng hoặc chậm đúng thời gian; có test `test_traps.gd` và bot (đẩy thùng lên bàn đạp, quái đi qua bẫy).
- Phải thêm bẫy vào `test_room.tscn`; bẫy là `resettable`.

Bước 5.2 — Mini-boss 2 phase (**xong 2026-10-25**: `test_boss.gd` 7 test, 2 bot trong `test_playtest.gd`, cả bộ 71 test pass, ảnh đã xem).
- File: `scripts/monster/boss.gd` (kế thừa hoặc dùng lại `Monster`), cảnh đấu trường.
- Phase 1: lao qua đấu trường theo nhịp, người chơi kích bẫy để làm nó choáng. Phase 2: nhanh hơn, thêm mẫu tấn công thứ hai. Hạ bằng bẫy, không tấn công trực tiếp.
- Đã làm: `Boss` kế thừa `Monster` (tách `_advance`, `_kill_touching`). Chu kỳ: đi tuần về phía người chơi, gồng (xúc tu dựng lên), lao tới mép đấu trường phía người chơi, hồi. Bẫy làm choáng = một đòn (`hits_to_win` = 2); choáng tối đa `max_stun` 6 s. Sau đòn đầu (phase 2): nhanh gấp 1.4 và lao hai lần liền (quay lại phía kia). Chết thì gục xuống (`scale.y` 0.45), xúc tu rũ. Người chơi đứng ngoài hai mép đấu trường thì an toàn. Đấu trường trong `test_room` ở x -2500..-1900: BossTrigger -1550, CheckpointC -1480, hốc đông (LeverBR -1730, bật điện ShockTrapB -1960), hốc tây (CheckpointD -2640 giữa trận, LeverBL -2670, bật đá DropTrapB -2440); hai bẫy nạp lại sau 8 s.
- DoD: máy trạng thái (tuần, lao, choáng, chết) có test đơn vị; bot hạ boss bằng bẫy; checkpoint trong đấu trường khôi phục đúng.

Bước 5.3 — Menu pause chỉ icon (**xong 2026-10-25**: `test_pause.gd` 9 test, bot bấm pause dồn dập, bot chơi như người thật thỉnh thoảng bấm pause, cả bộ 84 test pass, ảnh đã xem).
- File: `scenes/pause_menu.tscn`, `scripts/ui/pause_menu.gd`; `process_mode = PROCESS_MODE_ALWAYS`, `get_tree().paused`.
- Hành động: tiếp tục, về checkpoint, thoát; điều khiển bằng phím mũi tên và gamepad.
- DoD: test kiểm `paused` dừng vật lý và tiếp tục khi nhả; không có chữ trên màn hình.
- Đã làm: `PauseMenu` (CanvasLayer, `PROCESS_MODE_ALWAYS`) vẽ ba icon bằng `_draw` (tam giác tiếp tục, mũi tên vòng về checkpoint, dấu chéo thoát), Esc hoặc Start mở và đóng, mũi tên hoặc D-pad chọn, Enter/Space/A xác nhận. "Về checkpoint" gọi `player.die()` để `CheckpointManager` chạy cảnh mờ và hồi sinh quen thuộc (dưới 1 s). Bỏ qua pause khi người chơi đang chết (nếu không màn hình đen sẽ đứng yên). Chưa có chuột (ponytail: thêm khi cần). Có trong `test_room.tscn`.

Rủi ro: cửa đóng đè lên thùng hoặc người (xem mục 5). Xử lý khi thêm bẫy cơ học.

### 4.8 M6 — Lắp chương (xong 2026-10-25)

- File: `game/levels/chapter1.tscn`, `docs/level-notes.md` (bố cục, vị trí checkpoint, thứ tự bẫy), `game/tests/test_chapter.gd`.
- Nội dung: đoạn nhập môn (nhảy, bám mép, đu dây), puzzle 1 (thùng và bàn đạp và cửa), puzzle 2 (cần gạt và cửa), puzzle 3 (kết hợp thùng và bám mép hoặc dây), màn đuổi một chiều với quái từ phía sau, đấu trường mini-boss.
- Danh sách `resettable` đầy đủ cho từng đoạn; checkpoint trước mỗi đoạn.
- Đã làm: bố cục, vị trí, checkpoint và thứ tự bẫy ở `docs/level-notes.md`. Chương dài khoảng 9000 px, kết thúc ở `ExitTrigger` (gọi `Chapter.finish`: mờ đen rồi phát `completed`). Tường là `PILLAR` gồ ghề, vùng bám mép đặt theo đường viền đo thật. `project.godot` chạy `chapter1.tscn`; `test_room.tscn` vẫn là phòng thử cho bot ngẫu nhiên.
- Đo: 1920x1080, RTX 3060, tắt vsync: trung bình 451 fps, 1% thấp nhất 326 fps, khung tệ nhất 3.8 ms (`tools/fps.gd`); tối đa 4 đèn có bóng gần màn hình (test).
- DoD (đã đạt): bot chơi từng đoạn từ checkpoint của đoạn đó (không cần chạy một lần cả chương), cộng một bot chạy hết chương; `TEST_ONLY=chapter tools/test.sh` pass; fps đo ở 1080p.

### 4.10 M8 — Boss cuối 3 phase (post-slice, xong 2026-10-25)

- `Boss` giờ có `speedups`, `charges_per_attack`, `recover_scales` theo phase (mảng, số phần tử = số phase); `hits_to_win` = 3 cho boss cuối, 2 cho boss nhỏ (không bao giờ tới phase 3). Phase 1: một cú lao, hồi 1.2 s. Phase 2: nhanh 1.4x, hai cú lao liền. Phase 3: nhanh 1.8x, ba cú lao liền, hồi chỉ 0.33 s, nên phải bật bẫy sớm trước khi boss tới.
- Đấu trường cuối trong `chapter1.tscn`: x 9500 đến 10400, `FinalBoss` to hơn (đầu 210x240, 7 xúc tu), cần gạt điện ở hốc tây, cần gạt đá ở hốc đông (dùng đá hai lần, cần tắt cần gạt rồi bật lại sau khi bẫy nạp lại), hai checkpoint (`CheckpointFinal`, `CheckpointFinalMid`), lối ra ở x=10900. Chi tiết: `docs/level-notes.md`.
- Test: `test_boss.gd` (tốc độ, số cú lao và thời gian hồi theo phase, đòn thứ ba mới hạ được, checkpoint ở phase 3), `test_chapter.gd` (bot đánh bại boss cuối từ `CheckpointFinal`, một lượt hết chương, đèn, thứ tự vùng âm thanh và lưu).
- Bẫy lửa (`FireTrap`, `scripts/traps/fire_trap.gd`) đã thêm sau đó: cháy 3.5 s giữ quái như bẫy điện, không hại người chơi; dùng cho đòn thứ ba của boss cuối (cần gạt thứ hai ở hốc đông), có trong `test_room.tscn`, `test_traps.gd` và một bot trong `test_playtest.gd`.
- Cờ `--new-game` (`godot --path game -- --new-game`) xoá save và chơi lại từ đầu (`Progress.new_game`).

### 4.9 M7 — Audio, save, cutscene (post-slice, xong 2026-10-25)

- `AudioManager`: lớp ambient theo vùng, tiếng bước theo trạng thái, âm quái theo khoảng cách. Không thoại, không chữ khi chơi.
- Asset: tải về `game/assets/_incoming/<tên>`, kiểm tra, chỉ chuyển file dùng vào `game/assets/`, ghi một dòng vào `ASSETS.md`; âm thanh chuẩn hóa và đổi sang `.ogg` (ffmpeg có sẵn); texture chuyển xám (ImageMagick có sẵn). Ưu tiên CC0 (freesound, Kenney, OpenGameArt, ambientCG). CC-BY chỉ khi ghi lại và hiện ở màn credits sau cutscene. Nếu trang chặn tải tự động thì dừng và đưa URL cùng đường dẫn đích cho người dùng.
- Save local JSON ở `user://` với trường `version` và `saved_at`.
- Cutscene thức dậy: phòng ngủ ánh sáng ấm, tương phản với các màn trước.
- Đã làm:
  - **Âm thanh** không tải về mà **tạo bằng ffmpeg** (`tools/gen_audio.sh`, 11 file `.ogg` trong `game/assets/audio/`, mỗi file có dòng trong `ASSETS.md`): không phụ thuộc trang web chặn tải, không rủi ro giấy phép, chạy lại được. Chưa ai nghe thử (tôi không nghe được). Thay bằng bản thu thật chỉ cần giữ đúng tên file.
  - `AudioManager` (`scripts/audio/`): các lớp nền (`wind`, `drone`, `drips`) đổi âm lượng theo `AudioZone` người chơi đang đứng (4 vùng trong chương), bước chân theo quãng đường đi (không theo animation; chạy dài sải hơn, đẩy thùng nhỏ tiếng), tiếng đáp theo lực, tiếng rền của quái to dần khi lại gần (`proximity`), tắt khi quái bị giữ. Không có thoại, không có nhạc.
  - **Save** (`scripts/save/`): `SaveGame` ghi JSON có `version` và `saved_at` vào `user://dreamrun_save.json` (ghi file tạm rồi thay; file hỏng, thiếu hay sai version đọc như "không có save"). `Progress` lưu mỗi checkpoint chạm tới và khôi phục ở lần mở sau; chương đã xong thì bắt đầu lại. Chỉ lưu vị trí, không lưu thế giới (chương đi một chiều). Test runner đặt `DREAMRUN_SAVE` để không đụng save thật.
  - **Cutscene** `scenes/wake_up.tscn`: phòng ngủ sáng ấm bằng các đường viền gồ ghề của game, tia nắng cửa sổ, tiếng chim, đứa trẻ ngồi dậy; khoảng 10 s, không chữ. **Credits** `scenes/credits.tscn`: chữ trắng cuộn trên nền đen; `THIRD_PARTY` trong `credits.gd` phải liệt kê mọi dòng CC-BY của `ASSETS.md` (có test; hiện chưa có dòng nào).
  - Luồng: `Chapter.finish()` (mờ đen) sang `wake_up.tscn` sang `credits.tscn` sang `chapter1.tscn` (chơi lại từ đầu).
  - Đã tìm ra và sửa: tia sáng cửa sổ của cutscene không bao giờ sáng vì `LightShaft` tính lại `energy` từ giá trị lúc khởi tạo (nay có `base_energy` công khai).

## 5. Vấn đề đã biết và việc còn nợ

| Mục | Mô tả | Khi nào xử lý |
|---|---|---|
| Cửa đè | **Đã sửa 2026-10-25.** Cửa không đóng khi thùng hoặc người đang ở dưới (`Door.Gateway`), chờ rồi hạ xuống khi trống; `is_open` vẫn đổi ngay, `is_held_up()` cho biết cửa còn bị giữ. Test trong `test_interactables.gd` | — |
| Tốc độ quái | 150 px/s < tốc độ chạy 260 px/s nên rất dễ thoát; chưa có phản hồi của người dùng | M5 hoặc M6, khi chỉnh độ khó |
| Xúc tu quái | Đoạn thẳng nối tròn, trông hơi giống chân nhện; muốn mềm hơn cần thêm khớp hoặc đường cong | Khi đánh bóng hình ảnh |
| Hiệu năng | Đã đo ở M6: 451 fps trung bình ở 1080p | — |
| Đẩy thùng vào vật rơi | Thùng "kéo ra khỏi mép sàn" chưa xử lý (đã có trọng lực nhẹ khi giữ) | M6 nếu bố cục cần |
| Độ chi tiết hình | Nhân vật và vật thể là hình đen có viền gồ ghề; chi tiết vẽ tay (ván gỗ, rêu, nứt) cần texture CC0 chuyển xám | Tùy chọn, cần người dùng tải tay nếu trang chặn |
| Tay đẩy thùng | Tay đặt lên mặt thùng bằng IK (signal `grab_contact`); đã có bot đo khoảng cách tay đến mặt thùng khi đẩy và kéo | Đã sửa 2026-10-25 |
| Cú trèo | Chỉ có bám từ bên trái; chưa có trèo xuống hoặc từ phía phải | Khi level cần |
| Kẹt trên sàn | **Đã sửa 2026-10-25.** Người chơi đứng yên trên đỉnh nhọn của sàn (x≈2348 đến 2375 trong `test_room`) không đi được hướng nào: lún 0.001 px nên mọi hướng đều báo va chạm. Chữa bằng `safe_margin = 0.3` trong `player.tscn`. Bot: `FlightRecorder` phát hiện kẹt, `test_player_sim.gd`, `test_room_bugs.gd` | — |
| Bot chơi chưa giải hết puzzle | Bot như người chơi (`test_player_sim.gd`) qua được nhập môn (log, tường, bám mép) và màn đuổi, nhưng chưa tự giải 3 puzzle trong 45 s ở chương; mỗi puzzle có bot giải riêng trong `test_chapter.gd` | Khi cần chứng minh puzzle giải được bằng thử sai |

## 6. Bài học từ các lỗi đã gặp (đã thành quy tắc trong `CLAUDE.md`)

- Bot phải chạy trên đúng vật của `test_room.tscn`; một bot dùng dây cấu hình riêng đã bỏ sót dây tự lắc trong scene thật.
- Chỉ test đường đúng là chưa đủ: phải có đường sai (bấm lên khi đứng trên platform, đẩy thùng vào tường).
- Ép vận tốc một `RigidBody2D` mỗi frame làm nó bị tống ra khi va vật khác; dùng đóng băng và `move_and_collide`.
- Hàm hash dùng `sin()` tạo vân chéo trên màn hình; bóng cứng của đèn tạo vệt chéo; cành mảnh dưới ~2.5 px bị răng cưa thành vệt.
- Không báo xong thay đổi hình ảnh khi chưa chụp ảnh nhìn tận mắt.

## 7. Định nghĩa "xong" cho mỗi bước (áp dụng cho mọi milestone)

1. Có DoD cụ thể và lệnh kiểm tra cho riêng bước đó.
2. Bot chơi thử cả đường đúng và đường sai; vật mới có trong `test_room.tscn` và nhóm `resettable` nếu có trạng thái.
3. Test của bước pass; test toàn bộ pass trước khi báo xong milestone.
4. Thay đổi hình ảnh đã chụp ảnh hoặc dải ảnh và đã xem.
5. Cập nhật `docs/GDD.md` (điều khiển, cơ chế) và bảng trạng thái ở mục 3 của file này.
6. Không commit hay push khi người dùng chưa yêu cầu.
