#include<iostream>
#include<fstream>
#include<cmath>
#include<sstream>
#include<cstdlib>
#include<time.h>
using namespace std;
int main(int argc, char *argv[]) {
  ifstream filein(argv[1],ios::in);
  ofstream fileout(argv[2],ios::out);
  //srand(time(NULL));
  srand(time(NULL));
  int cache_size, block_size, associativity, replace_algorithm;
  string a;
  filein >> cache_size >> block_size >> associativity >> replace_algorithm; // read cache parameter 
  int tag, cache_width, offset;
  cache_width = log2(cache_size * 1024 / block_size);
  offset = log2(block_size);
  tag = 32 - cache_width - offset;
  int cache_index, set;
  switch(associativity) { // initialize type of cache and valid bit
    case 0:
      cache_index = cache_size * 1024 / block_size;
      set = 1;
      break;
    case 1:
      cache_index = cache_size * 1024 / block_size / 4;
      set = 4;
      break;
    case 2:
       cache_index = 1;
       set = cache_size * 1024 / block_size;
       break;
    default:
       break;       
  }
  unsigned int cache[cache_index][set];
  unsigned int fifo_head[cache_index];
  unsigned int lru[cache_index][set];
  bool valid[cache_index][set];
  for(int i = 0; i < cache_index; i++) { // initialize valid bit
    for(int j = 0; j < set; j++) {
      valid[i][j] = false;
      cache[i][j] = 0;
      lru[i][j] = 0;
    }
  }
  string memory_access;
  while(filein >> memory_access) { // read memory
    stringstream string_to_int;
    unsigned int memory_access_int;
    string_to_int << memory_access.substr(2,8);
    string_to_int >> hex >> memory_access_int;
    string_to_int.clear();
    unsigned int index_int, tag_int;
    index_int = (unsigned int)(memory_access_int << tag) >> (tag+offset);
    tag_int = (unsigned int)(memory_access_int) >> (cache_width + offset);
    //cout << index_int << endl;
    if(associativity == 0) { // direct_mapped
      if(!valid[index_int][0] || cache[index_int][0] != tag_int) { // need to update cache
        if(!valid[index_int][0]) { // valid bit = false
          fileout << -1 << endl;
          valid[index_int][0] = true;
          cache[index_int][0] = tag_int;
        }
        else { // valid bit = true
          fileout << cache[index_int][0] << endl;
        }
        cache[index_int][0] = tag_int;
      }
      else { // dont need to update cache
        fileout << -1 << endl;
      }
    }
    else if(associativity == 1) { // four-way set associativity
      index_int = (unsigned int)(memory_access_int << (tag+2)) >> (tag+2+offset);
      //index_int = (unsigned int)index_int >> 2;
      //tag_int = tag_int << 2;
      tag_int = (unsigned int)memory_access_int >> (cache_width + offset - 2);
      if(replace_algorithm == 0) { // FIFO
        bool update = true,full = false;
        int valid_num;
        for(int i = 0; i < 4; i++) {
          if(valid[index_int][i]) {
            if(i == 3)
              full = true;
            if(cache[index_int][i] == tag_int) {
              update = false;
            }
          }
        }
        if(update) {
          if(full) {
            fileout << cache[index_int][fifo_head[index_int]];
            cache[index_int][fifo_head[index_int]] = tag_int;
            fifo_head[index_int]++;
            if(fifo_head[index_int] > 3) {
                fifo_head[index_int] = 0;
            }
          }
          else {
            for(int i = 0; i < 4; i++) {
              if(!valid[index_int][i]) {
                valid_num = i;
                valid[index_int][i] = true;
                break;
              }
            }
            cache[index_int][valid_num] = tag_int;
            fileout << -1 << endl;
          }
        }
        else {
          fileout << -1 << endl;
        }
      }
      else if(replace_algorithm == 1) { // LRU
        bool update = true;
        bool full = false;
        int valid_num,recent_read;
        for(int i = 0; i < 4; i++) {
          if(valid[index_int][i]) {
            if(i == 3)
              full = true;
            if(cache[index_int][i] == tag_int) {
              recent_read = i;
              update = false;
            }
          }
        }
        if(update) {
          if(full) {
            for(int i = 0; i < 4; i++) {
              if(lru[index_int][i] == 1) {
                fileout << cache[index_int][i] << endl;
                cache[index_int][i] = tag_int;
                lru[index_int][i] = 4;
                for(int j = 0; j < 4; j++) {
                  if(j != i) {
                    lru[index_int][j]--;
                  }
                }
              }
            }
          }
          else { // not full
            for(int i = 0; i < 4; i++) {
              if(!valid[index_int][i]) {
                valid_num = i;
                valid[index_int][i] = true;
                break;
              }
            }
            cache[index_int][valid_num] = tag_int;
            fileout << -1 << endl;
            lru[index_int][valid_num] = 4;
            for(int i = 0; i < 4; i++) {
              if(lru[index_int][i]!=0 && i!=valid_num) {
                lru[index_int][i]--;
              }
            }
          }
        }
        else {
          fileout << -1 << endl;
          int tmp = lru[index_int][recent_read];
          lru[index_int][recent_read] = 4;
          for(int i = 0; i < 4; i++) {
            if(lru[index_int][i]>tmp && i!=recent_read)
              lru[index_int][i]--;
          }
        }
      }
      else { // your policy => random
        bool update = true;
        bool full = false;
        int valid_num;
        for(int i = 0; i < 4; i++) {
          if(valid[index_int][i]) {
            if(i == 3)
              full = true;
            if(cache[index_int][i] == tag_int) {
              update = false;
            }
          }
        }
        if(update) {
          if(full) {
            int update_num = rand() % 4;
            fileout << cache[index_int][update_num] << endl;
            cache[index_int][update_num] = tag_int;
          }
          else { // not full
            for(int i = 0; i < 4; i++) {
              if(!valid[index_int][i]) {
                valid_num = i;
                valid[index_int][i] = true;
                break;
              }
            }
            cache[index_int][valid_num] = tag_int;
            fileout << -1 << endl;
          }
        }
        else
          fileout << -1 << endl;
      }
    }
    //  change there  =============================================================================change there
    else if(associativity == 2) { // full associativity
      //tag_int = (unsigned int)memory_access_int >> offset;
      index_int = 0;
      tag_int = (unsigned int)memory_access_int >> (offset);
      if(replace_algorithm == 0) { // FIFO
        bool update = true,full = false;
        unsigned int valid_num;
        for(unsigned int i = 0; i < set; i++) {
          if(valid[index_int][i]) {
            if(i == set-1)
              full = true;
            if(cache[index_int][i] == tag_int) {
              update = false;
            }
          }
        }
        if(update) {
          if(full) {
            fileout << cache[index_int][fifo_head[index_int]];
            cache[index_int][fifo_head[index_int]] = tag_int;
            fifo_head[index_int]++;
            if(fifo_head[index_int] > set - 1) {
                fifo_head[index_int] = 0;
            }
          }
          else {
            for(unsigned int i = 0; i < set; i++) {
              if(!valid[index_int][i]) {
                valid_num = i;
                valid[index_int][i] = true;
                break;
              }
            }
            cache[index_int][valid_num] = tag_int;
            fileout << -1 << endl;
          }
        }
        else {
          fileout << -1 << endl;
        }
      }
      else if(replace_algorithm == 1) { // LRU
        bool update = true;
        bool full = false;
        unsigned int valid_num,recent_read;
        for(unsigned int i = 0; i < set; i++) {
          if(valid[index_int][i]) {
            if(i == set-1)
              full = true;
            if(cache[index_int][i] == tag_int) {
              recent_read = i;
              update = false;
            }
          }
        }
        if(update) {
          if(full) {
            for(unsigned int i = 0; i < set; i++) {
              if(lru[index_int][i] == 1) {
                fileout << cache[index_int][i] << endl;
                cache[index_int][i] = tag_int;
                lru[index_int][i] = set;
                for(unsigned int j = 0; j < set; j++) {
                  if(j != i) {
                    lru[index_int][j]--;
                  }
                }
                break;
              }
            }
          }
          else { // not full
            for(unsigned int i = 0; i < set; i++) {
              if(!valid[index_int][i]) {
                valid_num = i;
                valid[index_int][i] = true;
                break;
              }
            }
            cache[index_int][valid_num] = tag_int;
            fileout << -1 << endl;
            lru[index_int][valid_num] = set;
            for(unsigned int i = 0; i < set; i++) {
              if(lru[index_int][i]!=0 && i!=valid_num) {
                lru[index_int][i]--;
              }
            }
          }
        }
        else {
          fileout << -1 << endl;
          unsigned int tmp = lru[index_int][recent_read];
          lru[index_int][recent_read] = set;
          for(unsigned int i = 0; i < set; i++) {
            if(lru[index_int][i]>tmp && i!=recent_read)
              lru[index_int][i]--;
          }
        }
      }
      else { // your policy => random
        bool update = true;
        bool full = false;
        unsigned int valid_num;
        for(unsigned int i = 0; i < set; i++) {
          if(valid[index_int][i]) {
            if(i == set-1)
              full = true;
            if(cache[index_int][i] == tag_int) {
              update = false;
            }
          }
        }
        if(update) {
          if(full) {
            unsigned int update_num = rand() % set;
            fileout << cache[index_int][update_num] << endl;
            cache[index_int][update_num] = tag_int;
          }
          else { // not full
            for(unsigned int i = 0; i < set; i++) {
              if(!valid[index_int][i]) {
                valid_num = i;
                valid[index_int][i] = true;
                break;
              }
            }
            cache[index_int][valid_num] = tag_int;
            fileout << -1 << endl;
          }
        }
        else
          fileout << -1 << endl;
      }

    } 
  }
  return 0;
}
