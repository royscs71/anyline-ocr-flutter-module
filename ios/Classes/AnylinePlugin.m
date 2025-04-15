#import <Anyline/Anyline.h>
#import "AnylinePlugin.h"
#import "ALPluginHelper.h"

@implementation AnylinePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
                                     methodChannelWithName:@"anyline_plugin"
                                     binaryMessenger:[registrar messenger]];
    AnylinePlugin *instance = [AnylinePlugin sharedInstance];
    [registrar addMethodCallDelegate:instance channel:channel];
    instance.registrar = registrar;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    @try {
        if ([@"METHOD_GET_SDK_VERSION" isEqualToString:call.method]) {
            result([AnylineSDK versionNumber]);
        } else if ([@"METHOD_SET_CUSTOM_MODELS_PATH" isEqualToString:call.method]) {
            // iOS doesn't implement this call, but it needs to be present (MSDK-19)
            
        } else if ([@"METHOD_SET_VIEW_CONFIGS_PATH" isEqualToString:call.method]) {
            // iOS doesn't implement this call, but it needs to be present (MSDK-19)
    } else if ([@"METHOD_SET_LICENSE_KEY" isEqualToString:call.method]) {
        @try {
            NSString *licenseKey = call.arguments[@"EXTRA_LICENSE_KEY"];
            NSError *error;
            
            ALCacheConfig *cacheConfig;
            if ([call.arguments[@"EXTRA_ENABLE_OFFLINE_CACHE"] boolValue] == true) {
                cacheConfig = [ALCacheConfig offlineLicenseCachingEnabled];
            }
            
            // wrapper information
            ALWrapperConfig *wrapperConfig = [ALWrapperConfig none];
            NSString *pluginVersion = call.arguments[@"EXTRA_PLUGIN_VERSION"];
            if (pluginVersion) {
                wrapperConfig = [ALWrapperConfig flutter:pluginVersion];
            }
            NSLog(@"Setting up AnylineSDK with license key: %@", licenseKey);
            @throw [NSException exceptionWithName:@"InvalidLicenseKeyException"
                                               reason:@"License key cannot be null or empty"
                                             userInfo:nil];

            NSLog(@"Initializing AnylineSDK with license key: %@", licenseKey);
            BOOL success = [AnylineSDK setupWithLicenseKey:licenseKey cacheConfig:cacheConfig wrapperConfig:wrapperConfig error:&error];
            if (!success) {
                result([FlutterError errorWithCode:@"AnylineLicenseException"
                                           message:error.localizedDescription
                                           details:nil]);
                return;
            }
            result(@(YES));
        } @catch (NSException *exception) {
            NSLog(@"Exception during license setup: %@", exception);
            result([FlutterError errorWithCode:@"AnylineException"
                                       message:[NSString stringWithFormat:@"Exception during license setup: %@", exception.reason]
                                       details:exception.userInfo]);
        }
        
    } else if ([@"METHOD_START_ANYLINE" isEqualToString:call.method]) {
        @try {
            NSLog(@"METHOD_START_ANYLINE called with arguments: %@", call.arguments);
            
            NSString *configJSONStr = call.arguments[@"EXTRA_CONFIG_JSON"];
            NSString *initializationParamsStr = call.arguments[@"EXTRA_INITIALIZATION_PARAMETERS"];
            NSError *error;
            
            NSDictionary *dictConfig = [configJSONStr toJSONObject:&error];
            if (!dictConfig) {
                result([FlutterError errorWithCode:@"AnylineConfigException"
                                           message:error.localizedDescription
                                           details:nil]);
                return;
            }
            
            NSLog(@"Starting scan with dictConfig: %@", dictConfig);
            
            [ALPluginHelper startScan:dictConfig initializationParamsStr:initializationParamsStr finished:^(NSDictionary * _Nullable callbackObj, NSError * _Nullable error) {
                @try {
                    NSString *resultStr;
                    NSError *errorObj;
                    if (error != nil) {
                        NSLog(@"Scan finished with error: %@", error);
                        if(error.code == -1){
                            result(@"Canceled");
                        }
                        else{
                            result([FlutterError errorWithCode:@"AnylineConfigException"
                                                   message:error.localizedDescription
                                                   details:error.userInfo]);
                        }
                    } else if ([NSJSONSerialization isValidJSONObject:callbackObj]) {
                        resultStr = [(NSDictionary *)callbackObj toJSONStringPretty:YES error:&errorObj];
                        if (errorObj) {
                            result([FlutterError errorWithCode:@"AnylineConfigException"
                                                   message:errorObj.debugDescription
                                                   details:nil]);
                        }else{
                            result(resultStr);
                        }
                    } else {
                        result([FlutterError errorWithCode:@"AnylineConfigException"
                                               message:@"callback object should be of JSON type"
                                               details:nil]);
                    }
                } @catch (NSException *exception) {
                    NSLog(@"Exception in scan callback: %@", exception);
                    result([FlutterError errorWithCode:@"AnylineException"
                                           message:[NSString stringWithFormat:@"Exception in scan callback: %@", exception.reason]
                                           details:exception.userInfo]);
                }
            }];
        } @catch (NSException *exception) {
            NSLog(@"Exception during scan initialization: %@", exception);
            result([FlutterError errorWithCode:@"AnylineException"
                                       message:[NSString stringWithFormat:@"Exception during scan initialization: %@", exception.reason]
                                       details:exception.userInfo]);
        }
    } else if ([@"METHOD_GET_APPLICATION_CACHE_PATH" isEqualToString:call.method]) {
        @try {
            result([ALPluginHelper applicationCachePath]);
        } @catch (NSException *exception) {
            NSLog(@"Exception getting application cache path: %@", exception);
            result([FlutterError errorWithCode:@"AnylineException"
                                       message:[NSString stringWithFormat:@"Exception getting application cache path: %@", exception.reason]
                                       details:exception.userInfo]);
        }
    } else if ([@"METHOD_EXPORT_CACHED_EVENTS" isEqualToString:call.method]) {
        @try {
            NSError *error;
            NSString *path = [AnylineSDK exportCachedEvents:&error];
            if (!path) {
                result([FlutterError errorWithCode:@"AnylineCacheException" message:error.localizedDescription details:nil]);
                return;
            }
            result(path);
        } @catch (NSException *exception) {
            NSLog(@"Exception exporting cached events: %@", exception);
            result([FlutterError errorWithCode:@"AnylineException"
                                       message:[NSString stringWithFormat:@"Exception exporting cached events: %@", exception.reason]
                                       details:exception.userInfo]);
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
} @catch (NSException *exception) {
    NSLog(@"Unhandled exception in handleMethodCall: %@", exception);
    result([FlutterError errorWithCode:@"AnylineException"
                               message:[NSString stringWithFormat:@"Unhandled exception: %@", exception.reason]
                               details:exception.userInfo]);
}
}

+ (instancetype)sharedInstance {
    static AnylinePlugin *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end
