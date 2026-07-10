/*
 * main.c - PS4 Pong (Real Implementation)
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "config.h"
#include "game.h"
#include "input.h"
#include "video.h"

#define COLOR_BG     0xFF101018  /* فرمت واقعی A8B8G8R8 - این رنگ تقریبا خنثی/خاکستری تیره است */
#define COLOR_WHITE  0xFFFFFFFF

#define DELTA_TIME (1.0f / 60.0f)

int main(void)
{
    printf("========================================\n");
    printf("PS4 Pong - Real Implementation\n");
    printf("========================================\n");
    
    /* Initialize Video */
    if (video_init() != 0) {
        printf("[Main] Error: Video init failed\n");
        return 1;
    }

    /* Initialize Input */
    if (input_init() != 0) {
        printf("[Main] Error: Input init failed\n");
        video_shutdown();
        return 1;
    }
    
    /* Game Loop */
    int game_mode = GAME_MODE_TWO_PLAYER;
    game_state_t game_state;
    
    if (game_init(game_mode, &game_state) != 0) {
        printf("[Main] Error: Game init failed\n");
        input_shutdown();
        video_shutdown();
        return 1;
    }
    
    printf("[Main] Game started! (Team 1: 2 players vs Team 2: 2 players)\n");
    
    int running = 1;
    int frame_count = 0;
    float p1_y = game_state.p1.y;
    float p2_y = game_state.p2.y;
    
    while (running) {
        /* Read Input */
        input_t input;
        input_read(&input);
        
        /* Update Y positions */
        p1_y += input.p1_y * DELTA_TIME * 60;
        p2_y += input.p2_y * DELTA_TIME * 60;
        
        /* Clamp positions */
        if (p1_y < PADDLE_MIN_Y) p1_y = PADDLE_MIN_Y;
        if (p1_y > PADDLE_MAX_Y) p1_y = PADDLE_MAX_Y;
        if (p2_y < PADDLE_MIN_Y) p2_y = PADDLE_MIN_Y;
        if (p2_y > PADDLE_MAX_Y) p2_y = PADDLE_MAX_Y;
        
        /* Update Game */
        game_update(DELTA_TIME, &game_state, p1_y, p2_y);

        /* Render Frame */
        video_clear(COLOR_BG);
        video_draw_rect((int)game_state.p1.x, (int)game_state.p1.y,
                         PADDLE_WIDTH, PADDLE_HEIGHT, COLOR_WHITE);
        video_draw_rect((int)game_state.p2.x, (int)game_state.p2.y,
                         PADDLE_WIDTH, PADDLE_HEIGHT, COLOR_WHITE);
        video_draw_rect((int)(game_state.ball.x - BALL_SIZE / 2),
                         (int)(game_state.ball.y - BALL_SIZE / 2),
                         BALL_SIZE, BALL_SIZE, COLOR_WHITE);
        video_flip();

        /* Debug Output */
        if (frame_count % 60 == 0) {
            printf("[Frame %d] P1Y: %.0f, P2Y: %.0f, Ball: (%.0f, %.0f), Score: %d-%d | Pads: %d,%d,%d,%d\n",
                   frame_count, p1_y, p2_y, 
                   game_state.ball.x, game_state.ball.y,
                   game_state.score_p1, game_state.score_p2,
                   input.pads_connected[0], input.pads_connected[1],
                   input.pads_connected[2], input.pads_connected[3]);
        }
        
        /* Check Game Over */
        if (game_state.game_over) {
            printf("[Main] Game Over! Winner: Player %d\n", game_state.winner);
            sleep(3);
            running = 0;
        }
        
        /* Check Quit */
        if (input.quit) {
            printf("[Main] Quit requested\n");
            running = 0;
        }
        
        frame_count++;
        usleep(16666); /* ~60 FPS */
    }
    
    printf("[Main] Game finished (frames=%d)\n", frame_count);
    
    /* Cleanup */
    game_shutdown();
    input_shutdown();
    video_shutdown();
    
    printf("[Main] Cleanup complete. Exiting.\n");
    
    return 0;
}
