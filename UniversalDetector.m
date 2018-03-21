/*
 * UniversalDetector.m
 *
 * Copyright (c) 2017-present, MacPaw Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */
#import "UniversalDetector.h"
#import "WrappedUniversalDetector.h"

@implementation UniversalDetector

+(UniversalDetector *)detector
{
	return [[self new] autorelease];
}

+(NSArray *)possibleMIMECharsets
{
	static NSArray *array=nil;

	if(!array) array=[[NSArray alloc] initWithObjects:
	@"UTF-8",@"UTF-16BE",@"UTF-16LE",@"UTF-32BE",@"UTF-32LE",
	@"ISO-8859-2",@"ISO-8859-5",@"ISO-8859-7",@"ISO-8859-8",@"ISO-8859-8-I",
	@"windows-1250",@"windows-1251",@"windows-1252",@"windows-1253",@"windows-1255",
	@"KOI8-R",@"Shift_JIS",@"EUC-JP",@"EUC-KR"/* actually CP949 */,@"x-euc-tw",
	@"ISO-2022-JP",@"ISO-2022-CN",@"ISO-2022-KR",
	@"Big5",@"GB2312",@"HZ-GB-2312",@"gb18030",@"GB18030",
	@"IBM855",@"IBM866",@"TIS-620",@"X-ISO-10646-UCS-4-2143",@"X-ISO-10646-UCS-4-3412",
	@"x-mac-cyrillic",@"x-mac-hebrew",
	nil];

	return array;
}

-(id)init
{
	if((self=[super init]))
	{
		detector=AllocUniversalDetector();
		charset=nil;
		lastcstring=NULL;
	}
	return self;
}

-(void)dealloc
{
	FreeUniversalDetector(detector);
	[charset release];
	[super dealloc];
}

-(void)analyzeData:(NSData *)data
{
	[self analyzeBytes:(const char *)[data bytes] length:(int)[data length]];
}

-(void)analyzeBytes:(const char *)data length:(int)len
{
	UniversalDetectorHandleData(detector,data,len);
}

-(void)reset { UniversalDetectorReset(detector); }

-(BOOL)done { return UniversalDetectorDone(detector); }

-(NSString *)MIMECharset
{
	const char *cstr=UniversalDetectorCharset(detector,&confidence);
	if(!cstr) return nil;

	// nsUniversalDetector detects CP949 but returns "EUC-KR" because CP949
	// lacks an IANA name. Kludge the name to make sure decoding succeeds.
	if(strcmp(cstr,"EUC-KR")==0) cstr="CP949";

	if(cstr!=lastcstring)
	{
		[charset release];
		charset=[[NSString alloc] initWithUTF8String:cstr];
		lastcstring=cstr;
	}

	return charset;
}

-(float)confidence
{
	if(!charset) [self MIMECharset];
	return confidence;
}

#ifdef __APPLE__
-(NSStringEncoding)encoding
{
	NSString *mimecharset=[self MIMECharset];
	if(!mimecharset) return 0;

	CFStringEncoding cfenc=CFStringConvertIANACharSetNameToEncoding((CFStringRef)mimecharset);
	if(cfenc==kCFStringEncodingInvalidId) return 0;

	return CFStringConvertEncodingToNSStringEncoding(cfenc);
}

#endif

@end
