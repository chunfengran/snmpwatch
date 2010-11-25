//
//  snmpwatch_AppDelegate.h
//  snmpwatch
//
//  Created by Alexandre MOREL on 25/11/10.
//  Copyright __MyCompanyName__ 2010 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface snmpwatch_AppDelegate : NSObject 
{
    NSWindow *window;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) IBOutlet NSWindow *window;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:sender;

@end
