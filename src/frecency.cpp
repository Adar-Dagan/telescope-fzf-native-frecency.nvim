#include "frecency.h"
#include <string_view>

fastMap *init() {
  return new fastMap{};
}

void freeMap(fastMap *map) {
  delete map;
}

void set_score(fastMap *map, char *key, float value) {
  std::string_view key_view{key};
  if (map->map.count(key_view) != 0) {
    map->map[key_view] = value;
    return;
  }
  map->strings.emplace_back(key_view);
  map->map.emplace(map->strings.back(), value);
}

float get_score(fastMap *map, char *key) {
  std::string_view key_view{key};
  const auto iter = map->map.find(key_view);
  if (iter == map->map.end())
    return 0;
  return iter->second;
}
