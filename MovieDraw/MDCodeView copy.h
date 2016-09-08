//
//  MDCodeView.h
//  MovieDraw
//
//  Created by Neil Singh on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#include <vector>

#define MD_ERROR	1
#define MD_WARNING	2

typedef struct
{
	NSString* error;
	unsigned long long line;
	unsigned int type;
} MDError;

@interface MDCodeView : NSTextView
{
	BOOL waitForEdit;
	std::vector<NSRange> processed;
	std::vector<MDError> errors;
	NSMutableIndexSet* lineRanges;
}

- (void) setText:(NSString*)text;
- (void) processHighlight: (NSRange)range;
- (void) addError:(NSString*)error atLine:(unsigned long long)line type:(unsigned int)etype;
- (void) removeAllErrors;
- (std::vector<MDError>&) errors;
- (void) reloadLines;
- (BOOL) hasErrors;

@end
