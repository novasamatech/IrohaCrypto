//
//  SNKeypairFactory.h
//  IrohaCrypto
//
//  Created by Ruslan Rezin on 23.06.2020.
//

#import <Foundation/Foundation.h>
#import "SNKeypair.h"

typedef NS_ENUM(NSUInteger, SNKeyFactoryError) {
    SNKeyFactoryErrorInvalidSeed
};

@protocol SNKeyFactoryProtocol

- (id<SNKeypairProtocol> _Nullable)createKeypairFromSeed:(NSData* _Nonnull)seed
                                                   error:(NSError*_Nullable*_Nullable)error;

- (id<SNKeypairProtocol> _Nullable)createKeypairHard:(nonnull SNKeypair*)parent
                                           chaincode:(nonnull NSData*)chaincode
                                               error:(NSError*_Nullable*_Nullable)error;

- (id<SNKeypairProtocol> _Nullable)createKeypairSoft:(nonnull SNKeypair*)parent
                                           chaincode:(nonnull NSData*)chaincode
                                               error:(NSError*_Nullable*_Nullable)error;

- (nullable SNPublicKey*)createPublicKeySoft:(nonnull SNPublicKey*)publicKey
                                   chaincode:(nonnull NSData*)chaincode
                                       error:(NSError*_Nullable*_Nullable)error;

@end

@interface SNKeyFactory : NSObject<SNKeyFactoryProtocol>

@end
