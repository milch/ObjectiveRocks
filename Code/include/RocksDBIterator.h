//
//  RocksDBIterator.h
//  ObjectiveRocks
//
//  Created by Iska on 03/12/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RocksDBRange.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An iterator over the sorted DB keys. Supports iteration in the natural sort order, the reverse order, and prefix seek.
 */
@interface RocksDBIterator : NSObject

/** @brief Closes this Iterator */
- (void)close;

/**
 An iterator is either positioned at a key/value pair, or not valid.
 
 @return `YES` if the iterator is valid, `NO` otherwise.
 */
- (BOOL)isValid;

/** 
 Positions the iterator at the first key in the source.
 The iterator `isValid` after this call if the source is not empty.
 */
- (void)seekToFirst;

/**
 Positions the iterator at the last key in the source.
 The iterator `isValid` after this call if the source is not empty.
 */
- (void)seekToLast;

/** 
 Positions the iterator at the first key in the source that at or past the given key.
 The iterator `isValid` after this call if the source contains an entry that comes at
 or past the given key.

 @param aKey The key to position the iterator at.
 */
- (void)seekToKey:(NSData *)aKey;

/**
 Positions the iterator at the last key in the source at or before the given key.
 The iterator `isValid` after this call if the source contains an entry that comes at
 or past the given key.

 @param aKey The key to position the iterator at.
 */
- (void)seekForPrev:(NSData *)aKey;

/** 
 Moves to the next entry in the source. After this call, `isValid` is
 true if the iterator was not positioned at the last entry in the source.
 */
- (void)next;

/** 
 Moves to the previous entry in the source.  After this call, `isValid` is
 true iff the iterator was not positioned at the first entry in source.
 */
- (void)previous;

/** 
 Returns the key for the current entry. The underlying storage for the returned 
 value is valid only until the next modification of the iterator.

 @return The key at the current position.
 */
- (NSData *)key;

/** 
 Returns the value for the current entry. The underlying storage for the returned 
 value is valid only until the next modification of the iterator.

 @return The value for the key at the current position.
 */
- (NSData *)value;

/**
 If an error has occurred, throw it.  Else just continue
 If non-blocking IO is requested and this operation cannot be
 satisfied without doing some IO, then this throws Error with Status::Incomplete.

 @param error RocksDBError  if error happens in underlying native library.
 */
- (void)status:(NSError * __autoreleasing *)error;

/**
 Executes a given block for each key in the iterator.

 @param block The block to apply to elements.
 */
- (void)enumerateKeysUsingBlock:(void (^)(NSData *key, BOOL *stop))block;

/**
 Executes a given block for each key in the iterator in reverse order.

 @param reverse BOOL indicating whether to enumerate in the reverse order.
 @param block The block to apply to elements.
 */
- (void)enumerateKeysInReverse:(BOOL)reverse
					usingBlock:(void (^)(NSData *key, BOOL *stop))block;

/**
 Executes a given block for each key in the iterator in the given key range.

 @param range The key range.
 @param reverse BOOL indicating whether to enumerate in the reverse order.
 @param block The block to apply to elements.

 @see RocksDBIteratorKeyRange
 */
- (void)enumerateKeysInRange:(RocksDBKeyRange *)range
					 reverse:(BOOL)reverse
				  usingBlock:(void (^)(NSData *key, BOOL *stop))block;

/**
 Executes a given block for each key-value pair in the iterator.

 @param block The block to apply to elements.
 */
- (void)enumerateKeysAndValuesUsingBlock:(void (^)(NSData *key, NSData *value, BOOL *stop))block;

/**
 Executes a given block for each key-value pair in the iterator in reverse order.

 @param reverse BOOL indicating whether to enumerate in the reverse order.
 @param block The block to apply to elements.
 */
- (void)enumerateKeysAndValuesInReverse:(BOOL)reverse
							 usingBlock:(void (^)(NSData *key, NSData *value, BOOL *stop))block;

/**
 Executes a given block for each key-value pair in the iterator in the given key range.

 @param range The key range.
 @parame reverse BOOL indicating whether to enumerate in the reverse order.
 @param block The block to apply to elements.
 */
- (void)enumerateKeysAndValuesInRange:(RocksDBKeyRange *)range
							  reverse:(BOOL)reverse
						   usingBlock:(void (^)(NSData *key, NSData *value, BOOL *stop))block;

/**
 Executes a given block for each key with the given prefix in the iterator.

 @param block The block to apply to elements.
 */
- (void)enumerateKeysWithPrefix:(NSData *)prefix
					 usingBlock:(void (^)(NSData *key, BOOL *stop))block;

/**
 Executes a given block for each key-value pair with the given prefix in the iterator.

 @param block The block to apply to elements.
 */
- (void)enumerateKeysAndValuesWithPrefix:(NSData *)prefix
							  usingBlock:(void (^)(NSData *key, NSData *value, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
