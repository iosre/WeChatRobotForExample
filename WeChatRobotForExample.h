#import <substrate.h>

@class CMessageMgr;
@class WeixinContentLogicController;

extern NSOperationQueue *globalQueue;
extern CMessageMgr *globalMessageMgr;
extern WeixinContentLogicController *logicController;

@interface CAppViewControllerManager : NSObject
+ (instancetype)getAppViewControllerManager;
- (void)createContactsViewController;
- (id)getTabBarController;
@end

@interface MMTabBarController : UITabBarController
- (void)setSelectedIndex:(unsigned)index;
@end

@interface WCPayInfoItem : NSObject
@property (retain, nonatomic) NSString *m_c2cIconUrl;
@property (retain, nonatomic) NSString *m_c2cNativeUrl;
@property (retain, nonatomic) NSString *m_c2cUrl;
@property (nonatomic) NSUInteger m_c2c_msg_subtype;
@property (retain, nonatomic) NSString *m_fee_type;
@property (retain, nonatomic) NSString *m_hintText;
@property (retain, nonatomic) NSString *m_nsFeeDesc;
@property (retain, nonatomic) NSString *m_nsTranscationID;
@property (retain, nonatomic) NSString *m_nsTransferID;
@property (retain, nonatomic) NSString *m_receiverDesc;
@property (retain, nonatomic) NSString *m_receiverTitle;
@property (retain, nonatomic) NSString *m_sceneText;
@property (retain, nonatomic) NSString *m_senderDesc;
@property (retain, nonatomic) NSString *m_senderTitle;
@property (nonatomic) NSUInteger m_templateID;
@property (retain, nonatomic) NSString *m_total_fee;
@property (nonatomic) NSUInteger m_uiBeginTransferTime;
@property (nonatomic) NSUInteger m_uiEffectiveDate;
@property (nonatomic) NSUInteger m_uiInvalidTime;
@property (nonatomic) NSUInteger m_uiPaySubType;
@end

@interface CMessageWrap : NSObject // 微信消息
@property (retain, nonatomic) NSData *m_dtVoice;
@property (assign, nonatomic) NSUInteger m_uiMesLocalID;
@property (retain, nonatomic) NSString* m_nsFromUsr; // 发信人，可能是群或个人
@property (retain, nonatomic) NSString* m_nsToUsr; // 收信人
@property (assign, nonatomic) NSUInteger m_uiStatus;
@property (retain, nonatomic) NSString* m_nsContent; // 消息内容
@property (retain, nonatomic) NSString* m_nsRealChatUsr; // 群消息的发信人，具体是群里的哪个人
@property (nonatomic) NSUInteger m_uiMessageType;
@property (nonatomic) long long m_n64MesSvrID;
@property (nonatomic) NSUInteger m_uiCreateTime;
@property (retain, nonatomic) NSString *m_nsDesc;
@property (retain, nonatomic) NSString *m_nsAppExtInfo;
@property (nonatomic) NSUInteger m_uiAppDataSize;
@property (nonatomic) NSUInteger m_uiAppMsgInnerType;
@property (retain, nonatomic) NSString *m_nsShareOpenUrl;
@property (retain, nonatomic) NSString *m_nsShareOriginUrl;
@property (retain, nonatomic) NSString *m_nsJsAppId;
@property (retain, nonatomic) NSString *m_nsPrePublishId;
@property (retain, nonatomic) NSString *m_nsAppID;
@property (retain, nonatomic) NSString *m_nsAppName;
@property (retain, nonatomic) NSString *m_nsThumbUrl;
@property (retain, nonatomic) NSString *m_nsAppMediaUrl;
@property (retain, nonatomic) NSData *m_dtThumbnail;
@property (retain, nonatomic) NSString *m_nsTitle;
@property (retain, nonatomic) NSString *m_nsMsgSource;
@property (retain, nonatomic) NSString *m_nsMsgAttachUrl;
@property (retain, nonatomic) WCPayInfoItem *m_oWCPayInfoItem;
- (instancetype)initWithMsgType:(int)msgType;
+ (UIImage *)getMsgImg:(CMessageWrap *)arg1;
+ (NSData *)getMsgImgData:(CMessageWrap *)arg1;
+ (NSString *)getPathOfMsgImg:(CMessageWrap *)arg1;
- (UIImage *)GetImg;
- (BOOL)IsImgMsg;
- (BOOL)IsAtMe;
+ (void)GetPathOfAppThumb:(NSString *)senderID LocalID:(NSUInteger)mesLocalID retStrPath:(NSString **)pathBuffer;
+ (void)GetPathOfAppDataByUserName:(NSString *)senderID andMessageWrap:(CMessageWrap *)arg2 retStrPath:(NSString **)arg3;
+ (UIImage *)createMaskedThumbImageForMessageWrap:(CMessageWrap *)arg1;
@end

@interface CMessageMgr : NSObject // 这几个方法执行完可能需要若干秒时间；与后端的通信在其内部实现，在这些方法执行完成前，信息可能就已经发送成功，本地回调方法得到调用了，需要特别留意！
- (void)AddMsg:(NSString *)msg MsgWrap:(CMessageWrap *)wrap; // 发文字和图片（和其他各种消息），参数1是收件人ID，参数2是要发的信息
- (void)AddEmoticonMsg:(NSString *)arg1 MsgWrap:(CMessageWrap *)arg2; // 发表情
- (void)AddAppMsg:(NSString *)arg1 MsgWrap:(CMessageWrap *)arg2 Data:(NSData *)arg3 Scene:(NSUInteger)arg4; // 发链接
- (void)ResendMsg:(NSString *)arg1 MsgWrap:(CMessageWrap *)arg2;
- (void)DelMsg:(NSString *)userID MsgList:(NSArray *)wraps DelAll:(BOOL)arg3;
- (void)StartDownloadAppAttach:(NSString *)arg1 MsgWrap:(CMessageWrap *)arg2;
- (BOOL)StartDownloadThumb:(CMessageWrap *)arg1;
- (NSUInteger)GetDownloadThumbStatus:(CMessageWrap *)arg1;
- (CMessageWrap *)GetLastMsgFromUsr:(NSString *)arg1;
@end

@interface ContactsViewController : UIViewController
- (void)onAddContact;
@end

@interface CBaseContact : NSObject
@property (assign, nonatomic) NSUInteger m_uiSex; // 1 for male
@property (retain, nonatomic) NSString *m_nsRemark; // nickname
@property (retain, nonatomic) NSString* m_nsNickName;
@property (retain, nonatomic) NSString* m_nsUsrName; // wechat ID
@property (retain, nonatomic) NSString *m_nsEncodeUserName;
@property (nonatomic) NSUInteger m_uiFriendScene;
@property (nonatomic) NSUInteger m_uiType; // 3 for stock contact, 7 for others
@end

@interface CContact : CBaseContact
@property (nonatomic) int m_iWCFlag;
@property (retain, nonatomic) NSString *m_nsCity;
@property (retain, nonatomic) NSString *m_nsCountry;
@property (retain, nonatomic) NSString *m_nsProvince;
@property (retain, nonatomic) NSString *m_nsSignature;
- (NSString *)getChatRoomMemberDisplayName:(CContact *)arg1; // caller is group contact, arg1 is member contact, 返回我们看到的名称
- (NSString *)getChatRoomMemberNickName:(CContact *)arg1; // 返回该用户自己的昵称
- (NSString *)getChatRoomMembrGroupNickName:(CContact *)arg1; // 返回用户在群里设置的昵称
@end

@interface FindContactSearchViewCellInfo : NSObject
@property (retain, nonatomic) CContact *foundContact;
- (void)doSearch;
- (void)stopLoading;
@end

@interface MMUISearchBar : UISearchBar
@end

@interface MMSearchBar : NSObject
@property (retain, nonatomic) MMUISearchBar *m_searchBar;
@end

@interface CBaseContactInfoAssist : NSObject
- (void)onAddToContacts;
@end

@interface ContactInfoViewController : UIViewController
- (BOOL)isInMyContactList;
@end

@interface SendVerifyMsgViewController : UIViewController
- (void)onSendVerifyMsg;
@end

@interface CContactMgr : NSObject 
- (CContact *)getContactByName:(NSString *)m_nsUsrName;
- (CContact *)getSelfContact;
- (BOOL)setContact:(CContact *)arg1 remark:(NSString *)arg2 hideHashPhone:(BOOL)arg3;
- (BOOL)deleteContact:(CContact *)arg1 listType:(NSUInteger)arg2; // arg2传3
- (BOOL)isInContactList:(NSString *)userID;
- (NSArray *)getContactList:(NSUInteger)arg1 contactType:(NSUInteger)arg2 domain:(id)arg3; // 1, 0, nil
@end

@interface MMServiceCenter : NSObject
+ (instancetype)defaultCenter;
- (id)getService:(Class)service;
@end

@interface WebViewA8KeyLogicImpl : NSObject
- (void)getA8Key:(NSString *)arg1 Reason:(int)arg2;
@end

@interface PBGeneratedMessage : NSObject // iOS 6
@end

@interface WXPBGeneratedMessage : NSObject
- (NSData *)serializedData;
@end

@interface GetA8KeyResp : WXPBGeneratedMessage
@property (retain, nonatomic) NSString *fullUrl;
@end

@interface ProtobufCGIWrap : NSObject
@property (retain, nonatomic) WXPBGeneratedMessage *m_pbResponse;
@property (retain, nonatomic) WXPBGeneratedMessage *m_pbRequest;
@end

@interface CPushContact : CContact
@property (retain, nonatomic) NSString *m_nsNickName;
@end

@interface SayHelloDataLogic : NSObject
+ (CPushContact *)getContactFrom:(CMessageWrap *)arg1;
@end

@interface SayHelloViewController : NSObject
- (void)initData;
- (void)verifyContactWithOpCode:(CPushContact *)arg1 opcode:(NSUInteger)arg2;
@end

@interface BaseMsgContentLogicController : NSObject
- (void)PreviewImage:(CMessageWrap *)arg1;
@end

@interface ViewAppMsgController : NSObject
- (void)PreviewImage:(CMessageWrap *)arg1;
@end

@interface BaseMsgContentViewController : NSObject
- (void)PreviewImage:(CMessageWrap *)arg1;
@end

@interface WeixinContentLogicController : BaseMsgContentLogicController
- (CMessageWrap *)FormImageMsg:(NSString *)receiverID withImage:(UIImage *)arg2;
- (CMessageWrap *)FormTextMsg:(NSString *)receiverID withText:(NSString *)arg2;
@end

@interface CGroupMgr : NSObject
- (BOOL)InviteGroupMember:(NSString *)groupID withMemberList:(NSArray *)userIDs;
- (BOOL)IsUsrInChatRoom:(NSString *)groupID Usr:(NSString *)userID;
- (NSArray *)GetGroupMember:(NSString *)groupID;
- (BOOL)SetDislayName:(NSString *)displayName forGroup:(NSString *)groupID;
- (BOOL)QuitGroup:(NSString *)groupID withUsrName:(NSString *)myUserID;
@end

@interface CSettingExt : NSObject
- (void)theadSafeSetObject:(NSString *)arg1 forKey:(NSString *)arg2;
@end

@interface SettingUtil : NSObject
+ (NSString *)getLocalUsrName:(NSUInteger)arg1;
+ (CSettingExt *)getMainSettingExt;
@end

@interface CUtility : NSObject
+ (NSUInteger)genCurrentTime;
+ (NSString *)GetPathOfMesAudio:(NSString *)arg1 LocalID:(NSUInteger)arg2 DocPath:(NSString *)arg3;
+ (NSString *)GetDocPath;
@end

@interface DelaySwitchSettingLogic : NSObject
- (void)chatProfileSwitchSetting:(NSString *)groupID withType:(int)arg2 andValue:(BOOL)arg3;
- (void)commitAllSwitchSetting;
@end

@interface SendAppMsgResponse : WXPBGeneratedMessage
@property (nonatomic) unsigned int type;
@end

@interface CDNUploadMsgImgPrepareResponse : WXPBGeneratedMessage
@end

@interface GetQRCodeResponse : PBGeneratedMessage
@end

@interface ForwardMsgUtil : NSObject
+ (void)ForwardMsg:(CMessageWrap *)arg1 ToContact:(CContact *)arg2 NeedSrcInfo:(BOOL)arg3;
+ (CMessageWrap *)GenForwardMsgFromMsgWrap:(CMessageWrap *)arg1 ToContact:(CContact *)arg2 NeedSrcInfo:(BOOL)arg3;
+ (CMessageWrap *)appMsgFromMsgWrap:(CMessageWrap *)arg1;
@end

@interface MMSessionInfo
@property (retain, nonatomic) NSString *m_nsUserName;
@end

@interface MMNewSessionMgr : NSObject
{
	NSMutableArray *m_arrSession;
}
- (void)DeleteAllSession;
- (void)ChangeSessionUnReadCount:(NSString *)userID to:(unsigned int)count;
- (void)DeleteSessionOfUser:(NSString *)userID;
@end

@interface ModSingleField : WXPBGeneratedMessage
@property (nonatomic) unsigned int opType; // 1是改自己的昵称
@property (retain, nonatomic) NSString *value;
@end

@interface ModChatRoomMemberDisplayName : WXPBGeneratedMessage
@property (retain, nonatomic) NSString *chatRoomName;
@property (retain, nonatomic) NSString *displayName;
@property (retain, nonatomic) NSString *userName;
@end

@interface NewSyncService : NSObject
- (NSUInteger)StartOplog:(NSUInteger)arg1 Oplog:(NSData *)arg2;
@end

@interface CUsrInfo : NSObject
@property (retain, nonatomic) NSString *m_nsCity;
@property (retain, nonatomic) NSString *m_nsCountry;
@property (retain, nonatomic) NSString *m_nsNickName;
@property (retain, nonatomic) NSString *m_nsProvince;
@property (retain, nonatomic) NSString *m_nsSignature;
@property (nonatomic) NSUInteger m_uiSex;
@end

@interface UpdateProfileMgr : NSObject // for WeChat on iOS 6
+ (BOOL)modifyUserInfo:(CUsrInfo *)arg1;
@end

@interface BaseMessageNodeView : NSObject
- (CMessageWrap *)m_msgWrap;
@end

@interface OpenApiMgrHelper : NSObject
+ (NSData *)checkAppMsgThumbData:(NSData *)arg1;
@end

@interface CAppUtil : NSObject
+ (NSString *)getCurrentLanguageAppName:(NSString *)arg1;
@end

@interface SKBuiltinString_t : NSObject
@property (retain, nonatomic) NSString *string;
@end

@interface BaseResponse : NSObject
@property (retain, nonatomic) SKBuiltinString_t *errMsg;
@property (nonatomic) int ret;
@end

@interface SearchContactResponse : NSObject 
@property (retain, nonatomic) NSString *myBrandList;
@property (retain, nonatomic) SKBuiltinString_t *nickName;
@property (retain, nonatomic) SKBuiltinString_t *pyinitial;
@property (retain, nonatomic) SKBuiltinString_t *quanPin;
@property (nonatomic) int sex;
@property (retain, nonatomic) SKBuiltinString_t *userName;
@property (retain, nonatomic) NSString *verifyInfo;
@property (retain, nonatomic) BaseResponse *baseResponse;
@property (retain, nonatomic) NSMutableArray *contactList;
@end

@interface GetQRCodeRequest : WXPBGeneratedMessage
@property (retain, nonatomic) SKBuiltinString_t *userName;
@end

@interface CVerifyContactWrap : NSObject
@property (retain, nonatomic) NSString *m_nsUsrName;
@property (retain, nonatomic) CContact *m_oVerifyContact;
@property (nonatomic) NSUInteger m_uiScene;
@property (nonatomic) NSUInteger m_uiWCFlag;
@end

@interface CContactVerifyLogic : NSObject
{
    NSArray *m_arrVerifyContactWrap;
    NSString *m_nsVerifyValue;
    NSUInteger m_uiOpCode;
    NSUInteger m_uiFriendScene;
}
- (BOOL)doVerify:(NSString *)arg1;
@end

@interface CdnTaskInfo : NSObject
@property (retain, nonatomic) CMessageWrap *m_wrapMsg;
@end

@interface CdnDownloadTaskInfo : NSObject
@property (nonatomic) long m_nRetCode;
@property (nonatomic) NSUInteger m_uiFileLength;
@property (retain, nonatomic) NSString *m_nsExtInfo;
@property (retain, nonatomic) NSString *m_nsFileID;
@property (retain, nonatomic) NSString *m_nsTransInfo;
@end

@interface MMQRCodeMgr : NSObject
- (void)getQRCodeFromServer:(NSString *)userID withStyle:(NSUInteger)style;
- (NSString *)getQRCodeImagePath:(NSString *)userID;
@end

@interface ChatRoomInfoViewController : UIViewController
- (BOOL)quitChatRoom;
@end

@interface AudioHelper : NSObject
+ (BOOL)isSilkFile:(NSData *)data;
@end

@interface CPDistributedMessagingCenter : NSObject
+ (instancetype)centerNamed:(id)named;
- (NSDictionary *)sendMessageAndReceiveReplyName:(NSString *)name userInfo:(NSDictionary *)info;
- (BOOL)sendMessageName:(NSString *)name userInfo:(NSDictionary *)info;
- (void)runServerOnCurrentThread;
- (void)registerForMessageName:(NSString *)messageName target:(id)target selector:(SEL)selector;
@end

@interface MicroMessengerAppDelegate : NSObject
@end

@interface SBApplication : NSObject
- (NSString *)bundleIdentifier;
@end

@interface SpringBoard : NSObject
- (SBApplication *)_accessibilityFrontMostApplication;
- (BOOL)launchApplicationWithIdentifier:(NSString *)arg1 suspended:(BOOL)arg2;
@end

@interface VoiceTransFloatPreview : NSObject
- (NSString *)getVoiceIDFromMsg:(CMessageWrap *)arg1;
@end

@interface VoiceTransHelper : NSObject
- (instancetype)initWithVoiceMsg:(CMessageWrap *)arg1 VoiceID:(NSString *)arg2;
- (void)startVoiceTrans;
@end

@interface VoiceTransRes : PBGeneratedMessage
@property (nonatomic) unsigned int endFlag;
@property (retain, nonatomic) NSString *result;
@end

@interface GetVoiceTransResResponse : WXPBGeneratedMessage
@property (retain, nonatomic) VoiceTransRes *transRes;
@end

@interface GetVoiceTransResRequest : PBGeneratedMessage
@property (retain, nonatomic) NSString *voiceId;
@end

@interface AccountStorageMgr : NSObject
- (void)SaveSettingExt;
@end
