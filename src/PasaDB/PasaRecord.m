//  PasaRecord.m
//
//  Created by Ha Sang Eun on 2014. 5. 6..

#import "PasaDB.h"
#import "PasaRecord.h"

@implementation PasaRecord

+(NSArray*) queryWithKey1:(NSString*)key1
{
    PasaDB *db = [PasaDB get_instance];
    NSString *query = [NSString stringWithFormat:@"select * from Documents where key1='%@' order by idx desc",key1];
    
    return [db query:query];
}

+(NSArray*) queryWithKey2:(NSString*)key2
{
    PasaDB *db = [PasaDB get_instance];
    NSString *query = [NSString stringWithFormat:@"select * from Documents where key2='%@' order by idx desc",key2];
    
    return [db query:query];
}

+(NSArray*) queryWithKey3:(NSString*)key3
{
    PasaDB *db = [PasaDB get_instance];
    NSString *query = [NSString stringWithFormat:@"select * from Documents where key3='%@' order by idx desc",key3];
    
    return [db query:query];
}

-(PasaRecord*) init
{
    self = [super init];
    index = -1;
    
    return self;
}

-(PasaRecord*) initWithStatement:(sqlite3_stmt*)stmt
{
    if( stmt == 0 ) return nil;
    const char *ptr1,*ptr2,*ptr3,*ptr4,*ptr5;
    self = [self init];
    
    index = sqlite3_column_int(stmt, 0);
    ptr1 = (const char*)sqlite3_column_text(stmt, 1);
    ptr2 = (const char*)sqlite3_column_text(stmt, 2);
    ptr3 = (const char*)sqlite3_column_text(stmt, 3);
    ptr4 = (const char*)sqlite3_column_text(stmt, 4);
    ptr5 = (const char*)sqlite3_column_text(stmt, 5);
    
    key1 = key2 = key3 = nil;
    
    if(ptr1)
        key1 = [NSString stringWithUTF8String:ptr1];
    if(ptr2)
        key2 = [NSString stringWithUTF8String:ptr2];
    if(ptr3)
        key3 = [NSString stringWithUTF8String:ptr3];
    if(ptr4)
        document = [NSString stringWithUTF8String:ptr4];
    if(ptr5)
        date = [NSString stringWithUTF8String:ptr5];
    
    return self;
}

-(bool) save
{
    PasaDB *db = [PasaDB get_instance];
    bool ret = false;
    
    if( index != -1 && [db isThereIndex:index] )
        ret = [db update:self];
    else
    {
        int idx = [db store:self];
        
        index = idx;
        ret = idx != -1;
    }
    
    return ret;
}

-(bool) remove
{
    PasaDB *db = [PasaDB get_instance];
    return [db remove:self];
}

-(bool)load
{
    PasaDB *db = [PasaDB get_instance];
    return [db load:self];
}

-(int) Index
{
    return index;
}

-(NSString*) Key1
{
    return key1;
}

-(NSString*) Key2
{
    return key2;
}

-(NSString*) Key3
{
    return key3;
}

-(NSString*) Document
{
    return document;
}

-(NSString*) Date
{
    return date;
}

-(void)setKey1:(NSString*) Key1 Key2:(NSString*)Key2 Key3:(NSString*)Key3
{
    key1 = Key1;
    key2 = Key2;
    key3 = Key3;
}

-(void)setDocument:(NSString*)Document;
{
    document = Document;
}

-(NSMutableDictionary*)getDocumentJSON
{
    if( document == nil ) return [[NSMutableDictionary alloc] init];
    
    NSDictionary *JSON =
    [NSJSONSerialization JSONObjectWithData: [document dataUsingEncoding:NSUTF8StringEncoding]
                                    options: NSJSONReadingMutableContainers
                                      error: nil];

    return [[NSMutableDictionary alloc] initWithDictionary:JSON];
}

-(bool)setDocumentJSON:(NSMutableDictionary*)JSON
{
    if( JSON == nil ) document = nil;
    
    NSData* kData = [NSJSONSerialization dataWithJSONObject:JSON options:NSJSONWritingPrettyPrinted error:nil];
    [self setDocument:[[NSString alloc] initWithData:kData encoding:NSUTF8StringEncoding]];

    return [self save];
}
@end
