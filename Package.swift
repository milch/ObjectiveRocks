// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let baseDir = (#file as NSString).deletingLastPathComponent

func recursiveSearch(atPath: String) -> [String] {
  let fileManager = FileManager.default
  var files = [String]()
  let basePath = (baseDir as NSString).appendingPathComponent(atPath)
  let enumerator = fileManager.enumerator(atPath: basePath)
  while let element = enumerator?.nextObject() as? String {
    var isDirectory: ObjCBool = false
    fileManager.fileExists(atPath: "\(basePath)/\(element)", isDirectory: &isDirectory)
    if !isDirectory.boolValue {
      files.append(element)
    }
  }
  return files
}

let allRocksDBFiles = recursiveSearch(atPath: "rocksdb")
let rocksDBTests = allRocksDBFiles.filter { $0.hasSuffix("_test.cc") || $0.hasSuffix("_test.c") || $0.hasSuffix("_bench.cc") }
let nonSourceFiles = allRocksDBFiles.filter { !(
  $0.hasSuffix(".cc")
  || $0.hasSuffix(".c")
  || $0.hasSuffix(".cpp")
  || $0.hasSuffix(".m")
  || $0.hasSuffix(".mm")
  || $0.hasSuffix(".h")
)}

@discardableResult
func shell(_ args: String...) -> String? {
  let task = Process()
  let pipe = Pipe()
  task.standardOutput = pipe
  task.launchPath = "/usr/bin/env"
  task.arguments = args
  task.launch()
  task.waitUntilExit()
  guard task.terminationStatus == 0 else { return nil }
  
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  var result =  String(decoding: data, as: UTF8.self)
  result.removeLast()
  return result
}

let rocksDBGitDir = (baseDir as NSString).appendingPathComponent("rocksdb/.git")
let buildVersionFile = (baseDir as NSString).appendingPathComponent("rocksdb/util/build_version.cc")
let rocksDBGitSHA = shell("git", "--git-dir=\(rocksDBGitDir)", "rev-parse", "HEAD")
let date = shell("date")

let package = Package(
  name: "ObjectiveRocks",
  platforms: [
    .iOS(.v9),
    .macOS(.v10_10),
  ],
  products: [
    .library(
      name: "ObjectiveRocks",
      targets: ["ObjectiveRocks", "RocksDB"])
  ],
  dependencies: [
    .package(name: "lz4", url: "https://github.com/milch/lz4-spm", .upToNextMinor(from: "1.9.3"))
  ],
  targets: [
    .target(
      name: "ObjectiveRocks",
      dependencies: [],
      path: "Code",
      sources: [
        "../Code"
      ],
      publicHeadersPath: "include",
      cSettings: [
        .headerSearchPath("../rocksdb/include"),
        .headerSearchPath("include"),
        .define("NDEBUG", to: "1"),
        .define("OS_MACOSX", to: "1"),
        .define("ROCKSDB_PLATFORM_POSIX", to: "1"),
        .define("ROCKSDB_LIB_IO_POSIX", to: "1"),
        .define("ROCKSDB_USING_THREAD_STATUS", to: "1"),
        .define("ROCKSDB_GIT_SHA", to: rocksDBGitSHA ?? "unknown"),
        .define("ROCKSDB_GIT_DATE", to: date ?? "unknown")
      ]
    ),
    .target(
      name: "RocksDB",
      dependencies: [ "lz4" ],
      path: "rocksdb",
      exclude: [
        "java",
        "tools",
        "examples",
        "third-party",
        "port/win",
        "utilities/cassandra",
        "db/db_test_util.cc",
        "util/testharness.cc",
        "util/testutil.cc",
        "utilities/env_librados.cc",
        "util/crc32c_arm64.cc",
        "util/fault_injection_test_env.cc",
        "util/crc32c_ppc.c",
        "table/mock_table.cc",
        "db/db_test2.cc"
      ]
      + rocksDBTests
      + nonSourceFiles,
      sources: [
        // Copied from rocksdb/TARGETS with utilities/cassandra removed
        "cache/clock_cache.cc",
        "cache/lru_cache.cc",
        "cache/sharded_cache.cc",
        "db/builder.cc",
        "db/c.cc",
        "db/column_family.cc",
        "db/compacted_db_impl.cc",
        "db/compaction.cc",
        "db/compaction_iterator.cc",
        "db/compaction_job.cc",
        "db/compaction_picker.cc",
        "db/compaction_picker_fifo.cc",
        "db/compaction_picker_universal.cc",
        "db/convenience.cc",
        "db/db_filesnapshot.cc",
        "db/db_impl.cc",
        "db/db_impl_compaction_flush.cc",
        "db/db_impl_debug.cc",
        "db/db_impl_experimental.cc",
        "db/db_impl_files.cc",
        "db/db_impl_open.cc",
        "db/db_impl_readonly.cc",
        "db/db_impl_secondary.cc",
        "db/db_impl_write.cc",
        "db/db_info_dumper.cc",
        "db/db_iter.cc",
        "db/dbformat.cc",
        "db/error_handler.cc",
        "db/event_helpers.cc",
        "db/experimental.cc",
        "db/external_sst_file_ingestion_job.cc",
        "db/file_indexer.cc",
        "db/flush_job.cc",
        "db/flush_scheduler.cc",
        "db/forward_iterator.cc",
        "db/in_memory_stats_history.cc",
        "db/internal_stats.cc",
        "db/log_reader.cc",
        "db/log_writer.cc",
        "db/logs_with_prep_tracker.cc",
        "db/malloc_stats.cc",
        "db/memtable.cc",
        "db/memtable_list.cc",
        "db/merge_helper.cc",
        "db/merge_operator.cc",
        "db/range_del_aggregator.cc",
        "db/range_tombstone_fragmenter.cc",
        "db/repair.cc",
        "db/snapshot_impl.cc",
        "db/table_cache.cc",
        "db/table_properties_collector.cc",
        "db/transaction_log_impl.cc",
        "db/version_builder.cc",
        "db/version_edit.cc",
        "db/version_set.cc",
        "db/wal_manager.cc",
        "db/write_batch.cc",
        "db/write_batch_base.cc",
        "db/write_controller.cc",
        "db/write_thread.cc",
        "env/env.cc",
        "env/env_chroot.cc",
        "env/env_encryption.cc",
        "env/env_hdfs.cc",
        "env/env_posix.cc",
        "env/io_posix.cc",
        "env/mock_env.cc",
        "memtable/alloc_tracker.cc",
        "memtable/hash_linklist_rep.cc",
        "memtable/hash_skiplist_rep.cc",
        "memtable/skiplistrep.cc",
        "memtable/vectorrep.cc",
        "memtable/write_buffer_manager.cc",
        "monitoring/histogram.cc",
        "monitoring/histogram_windowing.cc",
        "monitoring/instrumented_mutex.cc",
        "monitoring/iostats_context.cc",
        "monitoring/perf_context.cc",
        "monitoring/perf_level.cc",
        "monitoring/statistics.cc",
        "monitoring/thread_status_impl.cc",
        "monitoring/thread_status_updater.cc",
        "monitoring/thread_status_updater_debug.cc",
        "monitoring/thread_status_util.cc",
        "monitoring/thread_status_util_debug.cc",
        "options/cf_options.cc",
        "options/db_options.cc",
        "options/options.cc",
        "options/options_helper.cc",
        "options/options_parser.cc",
        "options/options_sanity_check.cc",
        "port/port_posix.cc",
        "port/stack_trace.cc",
        "table/adaptive_table_factory.cc",
        "table/block.cc",
        "table/block_based_filter_block.cc",
        "table/block_based_table_builder.cc",
        "table/block_based_table_factory.cc",
        "table/block_based_table_reader.cc",
        "table/block_builder.cc",
        "table/block_fetcher.cc",
        "table/block_prefix_index.cc",
        "table/bloom_block.cc",
        "table/cuckoo_table_builder.cc",
        "table/cuckoo_table_factory.cc",
        "table/cuckoo_table_reader.cc",
        "table/data_block_footer.cc",
        "table/data_block_hash_index.cc",
        "table/flush_block_policy.cc",
        "table/format.cc",
        "table/full_filter_block.cc",
        "table/get_context.cc",
        "table/index_builder.cc",
        "table/iterator.cc",
        "table/merging_iterator.cc",
        "table/meta_blocks.cc",
        "table/partitioned_filter_block.cc",
        "table/persistent_cache_helper.cc",
        "table/plain_table_builder.cc",
        "table/plain_table_factory.cc",
        "table/plain_table_index.cc",
        "table/plain_table_key_coding.cc",
        "table/plain_table_reader.cc",
        "table/sst_file_reader.cc",
        "table/sst_file_writer.cc",
        "table/table_properties.cc",
        "table/two_level_iterator.cc",
        "util/arena.cc",
        "util/auto_roll_logger.cc",
        "util/bloom.cc",
        "util/build_version.cc",
        "util/coding.cc",
        "util/compaction_job_stats_impl.cc",
        "util/comparator.cc",
        "util/compression_context_cache.cc",
        "util/concurrent_arena.cc",
        "util/concurrent_task_limiter_impl.cc",
        "util/crc32c.cc",
        "util/delete_scheduler.cc",
        "util/dynamic_bloom.cc",
        "util/event_logger.cc",
        "util/file_reader_writer.cc",
        "util/file_util.cc",
        "util/filename.cc",
        "util/filter_policy.cc",
        "util/hash.cc",
        "util/jemalloc_nodump_allocator.cc",
        "util/log_buffer.cc",
        "util/murmurhash.cc",
        "util/random.cc",
        "util/rate_limiter.cc",
        "util/slice.cc",
        "util/sst_file_manager_impl.cc",
        "util/status.cc",
        "util/string_util.cc",
        "util/sync_point.cc",
        "util/sync_point_impl.cc",
        "util/thread_local.cc",
        "util/threadpool_imp.cc",
        "util/trace_replay.cc",
        "util/transaction_test_util.cc",
        "util/xxhash.cc",
        "utilities/backupable/backupable_db.cc",
        "utilities/blob_db/blob_compaction_filter.cc",
        "utilities/blob_db/blob_db.cc",
        "utilities/blob_db/blob_db_impl.cc",
        "utilities/blob_db/blob_db_impl_filesnapshot.cc",
        "utilities/blob_db/blob_dump_tool.cc",
        "utilities/blob_db/blob_file.cc",
        "utilities/blob_db/blob_log_format.cc",
        "utilities/blob_db/blob_log_reader.cc",
        "utilities/blob_db/blob_log_writer.cc",
        "utilities/checkpoint/checkpoint_impl.cc",
        "utilities/compaction_filters/remove_emptyvalue_compactionfilter.cc",
        "utilities/convenience/info_log_finder.cc",
        "utilities/debug.cc",
        "utilities/env_mirror.cc",
        "utilities/env_timed.cc",
        "utilities/leveldb_options/leveldb_options.cc",
        "utilities/memory/memory_util.cc",
        "utilities/merge_operators/bytesxor.cc",
        "utilities/merge_operators/max.cc",
        "utilities/merge_operators/put.cc",
        "utilities/merge_operators/string_append/stringappend.cc",
        "utilities/merge_operators/string_append/stringappend2.cc",
        "utilities/merge_operators/uint64add.cc",
        "utilities/option_change_migration/option_change_migration.cc",
        "utilities/options/options_util.cc",
        "utilities/persistent_cache/block_cache_tier.cc",
        "utilities/persistent_cache/block_cache_tier_file.cc",
        "utilities/persistent_cache/block_cache_tier_metadata.cc",
        "utilities/persistent_cache/persistent_cache_tier.cc",
        "utilities/persistent_cache/volatile_tier_impl.cc",
        "utilities/simulator_cache/sim_cache.cc",
        "utilities/table_properties_collectors/compact_on_deletion_collector.cc",
        "utilities/trace/file_trace_reader_writer.cc",
        "utilities/transactions/optimistic_transaction.cc",
        "utilities/transactions/optimistic_transaction_db_impl.cc",
        "utilities/transactions/pessimistic_transaction.cc",
        "utilities/transactions/pessimistic_transaction_db.cc",
        "utilities/transactions/snapshot_checker.cc",
        "utilities/transactions/transaction_base.cc",
        "utilities/transactions/transaction_db_mutex_impl.cc",
        "utilities/transactions/transaction_lock_mgr.cc",
        "utilities/transactions/transaction_util.cc",
        "utilities/transactions/write_prepared_txn.cc",
        "utilities/transactions/write_prepared_txn_db.cc",
        "utilities/transactions/write_unprepared_txn.cc",
        "utilities/transactions/write_unprepared_txn_db.cc",
        "utilities/ttl/db_ttl_impl.cc",
        "utilities/write_batch_with_index/write_batch_with_index.cc",
        "utilities/write_batch_with_index/write_batch_with_index_internal.cc",
      ],
      publicHeadersPath: "include",
      cSettings: [
        .headerSearchPath("include"),
        .headerSearchPath("."),
        .define("NDEBUG", to: "1"),
        .define("LZ4", to: "1"),
        .define("OS_MACOSX", to: "1"),
        .define("ROCKSDB_PLATFORM_POSIX", to: "1"),
        .define("ROCKSDB_LIB_IO_POSIX", to: "1"),
        .define("ROCKSDB_USING_THREAD_STATUS", to: "1")
      ]
    ),
  ],
  cLanguageStandard: .gnu99,
  cxxLanguageStandard: .gnucxx11
)
