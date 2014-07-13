//  PasaDB.m
//
//  Created by Ha Sang Eun on 2014. 5. 6..

#import "PasaDB.h"
#import "PasaRecord.h"

@implementation PasaDB

static PasaDB* instance = nil;

-(void)initDB
{
    if( db == nil )
    {
        NSFileManager *fileMgr = [NSFileManager defaultManager];

        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString* cacheDirectory = [paths lastObject];
        NSString* documentPath = [cacheDirectory stringByAppendingPathComponent:@"simple.db"];
        
        bool isFirstAccess = false;
        
        if(![fileMgr fileExistsAtPath:documentPath])
        {
            isFirstAccess = true;
        }
        
        BOOL success = [fileMgr fileExistsAtPath:documentPath];
        
        if(!success)
        {
            NSLog(@"Cannot locate database file '%@'.", documentPath);
        }
        
        int ret;
        if ((ret = sqlite3_config(SQLITE_CONFIG_SERIALIZED)) == SQLITE_OK) {
            NSLog(@"Can now use sqlite on multiple threads, using the same connection");
        }
        
        if(!(sqlite3_open([documentPath UTF8String], &db) == SQLITE_OK))
        {
            NSLog(@"An error has occured.");
        }
        
        if( isFirstAccess )
        {
            NSString *query = [[NSString alloc] initWithFormat:@"CREATE TABLE Documents (idx INTEGER PRIMARY KEY AUTOINCREMENT, key1 TEXT, key2 TEXT, key3 TEXT, document TEXT, logdate DATE);"];
            
            if(sqlite3_prepare(db, [query UTF8String], -1, &stmt, NULL) == SQLITE_OK)
            {
                if( sqlite3_step(stmt) == SQLITE_DONE )
                    NSLog(@"Prepare SimpleDB Succeed");

                sqlite3_finalize(stmt);
            }
        }
    }
}

+(PasaDB*)get_instance
{
    @synchronized([PasaDB class])
    {
        if( !instance )
            instance = [[self alloc]init];
        
        return instance;
    }
    
    return nil;
}

+(id)alloc
{
    @synchronized([PasaDB class])
    {
        NSAssert( instance == nil, @"second instsance of Preference");
        instance = [super alloc];
        
        [instance initDB];
        return instance;
    }
    
    return nil;
}

-(NSArray*)query:(NSString*)sql
{
    @synchronized([PasaDB class])
    {
        NSMutableArray *result = nil;
        if(sqlite3_prepare(db, [sql UTF8String], -1, &stmt, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(stmt)==SQLITE_ROW)
            {
                if( result == nil )
                    result = [[NSMutableArray alloc]init];
                
                PasaRecord *record = [[PasaRecord alloc] initWithStatement:stmt];
                if( record != nil )
                   [result addObject:record];
            }
            
            sqlite3_finalize(stmt);
        }
        return result;
    }
    return nil;
}

-(bool)load:(id)record
{
    PasaRecord *sr = (PasaRecord*)record;
    NSString *query = [NSString stringWithFormat:@"select * from Documents where idx=%i", [sr Index]];
    const char* str = [query cStringUsingEncoding:NSUTF8StringEncoding];

    int ret = false;
    
    if(sqlite3_prepare(db, str, -1, &stmt, NULL) == SQLITE_OK)
    {
        if (sqlite3_step(stmt)==SQLITE_ROW)
        {
            sr = [sr initWithStatement:stmt];
            ret = true;
        }
        sqlite3_finalize(stmt);
    }
    return ret;
}

-(int)store:(PasaRecord*)record
{
    sqlite3_stmt *compiledStmt;
    NSString *query = [[NSString alloc] initWithFormat:@"INSERT INTO Documents (key1, key2, key3, document, logdate) VALUES(?, ?, ?, ?, datetime('now','localtime') )"];
    const char* str = [query cStringUsingEncoding:NSUTF8StringEncoding];

    if(sqlite3_prepare_v2(db,str, -1, &compiledStmt, NULL) == SQLITE_OK)
    {
        sqlite3_bind_text(compiledStmt, 1, [[record Key1] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStmt, 2, [[record Key2] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStmt, 3, [[record Key3] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStmt, 4, [[record Document] UTF8String], -1, SQLITE_TRANSIENT);
        
        int ret = sqlite3_step(compiledStmt);
        sqlite3_finalize(compiledStmt);
        
        if( ret == SQLITE_DONE )
            return [self recordCount] ;
        else
            NSLog(@"SimpleDB store result = %i", ret);
    }
    
    return -1;
}

-(bool)update:(id)record
{
    PasaRecord *sr = (PasaRecord*)record;
    NSString *query = [[NSString alloc] initWithFormat:@"update Documents set key1=?, key2=?, key3=?, document=?, logdate=datetime('now','localtime') where idx=%i", [sr Index]];
    const char* str = [query cStringUsingEncoding:NSUTF8StringEncoding];
    bool ret = false;
    
    if(sqlite3_prepare_v2(db,str, -1, &stmt, NULL) == SQLITE_OK)
    {
        sqlite3_bind_text(stmt, 1, [[sr Key1] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 2, [[sr Key2] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 3, [[sr Key3] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 4, [[sr Document] UTF8String], -1, SQLITE_TRANSIENT);
        
        if( sqlite3_step(stmt) == SQLITE_DONE )
            ret = true;
        else
            NSLog(@"SimpleDB update = %i", ret);
        sqlite3_finalize(stmt);
    
    }
    
    return ret;
}

-(bool)remove:(id)record
{
    PasaRecord *sr = (PasaRecord*)record;
    NSString *query = [[NSString alloc] initWithFormat:@"delete from Documents where idx=%i", [sr Index]];
    int ret = -1;
    
    if(sqlite3_prepare(db, [query UTF8String], -1, &stmt, NULL) == SQLITE_OK)
    {
        ret = sqlite3_step(stmt);
        
        if( ret != SQLITE_DONE )
            NSLog(@"SimpleDB delete : %i",ret);
        sqlite3_finalize(stmt);
    }

    return ret == SQLITE_DONE;
}

-(int)recordCount
{
    @synchronized([PasaDB class])
    {
    int n=0;
    NSString *query = [[NSString alloc] initWithFormat:@"select count(*) from Documents"];
    
    const char* str = [query cStringUsingEncoding:NSUTF8StringEncoding];
    if(sqlite3_prepare(db, str, -1, &stmt, NULL) == SQLITE_OK)
    {
        while (sqlite3_step(stmt)==SQLITE_ROW) {
            n = sqlite3_column_int(stmt, 0);
        }
    }
    sqlite3_finalize(stmt);
    
    return n;
    }
    
    return -1;
}

-(bool)isThereIndex:(int)index
{
    @synchronized([PasaDB class])
    {

    int n=0;
    NSString *query = [[NSString alloc] initWithFormat:@"select count(*) from Documents where idx=%i",index];
    
    const char* str = [query cStringUsingEncoding:NSUTF8StringEncoding];
    if(sqlite3_prepare(db, str, -1, &stmt, NULL) == SQLITE_OK)
    {
        while (sqlite3_step(stmt)==SQLITE_ROW) {
            n = sqlite3_column_int(stmt, 0);
        }
    }
    
    sqlite3_finalize(stmt);

    return n > 0;
    }
    
    return false;
}

@end
