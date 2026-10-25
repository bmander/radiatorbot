# Builds and runs the valve library's tests on the host.
#
#     make -C firmware/host_test

CXX ?= g++
CXXFLAGS ?= -std=c++17 -O1 -g -Wall -Wextra -Werror -fsanitize=address,undefined
LIB := ../lib/valve/src
SRCS := test_main.cpp $(wildcard $(LIB)/*.cpp)
BUILD := build

.PHONY: test clean
test: $(BUILD)/tests
	./$(BUILD)/tests

$(BUILD)/tests: $(SRCS) $(wildcard $(LIB)/*.h)
	@mkdir -p $(BUILD)
	$(CXX) $(CXXFLAGS) -I$(LIB) $(SRCS) -o $@

clean:
	rm -rf $(BUILD)
