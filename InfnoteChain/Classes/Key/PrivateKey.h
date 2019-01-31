//
//  PrivateKey.h
//  InfnoteChain
//
//  Created by Vergil Choi on 2019/1/10.
//

#import <Foundation/Foundation.h>

#define PUB_KEY_LEN 33
#define PRIV_KEY_LEN 32
#define SIG_COMPACT_LEN 64

NS_ASSUME_NONNULL_BEGIN

@class PublicKey;

@interface PrivateKey : NSObject

@property (nonatomic, copy, readonly) NSData *data;

- (instancetype)init;
- (PublicKey *)publicKey;
- (NSData *)sign:(NSData*)data;
- (NSString *)WIFString;

@end

NS_ASSUME_NONNULL_END
