TARGET=book
CC=clang
CXX=clang++
CFLAGS=-O2 -mmacosx-version-min=11.1
BISON=bison
BISONFLAGS=-d
FLEX=flex
SRCS = book.tab.c \
	   lex.yy.c \
	   util.c

OBJS = $(SRCS:.c=.o) lex.yy.o

all: $(TARGET)

run: $(TARGET)
	./$(TARGET)

$(TARGET): $(OBJS)
	echo "making $(TARGET)..."
	$(CC) $(CFLAGS) -o $(TARGET) $^ -ly -lm $(LDFLAGS)
	chmod +x $(TARGET)

.c.o: $(SRCS) book.tab.h
	echo "compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

book.tab.c: book.y
	$(BISON) $(BISONFLAGS) $<

lex.yy.c: book.l
	$(FLEX) $<

clean:
	rm $(TARGET) $(OBJS) book.tab.c book.tab.h lex.yy.c
