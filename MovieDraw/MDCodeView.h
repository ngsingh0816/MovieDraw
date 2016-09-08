//
//  MDCodeView.h
//  MovieDraw
//
//  Created by Neil Singh on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <vector>

#define MD_ERROR	1
#define MD_WARNING	2

unsigned long long PositionAfterSpaces(unsigned long long index, NSString* string, BOOL any);
unsigned long long PositionAfterSpacesAndComments(unsigned long long index, NSString* string, BOOL any);
unsigned long long PositionBeforeSpaces(unsigned long long index, NSString* string, BOOL any);
NSString* WordFromIndex(unsigned long long index, NSString* str);
NSString* ValueFromIndex(unsigned long long index, NSString* str);

@class MDCodeView;

typedef struct
{
	NSString* error;
	unsigned long long line;
	unsigned int type;
} MDError;

@interface MDAutoComplete : NSView {
	NSMutableArray* variables;
	NSMutableArray* methods;
	NSString* keyword;
	NSString* keyword2;
	NSString* classType;
	BOOL visible;
	unsigned long selected;
	unsigned long lastDrawNumber;
	float scroll;
	float maxScroll;
	float rowHeight;
	BOOL method;
	MDCodeView* codeView;
	BOOL useBoth;
	NSArray* matchesWithFunction;
	NSArray* matchesWithoutFunction;
}

- (void) addVariable:(NSString*)var;
@property (readonly, copy) NSMutableArray *variables;
- (void) setKeyword:(NSString*)word;
- (void) setClassType: (NSString*)word withData:(NSArray*)data andNames:(NSArray*)names hasDot:(BOOL)dot;
@property (readonly, copy) NSString *classType;
@property (readonly, copy) NSString *keyWord;
@property  BOOL visible;
@property  unsigned long selectedIndex;
@property (readonly, copy) NSString *selectedItem;
@property (readonly) unsigned long long numberOfMatches;
@property (readonly, copy) NSArray *matches;
@property  BOOL hasClassType;
@property (strong) MDCodeView *codeView;
- (void) setUseBoth: (BOOL)use keyWord:(NSString*)key;
@property (readonly) BOOL useBoth;
- (void) fillMatch: (unsigned long long)autoStart fullComplete:(BOOL)full;
@property (readonly, copy) NSString *trueKeyword;
- (NSArray*) matches: (BOOL)withFunction;

@end

typedef struct
{
	NSString* name;
	NSString* type;
	NSString* document;
	unsigned long long line;
} CodeVariable;

typedef struct
{
	unsigned long long position;
	NSString* text;
} AutoCompleteBlock;

typedef NS_ENUM(int, MDLanguage)
{
	MD_OBJ_C = 0,
	MD_JAVASCRIPT,
};

@interface MDCodeView : NSTextView
{
	BOOL waitForEdit;
	std::vector<NSRange> processed;
	std::vector<MDError> errors;
	std::vector<NSRange> lineRanges;
	MDAutoComplete* completeView;
	unsigned long long autoStart;
	BOOL inObjCCommand;
	NSMutableString* msgSender;
	NSMutableArray* included;
	std::vector<CodeVariable> variables;
	std::vector<CodeVariable> globalVariables;
	std::vector<AutoCompleteBlock> completeBlocks;
	unsigned long long selectedBlock;
	NSMutableArray* classNames;
	NSMutableArray* classData;
	BOOL readingDocs;
	NSString* fileName;
	BOOL loading;
	unsigned long depthIn;
	NSThread* loadingThread;
	std::vector<unsigned long> breakpoints;
	std::vector<float> lineHeights;
	unsigned long executionLine;
	BOOL enableBreaks;
	id breakTarget;
	SEL breakPointEdited;
	BOOL updateBreaks;
	NSMutableArray* numberArray;
	BOOL updateHighlight;
	BOOL edited;
	MDLanguage language;
	
	id variableTarget;
	SEL variableRequested;
	SEL variableUpdated;
	NSString* variableString;
	NSPoint variablePoint;
	BOOL showVariable;
	NSTimer* variableTimer;
	NSSize variableSize;
}

- (void) setup;
- (void) setText:(NSString*)text;
- (void) processHighlight: (NSRange)range;
- (void) addError:(NSString*)error atLine:(unsigned long long)line type:(unsigned int)etype;
- (void) removeAllErrors;
@property (readonly) std::vector<MDError> & errors;
- (void) reloadLines;
@property (readonly) BOOL hasErrors;
- (void) textStorageDidProcessEditing:(NSNotification*)notification;
- (void) checkMessage;
- (void) parseRegion: (NSRange)range usingString:(NSString*)string;
- (void) parseRegion: (NSRange)range usingString:(NSString*)string shouldString:(BOOL)shouldStr;
- (void) readDocuments;
@property (readonly) unsigned long long autoStart;
- (void) jumpToDefinition;
- (void) addCompleteBlock:(AutoCompleteBlock*)block;
@property (readonly) unsigned long long numberOfBlocks;
- (void) setSelectedBlock:(unsigned long long)block;
@property (copy) NSString *fileName;
- (void) removeComments:(NSMutableString*)string;
@property (readonly) BOOL loading;
@property  unsigned long executionLine;
- (void) setBreakpoints:(std::vector<unsigned long>) breaks;
- (std::vector<unsigned long>&) breakpoints;
@property  BOOL enableBreaks;
@property (strong) id breakTarget;
@property  SEL breakPointAction;
@property (strong) id variableTarget;
@property  SEL variableAction;
- (void) checkVariableSecond;
- (void) requestVariable:(NSString*)varName;
@property (copy) NSString *variableString;
- (void) setVariableUpdated:(SEL)act;
@property (readonly) SEL variableUpdatedAction;
- (void) updateVariable:(NSString*)varName value:(NSString*)varValue;
@property  BOOL edited;
@property (readonly) BOOL editedNoReset;
@property  MDLanguage language;

@end
