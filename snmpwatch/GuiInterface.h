//
//  GuiInterface.h
//
//  Created by Alexandre MOREL on 25/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GuiInterface : NSObject {
    IBOutlet id myCommunity;
    IBOutlet id myIp;
    IBOutlet id myValue;
	IBOutlet id myInterfaces;
}
- (IBAction)myLecture:(id)sender;
- (IBAction)myListe:(id)sender;
@end
