sprite_index = sprite_add("spr_test.png", 1, false, false, 24, 24);

#event step
//x += 4 * (keyboard_check(vk_right) - keyboard_check(vk_left));
y += 4 * (keyboard_check(vk_down) - keyboard_check(vk_up));

#event keyboard:vk_left
x -= 4;

#event keyboard:vk_right
x += 4;