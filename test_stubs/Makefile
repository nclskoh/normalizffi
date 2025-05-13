SOURCES = $(shell find ../src -name '*.cpp')
HEADERS = $(shell find ../src -name '*.h')

CXXFLAGS = -I../Normaliz-offline/local/include -I.
LDFLAGS = -L../Normaliz-offline/local/lib -lstdc++ -pthread -lnauty -lflint -lnormaliz -lgomp -lmpfr -lgmp -lgmpxx -lstdc++

.PHONY: clean manual_copy

test_stubs : $(patsubst %.cpp, %.o, $(shell find ./ -name '*.cpp'))
	$(CXX) -o $@ $^ $(LDFLAGS)

%.o : %.cpp
	$(CXX) -o $@ -c $(CXXFLAGS) $^

manual_copy:
	cp $(SOURCES) ./
	cp $(HEADERS) ./

clean:
	rm test_stubs *.o $(notdir $(SOURCES)) $(notdir $(HEADERS))

# LD_LIBRARY_PATH=../Normaliz-offline/local/lib ./test_stubs
