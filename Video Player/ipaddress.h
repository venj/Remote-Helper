//
//  ipaddress.h
//  Video Player
//
//  Created by 朱 文杰 on 13-6-25.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#ifndef Video_Player_ipaddress_h
#define Video_Player_ipaddress_h

#define MAXADDRS    32

extern char *if_names[MAXADDRS];
extern char *ip_names[MAXADDRS];
extern char *hw_addrs[MAXADDRS];
extern unsigned long ip_addrs[MAXADDRS];

// Function prototypes

void InitAddresses();
void FreeAddresses();
void GetIPAddresses();
void GetHWAddresses();

#endif
