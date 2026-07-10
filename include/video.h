/*
 * video.h - خروجی تصویر (Framebuffer) روی PS4 با رسم مستقیم پیکسل (CPU)
 */

#ifndef VIDEO_H
#define VIDEO_H

#include <stdint.h>

int video_init(void);
void video_flip(void);
void video_shutdown(void);

/* رسم یک مستطیل ساده روی بافر فعلی
 * فرمت واقعی پیکسل A8B8G8R8 هست (طبق هدر واقعی _types/video.h)،
 * یعنی رنگ باید به شکل 0xAABBGGRR داده بشه، نه 0xAARRGGBB معمول. */
void video_draw_rect(int x, int y, int w, int h, uint32_t color);
void video_clear(uint32_t color);

#endif
