//
//  GuiInterface.m
//
//  Created by Alexandre MOREL on 25/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GuiInterface.h"
#import <net-snmp/net-snmp-config.h>
#import <net-snmp/net-snmp-includes.h>

void myAlert(){
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"OK"];	
	[alert setMessageText:@"Erreur dans la saisie"];
	[alert setInformativeText:@"L'adresse IP ou la communauté est incorrecte !"];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert runModal];
}

@implementation GuiInterface


- (IBAction)myLecture:(id)sender {
	struct snmp_session session; 
	struct snmp_session *sess_handle;
	struct snmp_pdu *pdu;                   
	struct snmp_pdu *response;
	struct variable_list *vars;            
	oid id_oid[MAX_OID_LEN];
	size_t id_len = MAX_OID_LEN;
	int status;                             
	char *sp;
	
	
	
	NSString *community = [myCommunity stringValue];
	NSString *hostname = [myIp stringValue];
	
	if ([community length] == 0 || [hostname length] == 0) {
		myAlert();
	} else {
	
		init_snmp("APC Check");
		snmp_sess_init( &session );
		session.version = SNMP_VERSION_2c;
		session.community = (u_char *)[community cStringUsingEncoding:NSASCIIStringEncoding]; 
		session.community_len = strlen(session.community);
		session.peername = (char *)[hostname cStringUsingEncoding:NSASCIIStringEncoding]; 
		sess_handle = snmp_open(&session);
		pdu = snmp_pdu_create(SNMP_MSG_GET);
		read_objid("IF-MIB::ifInOctets.502", id_oid, &id_len);
		snmp_add_null_var(pdu, id_oid, id_len);
		NSString *value = [NSString stringWithString:@"Default"];
		status = snmp_synch_response(sess_handle, pdu, &response);
		for(vars = response->variables; vars; vars = vars->next_variable){
			sp = (char *)malloc(1 + vars->val_len);
			memcpy(sp, vars->val.string, vars->val_len);
			sp[vars->val_len] = '\0';
			printf("%s\n",sp);
			value = [[NSString alloc] initWithBytes:sp length:strlen(sp) encoding:NSASCIIStringEncoding];
			[myValue setStringValue:value];
		}
		snmp_free_pdu(response);
		snmp_close(sess_handle);
	}
}

- (IBAction)myListe:(id)sender {
	struct snmp_session session; 
	struct snmp_session *sess_handle;
	struct snmp_pdu *pdu;                   
	struct snmp_pdu *response;
	struct variable_list *vars;            
	oid id_oid[MAX_OID_LEN];
	size_t id_len = MAX_OID_LEN;
	int status;                             
	char *sp;
	
	
	
	NSString *community = [myCommunity stringValue];
	NSString *hostname = [myIp stringValue];
	NSString *value = [NSString stringWithString:@"Default"];

	
	if ([community length] == 0 || [hostname length] == 0) {
		myAlert();
	} else {
		
		init_snmp("APC Check");
		snmp_sess_init( &session );
		session.version = SNMP_VERSION_2c;
		session.community = (u_char *)[community cStringUsingEncoding:NSASCIIStringEncoding]; 
		session.community_len = strlen(session.community);
		session.peername = (char *)[hostname cStringUsingEncoding:NSASCIIStringEncoding]; 
		sess_handle = snmp_open(&session);
		pdu = snmp_pdu_create(SNMP_MSG_GET);
		read_objid("IF-MIB::ifInOctets", id_oid, &id_len);
		snmp_add_null_var(pdu, id_oid, id_len);
		status = snmp_synch_response(sess_handle, pdu, &response);
		if (status == STAT_SUCCESS && response->errstat == SNMP_ERR_NOERROR) {
			for(vars = response->variables; vars; vars = vars->next_variable){
				print_value(vars->name, vars->name_length, vars);
				//value = [[NSString alloc] initWithBytes:sp length:strlen(sp) encoding:NSASCIIStringEncoding];
				//[myValue setStringValue:value];
			}
		} else {
			NSLog(@"Erreur SNMP !!");
		}
		snmp_free_pdu(response);
		snmp_close(sess_handle);
	}
}

@end
