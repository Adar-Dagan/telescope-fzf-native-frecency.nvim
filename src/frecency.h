#include <stddef.h>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

struct fastMap {
  std::unordered_map<std::string_view, float> map;
  std::vector<std::string> strings;
};

extern "C" {
fastMap *init();
void set_score(fastMap *, char *, float);
float get_score(fastMap *, char *);
void freeMap(fastMap *);
}
