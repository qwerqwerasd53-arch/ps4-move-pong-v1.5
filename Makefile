# Makefile - PS4 Pong (Real)
#
# نکته: هدرهای عمومی C (stdio.h و...) و خودِ clang/ld.lld در ریپوی گیت OpenOrbis
# نیستن (اونا تو ریپوی جدای musl و در نسخه‌ی ریلیزشده‌ی تول‌چین هستن).
# برای همین تو ورک‌فلوی گیت‌هاب اکشن، کل جاب داخل ایمیج داکر رسمی
# openorbisofficial/toolchain اجرا میشه که همه‌چی از قبل توش آماده‌ست.

OO_PS4_TOOLCHAIN ?= $(shell pwd)/OpenOrbis-PS4-Toolchain

# نکته مهم (رفع قطعی خطای اجرا روی خودِ PS4 - علت واقعی کرش):
# لاگ کرش نشون داد GoldHENLoader موقع اجرا با null pointer کرش می‌کنه.
# دلیل واقعی: تو نسخه‌های قبلی این Makefile، فایل استارتاپ واقعی PS4
# (crt1.o) هیچ‌وقت لینک نمی‌شد. این فایله که _start رو تعریف می‌کنه و
# قبل از main() محیط اجرا (استک، TLS و...) رو آماده می‌کنه. بدون اون:
#   orbis-ld: warning: cannot find entry symbol _start
# یعنی هیچ entry point معتبری نداریم و کنسول موقع اجرا کرش می‌کنه.
#
# راه‌حل درست و مستند (بر اساس پروژه‌های واقعی و کارکن OpenOrbis مثل
# ps4-ipi و PS4RPI): باید مستقیم با خودِ ld.lld لینک کنیم، با اسکریپت
# لینکر رسمی تول‌چین (link.x) و فایل استارتاپ (crt1.o) که خودِ تول‌چین
# همراهش میاد. این کار کاملاً جایگزین تلاش‌های قبلی با clang -fuse-ld
# می‌شه و اون مشکلات رو از اساس کنار می‌ذاره.
CC = clang
LD = ld.lld

# Target
TARGET = x86_64-scei-ps4

# Flags
CFLAGS = -target $(TARGET)
CFLAGS += -fPIC -fno-strict-aliasing -fvisibility=hidden
CFLAGS += -isystem $(OO_PS4_TOOLCHAIN)/include
CFLAGS += -Iinclude

LDFLAGS = -m elf_x86_64 -pie --eh-frame-hdr
LDFLAGS += --script $(OO_PS4_TOOLCHAIN)/link.x
LDFLAGS += -L$(OO_PS4_TOOLCHAIN)/lib
LDFLAGS += -L$(OO_PS4_TOOLCHAIN)/lib/x86_64-scei-ps4

# Files
SRCDIR = src
OBJDIR = objs

SOURCES = \
	$(SRCDIR)/main.c \
	$(SRCDIR)/game.c \
	$(SRCDIR)/input.c \
	$(SRCDIR)/video.c

OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
EBOOT = eboot.elf

# Rules
all: $(EBOOT)

$(OBJDIR):
	@mkdir -p $(OBJDIR)

$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	@echo "[CC] $<"
	$(CC) $(CFLAGS) -c $< -o $@

$(EBOOT): $(OBJECTS)
	@echo "[LD] Linking $@"
	$(LD) $(LDFLAGS) -o $@ $(OO_PS4_TOOLCHAIN)/lib/crt1.o $(OBJECTS) \
		-lkernel -lc -lm -lSceVideoOut -lSceSysmodule -lScePad -lSceUserService
	@echo "Build complete: $@"
	@ls -lh $@

clean:
	@rm -rf $(OBJDIR) $(EBOOT)
	@echo "Clean complete"

.PHONY: all clean
