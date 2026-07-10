/*
 * config.h - تنظیمات بازی PS4 Pong (Real)
 */

#ifndef CONFIG_H
#define CONFIG_H

/* تنظیمات صفحه */
#define SCREEN_WIDTH    1920
#define SCREEN_HEIGHT   1080

/* تنظیمات بازی */
#define PADDLE_WIDTH    20
#define PADDLE_HEIGHT   200
#define PADDLE_SPEED    5.0f

#define BALL_SIZE       15
#define BALL_SPEED      6.0f
#define BALL_MAX_SPEED  10.0f

/* سرعت هوش مصنوعی (کمی کندتر از بازیکن تا بازی عادلانه بمونه) */
#define AI_SPEED        (PADDLE_SPEED * 0.82f)

#define WIN_SCORE       5

/* موقعیت ها */
#define PADDLE_P1_X     50
#define PADDLE_P2_X     (SCREEN_WIDTH - 50 - PADDLE_WIDTH)
#define PADDLE_MIN_Y    100
#define PADDLE_MAX_Y    (SCREEN_HEIGHT - 100 - PADDLE_HEIGHT)

#define TABLE_LEFT      100
#define TABLE_RIGHT     (SCREEN_WIDTH - 100)
#define TABLE_TOP       100
#define TABLE_BOTTOM    (SCREEN_HEIGHT - 100)

/* حالت های بازی */
#define GAME_MODE_MENU          0
#define GAME_MODE_SINGLE_PLAYER 1
#define GAME_MODE_TWO_PLAYER    2

#endif
