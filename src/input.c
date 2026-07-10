/*
 * input.c - ورودی ۴ دسته‌ی مستقل PS4 (OpenOrbis) در قالب ۲ تیم ۲نفره
 *
 * هر ۴ دسته با scePadOpen به‌صورت جدا باز میشن (index 0 تا 3).
 * اگه بعضی از دسته‌ها وصل نباشن، خطا نمیده - فقط اون‌ها رو نادیده می‌گیره
 * و هم‌تیمیش (اگه وصل باشه) تنهایی راکت رو کنترل می‌کنه.
 */

#include "input.h"
#include "config.h"
#include <stdio.h>
#include <orbis/Pad.h>
#include <orbis/UserService.h>

#define NUM_PADS 4

static int32_t g_pad_handles[NUM_PADS] = { -1, -1, -1, -1 };

int input_init(void)
{
    printf("[Input] Initializing Pad...\n");

    int32_t result = scePadInit();
    if (result < 0) {
        printf("[Input] scePadInit failed: 0x%x\n", result);
        return 1;
    }

    int32_t user_id = 0;
    result = sceUserServiceGetInitialUser(&user_id);
    if (result < 0) {
        printf("[Input] sceUserServiceGetInitialUser failed: 0x%x\n", result);
        return 1;
    }

    int connected_count = 0;
    for (int i = 0; i < NUM_PADS; i++) {
        g_pad_handles[i] = scePadOpen(user_id, 0, i, NULL);
        if (g_pad_handles[i] < 0) {
            printf("[Input] Pad %d not connected (0x%x)\n", i + 1, g_pad_handles[i]);
            g_pad_handles[i] = -1;
        } else {
            printf("[Input] Pad %d initialized (handle=%d)\n", i + 1, g_pad_handles[i]);
            connected_count++;
        }
    }

    /* حداقل یه دسته باید وصل باشه تا بازی اصلا قابل کنترل باشه */
    if (connected_count == 0) {
        printf("[Input] Error: no controller connected\n");
        return 1;
    }

    printf("[Input] %d/%d pads connected\n", connected_count, NUM_PADS);
    return 0;
}

/* ترکیب ورودی دو نفر یه تیم: هر کدوم بالا/پایین بزنه، راکت همون کارو می‌کنه */
static void read_team(int idx_a, int idx_b, float *out_y, int *connected_a, int *connected_b)
{
    int up = 0, down = 0;
    *connected_a = 0;
    *connected_b = 0;

    if (g_pad_handles[idx_a] >= 0) {
        OrbisPadData pad;
        if (scePadReadState(g_pad_handles[idx_a], &pad) >= 0) {
            *connected_a = 1;
            if (pad.buttons & ORBIS_PAD_BUTTON_UP)   up = 1;
            if (pad.buttons & ORBIS_PAD_BUTTON_DOWN) down = 1;
        }
    }

    if (g_pad_handles[idx_b] >= 0) {
        OrbisPadData pad;
        if (scePadReadState(g_pad_handles[idx_b], &pad) >= 0) {
            *connected_b = 1;
            if (pad.buttons & ORBIS_PAD_BUTTON_UP)   up = 1;
            if (pad.buttons & ORBIS_PAD_BUTTON_DOWN) down = 1;
        }
    }

    if (up) {
        *out_y = -PADDLE_SPEED;
    } else if (down) {
        *out_y = PADDLE_SPEED;
    } else {
        *out_y = 0;
    }
}

void input_read(input_t *input)
{
    if (!input) return;

    int c0, c1, c2, c3;

    /* تیم ۱: دسته ۰ و ۱  -> راکت چپ */
    read_team(0, 1, &input->p1_y, &c0, &c1);

    /* تیم ۲: دسته ۲ و ۳  -> راکت راست */
    read_team(2, 3, &input->p2_y, &c2, &c3);

    input->pads_connected[0] = c0;
    input->pads_connected[1] = c1;
    input->pads_connected[2] = c2;
    input->pads_connected[3] = c3;

    /* منو/خروج فقط از دسته‌ی اول خونده میشه */
    input->menu_select = 0;
    input->quit = 0;
    if (g_pad_handles[0] >= 0) {
        OrbisPadData pad;
        if (scePadReadState(g_pad_handles[0], &pad) >= 0) {
            input->menu_select = (pad.buttons & ORBIS_PAD_BUTTON_CROSS) ? 1 : 0;
            input->quit = (pad.buttons & ORBIS_PAD_BUTTON_OPTIONS) ? 1 : 0;
        }
    }
}

void input_shutdown(void)
{
    for (int i = 0; i < NUM_PADS; i++) {
        if (g_pad_handles[i] >= 0) {
            scePadClose(g_pad_handles[i]);
            g_pad_handles[i] = -1;
        }
    }
    printf("[Input] Shutdown\n");
}
