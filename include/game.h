/*
 * game.h - منطق بازی PS4 Pong
 */

#ifndef GAME_H
#define GAME_H

typedef struct {
    float x, y;
    float vx, vy;
    float speed;
} ball_t;

typedef struct {
    float x, y;
} paddle_t;

typedef struct {
    ball_t ball;
    paddle_t p1, p2;
    int score_p1, score_p2;
    int game_mode;
    int game_over;
    int winner;
} game_state_t;

/* توابع بازی */
int game_init(int mode, game_state_t *state);
void game_update(float dt, game_state_t *state, float p1_y, float p2_y);
void game_shutdown(void);

#endif
