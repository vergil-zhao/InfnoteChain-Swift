//
//  PublicKey.h
//  InfnoteChain
//
//  Created by Vergil Choi on 2019/1/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PublicKey : NSObject

@property (nonatomic, copy, readonly) NSData *data;

- (instancetype)initWithBytes:(const unsigned int *)bytes;
- (instancetype)initWithData:(NSData *)data;
- (instancetype)initWithRecoverableSignature:(NSData *)data message:(NSData *)message;
- (BOOL)verifyWithData:(NSData *)data signature:(NSData *)data;
- (NSString *)address;

@end

NS_ASSUME_NONNULL_END
