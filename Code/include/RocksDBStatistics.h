//
//  RocksDBStatistics.h
//  ObjectiveRocks
//
//  Created by Iska on 04/01/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RocksDBStatisticsHistogram.h"

NS_ASSUME_NONNULL_BEGIN

/** @brief An enum for the Ticker Types. */
typedef NS_ENUM(uint32_t, RocksDBTicker)
{
	/** @brief Total block cache misses. */
	RocksDBTickerBlockCacheMiss = 0,

	/** @brief Total block cache hits. */
	RocksDBTickerBlockCacheHit,

	/** @brief Number of blocks added to block cache. */
	RocksDBTickerBlockCacheAdd,

	/** @brief Number of failures when adding blocks to block cache. */
	RocksDBTickerBlockCacheAddFailures,

	/** @brief  # of times cache miss when accessing index block 
	 from block cache. */
	RocksDBTickerBlockCacheIndexMiss,

	/** @brief # of times cache hit when accessing index block 
	 from block cache. */
	RocksDBTickerBlockCacheIndexHit,

	/** @brief # of index blocks added to block cache. */
	RocksDBTickerBlockCacheIndexAdd,

	/** @brief # of bytes of index blocks inserted into cache */
	RocksDBTickerBlockCacheIndexBytesInsert,

	/** @brief # of bytes of index block erased from cache */
	RocksDBTickerBlockCacheIndexBytesEvict,

	/** @brief # of times cache miss when accessing filter block 
	 from block cache. */
	RocksDBTickerBlockCacheFilterMiss,

	/** @brief # of times cache hit when accessing filter block 
	 from block cache. */
	RocksDBTickerBlockCacheFilterHit,

	/** @brief # of filter blocks added to block cache. */
	RocksDBTickerBlockCacheFilterAdd,

	/** @brief # of bytes of bloom filter blocks inserted into cache. */
	RocksDBTickerBlockCacheFilterBytesInsert,

	/** @brief # of bytes of bloom filter block erased from cache. */
	RocksDBTickerBlockCacheFilterBytesEvict,

	/** @brief # of times cache miss when accessing data block 
	 from block cache. */
	RocksDBTickerBlockCacheDataMiss,

	/** @brief # of times cache hit when accessing data block 
	 from block cache.  */
	RocksDBTickerBlockCacheDataHit,

	/** @brief # of data blocks added to block cache. */
	RocksDBTickerBlockCacheDataAdd,

	/** @brief # of bytes of data blocks inserted into cache. */
	RocksDBTickerBlockCacheDataBytesInsert,

	/** @brief Number of bytes read from cache. */
	RocksDBTickerBlockCacheBytesRead,

	/** @brief Number of bytes written to cache. */
	RocksDBTickerBlockCacheBytesWrite,

	/** @brief # of times bloom filter has avoided file reads. */
	RocksDBTickerBloomFilterUseful,

	/** @brief # persistent cache hit. */
	RocksDBTickerPersistentCacheHit,

	/** @brief # persistent cache miss. */
	RocksDBTickerPersistentCacheMiss,

	/** @brief # total simulation block cache hits */
	RocksDBTickerSimBlockCacheHit,

	/** @brief # total simulation block cache misses */
	RocksDBTickerSimBlockCacheMiss,

	/** @brief # of memtable hits. */
	RocksDBTickerMemtableHit,

	/** @brief # of memtable misses. */
	RocksDBTickerMemtableMiss,

	/** @brief # of Get() queries served by L0 */
	RocksDBTickerGetHit_L0,

	/** @brief #of Get() queries served by L1 */
	RocksDBTickerGetHit_L1,

	/** @brief # of Get() queries served by L2 and up */
	RocksDBTickerGetHit_L2_AndUp,

	/** @brief Reason for key drop during compaction: The key was written 
	 with a newer value. */
	RocksDBTickerCompactionKeyDropNewerEntry,

	/** @brief Reason for key drop during compaction: The key is obsolete. */
	RocksDBTickerCompactionKeyDropObsolete,

	/** @brief Reason for key drop during compaction: The key was covered by 
	 a range tombstone. */
	RocksDBTickerCompactionKeyRangeDelete,

	/** @brief Reason for key drop during compaction: User compaction 
	 function has dropped the key. */
	RocksDBTickerCompactionKeyDropUser,

	/** @brief Reason for key drop during compaction: all keys in range were deleted. */
	RocksDBTickerCompactionRangeDelDropObsolete,

	/** @brief Deletions obsoleted before bottom level due to file gap optimization. */
	RocksDBTickerCompactionOptimizedDelDropObsolete,

	/** @brief If a compaction was cancelled in sfm to prevent ENOSPC. */
	RocksDBTickerCompactionCancelled,

	/** @brief Number of keys written to the database via the Put and 
	 Write call's. */
	RocksDBTickerNumberKeysWritten,

	/** @brief Number of Keys read. */
	RocksDBTickerNumberKeysRead,

	/** @brief Number keys updated, if inplace update is enabled. */
	RocksDBTickerNumberKeysUpdated,

	/** @brief Number of bytes written. */
	RocksDBTickerBytesWritten,

	/** @brief Number of bytes read. */
	RocksDBTickerBytesRead,

	/** @brief Number of calls to `seek`. */
	RocksDBTickerNumberDBSeek,

	/** @brief Number of calls to `next`. */
	RocksDBTickerNumberDBNext,

	/** @brief Number of calls to `previous`. */
	RocksDBTickerNumberDBPrevious,

	/** @brief Number of calls to `seek` that returned data. */
	RocksDBTickerNumberDBSeekFound,

	/** @brief Number of calls to `next` that returned data. */
	RocksDBTickerNumberDBNextFound,

	/** @brief Number of calls to `previous` that returned data. */
	RocksDBTickerNumberDBPreviousFound,

	/** @brief The number of uncompressed bytes read from an iterator. 
	 Includes size of key and value. */
	RocksDBTickerIterBytesRead,

	/** @brief Number of file closes. */
	RocksDBTickerNoFileCloses,

	/** @brief Number of file opens. */
	RocksDBTickerNoFileOpens,

	/** @brief Number of file errors. */
	RocksDBTickerNoFileErrors,

	/** @brief Time system had to wait to do LO-L1 compactions
		@deprecated Deprecated in rocksdb `9132e52ea4fd60886616cbec6c412f88117333fa`
	 */
	RocksDBTickerStall_L0SlowdownMicros,

	/** @brief Time system had to wait to move memtable to L1.
		@deprecated Deprecated in rocksdb `9132e52ea4fd60886616cbec6c412f88117333fa`
	 */
	RocksDBTickerStallMemtableCompactionMicros,

	/** @brief Write throttle because of too many files in L0
		@deprecated Deprecated in rocksdb `9132e52ea4fd60886616cbec6c412f88117333fa`
	 */
	RocksDBTickerStall_L0NumFilesMicros,

	/** @brief Writer has to wait for compaction or flush to finish. */
	RocksDBTickerStallMicros,

	/** @brief The wait time for db mutex. */
	RocksDBTickerDBMutexWaitMicros,

	/** @brief The rate limit delay. */
	RocksDBTickerRateLimitDelayMillis,

	/** @brief Number of iterators currently open. */
	RocksDBTickerNoIterators,

	/** @brief Number of MultiGet calls. */
	RocksDBTickerNumberMultigetCalls,

	/** @brief Number of MultiGet keys read. */
	RocksDBTickerNumberMultigetKeysRead,

	/** @brief Number of MultiGet bytes read. */
	RocksDBTickerNumberMultigetBytesRead,

	/** @brief Number of deletes records that were not required 
	 to be written to storage because key does not exist. */
	RocksDBTickerNumberFilteredDeletes,

	/** @brief Number of merge failures. */
	RocksDBTickerNumberMergeFailures,

	/** @brief Number of times bloom was checked before creating 
	 iterator on a file. */
	RocksDBTickerBloomFilterPrefixChecked,

	/** @brief Number of times the check was useful in avoiding
	 iterator creation (and thus likely IOPs). */
	RocksDBTickerBloomFilterPrefixUseful,

	/** @brief Number reseeks inside an iteration to skip over 
	 large number of keys with same userkey. */
	RocksDBTickerNumberOfReseeksInIteration,

	/** @brief Number of calls to GetUpadtesSince. Useful to keep 
	 track of transaction log iterator refreshes. */
	RocksDBTickerGetUpdatesSinceCalls,

	/** @brief Number of misses in the compressed block cache. */
	RocksDBTickerBlockCacheCompressedMiss,

	/** @brief Number of hits in the compressed block cache. */
	RocksDBTickerBlockCacheCompressedHit,

	/** @brief Number of blocks added to comopressed block cache. */
	RocksDBTickerBlockCacheCompressedAdd,

	/** @brief Number of failures when adding blocks to compressed block cache. */
	RocksDBTickerBlockCacheCompressedAddFailures,

	/** @brief Number of times WAL sync is done. */
	RocksDBTickerWalFileSynced,

	/** @brief Number of bytes written to WAL. */
	RocksDBTickerWalFileBytes,

	/** @brief Number of wrtites done by the requesting thread. */
	RocksDBTickerWriteDoneBySelf,

	/** @brief Number of wrtites done by by a thread at thehead 
	 of the writers queue. */
	RocksDBTickerWriteDoneByOther,

	/** @brief Number of writes ending up with timed-out. */
	RocksDBTickerWriteTimedout,

	/** @brief Number of Write calls that request WAL. */
	RocksDBTickerWriteWithWal,

	/** @brief Bytes read during compaction. */
	RocksDBTickerCompactReadBytes,

	/** @brief Bytes written during compaction. */
	RocksDBTickerCompactWriteBytes,

	/** @brief Bytes written during flush. */
	RocksDBTickerFlushWriteBytes,

	/** @brief Number of table's properties loaded directly from file, 
	 without creating table reader object. */
	RocksDBTickerNumberDirectLoadTableProperties,

	/** @brief Number of supervision acquires. */
	RocksDBTickerNumberSuperversionAcquires,

	/** @brief Number of supervision releases. */
	RocksDBTickerNumberSuperversionReleases,

	/** @brief Number of supervision cleanups. */
	RocksDBTickerNumberSuperversionCleanups,

	/** @brief # of compressions executed. */
	RocksDBTickerNumberBlockCompressed,

	/** @brief # of decompressions executed. */
	RocksDBTickerNumberBlockDecompressed,

	/** @brief # of blocks not compressed. */
	RocksDBTickerNumberBlockNotCompressed,

	/** @brief The total time of the merge operation. */
	RocksDBTickerMergeOprationTotalTime,

	/** @brief The total time of the filter operation. */
	RocksDBTickerFilterOperationTotalTime,

	/** @brief Total row cache hits. */
	RocksDBTickerRowCacheHit,

	/** @brief Total row cache misses. */
	RocksDBTickerRowCacheMiss,

	/** @brief Read amplification statistics: Estimate of total bytes actually used. */
	RocksDBTickerReadAmpEstimateUsefulBytes,

	/** @brief Read amplification statistics: Total size of loaded data blocks. */
	RocksDBTickerReadAmpTotalReadBytes,

	/** @brief Number of refill intervals where rate limiter's bytes are fully consumed. */
	RocksDBTickerNumberRateLimiterDrains,

	/** @brief Number of internal keys skipped by Iterator. **/
	RocksDBTickerNumberIterSkip,

	/** @brief # of Put/PutTTL/PutUntil to BlobDB. **/
	RocksDBTickerBlobDBNumPut,

	/** @brief # of Write to BlobDB. **/
	RocksDBTickerBlobDBNumWrite,

	/** @brief # of Get to BlobDB. **/
	RocksDBTickerBlobDBNumGet,

	/** @brief # of Multiget to BlobDB. **/
	RocksDBTickerBlobDBNumMultiget,

	/** @brief # of Seek/SeekToFirst/SeekToLast/SeekForPrev to BlobDB iterator. **/
	RocksDBTickerBlobDBNumSeek,

	/** @brief # of Next to BlobDB iterator. **/
	RocksDBTickerBlobDBNumNext,

	/** @brief # of Prev to BlobDB iterator. **/
	RocksDBTickerBlobDBNumPrev,

	/** @brief # of keys written to BlobDB. **/
	RocksDBTickerBlobDBNumKeysWritten,

	/** @brief # of keys read from BlobDB. **/
	RocksDBTickerBlobDBNumKeysRead,

	/** @brief # of bytes (key + value) written to BlobDB. **/
	RocksDBTickerBlobDBBytesWritten,

	/** @brief # of bytes (keys + value) read from BlobDB. **/
	RocksDBTickerBlobDBBytesRead,

	/** @brief # of keys written by BlobDB as non-TTL inlined value. **/
	RocksDBTickerBlobDBWriteInlined,

	/** @brief # of keys written by BlobDB as TTL inlined value. **/
	RocksDBTickerBlobDBWriteInlinedTTL,

	/** @brief # of keys written by BlobDB as non-TTL blob value. **/
	RocksDBTickerBlobDBWriteBlob,

	/** @brief # of keys written by BlobDB as TTL blob value. **/
	RocksDBTickerBlobDBWriteBlobTTL,

	/** @brief # of bytes written to blob file. **/
	RocksDBTickerBlobDBBlobFileBytesWritten,

	/** @brief # of bytes read from blob file. **/
	RocksDBTickerBlobDBBlobFileBytesRead,

	/** @brief # of times a blob files being synced. **/
	RocksDBTickerBlobDBBlobFileSynced,

	/** @brief  # of blob index evicted from base DB by BlobDB compaction filter because of expiration. */
	RocksDBTickerBlobDBBlobIndexExpiredCount,

	/** @brief Size of blob index evicted from base DB by BlobDB compaction filter because of expiration. */
	RocksDBTickerBlobDBBlobIndexExpiredSize,

	/** @brief # of blob index evicted from base DB by BlobDB compaction filter because of corresponding file deleted. */
	RocksDBTickerBlobDBBlobIndexEvictedCount,

	/** @brief Size of blob index evicted from base DB by BlobDB compaction filter because of corresponding file deleted. */
	RocksDBTickerBlobDBBlobIndexEvictedSize,

	/** @brief # of blob files being garbage collected. **/
	RocksDBTickerBlobDBGCNumFiles,

	/** @brief # of blob files generated by garbage collection. **/
	RocksDBTickerBlobDBGCNumNewFiles,

	/** @brief # of BlobDB garbage collection failures. **/
	RocksDBTickerBlobDBGCFailures,

	/** @brief # of keys drop by BlobDB garbage collection because they had been overwritten. **/
	RocksDBTickerBlobDBGCNumKeysOverwritten,

	/** @brief # of keys drop by BlobDB garbage collection because of expiration. **/
	RocksDBTickerBlobDBGCNumKeysExpired,

	/** @brief # of keys relocated to new blob file by garbage collection. **/
	RocksDBTickerBlobDBGCNumKeysRelocated,

	/** @brief # of bytes drop by BlobDB garbage collection because they had been overwritten. **/
	RocksDBTickerBlobDBGCBytesOverwritten,

	/** @brief # of bytes drop by BlobDB garbage collection because of expiration. **/
	RocksDBTickerBlobDBGCBytesExpired,

	/** @brief # of bytes relocated to new blob file by garbage collection. **/
	RocksDBTickerBlobDBGCBytesRelocated,

	/** @brief # of blob files evicted because of BlobDB is full. **/
	RocksDBTickerBlobDBFifoNumFilesEvicted,

	/** @brief # of keys in the blob files evicted because of BlobDB is full. **/
	RocksDBTickerBlobDBFifoNumKeysEvicted,

	/** @brief # of bytes in the blob files evicted because of BlobDB is full. **/
	RocksDBTickerBlobDBFifoBytesEvicted
};

/** @brief An enum for the Histogram Types. */
typedef NS_ENUM(uint32_t, RocksDBHistogram)
{
	/** @brief Time spent in DB Get() calls */
	RocksDBHistogramDBGet = 0,

	/** @brief Time spent in DB Write() calls */
	RocksDBHistogramDBWrite,

	/** @brief Time spent during compaction. */
	RocksDBHistogramCompactionTime,

	/** @brief Time spent during subcompaction. */
	RocksDBHistogramSubcompactionTime,

	/** @brief Time spent during table syncs. */
	RocksDBHistogramTableSyncMicros,

	/** @brief Time spent during compaction outfile syncs. */
	RocksDBHistogramCompactionOutfileSyncMicros,

	/** @brief Time spent during WAL file syncs. */
	RocksDBHistogramWalFileSyncMicros,

	/** @brief Time spent during manifest file syncs. */
	RocksDBHistogramManifestFileSyncMicros,

	/** @brief Time spent during in IO during table open. */
	RocksDBHistogramTableOpenIOMicros,

	/** @brief Time spend during DB MultiGet() calls. */
	RocksDBHistogramDBMultiget,

	/** @brief Time spend during read block compaction. */
	RocksDBHistogramReadBlockCompactionMicros,

	/** @brief Time spend during read block Get(). */
	RocksDBHistogramReadBlockGetMicros,

	/** @brief Time spend during write raw blocks. */
	RocksDBHistogramWriteRawBlockMicros,

	/** @brief The number of stalls in L0 slowdowns. */
	RocksDBHistogramStall_L0SlowdownCount,

	/** @brief The number of stalls in memtable compations */
	RocksDBHistogramStallMemtableCompactionCount,

	/** @brief The number of stalls in L0 files. */
	RocksDBHistogramStall_L0NumFilesCount,

	/** @brief The count of delays in hard rate limiting. */
	RocksDBHistogramHardRateLimitDelayCount,

	/** @brief The count of delays in soft rate limiting. */
	RocksDBHistogramSoftRateLimitDelayCount,

	/** @brief The number of files in a single compaction. */
	RocksDBHistogramNumFilesInSingleCompaction,

	/** @brief Time Spent in Seek() calls. */
	RocksDBHistogramDBSeek,

	/** @brief Time spent in Write Stall. */
	RocksDBHistogramWriteStall,

	/** @brief  Time spent in SST Read. */
	RocksDBHistogramSSTReadMicros,

	/** @brief The number of subcompactions actually scheduled during a compaction. */
	RocksDBHistogramNumCompactionsScheduled,

	/** @brief Distribution of bytes read in each operations. */
	RocksDBHistogramBytesPerRead,

	/** @brief Distribution of bytes written in each operations. */
	RocksDBHistogramBytesPerWrite,

	/** @brief Distribution of bytes via multiget in each operations. */
	RocksDBHistogramBytesPerMultiGet,

	/** @brief # of bytes compressed. */
	RocksDBHistogramBytesCompressed,

	/** @brief # of bytes decompressed. */
	RocksDBHistogramBytesDecompressed,

	/** @brief Compression time. */
	RocksDBHistogramCompressionTimeNanos,

	/** @brief Decompression time. */
	RocksDBHistogramDecompressionTimeNanos,

	/** @brief Number of merge operands passed to the merge operator in user read requests. **/
	RocksDBHistogramReadNumMergeOperands,

	/** @brief Size of keys written to BlobDB. **/
	RocksDBHistogramBlobDbKeySize,

	/** @brief Size of values written to BlobDB. **/
	RocksDBHistogramBlobDbValueSize,

	/** @brief BlobDB Put/PutWithTTL/PutUntil/Write latency. **/
	RocksDBHistogramBlobDbWriteMicros,

	/** @brief BlobDB Get lagency. **/
	RocksDBHistogramBlobDbGetMicros,

	/** @brief BlobDB MultiGet lagency. **/
	RocksDBHistogramBlobDbMultigetMicros,

	/** @brief BlobDB Seek/SeekToFirst/SeekToLast/SeekForPrev latency. **/
	RocksDBHistogramBlobDbSeekMicros,

	/** @brief BlobDB Next latency. **/
	RocksDBHistogramBlobDbNextMicros,

	/** @brief BlobDB Prev latency. **/
	RocksDBHistogramBlobDbPrevMicros,

	/** @brief Blob file write latency. **/
	RocksDBHistogramBlobDbBlobFileWriteMicros,

	/** @brief Blob file read latency. **/
	RocksDBHistogramBlobDbBlobFileReadMicros,

	/** @brief Blob file sync latency. **/
	RocksDBHistogramBlobDbBlobFileSyncMicros,

	/** @brief BlobDB garbage collection time. **/
	RocksDBHistogramBlobDbGcMicros,

	/** @brief BlobDB compression time. **/
	RocksDBHistogramBlobDbCompressionMicros,

	/** @brief BlobDB decompression time. **/
	RocksDBHistogramBlobDbDecompressionMicros,

	/** @brief Time spent flushing memtable to disk. **/
	RocksDBHistogramFlushTime
};

/**
 The `RocksDBStatistics`, when set in the `RocksDBOptions`, is used to collect usage statistics.

 @see RocksDBOptions
 */
@interface RocksDBStatistics : NSObject

/**
 Returns the value for the given ticker.

 @param ticker The ticker type to get.
 @return The value for the given ticker type.
*/
- (uint64_t)countForTicker:(RocksDBTicker)ticker;

/**
 Returns the histogram for the given histogram type.

 @param type The type of the histogram to get.
 @return The value for the given histogram type.

 @see RocksDBStatisticsHistogram
 */
- (RocksDBStatisticsHistogram *)histogramDataForType:(RocksDBHistogram)type;

/** @brief String representation of the statistic object. */
- (NSString *)description;

@end

NS_ASSUME_NONNULL_END
