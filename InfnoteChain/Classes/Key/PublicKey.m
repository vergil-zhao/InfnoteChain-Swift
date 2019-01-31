//
//  PublicKey.m
//  InfnoteChain
//
//  Created by Vergil Choi on 2019/1/11.
//

#import "PublicKey.h"
#import "PrivateKey.h"
#import <secp256k1.h>
#import <secp256k1_recovery.h>

@interface PublicKey()

@property (nonatomic, assign) secp256k1_context *context;
@property (nonatomic, assign) unsigned int *cBytes;

@end


@implementation PublicKey

- (instancetype)init {
    if (self = [super init]) {
        _context = secp256k1_context_create(SECP256K1_CONTEXT_VERIFY);
        return self;
    }
    return nil;
}

- (instancetype)initWithBytes:(const unsigned int *)bytes {
    self = [self init];
    _cBytes = malloc(PUB_KEY_LEN);
    memcpy(_cBytes, bytes, PUB_KEY_LEN);
    _data = [[NSData alloc] initWithBytes:_cBytes length:PUB_KEY_LEN];
    return self;
}

- (instancetype)initWithData:(NSData *)data {
    self = [self init];
    _data = [data copy];
    _cBytes = data.bytes;
    return self;
}

- (instancetype)initWithRecoverableSignature:(NSData *)data message:(NSData *)message {
    self = [self init];
//    secp256k1_pubkey *pubkey = malloc(sizeof(secp256k1_pubkey));
//    secp256k1_ecdsa_recoverable_signature *sig = malloc(sizeof(secp256k1_ecdsa_recoverable_signature));
//    secp256k1_ecdsa_recoverable_signature_parse_compact(_context, sig, data.bytes, 0);
//    if (secp256k1_ecdsa_recover(_context, pubkey, sig, message.bytes) == 1) {
//        _cBytes = malloc(PUB_KEY_LEN);
//        size_t len = PUB_KEY_LEN;
//        secp256k1_ec_pubkey_serialize(_context, _cBytes, &len, pubkey, SECP256K1_EC_COMPRESSED);
//        _data = [[NSData alloc] initWithBytes:_cBytes length:len];
//        return self;
//    }
    return nil;
}

@end
