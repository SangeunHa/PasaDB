//  PasaRecord.h
//
//  Created by Ha Sang Eun on 2014. 5. 6..

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface PasaRecord : NSObject
{
    int index;
    NSString *key1, *key2, *key3;
    NSString *document;
    NSString *date;
}

+(NSArray*) queryWithKey1:(NSString*)key1;
+(NSArray*) queryWithKey2:(NSString*)key2;
+(NSArray*) queryWithKey3:(NSString*)key3;
-(PasaRecord*) initWithStatement:(sqlite3_stmt*)stmt;
-(PasaRecord*) init;
-(bool) save;
-(bool) remove;
-(bool)load;
-(int) Index;
-(NSString*) Key1;
-(NSString*) Key2;
-(NSString*) Key3;
-(NSString*) Document;
-(NSString*) Date;
-(void)setKey1:(NSString*) key1 Key2:(NSString*)key2 Key3:(NSString*)key3;
-(void)setDocument:(NSString*)Document;
-(NSMutableDictionary*)getDocumentJSON;
-(bool)setDocumentJSON:(NSMutableDictionary*)JSON;

@end
