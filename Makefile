TARGET=book
CC=clang
CXX=clang++
CFLAGS=-O2 -mmacosx-version-min=11.1
BISON=bison
SRCS = book.tab.c \
	   util.c

OBJS = $(SRCS:.c=.o)

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
	$(BISON) -d book.y

clean:
	rm $(TARGET) $(OBJS) *.tab.c *.tab.h
