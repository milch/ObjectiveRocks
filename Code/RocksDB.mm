//
//  ObjectiveRocks.m
//  ObjectiveRocks
//
//  Created by Iska on 15/11/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import "RocksDB.h"

#import "RocksDBOptions+Private.h"

#import "RocksDBColumnFamily.h"
#import "RocksDBColumnFamily+Private.h"

#import "RocksDBOptions.h"
#import "RocksDBReadOptions.h"
#import "RocksDBWriteOptions.h"

#import "RocksDBCompactRangeOptions+Private.h"

#import "RocksDBIterator+Private.h"
#import "RocksDBWriteBatch+Private.h"

#import "RocksDBSnapshot.h"
#import "RocksDBSnapshot+Private.h"

#import "RocksDBError.h"
#import "RocksDBSlice.h"

#include <rocksdb/db.h>
#include <rocksdb/slice.h>
#include <rocksdb/options.h>

#if !(defined(ROCKSDB_LITE) && defined(TARGET_OS_IPHONE))
#import "RocksDBColumnFamilyMetaData+Private.h"
#import "RocksDBIndexedWriteBatch+Private.h"
#import "RocksDBProperties.h"
#endif

#pragma mark -

@interface RocksDBColumnFamilyDescriptor (Private)
@property (nonatomic, assign) std::vector<rocksdb::ColumnFamilyDescriptor> *columnFamilies;
@end

@interface RocksDB ()
{
	NSString *_path;
	rocksdb::DB *_db;
	rocksdb::ColumnFamilyHandle *_columnFamily;
	std::vector<rocksdb::ColumnFamilyHandle *> *_columnFamilyHandles;
	std::atomic<bool> _closed;

	NSMutableArray *_columnFamilies;

	RocksDBOptions *_options;
	RocksDBReadOptions *_readOptions;
	RocksDBWriteOptions *_writeOptions;
}
@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) rocksdb::DB *db;
@property (nonatomic, assign) rocksdb::ColumnFamilyHandle *columnFamily;
@property (nonatomic, strong) RocksDBOptions *options;
@property (nonatomic, strong) RocksDBReadOptions *readOptions;
@property (nonatomic, strong) RocksDBWriteOptions *writeOptions;
@end

@implementation RocksDB
@synthesize path = _path;
@synthesize db = _db;
@synthesize columnFamily = _columnFamily;
@synthesize options = _options;
@synthesize readOptions = _readOptions;
@synthesize writeOptions = _writeOptions;

#pragma mark - Lifecycle

+ (instancetype)databaseAtPath:(NSString *)path andDBOptions:(void (^)(RocksDBOptions *))optionsBlock error:(NSError**)error
{
	RocksDB *rocks = [[RocksDB alloc] initWithPath:path];

	if (optionsBlock) {
		optionsBlock(rocks.options);
	}

	if ([rocks openDatabaseReadOnly:NO error:error] == NO) {
		return nil;
	}
	return rocks;
}

+ (instancetype)databaseAtPath:(NSString *)path
				columnFamilies:(RocksDBColumnFamilyDescriptor *)descriptor
            andDatabaseOptions:(void (^)(RocksDBDatabaseOptions *options))optionsBlock
                         error:(NSError**)error
{
	RocksDB *rocks = [[RocksDB alloc] initWithPath:path];

	RocksDBDatabaseOptions *dbOptions = [RocksDBDatabaseOptions new];
	if (optionsBlock) {
		optionsBlock(dbOptions);
	}
	rocks.options.databaseOptions = dbOptions;

	if ([rocks openColumnFamilies:descriptor readOnly:NO error:error] == NO) {
		return nil;
	}
	return rocks;
}

#if !(defined(ROCKSDB_LITE) && defined(TARGET_OS_IPHONE))

+ (instancetype)databaseForReadOnlyAtPath:(NSString *)path
							 andDBOptions:(void (^)(RocksDBOptions *options))optionsBlock
                                    error:(NSError**)error
{
	RocksDB *rocks = [[RocksDB alloc] initWithPath:path];

	if (optionsBlock) {
		optionsBlock(rocks.options);
	}

	if ([rocks openDatabaseReadOnly:YES error:error] == NO) {
		return nil;
	}
	return rocks;
}

+ (instancetype)databaseForReadOnlyAtPath:(NSString *)path
						   columnFamilies:(RocksDBColumnFamilyDescriptor *)descriptor
					   andDatabaseOptions:(void (^)(RocksDBDatabaseOptions *options))optionsBlock
                                    error:(NSError**)error
{
	RocksDB *rocks = [[RocksDB alloc] initWithPath:path];

	RocksDBDatabaseOptions *dbOptions = [RocksDBDatabaseOptions new];
	if (optionsBlock) {
		optionsBlock(dbOptions);
	}
	rocks.options.databaseOptions = dbOptions;

	if ([rocks openColumnFamilies:descriptor readOnly:YES error:error] == NO) {
		return nil;
	}
	return rocks;
}

#endif

- (instancetype)initWithPath:(NSString *)path
{
	self = [super init];
	if (self) {
		_path = [path copy];
		_options = [RocksDBOptions new];
		_readOptions = [RocksDBReadOptions new];
		_writeOptions = [RocksDBWriteOptions new];
	}
	return self;
}

- (void)dealloc
{
	[self close];
}

- (void)close
{
	if (_closed.load()) {
		return ;
	}
	_closed = true;
	[_columnFamilies makeObjectsPerformSelector:@selector(close)];

	if (_columnFamilyHandles != nullptr) {
		delete _columnFamilyHandles;
		_columnFamilyHandles = nullptr;
	}

	if (_db != nullptr) {
		delete _db;
		_db = nullptr;
	}
}

- (BOOL)isClosed {
	@synchronized(self) {
		return _db == nullptr;
	}
}

#pragma mark - Open

- (BOOL)openDatabaseReadOnly:(BOOL)readOnly error:(NSError**)error
{
	rocksdb::Status status;
	if (readOnly) {
		status = rocksdb::DB::OpenForReadOnly(_options.options, _path.UTF8String, &_db);
	} else {
		status = rocksdb::DB::Open(_options.options, _path.UTF8String, &_db);
	}

	if (!status.ok()) {
		NSError *statusError = [RocksDBError errorWithRocksStatus:status];
		*error = statusError;
		NSLog(@"Error opening database: %@", statusError);
		[self close];
		return NO;
	}
	_columnFamily = _db->DefaultColumnFamily();
	_closed = false;

	return YES;
}

- (BOOL)openColumnFamilies:(RocksDBColumnFamilyDescriptor *)descriptor readOnly:(BOOL)readOnly error:(NSError**)error
{
	rocksdb::Status status;
	std::vector<rocksdb::ColumnFamilyDescriptor> *columnFamilies = descriptor.columnFamilies;
	_columnFamilyHandles = new std::vector<rocksdb::ColumnFamilyHandle *>;

	if (readOnly) {
		status = rocksdb::DB::OpenForReadOnly(_options.options,
											  _path.UTF8String,
											  *columnFamilies,
											  _columnFamilyHandles,
											  &_db);
	} else {
		status = rocksdb::DB::Open(_options.options,
								   _path.UTF8String,
								   *columnFamilies,
								   _columnFamilyHandles,
								   &_db);
	}


	if (!status.ok()) {
		NSError *statusError = [RocksDBError errorWithRocksStatus:status];
		*error = statusError;
		NSLog(@"Error opening database: %@", statusError);
		[self close];
		return NO;
	}
	_columnFamily = _db->DefaultColumnFamily();
	_closed = false;

	return YES;
}

#pragma mark - Column Families

+ (NSArray *)listColumnFamiliesInDatabaseAtPath:(NSString *)path
{
	std::vector<std::string> names;

	rocksdb::Status status = rocksdb::DB::ListColumnFamilies(rocksdb::Options(), path.UTF8String, &names);
	if (!status.ok()) {
		NSLog(@"Error listing column families in database at %@: %@", path, [RocksDBError errorWithRocksStatus:status]);
	}

	NSMutableArray *columnFamilies = [NSMutableArray array];
	for(auto it = std::begin(names); it != std::end(names); ++it) {
		[columnFamilies addObject:[[NSString alloc] initWithCString:it->c_str() encoding:NSUTF8StringEncoding]];
	}
	return columnFamilies;
}

- (RocksDBColumnFamily *)createColumnFamilyWithName:(NSString *)name andOptions:(void (^)(RocksDBColumnFamilyOptions *options))optionsBlock
{
	if (_closed.load()) {
		return nil;
	}
	RocksDBColumnFamilyOptions *columnFamilyOptions = [RocksDBColumnFamilyOptions new];
	if (optionsBlock) {
		optionsBlock(columnFamilyOptions);
	}

	rocksdb::ColumnFamilyHandle *handle;
	rocksdb::Status status = _db->CreateColumnFamily(columnFamilyOptions.options, name.UTF8String, &handle);
	if (!status.ok()) {
		NSLog(@"Error creating column family: %@", [RocksDBError errorWithRocksStatus:status]);
		return nil;
	}

	RocksDBOptions *options = [[RocksDBOptions alloc] initWithDatabaseOptions:_options.databaseOptions
													   andColumnFamilyOptions:columnFamilyOptions];

	RocksDBColumnFamily *columnFamily = [[RocksDBColumnFamily alloc] initWithDBInstance:_db
																		   columnFamily:handle
																			 andOptions:options];
	return columnFamily;
}

- (NSArray *)columnFamilies
{
	if (_closed.load()) {
		return nil;
	}
	if (_columnFamilyHandles == nullptr) {
		return nil;
	}

	if (_columnFamilies == nil) {
		_columnFamilies = [NSMutableArray new];
		for(auto it = std::begin(*_columnFamilyHandles); it != std::end(*_columnFamilyHandles); ++it) {
			RocksDBColumnFamily *columnFamily = [[RocksDBColumnFamily alloc] initWithDBInstance:_db
																				   columnFamily:*it
																					 andOptions:_options];
			[_columnFamilies addObject:columnFamily];
		}
	}

	return _columnFamilies;
}

#if !(defined(ROCKSDB_LITE) && defined(TARGET_OS_IPHONE))

- (RocksDBColumnFamilyMetaData *)columnFamilyMetaData
{
	if (_closed.load()) {
		return nil;
	}
	rocksdb::ColumnFamilyMetaData metadata;
	_db->GetColumnFamilyMetaData(_columnFamily, &metadata);

	RocksDBColumnFamilyMetaData *columnFamilyMetaData = [[RocksDBColumnFamilyMetaData alloc] initWithMetaData:metadata];
	return columnFamilyMetaData;
}

#endif

#pragma mark - Read/Write Options

- (void)setDefaultReadOptions:(void (^)(RocksDBReadOptions *))readOptionsBlock writeOptions:(void (^)(RocksDBWriteOptions *))writeOptionsBlock
{
	_readOptions = [RocksDBReadOptions new];
	_writeOptions = [RocksDBWriteOptions new];

	if (readOptionsBlock) {
		readOptionsBlock(_readOptions);
	}

	if (writeOptionsBlock) {
		writeOptionsBlock(_writeOptions);
	}
}

#if !(defined(ROCKSDB_LITE) && defined(TARGET_OS_IPHONE))

#pragma mark - Peroperties

- (NSString *)valueForProperty:(RocksDBProperty)property
{
	if (_closed.load()) {
		return nil;
	}
	std::string value;
	bool ok = _db->GetProperty(_columnFamily,
							   SliceFromData([ResolveProperty(property) dataUsingEncoding:NSUTF8StringEncoding]),
							   &value);
	if (!ok) {
		return nil;
	}

	NSData *data = DataFromSlice(rocksdb::Slice(value));
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (uint64_t)valueForIntProperty:(RocksDBIntProperty)property
{
	if (_closed.load()) {
		return 0;
	}
	uint64_t value;
	bool ok = _db->GetIntProperty(_columnFamily,
								  SliceFromData([ResolveIntProperty(property) dataUsingEncoding:NSUTF8StringEncoding]),
								  &value);
	if (!ok) {
		return 0;
	}
	return value;
}

#endif

#pragma mark - Write Operations

- (BOOL)setData:(NSData *)anObject forKey:(NSData *)aKey error:(NSError * __autoreleasing *)error
{
	if (_closed.load()) {
		*error = [RocksDBError errorIsClosed];
		return NO;
	}
	return [self setData:anObject forKey:aKey writeOptions:nil error:error];
}

- (BOOL)setData:(NSData *)anObject
		   forKey:(NSData *)aKey
	 writeOptions:(void (^)(RocksDBWriteOptions *writeOptions))writeOptionsBlock
			error:(NSError * __autoreleasing *)error
{
	if (_closed.load()) {
		*error = [RocksDBError errorIsClosed];
		return NO;
	}
	RocksDBWriteOptions *writeOptions = [_writeOptions copy];
	if (writeOptionsBlock) {
		writeOptionsBlock(writeOptions);
	}

	rocksdb::Status status = _db->Put(writeOptions.options,
									  _columnFamily,
									  SliceFromData(aKey),
									  SliceFromData(anObject));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
}

#pragma mark - Merge Operations

- (BOOL)mergeData:(NSData *)anObject forKey:(NSData *)aKey error:(NSError * __autoreleasing *)error
{
	if (_closed.load()) {
		*error = [RocksDBError errorIsClosed];
		return NO;
	}
	return [self mergeData:anObject forKey:aKey writeOptions:nil error:error];
}

- (BOOL)mergeData:(NSData *)anObject
		   forKey:(NSData *)aKey
	 writeOptions:(void (^)(RocksDBWriteOptions *writeOptions))writeOptionsBlock
			error:(NSError * __autoreleasing *)error
{
	if (_closed.load()) {
		*error = [RocksDBError errorIsClosed];
		return NO;
	}
	RocksDBWriteOptions *writeOptions = [_writeOptions copy];
	if (writeOptionsBlock) {
		writeOptionsBlock(writeOptions);
	}

	rocksdb::Status status = _db->Merge(_writeOptions.options,
										_columnFamily,
										SliceFromData(aKey),
										SliceFromData(anObject));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
}

#pragma mark - Read Operations

- (NSData *)dataForKey:(NSData *)aKey error:(NSError * __autoreleasing *)error
{
	if (_closed.load()) {
		*error = [RocksDBError errorIsClosed];
		return nil;
	}
	return [self dataForKey:aKey readOptions:nil error:error];
}

- (NSData *)dataForKey:(NSData *)aKey
		   readOptions:(void (^)(RocksDBReadOptions *readOptions))readOptionsBlock
				 error:(NSError * __autoreleasing *)error
{
	if (_closed.load()) {
		*error = [RocksDBError errorIsClosed];
		return nil;
	}
	RocksDBReadOptions *readOptions = [_readOptions copy];
	if (readOptionsBlock) {
		readOptionsBlock(readOptions);
	}

	std::string value;
	rocksdb::Status status = _db->Get(readOptions.options,
									  _columnFamily,
									  SliceFromData(aKey),
									  &value);
	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return nil;
	}

	return DataFromSlice(rocksdb::Slice(value));
}

#pragma mark - Delete Operations

- (BOOL)deleteDataForKey:(NSData *)aKey error:(NSError * __autoreleasing *)error
{
	if (_closed.load()) {
		*error = [RocksDBError errorIsClosed];
		return NO;
	}
	return [self deleteDataForKey:aKey writeOptions:nil error:error];
}

- (BOOL)deleteDataForKey:(NSData *)aKey
			writeOptions:(void (^)(RocksDBWriteOptions *writeOptions))writeOptionsBlock
				   error:(NSError * __autoreleasing *)error
{
	if (_closed.load()) {
		*error = [RocksDBError errorIsClosed];
		return NO;
	}
	RocksDBWriteOptions *writeOptions = [_writeOptions copy];
	if (writeOptionsBlock) {
		writeOptionsBlock(writeOptions);
	}

	rocksdb::Status status = _db->Delete(writeOptions.options,
										 _columnFamily,
										 SliceFromData(aKey));

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}

	return YES;
}

#pragma mark - Batch Writes

- (RocksDBWriteBatch *)writeBatch
{
	if (_closed.load()) {
		return nil;
	}
	return [[RocksDBWriteBatch alloc] initWithColumnFamily:_columnFamily];
}

- (BOOL)performWriteBatch:(void (^)(RocksDBWriteBatch *batch, RocksDBWriteOptions *options))batchBlock
					error:(NSError * __autoreleasing *)error
{
	if (_closed.load()) {
		*error = [RocksDBError errorIsClosed];
		return NO;
	}
	if (batchBlock == nil) return NO;

	RocksDBWriteBatch *writeBatch = [self writeBatch];
	RocksDBWriteOptions *writeOptions = [_writeOptions copy];

	batchBlock(writeBatch, writeOptions);
	rocksdb::WriteBatch *batch = writeBatch.writeBatchBase->GetWriteBatch();
	rocksdb::Status status = _db->Write(writeOptions.options, batch);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

- (BOOL)applyWriteBatch:(RocksDBWriteBatch *)writeBatch
		   writeOptions:(void (^)(RocksDBWriteOptions *writeOptions))writeOptionsBlock
				  error:(NSError * __autoreleasing *)error
{
	if (_closed.load()) {
		*error = [RocksDBError errorIsClosed];
		return NO;
	}
	RocksDBWriteOptions *writeOptions = [_writeOptions copy];
	if (writeOptionsBlock) {
		writeOptionsBlock(writeOptions);
	}

	rocksdb::WriteBatch *batch = writeBatch.writeBatchBase->GetWriteBatch();
	rocksdb::Status status = _db->Write(writeOptions.options, batch);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

#if !(defined(ROCKSDB_LITE) && defined(TARGET_OS_IPHONE))

- (RocksDBIndexedWriteBatch *)indexedWriteBatch
{
	if (_closed.load()) {
		return nil;
	}
	return [[RocksDBIndexedWriteBatch alloc] initWithDBInstance:_db
												   columnFamily:_columnFamily
													readOptions:_readOptions];
}

- (BOOL)performIndexedWriteBatch:(void (^)(RocksDBIndexedWriteBatch *batch, RocksDBWriteOptions *options))batchBlock
						   error:(NSError * __autoreleasing *)error
{
	if (_closed.load()) {
		*error = [RocksDBError errorIsClosed];
		return NO;
	}
	if (batchBlock == nil) return NO;

	RocksDBIndexedWriteBatch *writeBatch = [self indexedWriteBatch];
	RocksDBWriteOptions *writeOptions = [_writeOptions copy];

	batchBlock(writeBatch, writeOptions);
	rocksdb::WriteBatch *batch = writeBatch.writeBatchBase->GetWriteBatch();
	rocksdb::Status status = _db->Write(writeOptions.options, batch);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

#endif

#pragma mark - Iteration

- (RocksDBIterator *)iterator
{
	if (_closed.load()) {
		return nil;
	}
	return [self iteratorWithReadOptions:nil];
}

- (RocksDBIterator *)iteratorWithReadOptions:(void (^)(RocksDBReadOptions *readOptions))readOptionsBlock
{
	RocksDBReadOptions *readOptions = [_readOptions copy];
	if (readOptionsBlock) {
		readOptionsBlock(readOptions);
	}
	rocksdb::Iterator *iterator = _db->NewIterator(readOptions.options,
												   _columnFamily);

	return [[RocksDBIterator alloc] initWithDBIterator:iterator];
}

#pragma mark - Snapshot

- (RocksDBSnapshot *)snapshot
{
	if (_closed.load()) {
		return nil;
	}
	return [self snapshotWithReadOptions:nil];
}

- (RocksDBSnapshot *)snapshotWithReadOptions:(void (^)(RocksDBReadOptions *readOptions))readOptionsBlock
{
	if (_closed.load()) {
		return nil;
	}
	RocksDBReadOptions *readOptions = [_readOptions copy];
	if (readOptionsBlock) {
		readOptionsBlock(readOptions);
	}

	rocksdb::ReadOptions options = readOptions.options;
	options.snapshot = _db->GetSnapshot();
	readOptions.options = options;

	RocksDBSnapshot *snapshot = [[RocksDBSnapshot alloc] initWithDBInstance:_db columnFamily:_columnFamily andReadOptions:readOptions];
	return snapshot;
}

#pragma mark - Compaction

- (BOOL)compactRange:(RocksDBKeyRange *)range
		 withOptions:(void (^)(RocksDBCompactRangeOptions *options))optionsBlock
			   error:(NSError * __autoreleasing *)error
{
	if (_closed.load()) {
		*error = [RocksDBError errorIsClosed];
		return NO;
	}
	RocksDBCompactRangeOptions *rangeOptions = [RocksDBCompactRangeOptions new];
	if (optionsBlock) {
		optionsBlock(rangeOptions);
	}

	rocksdb::Slice startSlice = SliceFromData(range.start);
	rocksdb::Slice endSlice = SliceFromData(range.end);

	rocksdb::Status status = _db->CompactRange(rangeOptions->options, _columnFamily, &startSlice, &endSlice);

	if (!status.ok()) {
		NSError *temp = [RocksDBError errorWithRocksStatus:status];
		if (error && *error == nil) {
			*error = temp;
		}
		return NO;
	}
	return YES;
}

@end
