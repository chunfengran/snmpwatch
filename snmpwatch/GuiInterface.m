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
	size_t rootlen;
	oid    root[MAX_OID_LEN];
	int numprinted = 0;
	int    check;
	int    exitval = 0;
	int		count;
	oid name[MAX_OID_LEN];
	size_t name_length = MAX_OID_LEN;
	int status,running=1;                             
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
		oid objid_mib[] = {1, 3, 6, 1, 2, 1, 2, 2, 1, 2};
		
		memmove(root, objid_mib, sizeof(objid_mib));
		rootlen = sizeof(objid_mib) / sizeof(oid);
		memmove(name, root, rootlen * sizeof(oid));
		name_length = rootlen;

		
		NSString *value = [NSString stringWithString:@"Default"];
		[myInterfaces removeAllItems];
		
		while(running){
			/* create PDU for GETNEXT request and add object name to request */
			pdu = snmp_pdu_create(SNMP_MSG_GETNEXT);
			snmp_add_null_var(pdu, name, name_length);
			
			/* do the request */
			status = snmp_synch_response(sess_handle, pdu, &response);
			if (status == STAT_SUCCESS){
				if (response->errstat == SNMP_ERR_NOERROR){
					/* check resulting variables */
					for(vars = response->variables; vars; vars = vars->next_variable){
						if ((vars->name_length < rootlen) ||
							(memcmp(root, vars->name, rootlen * sizeof(oid))!=0)) {
							/* not part of this subtree */
							running = 0;
							continue;
						}
						numprinted++;
						print_variable(vars->name, vars->name_length, vars);
						sp = (char *)malloc(1 + vars->val_len);
						memcpy(sp, vars->val.string, vars->val_len);
						sp[vars->val_len] = '\0';
						value = [[NSString alloc] initWithBytes:sp length:strlen(sp) encoding:NSASCIIStringEncoding];
						[myInterfaces addItemWithObjectValue:value];
						
						if ((vars->type != SNMP_ENDOFMIBVIEW) &&
							(vars->type != SNMP_NOSUCHOBJECT) &&
							(vars->type != SNMP_NOSUCHINSTANCE)){
							/* not an exception value */
							if (check && snmp_oid_compare(name, name_length, vars->name,
														  vars->name_length) >= 0) {
								char name_buf[SPRINT_MAX_LEN], var_buf[SPRINT_MAX_LEN];
								//sprint_objid(name_buf, name, name_length);
								//sprint_objid(var_buf, vars->name, vars->name_length);
								fprintf(stderr, "Error: OID not increasing: %s >= %s\n",
										name_buf, var_buf);
								running = 0;
								exitval = 1;
							}
							memmove((char *)name, (char *)vars->name,
									vars->name_length * sizeof(oid));
							name_length = vars->name_length;
						} else
						/* an exception value, so stop */
							running = 0;
					}
				} else {
					/* error in response, print it */
					running = 0;
					if (response->errstat == SNMP_ERR_NOSUCHNAME){
						printf("End of MIB\n");
					} else {
						fprintf(stderr, "Error in packet.\nReason: %s\n",
								snmp_errstring(response->errstat));
						if (response->errindex != 0){
							fprintf(stderr, "Failed object: ");
							for(count = 1, vars = response->variables;
								vars && count != response->errindex;
								vars = vars->next_variable, count++)
							/*EMPTY*/;
							if (vars)
								fprint_objid(stderr, vars->name, vars->name_length);
							fprintf(stderr, "\n");
						}
						exitval = 2;
					}
				}
			} else if (status == STAT_TIMEOUT){
				fprintf(stderr, "Timeout: No Response from %s\n", session.peername);
				running = 0;
				exitval = 1;
			} else {    /* status == STAT_ERROR */

				running = 0;
				exitval = 1;
			}
		}
		snmp_free_pdu(response);
		snmp_close(sess_handle);
	}
	
}

@end
