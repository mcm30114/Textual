// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

NSComparisonResult channelDataSort(IRCChannel *s1, IRCChannel *s2, void *context) {
	return [s1.name.lowercaseString compare:s2.name.lowercaseString];
}

@implementation IRCClientConfig

@synthesize altNicks;
@synthesize autoConnect;
@synthesize autoReconnect;
@synthesize bouncerMode;
@synthesize channels;
@synthesize cuid;
@synthesize encoding;
@synthesize fallbackEncoding;
@synthesize guid;
@synthesize host;
@synthesize ignores;
@synthesize prefersIPv6;
@synthesize invisibleMode;
@synthesize isTrustedConnection;
@synthesize leavingComment;
@synthesize loginCommands;
@synthesize name;
@synthesize network;
@synthesize nick;
@synthesize nickPassword;
@synthesize password;
@synthesize port;
@synthesize proxyHost;
@synthesize proxyPassword;
@synthesize proxyPort;
@synthesize proxyType;
@synthesize proxyUser;
@synthesize realName;
@synthesize server;
@synthesize sleepQuitMessage;
@synthesize username;
@synthesize useSSL;
@synthesize outgoingFloodControl;
@synthesize floodControlMaximumMessages;
@synthesize floodControlDelayTimerInterval;

- (id)init
{
	if ((self = [super init])) {
		self.cuid = TXRandomNumber(9999);
		self.guid = [NSString stringWithUUID];
		
		self.ignores         = [NSMutableArray new];
		self.altNicks        = [NSMutableArray new];
		self.channels        = [NSMutableArray new];
		self.loginCommands   = [NSMutableArray new];
		
		self.host         = NSStringEmptyPlaceholder;
		self.port         = 6667;
		self.password     = NSStringEmptyPlaceholder;
		self.nickPassword = NSStringEmptyPlaceholder;
		
		self.proxyHost       = NSStringEmptyPlaceholder;
		self.proxyPort       = 1080;
		self.proxyUser       = NSStringEmptyPlaceholder;
		self.proxyPassword   = NSStringEmptyPlaceholder;
        
        self.prefersIPv6 = NO;
		
		self.encoding         = NSUTF8StringEncoding;
		self.fallbackEncoding = NSISOLatin1StringEncoding;
        
        self.outgoingFloodControl            = NO;
        self.floodControlMaximumMessages     = TXFloodControlDefaultMessageCount;
		self.floodControlDelayTimerInterval  = TXFloodControlDefaultDelayTimer;
		
		self.name        = TXTLS(@"DefaultNewConnectionName");
		self.nick        = [TPCPreferences defaultNickname];
		self.username    = [TPCPreferences defaultUsername];
		self.realName    = [TPCPreferences defaultRealname];
		
		self.leavingComment      = TXTLS(@"DefaultDisconnectQuitMessage");
		self.sleepQuitMessage    = TXTLS(@"OSXGoingToSleepQuitMessage");
	}
	
	return self;
}

#pragma mark -
#pragma mark Keychain Management

- (NSString *)nickPassword
{
	NSString *kcPassword = nil;
	
	if (NSObjectIsEmpty(nickPassword)) {
		kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (NickServ)"
												withItemKind:@"application password" 
												 forUsername:nil 
												 serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]];
	}
	
	if (kcPassword) {
		if ([kcPassword isEqualToString:nickPassword] == NO) {
			nickPassword = nil;
			nickPassword = kcPassword;
		}
	}
	
	return nickPassword;
}

- (void)setNickPassword:(NSString *)pass
{
	if ([nickPassword isEqualToString:pass] == NO) {	
		if (NSObjectIsEmpty(pass)) {
			[AGKeychain deleteKeychainItem:@"Textual (NickServ)"
							  withItemKind:@"application password"
							   forUsername:nil
							   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]];
			
		} else {
			[AGKeychain modifyOrAddKeychainItem:@"Textual (NickServ)"
								   withItemKind:@"application password"
									forUsername:nil
								withNewPassword:pass
									withComment:self.host
									serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]];
		}
		
		nickPassword = nil;
		nickPassword = pass;
	}
}

- (NSString *)password
{
	NSString *kcPassword = nil;
	
	if (NSObjectIsEmpty(password)) {
		kcPassword = [AGKeychain getPasswordFromKeychainItem:@"Textual (Server Password)"
												withItemKind:@"application password" 
												 forUsername:nil 
												 serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]];
	}
	
	if (kcPassword) {
		if ([kcPassword isEqualToString:password] == NO) {
			password = nil;
			password = kcPassword;
		}
	}
	
	return password;
}

- (void)setPassword:(NSString *)pass
{
	if ([password isEqualToString:pass] == NO) {
		if (NSObjectIsEmpty(pass)) {
			[AGKeychain deleteKeychainItem:@"Textual (Server Password)"
							  withItemKind:@"application password"
							   forUsername:nil
							   serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]];		
		} else {
			[AGKeychain modifyOrAddKeychainItem:@"Textual (Server Password)"
								   withItemKind:@"application password"
									forUsername:nil
								withNewPassword:pass
									withComment:self.host
									serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]];			
		}
		
		password = nil;
		password = pass;
	}
}

- (void)destroyKeychains
{	
	[AGKeychain deleteKeychainItem:@"Textual (Server Password)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.server.%@", self.guid]];
	
	[AGKeychain deleteKeychainItem:@"Textual (NickServ)"
					  withItemKind:@"application password"
					   forUsername:nil
					   serviceName:[NSString stringWithFormat:@"textual.nickserv.%@", self.guid]];
}

#pragma mark -
#pragma mark Server Configuration

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		dic = [TPCPreferencesMigrationAssistant convertIRCClientConfiguration:dic];
		
		self.cuid = NSDictionaryIntegerKeyValueCompare(dic, @"connectionID", self.cuid);
		self.guid = NSDictionaryObjectKeyValueCompare(dic, @"uniqueIdentifier", self.guid);
		self.name = NSDictionaryObjectKeyValueCompare(dic, @"connectionName", self.name);
		self.host = NSDictionaryObjectKeyValueCompare(dic, @"serverAddress", self.host);
		self.port = NSDictionaryIntegerKeyValueCompare(dic, @"serverPort", self.port);
		self.nick = NSDictionaryObjectKeyValueCompare(dic, @"identityNickname", self.nick);
		self.username = NSDictionaryObjectKeyValueCompare(dic, @"identityUsername", self.username);
		self.realName = NSDictionaryObjectKeyValueCompare(dic, @"identityRealname", self.realName);
		
		[self.altNicks addObjectsFromArray:[dic arrayForKey:@"identityAlternateNicknames"]];
		
		self.proxyType       = (TXConnectionProxyType)[dic integerForKey:@"proxy"];
		self.proxyPort       = NSDictionaryIntegerKeyValueCompare(dic, @"proxyServerPort", self.proxyPort);
		self.proxyHost		 = NSDictionaryObjectKeyValueCompare(dic, @"proxyServerAddress", self.proxyHost);
		self.proxyUser		 = NSDictionaryObjectKeyValueCompare(dic, @"proxyServerUsername", self.proxyUser);
		self.proxyPassword	 = NSDictionaryObjectKeyValueCompare(dic, @"proxyServerPassword", self.proxyPassword);
		
		self.useSSL				 = [dic boolForKey:@"connectUsingSSL"];
		self.autoConnect         = [dic boolForKey:@"connectOnLaunch"];
		self.autoReconnect       = [dic boolForKey:@"connectOnDisconnect"];
		self.bouncerMode         = [dic boolForKey:@"serverIsIRCBouncer"];
		
		self.encoding			 = NSDictionaryIntegerKeyValueCompare(dic, @"characterEncodingDefault", self.encoding);
		self.fallbackEncoding	 = NSDictionaryIntegerKeyValueCompare(dic, @"characterEncodingFallback", self.fallbackEncoding);
		self.leavingComment		 = NSDictionaryObjectKeyValueCompare(dic, @"connectionDisconnectDefaultMessage", self.leavingComment);
		self.sleepQuitMessage	 = NSDictionaryObjectKeyValueCompare(dic, @"connectionDisconnectSleepModeMessage", self.sleepQuitMessage);
		
		self.prefersIPv6         = [dic boolForKey:@"DNSResolverPrefersIPv6"];
		self.invisibleMode       = [dic boolForKey:@"setInvisibleOnConnect"];
		self.isTrustedConnection = [dic boolForKey:@"trustedSSLConnection"];
		
		[self.loginCommands addObjectsFromArray:[dic arrayForKey:@"onConnectCommands"]];
		
		for (NSDictionary *e in [dic arrayForKey:@"channelList"]) {
			IRCChannelConfig *c;
			
			c = [IRCChannelConfig alloc];
			c = [c initWithDictionary:e];
			c = c;
			
			[self.channels safeAddObject:c];
		}
		
		for (NSDictionary *e in [dic arrayForKey:@"ignoreList"]) {
			IRCAddressBook *ignore;
			
			ignore = [IRCAddressBook alloc];
			ignore = [ignore initWithDictionary:e];
			ignore = ignore;
			
			[self.ignores safeAddObject:ignore];
		}
		
		if ([dic containsKey:@"floodControl"]) {
			NSDictionary *e = [dic dictionaryForKey:@"floodControl"];
			
			if (NSObjectIsNotEmpty(e)) {
				self.outgoingFloodControl           = [e boolForKey:@"serviceEnabled"];

				self.floodControlMaximumMessages	= NSDictionaryIntegerKeyValueCompare(e, @"maximumMessageCount", TXFloodControlDefaultMessageCount);
				self.floodControlDelayTimerInterval	= NSDictionaryIntegerKeyValueCompare(e, @"delayTimerInterval", TXFloodControlDefaultDelayTimer);
			}
		} else {
			/* Enable flood control by default for Freenode servers. 
			 They are very strict about flooding. This is required. */
			
			if ([self.host hasSuffix:@"freenode.net"]) {
				self.outgoingFloodControl = YES;
			}
		}
		
		return self;
	}
	
	return nil;
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInteger:self.port				forKey:@"serverPort"];
	[dic setInteger:self.proxyType			forKey:@"proxyServerType"];
	[dic setInteger:self.proxyPort			forKey:@"proxyServerPort"];
	[dic setInteger:self.encoding			forKey:@"characterEncodingDefault"];
	[dic setInteger:self.fallbackEncoding	forKey:@"characterEncodingFallback"];
	
	[dic setBool:self.useSSL				forKey:@"connectUsingSSL"];
    [dic setBool:self.prefersIPv6			forKey:@"DNSResolverPrefersIPv6"];
	[dic setBool:self.autoConnect			forKey:@"connectOnLaunch"];
	[dic setBool:self.autoReconnect			forKey:@"connectOnDisconnect"];
	[dic setBool:self.bouncerMode			forKey:@"serverIsIRCBouncer"];
	[dic setBool:self.invisibleMode			forKey:@"setInvisibleOnConnect"];
	[dic setBool:self.isTrustedConnection	forKey:@"trustedSSLConnection"];
	
	[dic setInteger:self.cuid				forKey:@"connectionID"];
	
	[dic safeSetObject:self.guid				forKey:@"uniqueIdentifier"];
	[dic safeSetObject:self.name				forKey:@"connectionName"];
	[dic safeSetObject:self.host				forKey:@"serverAddress"];
	[dic safeSetObject:self.nick				forKey:@"identityNickname"];
	[dic safeSetObject:self.username			forKey:@"identityUsername"];
	[dic safeSetObject:self.realName			forKey:@"identityRealname"];
	[dic safeSetObject:self.altNicks			forKey:@"identityAlternateNicknames"];
	[dic safeSetObject:self.proxyHost			forKey:@"proxyServerAddress"];
	[dic safeSetObject:self.proxyUser			forKey:@"proxyServerUsername"];
	[dic safeSetObject:self.proxyPassword		forKey:@"proxyServerPassword"];
	[dic safeSetObject:self.leavingComment		forKey:@"connectionDisconnectDefaultMessage"];
	[dic safeSetObject:self.sleepQuitMessage	forKey:@"connectionDisconnectSleepModeMessage"];
	[dic safeSetObject:self.loginCommands		forKey:@"onConnectCommands"];
    
    NSMutableDictionary *floodControl = [NSMutableDictionary dictionary];
    
    [floodControl setInteger:self.floodControlDelayTimerInterval	forKey:@"delayTimerInterval"];
    [floodControl setInteger:self.floodControlMaximumMessages		forKey:@"maximumMessageCount"];
	
    [floodControl setBool:self.outgoingFloodControl forKey:@"serviceEnabled"];
    
    [dic setObject:floodControl forKey:@"floodControl"];
	
	NSMutableArray *channelAry = [NSMutableArray array];
	NSMutableArray *ignoreAry = [NSMutableArray array];
	
	for (IRCChannelConfig *e in self.channels) {
		[channelAry safeAddObject:[e dictionaryValue]];
	}
	
	for (IRCAddressBook *e in self.ignores) {
		[ignoreAry safeAddObject:[e dictionaryValue]];
	}
	
	[dic setObject:channelAry forKey:@"channelList"];
	[dic setObject:ignoreAry forKey:@"ignoreList"];
	
	[dic safeSetObject:TPCPreferencesMigrationAssistantUpgradePath
				forKey:TPCPreferencesMigrationAssistantVersionKey];
	
	return [dic sortedDictionary];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCClientConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end