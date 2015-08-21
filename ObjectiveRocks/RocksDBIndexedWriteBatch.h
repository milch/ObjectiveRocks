//
//  RocksDBIndexedWriteBatch.h
//  ObjectiveRocks
//
//  Created by Iska on 20/08/15.
//  Copyright (c) 2015 BrainCookie. All rights reserved.
//

#import "RocksDBWriteBatch.h"
#import "RocksDBWriteBatchIterator.h"

@class RocksDBColumnFamily;
@class RocksDBReadOptions;

@interface RocksDBIndexedWriteBatch : RocksDBWriteBatch

/**
 Returns the value for the given key in this Write Batch.

 @discussion This method will only read the key from this batch.

 @remark If the batch does not have enough data to resolve Merge operations,
 MergeInProgress status may be returned.

 @param aKey The key for object.
 @param columnFamily The column family from which the data should be read.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return The object for the given key.

 @see RocksDBColumnFamily
 */
- (id)objectForKey:(id)aKey
	inColumnFamily:(RocksDBColumnFamily *)columnFamily
			 error:(NSError **)error;

/**
 Returns the object for the given key.

 @discussion This function will query both this batch and the DB and then merge
 the results using the DB's merge operator (if the batch contains any
 merge requests).

 Setting the `RocksDBSnapshot` on the `RocksDBReadOptions` will affect what is read 
 from the DB but will not change which keys are read from the batch (the keys in
 this batch do not yet belong to any snapshot and will be fetched
 regardless).

 @param aKey The key for object.
 @param columnFamily The column family from which the data should be read.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @param readOptions A block with a `RocksDBReadOptions` instance for configuring this read operation.
 @return The object for the given key.

 @see RocksDBColumnFamily
 @see RocksDBReadOptions
 */
- (id)objectForKeyIncludingDatabase:(id)aKey
					 inColumnFamily:(RocksDBColumnFamily *)columnFamily
							  error:(NSError **)error
						readOptions:(void (^)(RocksDBReadOptions *readOptions))readOptions;

/**
 Creates and returns an iterator over this indexed write batch.

 @discussion Keys will be iterated in the order given by the write batch's
 comparator. For multiple updates on the same key, each update will be 
 returned as a separate entry, in the order of update time.

 @return An iterator over this indexed write batch.

 @see RocksDBWriteBatchIterator
 */
- (RocksDBWriteBatchIterator *)iterator;

@end
