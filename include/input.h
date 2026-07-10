/*
 * input.h - ورودی ۴ دسته‌ی مستقل PS4 (OpenOrbis) در قالب ۲ تیم ۲نفره
 *
 * تیم ۱ (دسته‌ی ۱ و ۲) راکت سمت چپ رو کنترل می‌کنن.
 * تیم ۲ (دسته‌ی ۳ و ۴) راکت سمت راست رو کنترل می‌کنن.
 * اگه یه دسته وصل نباشه، هم‌تیمیش هنوزم می‌تونه راکت رو تنها کنترل کنه.
 */

#ifndef INPUT_H
#define INPUT_H

typedef struct {
    float p1_y;              /* حرکت راکت تیم ۱ (ترکیب دسته‌ی ۱ و ۲) */
    float p2_y;              /* حرکت راکت تیم ۲ (ترکیب دسته‌ی ۳ و ۴) */
    int   pads_connected[4]; /* وضعیت اتصال هر ۴ دسته */
    int   menu_select;       /* دکمه‌ی ضربدر روی دسته‌ی ۱ */
    int   quit;               /* دکمه‌ی Options روی دسته‌ی ۱ */
} input_t;

int input_init(void);
void input_read(input_t *input);
void input_shutdown(void);

#endif
