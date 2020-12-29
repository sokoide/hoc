TARGET=book
CC=clang
CXX=clang++
CFLAGS=-O0 -g -mmacosx-version-min=11.1
BISON=bison
# -t enables bison debug if yydebug=1 in book.y
BISONFLAGS=-d -t
FLEX=flex
SRCS = book.tab.c \
	   lex.yy.c \
	   util.c

OBJS = $(SRCS:.c=.o) lex.yy.o

all: $(TARGET)

run: $(TARGET)
	./$(TARGET)

test: $(TARGET)
	for testfile in $$(ls tests | sort);do echo "* running: $$testfile";cat tests/$$testfile | ./$(TARGET);done

$(TARGET): $(OBJS)
	echo "making $(TARGET)..."
	$(CC) $(CFLAGS) -o $(TARGET) $^ -ly -lm $(LDFLAGS)
	chmod +x $(TARGET)

.c.o: $(SRCS) book.tab.h
	echo "compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

book.tab.c: book.y
	$(BISON) $(BISONFLAGS) $<

lex.yy.c: book.l book.tab.h
	$(FLEX) $<

clean:
	rm $(TARGET) $(OBJS) book.tab.c book.tab.h lex.yy.c
