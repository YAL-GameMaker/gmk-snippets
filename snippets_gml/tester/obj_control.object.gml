#event create
start_time = current_time;

#event keypress:vk_escape
if (keyboard_check(vk_shift)) {
	game_end_direct()
} else {
	game_end();
}

#event keypress:vk_f5
game_restart();

#event draw
draw_text(5, 5, string((current_time - start_time) div 1000))