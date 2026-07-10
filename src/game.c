/*
 * game.c - منطق بازی PS4 Pong
 */

#include "game.h"
#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

static game_state_t *g_game_state = NULL;

int game_init(int mode, game_state_t *state)
{
    if (!state) return 1;
    
    state->game_mode = mode;
    state->game_over = 0;
    state->winner = 0;
    state->score_p1 = 0;
    state->score_p2 = 0;
    
    /* راکت‌ها */
    state->p1.x = PADDLE_P1_X;
    state->p1.y = SCREEN_HEIGHT / 2 - PADDLE_HEIGHT / 2;
    
    state->p2.x = PADDLE_P2_X;
    state->p2.y = SCREEN_HEIGHT / 2 - PADDLE_HEIGHT / 2;
    
    /* توپ */
    state->ball.x = SCREEN_WIDTH / 2;
    state->ball.y = SCREEN_HEIGHT / 2;
    state->ball.speed = BALL_SPEED;
    state->ball.vx = (rand() % 2 == 0) ? BALL_SPEED : -BALL_SPEED;
    state->ball.vy = ((rand() % 100) - 50) / 100.0f * BALL_SPEED;
    
    g_game_state = state;
    return 0;
}

static void normalize_velocity(float *vx, float *vy, float speed)
{
    float mag = sqrtf(*vx * *vx + *vy * *vy);
    if (mag > 0.01f) {
        *vx = (*vx / mag) * speed;
        *vy = (*vy / mag) * speed;
    }
}

void game_update(float dt, game_state_t *state, float p1_y, float p2_y)
{
    if (!state || state->game_over) return;
    
    /* حد راکت‌ها */
    if (p1_y < PADDLE_MIN_Y) p1_y = PADDLE_MIN_Y;
    if (p1_y > PADDLE_MAX_Y) p1_y = PADDLE_MAX_Y;
    if (p2_y < PADDLE_MIN_Y) p2_y = PADDLE_MIN_Y;
    if (p2_y > PADDLE_MAX_Y) p2_y = PADDLE_MAX_Y;
    
    state->p1.y = p1_y;
    state->p2.y = p2_y;
    
    /* حرکت توپ */
    state->ball.x += state->ball.vx * dt * 60;
    state->ball.y += state->ball.vy * dt * 60;
    
    /* برخورد دیوار */
    if (state->ball.y - BALL_SIZE / 2 < TABLE_TOP) {
        state->ball.y = TABLE_TOP + BALL_SIZE / 2;
        state->ball.vy = -state->ball.vy;
    }
    if (state->ball.y + BALL_SIZE / 2 > TABLE_BOTTOM) {
        state->ball.y = TABLE_BOTTOM - BALL_SIZE / 2;
        state->ball.vy = -state->ball.vy;
    }
    
    /* برخورد راکت P1 */
    if (state->ball.x - BALL_SIZE / 2 < state->p1.x + PADDLE_WIDTH &&
        state->ball.y >= state->p1.y && 
        state->ball.y <= state->p1.y + PADDLE_HEIGHT) {
        state->ball.x = state->p1.x + PADDLE_WIDTH + BALL_SIZE / 2;
        state->ball.vx = -state->ball.vx;
        state->ball.speed += 0.5f;
        if (state->ball.speed > BALL_MAX_SPEED) state->ball.speed = BALL_MAX_SPEED;
        normalize_velocity(&state->ball.vx, &state->ball.vy, state->ball.speed);
    }
    
    /* برخورد راکت P2 */
    if (state->ball.x + BALL_SIZE / 2 > state->p2.x &&
        state->ball.y >= state->p2.y && 
        state->ball.y <= state->p2.y + PADDLE_HEIGHT) {
        state->ball.x = state->p2.x - BALL_SIZE / 2;
        state->ball.vx = -state->ball.vx;
        state->ball.speed += 0.5f;
        if (state->ball.speed > BALL_MAX_SPEED) state->ball.speed = BALL_MAX_SPEED;
        normalize_velocity(&state->ball.vx, &state->ball.vy, state->ball.speed);
    }
    
    /* گول */
    if (state->ball.x < TABLE_LEFT) {
        state->score_p2++;
        printf("[Game] Goal P2! Score: P1=%d P2=%d\n", state->score_p1, state->score_p2);
        
        state->ball.x = SCREEN_WIDTH / 2;
        state->ball.y = SCREEN_HEIGHT / 2;
        state->ball.speed = BALL_SPEED;
        state->ball.vx = (rand() % 2 == 0) ? BALL_SPEED : -BALL_SPEED;
        state->ball.vy = ((rand() % 100) - 50) / 100.0f * BALL_SPEED;
    }
    
    if (state->ball.x > TABLE_RIGHT) {
        state->score_p1++;
        printf("[Game] Goal P1! Score: P1=%d P2=%d\n", state->score_p1, state->score_p2);
        
        state->ball.x = SCREEN_WIDTH / 2;
        state->ball.y = SCREEN_HEIGHT / 2;
        state->ball.speed = BALL_SPEED;
        state->ball.vx = (rand() % 2 == 0) ? BALL_SPEED : -BALL_SPEED;
        state->ball.vy = ((rand() % 100) - 50) / 100.0f * BALL_SPEED;
    }
    
    /* شرط برد */
    if (state->score_p1 >= WIN_SCORE) {
        state->game_over = 1;
        state->winner = 1;
        printf("[Game] Player 1 WINS!\n");
    }
    if (state->score_p2 >= WIN_SCORE) {
        state->game_over = 1;
        state->winner = 2;
        printf("[Game] Player 2 WINS!\n");
    }
}

void game_shutdown(void)
{
    g_game_state = NULL;
    printf("[Game] Shutdown\n");
}
