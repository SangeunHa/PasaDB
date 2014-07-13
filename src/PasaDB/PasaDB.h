//  PasaDB.h
//
//  Created by Ha Sang Eun on 2014. 5. 6..

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "PasaRecord.h"

@interface PasaDB : NSObject
{
    sqlite3 *db;
    sqlite3_stmt *stmt;
}

+(PasaDB*)get_instance;
+(id)alloc;

-(void)initDB;
-(int)recordCount;
-(int)store:(PasaRecord*)record;
-(bool)update:(id)record;
-(bool)remove:(id)record;
-(bool)load:(id)record;
-(bool)isThereIndex:(int)index;
-(NSArray*)query:(NSString*)sql;
@end
