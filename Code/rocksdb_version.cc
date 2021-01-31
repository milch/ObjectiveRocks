// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.

#define STR_EXPAND(tok) #tok
#define STR(tok) STR_EXPAND(tok)
#define concat_str(x, y) x##y
#define concat(x, y) concat_str(x, y)


#if defined(ROCKSDB_GIT_SHA) && defined(ROCKSDB_GIT_DATE)
#define ROCKSDB_GIT_SHA_STRING "rocksdb_build_git_sha:" STR(ROCKSDB_GIT_SHA)
#define ROCKSDB_GIT_DATE_STRING "rocksdb_build_git_date:" STR(ROCKSDB_GIT_DATE)
const char* rocksdb_build_git_sha = ROCKSDB_GIT_SHA_STRING;
const char* rocksdb_build_git_date = ROCKSDB_GIT_DATE_STRING;
const char* rocksdb_build_compile_date = __DATE__;
#else
#error Need to define the build vars
#endif
