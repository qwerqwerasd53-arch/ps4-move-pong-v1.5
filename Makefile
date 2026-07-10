# Makefile - PS4 Pong (Real)
#
# نکته: هدرهای عمومی C (stdio.h و...) و خودِ clang/ld.lld در ریپوی گیت OpenOrbis
# نیستن (اونا تو ریپوی جدای musl و در نسخه‌ی ریلیزشده‌ی تول‌چین هستن).
# برای همین تو ورک‌فلوی گیت‌هاب اکشن، کل جاب داخل ایمیج داکر رسمی
# openorbisofficial/toolchain اجرا میشه که همه‌چی از قبل توش آماده‌ست.

OO_PS4_TOOLCHAIN ?= $(shell pwd)/OpenOrbis-PS4-Toolchain

# clang برای کامپایل. برای لینک هم از clang استفاده می‌کنیم (نه ld.lld مستقیم)،
# چون فقط clang به‌عنوان "driver" فلگ -target رو می‌فهمه و خودش به‌درستی
# ld.lld رو با آرگومان‌های صحیح صدا می‌زنه. صدا زدن مستقیم ld.lld با -target
# خطای "unknown argument" می‌ده.
#
# نکته مهم (رفع قطعی خطای CI - نسخه‌ی نهایی واقعی):
# بعد از حذف -fuse-ld=، این خطای جدید ظاهر شد:
#   clang: error: unable to execute command: Executable "orbis-ld" doesn't exist!
# دلیلش: این fork اختصاصی کلنگ برای تارگت scei-ps4، وقتی هیچ -fuse-ld
# مشخص نشده باشه، به‌صورت پیش‌فرض دنبال فایل اجرایی‌ای دقیقاً به اسم
# "orbis-ld" می‌گرده (این رفتار مستنده و تو خودِ سورس کلنگ PS4 هست) — نه
# ld.lld. این ایمیج داکر فقط ld.lld رو داره، نه orbis-ld.
# و همون‌طور که قبلاً دیدیم، دادن مستقیم مقدار به -fuse-ld= (چه اسم کوتاه
# lld، چه مسیر کامل) با خطای "unsupported value ... for -linker option"
# رد می‌شه، پس نمی‌تونیم از اون مسیر هم وارد بشیم.
#
# راه‌حل قطعی: یک symlink موقت دقیقاً به اسم "orbis-ld" می‌سازیم که به
# همون ld.lld واقعی اشاره می‌کنه، و با فلگ استاندارد -B به کلنگ می‌گیم
# این مسیر رو هم برای پیدا کردن ابزارهای کمکی (linker/assembler) بگرده.
# این کار کاملاً مستقل از -fuse-ld= هست، پس به اون enum محدودشده گیر
# نمی‌کنه.
LLD_REAL := $(shell command -v ld.lld 2>/dev/null)
ifeq ($(LLD_REAL),)
LLD_REAL := /usr/bin/ld.lld
endif
LD_SHIM_DIR := $(CURDIR)/.ld-shim

CC = clang
LD = clang -B$(LD_SHIM_DIR)

# Target
TARGET = x86_64-scei-ps4

# Flags
CFLAGS = -target $(TARGET)
CFLAGS += -fPIC -fno-strict-aliasing -fvisibility=hidden
CFLAGS += -isystem $(OO_PS4_TOOLCHAIN)/include
CFLAGS += -Iinclude

LDFLAGS = -target $(TARGET)
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
	@mkdir -p $(LD_SHIM_DIR)
	@ln -sf "$(LLD_REAL)" "$(LD_SHIM_DIR)/orbis-ld"
	@echo "[LD] Linking $@ (using orbis-ld shim -> $(LLD_REAL))"
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS) \
		-lkernel -lc -lm -lSceVideoOut -lSceSysmodule -lScePad -lSceUserService
	@echo "Build complete: $@"
	@ls -lh $@

clean:
	@rm -rf $(OBJDIR) $(EBOOT) $(LD_SHIM_DIR)
	@echo "Clean complete"

.PHONY: all clean