//
//  PrivateKey.m
//  InfnoteChain
//
//  Created by Vergil Choi on 2019/1/10.
//

#import "PrivateKey.h"
#import "PublicKey.h"
#import <secp256k1.h>
#import <secp256k1_recovery.h>
#import <openssl/sha.h>
#import <openssl/ripemd.h>

@interface PrivateKey()

@property (nonatomic, assign) secp256k1_context *context;
@property (nonatomic, assign) unsigned int *cBytes;

@end

@implementation PrivateKey

- (instancetype)init {
    if (self = [super init]) {
        _context = secp256k1_context_create(SECP256K1_CONTEXT_SIGN);
        
        _cBytes = (unsigned int []){
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0
        };
        if (SecRandomCopyBytes(kSecRandomDefault, PRIV_KEY_LEN, _cBytes) != errSecSuccess ||
            [self check32:_cBytes] == NO) {
            return nil;
        }
        
        _data = [[NSData alloc] initWithBytes:_cBytes length:32];
        
        return self;
    }
    return nil;
}

- (PublicKey *)publicKey {
    size_t len = PUB_KEY_LEN;
    secp256k1_pubkey *pubkey = malloc(sizeof(secp256k1_pubkey));
    unsigned char *output = malloc(len);
    if (secp256k1_ec_pubkey_create(_context, pubkey, (const unsigned char *)_cBytes) == 1) {
        secp256k1_ec_pubkey_serialize(_context, output, &len, pubkey, SECP256K1_EC_COMPRESSED);
        return [[PublicKey alloc] initWithBytes:output];
    }
    return nil;
}

- (NSData *)sign:(NSData *)data {
//    secp256k1_ecdsa_recoverable_signature *sig = malloc(sizeof(secp256k1_ecdsa_recoverable_signature));
//    if (secp256k1_ecdsa_sign(_context, sig, data.bytes, _cBytes, NULL, NULL) == 1) {
//        unsigned char *output = malloc(SIG_COMPACT_LEN);
//        secp256k1_ecdsa_recoverable_signature_serialize_compact(_context, output, NULL, sig);
//        return [[NSData alloc] initWithBytes:output length:SIG_COMPACT_LEN];
//    }
    return nil;
}

- (NSString *)toWIF {
    
}

- (BOOL)check32:(const unsigned int[])data {
    char max[] = {
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE,
        0xBA, 0xAE, 0xDC, 0xE6, 0xAF, 0x48, 0xA0, 0x3B,
        0xBF, 0xD2, 0x5E, 0x8C, 0xD0, 0x36, 0x41, 0x40
    };
    
    BOOL fIsZero = YES;
    for (int i = 0; i < PRIV_KEY_LEN; i++) {
        if (data[i] != 0) {
            fIsZero = NO;
            break;
        }
    }
    
    if (fIsZero) {
        return NO;
    }
    
    for (int i = 0; i < PRIV_KEY_LEN; i++) {
        if (data[i] < max[i]) {
            return YES;
        }
        if (data[i] > max[i]) {
            return NO;
        }
    }
    
    return YES;
}

@end
