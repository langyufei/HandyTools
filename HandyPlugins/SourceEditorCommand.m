//
//  SourceEditorCommand.m
//  HandyPlugins
//
//  Created by YUFEI LANG on 7/6/17.
//  Copyright © 2017 The Casey Group. All rights reserved.
//

#import "SourceEditorCommand.h"

@interface SourceEditorCommand()

@end

@implementation SourceEditorCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    if ([invocation.commandIdentifier isEqualToString:@"add-a-comment"])
    {
        [self addComment:invocation];
    }
    else if ([invocation.commandIdentifier isEqualToString:@"convert-to-dot-notation"])
    {
        [self convertToDotNotation:invocation];
    }
    
    completionHandler(nil);
}

- (void)addComment:(XCSourceEditorCommandInvocation *)invocation
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MMM d''yy<#@H:mm#>"; // Aug 24'16@15:33
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    if (invocation.buffer.selections.count > 0)
    {
        NSString *comment = [NSString stringWithFormat:@"// <#comment#> [yufei %@]", dateString];
        
        XCSourceTextBuffer *buffer = invocation.buffer;
        XCSourceTextRange *firstTxtRange = [buffer.selections firstObject];
        XCSourceTextRange *lastTxtRange = [buffer.selections lastObject];
        
        // normally just insertion point - no text select
        if (firstTxtRange.start.line == lastTxtRange.end.line && firstTxtRange.start.column == lastTxtRange.end.column)
        {
            NSRange rangeAtInsertionPt = NSMakeRange(firstTxtRange.start.column, 0);
            NSString *insertionLine = buffer.lines[firstTxtRange.start.line];
            NSString *updatedLine = [insertionLine stringByReplacingCharactersInRange:rangeAtInsertionPt withString:comment];
            buffer.lines[firstTxtRange.start.line] = updatedLine;
            
            XCSourceTextPosition updatedStartPos = XCSourceTextPositionMake(firstTxtRange.start.line, firstTxtRange.start.column + 3); // + 3 is for '// '
            XCSourceTextPosition updatedEndPos = XCSourceTextPositionMake(firstTxtRange.start.line, updatedStartPos.column + @"<#comment#>".length);
            XCSourceTextRange *updatedTxtRange = [[XCSourceTextRange alloc] initWithStart:updatedStartPos end:updatedEndPos];
            buffer.selections[0] = updatedTxtRange;
        }
        // have some text selecteds
        else
        {
            NSString *stringAt1stLines = buffer.lines[firstTxtRange.start.line];
            
            NSMutableCharacterSet *noneWhitespaceCharSet = [NSMutableCharacterSet whitespaceCharacterSet];
            [noneWhitespaceCharSet addCharactersInRange:NSMakeRange((unsigned int)'\t', 1)];
            [noneWhitespaceCharSet invert];
            
            NSRange firstCharRange = [stringAt1stLines rangeOfCharacterFromSet:noneWhitespaceCharSet options:0];
            if (firstCharRange.location != NSNotFound)
            {
                NSUInteger numberOfWhitespace = 0;
                NSString *stringBefore1stLetter = [stringAt1stLines substringToIndex:firstCharRange.location];
                for (NSUInteger idx = 0; idx < stringBefore1stLetter.length; idx++) {
                    numberOfWhitespace += ([stringBefore1stLetter characterAtIndex:idx] == '\t') ? 4 : 1; // deal with 'tab' symbol
                }
                
                NSMutableString *whiteSpaces = [NSMutableString string];
                for (NSUInteger i = 0; i < numberOfWhitespace; i++) {
                    [whiteSpaces appendString:@" "];
                }
                
                NSString *firstCommentLine = [NSString stringWithFormat:@"%@/* <#comment#> [yufei %@]\n", whiteSpaces, dateString];
                NSString *secondCommentLine = [NSString stringWithFormat:@"%@ *\n", whiteSpaces];
                NSString *lastCommentLine = [NSString stringWithFormat:@"%@ */\n", whiteSpaces];
                
                NSUInteger beginningLine = firstTxtRange.start.line;
                NSUInteger endingLine = lastTxtRange.end.column > 0 ? lastTxtRange.end.line + 3: lastTxtRange.end.line + 2;
                [buffer.lines insertObject:firstCommentLine atIndex:beginningLine];
                [buffer.lines insertObject:secondCommentLine atIndex:beginningLine + 1];
                [buffer.lines insertObject:lastCommentLine atIndex:endingLine];
                
                NSRange rangeOfComment = [firstCommentLine rangeOfString:@"<#comment#>"];
                XCSourceTextPosition updatedStartPos = XCSourceTextPositionMake(firstTxtRange.start.line, rangeOfComment.location);
                XCSourceTextPosition updatedEndPos = XCSourceTextPositionMake(firstTxtRange.start.line, updatedStartPos.column + @"<#comment#>".length);
                XCSourceTextRange *updatedTxtRange = [[XCSourceTextRange alloc] initWithStart:updatedStartPos end:updatedEndPos];
                buffer.selections[0] = updatedTxtRange;
            }
        }
    }
}

- (void)convertToDotNotation:(XCSourceEditorCommandInvocation *)invocation
{
    NSArray *selectedRanges = [textView selectedRanges];
    if (selectedRanges.count > 0)
    {
        /* this is a comment [yufei]
         *
         NSRange range = [[selectedRanges firstObject] rangeValue];
         NSRange lineRange = [textView.textStorage.string lineRangeForRange:range];
         NSString *line = [textView.textStorage.string substringWithRange:lineRange];
         */
        
        NSRange range = [[selectedRanges firstObject] rangeValue];
        NSRange lineRange = [textView.textStorage.string lineRangeForRange:range];
        NSString *line = [textView.textStorage.string substringWithRange:lineRange];
        
        NSString *dotNotationRegex = @".*[.].*[ ]{0,}=[ ]{0,}.*[ ]{0,}\\;";
        NSString *messageNotationRegex = @"\\[[ ]{0,}(.*)\\sset(.*?)[ ]{0,}\\:[ ]{0,}(.*)\\]\\;";
        
        NSRegularExpression *dotNotationRex = [[NSRegularExpression alloc] initWithPattern:dotNotationRegex options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *dotNotationMatches = [dotNotationRex matchesInString:line options:0 range:NSMakeRange(0, line.length)];
        
        NSRegularExpression *MsgNotationRegex = [[NSRegularExpression alloc] initWithPattern:messageNotationRegex options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *msgNotationMatches = [MsgNotationRegex matchesInString:line options:0 range:NSMakeRange(0, line.length)];
        
        NSInteger addedLength = 0;
        
        for (NSTextCheckingResult *result in msgNotationMatches)
        {
            NSRange matchedRangeInLine = result.range;
            NSRange matchedRangeInDocument = NSMakeRange(lineRange.location + matchedRangeInLine.location + addedLength, matchedRangeInLine.length);
            NSString *string = [line substringWithRange:matchedRangeInLine];
            
            NSString *receiver = [line substringWithRange:[result rangeAtIndex:1]];
            NSString *property = [line substringWithRange:[result rangeAtIndex:2]];
            NSString *newValue = [line substringWithRange:[result rangeAtIndex:3]];
            
            if ([self isRange:matchedRangeInLine inSkipedRanges:dotNotationMatches]) {
                continue;
            }
            
            NSString *lowerCasePropertyFirstLetter = [[[property substringToIndex:1] lowercaseString] stringByAppendingString:[property substringFromIndex:1]];
            NSString *outputString = [NSString stringWithFormat:@"%@.%@ = %@;", receiver, lowerCasePropertyFirstLetter, newValue];
            
            addedLength = addedLength + outputString.length - string.length;
            
            if ([textView shouldChangeTextInRange:matchedRangeInDocument replacementString:outputString])
            {
                [textView.textStorage replaceCharactersInRange:matchedRangeInDocument withAttributedString:[[NSAttributedString alloc] initWithString:outputString]];
                [textView didChangeText];
            }
        }
    }
}

- (BOOL)isRange:(NSRange)range inSkipedRanges:(NSArray *)ranges
{
    for (int i = 0; i < [ranges count]; i++)
    {
        NSTextCheckingResult *result = [ranges objectAtIndex:i];
        NSRange skippedRange = result.range;
        
        if (skippedRange.location <= range.location && skippedRange.location + skippedRange.length > range.location + range.length)
        {
            return YES;
        }
    }
    
    return NO;
}

@end
