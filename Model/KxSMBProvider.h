//
//  KxSambaProvider.h
//  kxsmb project
//  https://github.com/kolyvan/kxsmb/
//
//  Created by Kolyvan on 28.03.13.
//

/*
 Copyright (c) 2013 Konstantin Bukreev All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Foundation/Foundation.h>

extern NSString * const _Nonnull KxSMBErrorDomain;

typedef enum {
    
    KxSMBErrorUnknown,
    KxSMBErrorInvalidArg,
    KxSMBErrorInvalidProtocol,
    KxSMBErrorOutOfMemory,
    KxSMBErrorAccessDenied,
    KxSMBErrorInvalidPath,
    KxSMBErrorPathIsNotDir,
    KxSMBErrorPathIsDir,
    KxSMBErrorWorkgroupNotFound,
    KxSMBErrorShareDoesNotExist,
    KxSMBErrorItemAlreadyExists,
    KxSMBErrorDirNotEmpty,
    KxSMBErrorFileIO,
    KxSMBErrorConnRefused,
    KxSMBErrorOpNotPermited,

} KxSMBError;

typedef enum {
    
    KxSMBItemTypeUnknown,
    KxSMBItemTypeWorkgroup,
    KxSMBItemTypeServer,
    KxSMBItemTypeFileShare,
    KxSMBItemTypePrinter,
    KxSMBItemTypeComms,
    KxSMBItemTypeIPC,
    KxSMBItemTypeDir,
    KxSMBItemTypeFile,
    KxSMBItemTypeLink,    
    
} KxSMBItemType;

@class KxSMBItem;
@class KxSMBAuth;

typedef void (^KxSMBBlock)(id _Nullable result);
typedef void (^KxSMBBlockProgress)(KxSMBItem * _Nonnull item, long transferred, BOOL * _Nonnull stop);

@interface KxSMBItemStat : NSObject
@property(readonly, nonatomic, retain, nonnull) NSDate *lastModified;
@property(readonly, nonatomic, retain, nonnull) NSDate *lastAccess;
@property(readonly, nonatomic, retain, nonnull) NSDate *creationTime;
@property(readonly, nonatomic) SInt64 size;
@property(readonly, nonatomic) UInt16 mode;
@end

@interface KxSMBItem : NSObject
@property(readonly, nonatomic) KxSMBItemType type;
@property(readonly, nonatomic, retain, nonnull) NSString *path;
@property(readonly, nonatomic, retain, nonnull) KxSMBItemStat *stat;
@property(readonly, nonatomic, retain, nullable) KxSMBAuth *auth;
@end

@class KxSMBItemFile;

@interface KxSMBItemTree : KxSMBItem

- (void) fetchItems:(nullable KxSMBBlock)block;

- (nullable id) fetchItems;

- (void) createFileWithName:(nonnull NSString *)name
                  overwrite:(BOOL)overwrite
                      block:(nonnull KxSMBBlock)block;

- (nullable id) createFileWithName:(nonnull NSString *)name
                         overwrite:(BOOL)overwrite;

- (void) removeWithName:(nonnull NSString *)name
                  block:(nonnull KxSMBBlock)block;

- (nullable id) removeWithName:(nonnull NSString *)name;

@end

@interface KxSMBItemFile : KxSMBItem

- (void) close;

- (void)readDataOfLength:(NSUInteger)length
                   block:(nonnull KxSMBBlock)block;

- (nullable id)readDataOfLength:(NSUInteger)length;

- (void)readDataToEndOfFile:(nonnull KxSMBBlock)block;

- (nullable id)readDataToEndOfFile;

- (void)seekToFileOffset:(off_t)offset
                  whence:(NSInteger)whence
                   block:(nonnull KxSMBBlock)block;

- (nullable id)seekToFileOffset:(off_t)offset
                         whence:(NSInteger)whence;

- (void)writeData:(nonnull NSData *)data
            block:(nonnull KxSMBBlock)block;

- (nullable id)writeData:(nonnull NSData *)data;

@end

@interface KxSMBAuth : NSObject
@property (readwrite, nonatomic, retain, nullable) NSString *workgroup;
@property (readwrite, nonatomic, retain, nullable) NSString *username;
@property (readwrite, nonatomic, retain, nullable) NSString *password;

+ (nullable instancetype) smbAuthWorkgroup:(nullable NSString *)workgroup
                                  username:(nullable NSString *)username
                                  password:(nullable NSString *)password;

@end

@protocol KxSMBProviderDelegate <NSObject>

- (nullable KxSMBAuth *) smbRequestAuthServer:(nonnull NSString *)server
                                        share:(nonnull NSString *)share
                                    workgroup:(nonnull NSString *)workgroup
                                     username:(nonnull NSString *)username;
@end

// smbc_share_mode
typedef NS_ENUM(NSUInteger, KxSMBConfigShareMode) {
    
    KxSMBConfigShareModeDenyDOS     = 0,
    KxSMBConfigShareModeDenyAll     = 1,
    KxSMBConfigShareModeDenyWrite   = 2,
    KxSMBConfigShareModeDenyRead    = 3,
    KxSMBConfigShareModeDenyNone    = 4,
    KxSMBConfigShareModeDenyFCB     = 7,
};

// smbc_smb_encrypt_level
typedef NS_ENUM(NSUInteger, KxSMBConfigEncryptLevel) {
    
    KxSMBConfigEncryptLevelNone      = 0,
    KxSMBConfigEncryptLevelRequest   = 1,
    KxSMBConfigEncryptLevelRequire   = 2,
};

@interface KxSMBConfig : NSObject
@property (readwrite, nonatomic) NSUInteger timeout;
@property (readwrite, nonatomic) NSUInteger debugLevel;
@property (readwrite, nonatomic) BOOL debugToStderr;
@property (readwrite, nonatomic) BOOL fullTimeNames;
@property (readwrite, nonatomic) KxSMBConfigShareMode shareMode;
@property (readwrite, nonatomic) KxSMBConfigEncryptLevel encryptionLevel;
@property (readwrite, nonatomic) BOOL caseSensitive;
@property (readwrite, nonatomic) NSUInteger browseMaxLmbCount;
@property (readwrite, nonatomic) BOOL urlEncodeReaddirEntries;
@property (readwrite, nonatomic) BOOL oneSharePerServer;
@property (readwrite, nonatomic) BOOL useKerberos;
@property (readwrite, nonatomic) BOOL fallbackAfterKerberos;
@property (readwrite, nonatomic) BOOL noAutoAnonymousLogin;
@property (readwrite, nonatomic) BOOL useCCache;
@property (readwrite, nonatomic) BOOL useNTHash;
@property (readwrite, nonatomic, retain, nullable) NSString *netbiosName;
@property (readwrite, nonatomic, retain, nullable) NSString *workgroup;
@property (readwrite, nonatomic, retain, nullable) NSString *username;
@end

@interface KxSMBProvider : NSObject

@property (readwrite, nonatomic, weak, nullable) id<KxSMBProviderDelegate> delegate;
@property (readwrite, nonatomic, retain, nonnull) KxSMBConfig *config;
@property (readwrite, nonatomic, retain, nullable) dispatch_queue_t completionQueue;

+ (nullable instancetype) sharedSmbProvider;

- (void) fetchAtPath:(nonnull NSString *)path
                auth:(nullable KxSMBAuth *)auth
               block:(nonnull KxSMBBlock)block;

- (void) fetchAtPath:(nonnull NSString *)path
           expandDir:(BOOL)expandDir
                auth:(nullable KxSMBAuth *)auth
               block:(nonnull KxSMBBlock)block;

- (nullable id) fetchAtPath:(nonnull NSString *)path
                       auth:(nullable KxSMBAuth *)auth;

- (nullable id) fetchAtPath:(nonnull NSString *)path
                  expandDir:(BOOL)expandDir
                       auth:(nullable KxSMBAuth *)auth;

- (void) createFileAtPath:(nonnull NSString *)path
                overwrite:(BOOL)overwrite
                     auth:(nullable KxSMBAuth *)auth
                    block:(nonnull KxSMBBlock)block;

- (nullable id) createFileAtPath:(nonnull NSString *)path
                       overwrite:(BOOL)overwrite
                            auth:(nullable KxSMBAuth *)auth;

- (void) createFolderAtPath:(nonnull NSString *)path
                       auth:(nullable KxSMBAuth *)auth
                      block:(nonnull KxSMBBlock)block;

- (nullable id) createFolderAtPath:(nonnull NSString *)path
                              auth:(nullable KxSMBAuth *)auth;

- (void) removeAtPath:(nonnull NSString *)path
                 auth:(nullable KxSMBAuth *)auth
                block:(nonnull KxSMBBlock)block;

- (nullable id) removeAtPath:(nonnull NSString *)path
                        auth:(nullable KxSMBAuth *)auth;

- (void) copySMBPath:(nonnull NSString *)smbPath
           localPath:(nonnull NSString *)localPath
           overwrite:(BOOL)overwrite
                auth:(nullable KxSMBAuth *)auth
               block:(nonnull KxSMBBlock)block;

- (void) copyLocalPath:(nonnull NSString *)localPath
               smbPath:(nonnull NSString *)smbPath
             overwrite:(BOOL)overwrite
                  auth:(nullable KxSMBAuth *)auth
                 block:(nonnull KxSMBBlock)block;

- (void) copySMBPath:(nonnull NSString *)smbPath
           localPath:(nonnull NSString *)localPath
           overwrite:(BOOL)overwrite
                auth:(nullable KxSMBAuth *)auth
            progress:(nullable KxSMBBlockProgress)progress
               block:(nonnull KxSMBBlock)block;

- (void) copyLocalPath:(nonnull NSString *)localPath
               smbPath:(nonnull NSString *)smbPath
             overwrite:(BOOL)overwrite
                  auth:(nullable KxSMBAuth *)auth
              progress:(nullable KxSMBBlockProgress)progress
                 block:(nonnull KxSMBBlock)block;

- (void) copyFromPath:(nonnull NSString *)oldPath
               toPath:(nonnull NSString *)newPath
            overwrite:(BOOL)overwrite
                 auth:(nullable KxSMBAuth *)auth
             progress:(nullable KxSMBBlockProgress)progress
                block:(nonnull KxSMBBlock)block;

- (void) removeFolderAtPath:(nonnull NSString *)path
                       auth:(nullable KxSMBAuth *)auth
                      block:(nonnull KxSMBBlock)block;

- (void) renameAtPath:(nonnull NSString *)oldPath
              newPath:(nonnull NSString *)newPath
                 auth:(nullable KxSMBAuth *)auth
                block:(nonnull KxSMBBlock)block;

// without auth (compatible)

- (void) fetchAtPath:(nonnull NSString *)path
               block:(nullable KxSMBBlock)block;

- (nullable id) fetchAtPath:(nonnull NSString *)path;

- (void) createFileAtPath:(nonnull NSString *)path
                overwrite:(BOOL)overwrite
                    block:(nonnull KxSMBBlock)block;

- (nullable id) createFileAtPath:(nonnull NSString *)path
                       overwrite:(BOOL)overwrite;

- (void) createFolderAtPath:(nonnull NSString *)path
                      block:(nonnull KxSMBBlock)block;

- (nullable id) createFolderAtPath:(nonnull NSString *)path;

- (void) removeAtPath:(nonnull NSString *)path
                block:(nonnull KxSMBBlock)block;

- (nullable id) removeAtPath:(nonnull NSString *)path;

- (void) copySMBPath:(nonnull NSString *)smbPath
           localPath:(nonnull NSString *)localPath
           overwrite:(BOOL)overwrite
               block:(nonnull KxSMBBlock)block;

- (void) copyLocalPath:(nonnull NSString *)localPath
               smbPath:(nonnull NSString *)smbPath
             overwrite:(BOOL)overwrite
                 block:(nonnull KxSMBBlock)block;

- (void) copySMBPath:(nonnull NSString *)smbPath
           localPath:(nonnull NSString *)localPath
           overwrite:(BOOL)overwrite
            progress:(nullable KxSMBBlockProgress)progress
               block:(nonnull KxSMBBlock)block;

- (void) copyLocalPath:(nonnull NSString *)localPath
               smbPath:(nonnull NSString *)smbPath
             overwrite:(BOOL)overwrite
              progress:(nullable KxSMBBlockProgress)progress
                 block:(nonnull KxSMBBlock)block;

- (void) removeFolderAtPath:(nonnull NSString *)path
                      block:(nonnull KxSMBBlock)block;

- (void) renameAtPath:(nonnull NSString *)oldPath
              newPath:(nonnull NSString *)newPath
                block:(nonnull KxSMBBlock)block;

@end

@interface NSString (KxSMB)

- (nonnull NSString *) stringByAppendingSMBPathComponent:(nonnull NSString *)aString;

@end
