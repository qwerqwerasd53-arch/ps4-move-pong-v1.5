/*
 * video.c - خروجی تصویر PS4 با رسم مستقیم پیکسل (CPU rendering)، بدون GPU pipeline
 *
 * هشدار صادقانه: این بخش برخلاف input.c/Pad API که مستقیما از مستندات
 * رسمی OpenOrbis تایید شد، بر اساس الگوی رایج و شناخته‌شده در نمونه‌های
 * جامعه‌ی هوم‌بروی PS4 (سمپل‌های 2D رندرینگ OpenOrbis) نوشته شده.
 * چون گیت‌هاب اکشن نمی‌تونه رو یه PS4 واقعی تستش کنه، فقط کامپایل‌شدنش
 * تضمین میشه، نه صد در صد رفتار درستش رو صفحه تلویزیون. اگه بعد از اجرا
 * رو کنسول واقعی، خروجی رو صفحه نیومد، اولین جای مشکوک همین فایله.
 */

#include "video.h"
#include "config.h"
#include <stdio.h>
#include <string.h>
#include <sys/types.h>   /* برای تایپ‌های u_short/u_int که orbis/_types/kernel.h بهشون نیاز داره */
#include <orbis/VideoOut.h>
#include <orbis/libkernel.h>

#define NUM_BUFFERS 2

static int32_t g_video_handle = -1;
static uint32_t *g_buffers[NUM_BUFFERS];
static off_t g_direct_mem_off[NUM_BUFFERS];
static size_t g_buffer_size = 0;
static int g_current_buffer = 0;

static size_t align_up(size_t value, size_t align)
{
    return (value + align - 1) & ~(align - 1);
}

int video_init(void)
{
    printf("[Video] Initializing VideoOut...\n");

    g_video_handle = sceVideoOutOpen(0xff /* ORBIS_VIDEO_USER_MAIN */,
                                      ORBIS_VIDEO_OUT_BUS_MAIN, 0, NULL);
    if (g_video_handle < 0) {
        printf("[Video] sceVideoOutOpen failed: 0x%x\n", g_video_handle);
        return 1;
    }

    size_t stride = SCREEN_WIDTH * sizeof(uint32_t);
    size_t frame_size = stride * SCREEN_HEIGHT;
    g_buffer_size = align_up(frame_size, 16 * 1024 * 1024); /* align به 16MB */

    for (int i = 0; i < NUM_BUFFERS; i++) {
        /* توجه: هدر واقعی این تولچین (libkernel.h همین ایمیج داکر) این تابع
         * رو دقیقاً این‌طور تعریف کرده:
         *   int32_t sceKernelAllocateMainDirectMemory(size_t, size_t, int, off_t);
         * یعنی پارامتر آخر واقعاً off_t هست، نه off_t* (برخلاف مستندات
         * عمومی PS4 SDK که برای این خانواده توابع pointer انتظار دارن).
         * پس باید دقیقاً با off_t صداش بزنیم؛ چون PS4 روی x86-64 هست،
         * آدرس و مقدار ۶۴بیتی هر دو یک رجیستر رو اشغال می‌کنن، این cast
         * صرفاً برای عبور از type-check کامپایلره. */
        int result = sceKernelAllocateMainDirectMemory(
            g_buffer_size, 16 * 1024 * 1024,
            ORBIS_KERNEL_WB_ONION, (off_t)(intptr_t)&g_direct_mem_off[i]);
        if (result < 0) {
            printf("[Video] sceKernelAllocateMainDirectMemory failed: 0x%x\n", result);
            return 1;
        }

        void *addr = NULL;
        result = sceKernelMapDirectMemory(&addr, g_buffer_size,
                                           ORBIS_KERNEL_PROT_CPU_RW,
                                           0, g_direct_mem_off[i], 16 * 1024 * 1024);
        if (result < 0) {
            printf("[Video] sceKernelMapDirectMemory failed: 0x%x\n", result);
            return 1;
        }

        g_buffers[i] = (uint32_t *)addr;
        memset(g_buffers[i], 0, g_buffer_size);
    }

    OrbisVideoOutBufferAttribute attr;
    /* tmode و aspect تو هدر واقعی هیچ ثابتی ندارن؛ 0 (خطی/پیش‌فرض) رایج‌ترین
     * مقداره تو نمونه‌های جامعه‌ی هوم‌بروی OpenOrbis برای این دو فیلد. */
    sceVideoOutSetBufferAttribute(&attr,
                                   ORBIS_VIDEO_OUT_PIXEL_FORMAT_A8B8G8R8_SRGB,
                                   0 /* tmode: linear */,
                                   0 /* aspect: default */,
                                   SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_WIDTH);

    int result = sceVideoOutRegisterBuffers(g_video_handle, 0,
                                             (void **)g_buffers, NUM_BUFFERS, &attr);
    if (result < 0) {
        printf("[Video] sceVideoOutRegisterBuffers failed: 0x%x\n", result);
        return 1;
    }

    printf("[Video] VideoOut initialized (handle=%d)\n", g_video_handle);
    return 0;
}

void video_clear(uint32_t color)
{
    uint32_t *buf = g_buffers[g_current_buffer];
    for (int i = 0; i < SCREEN_WIDTH * SCREEN_HEIGHT; i++) {
        buf[i] = color;
    }
}

void video_draw_rect(int x, int y, int w, int h, uint32_t color)
{
    uint32_t *buf = g_buffers[g_current_buffer];

    int x0 = x < 0 ? 0 : x;
    int y0 = y < 0 ? 0 : y;
    int x1 = (x + w) > SCREEN_WIDTH ? SCREEN_WIDTH : (x + w);
    int y1 = (y + h) > SCREEN_HEIGHT ? SCREEN_HEIGHT : (y + h);

    for (int py = y0; py < y1; py++) {
        for (int px = x0; px < x1; px++) {
            buf[py * SCREEN_WIDTH + px] = color;
        }
    }
}

void video_flip(void)
{
    sceVideoOutSubmitFlip(g_video_handle, g_current_buffer,
                           ORBIS_VIDEO_OUT_FLIP_VSYNC, 0);
    sceVideoOutWaitVblank(g_video_handle);

    g_current_buffer = (g_current_buffer + 1) % NUM_BUFFERS;
}

void video_shutdown(void)
{
    if (g_video_handle >= 0) {
        sceVideoOutClose(g_video_handle);
        g_video_handle = -1;
    }
    printf("[Video] Shutdown\n");
}
