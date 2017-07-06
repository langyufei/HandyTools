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
        NSLog(@"Lines are: \n%@", invocation.buffer.lines);
        NSLog(@"Selections are: \n%@", invocation.buffer.selections);
    }
    
    completionHandler(nil);
}

- (void)addComment:(XCSourceEditorCommandInvocation *)invocation
{
    if (invocation.buffer.selections.count > 0)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"MMM d''yy<#@H:mm#>"; // Aug 24'16@15:33
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        NSString *comment = [NSString stringWithFormat:@"// <#comment#> [yufei %@]", dateString];
        
        XCSourceTextBuffer *buffer = invocation.buffer;
        XCSourceTextRange *firstTxtRange = [buffer.selections firstObject];
        
        // normally just insertion point - no text select
        if (firstTxtRange.start.line == firstTxtRange.end.line && firstTxtRange.start.column == firstTxtRange.end.column)
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
            
        }
        
//        NSRange selectedRange = ((NSValue *)[[textView selectedRanges] firstObject]).rangeValue;
//        NSUInteger insertionPoint = selectedRange.location;
//        NSUInteger selectedTextLenght = selectedRange.length;
//        
//        if (selectedTextLenght > 0) // have text selected
//        {
//            NSRange lineRange = [textView.textStorage.string lineRangeForRange:selectedRange];
//            NSString *stringAtLines = [textView.textStorage.string substringWithRange:lineRange];
//            
//            NSMutableCharacterSet *noneWhitespaceCharSet = [NSMutableCharacterSet whitespaceCharacterSet];
//            [noneWhitespaceCharSet addCharactersInRange:NSMakeRange((unsigned int)'\t', 1)];
//            [noneWhitespaceCharSet invert];
//            
//            NSRange firstCharRange = [stringAtLines rangeOfCharacterFromSet:noneWhitespaceCharSet options:0];
//            if (firstCharRange.location != NSNotFound)
//            {
//                NSUInteger numberOfWhitespace = 0;
//                NSString *stringBefore1stLetter = [stringAtLines substringToIndex:firstCharRange.location];
//                for (NSUInteger idx = 0; idx < stringBefore1stLetter.length; idx++) {
//                    numberOfWhitespace += ([stringBefore1stLetter characterAtIndex:idx] == '\t') ? 4 : 1; // deal with 'tab' symbol
//                }
//                
//                NSMutableString *whiteSpaces = [NSMutableString string];
//                for (NSUInteger i = 0; i < numberOfWhitespace; i++) {
//                    [whiteSpaces appendString:@" "];
//                }
//                NSMutableString *newString = [[NSMutableString alloc] initWithFormat:@"%@/* <#comment#> [yufei %@]\n%@ *\n%@%@ */\n", whiteSpaces, dateString, whiteSpaces, stringAtLines, whiteSpaces];
//                if ([textView shouldChangeTextInRange:lineRange replacementString:newString])
//                {
//                    [textView.textStorage replaceCharactersInRange:lineRange withAttributedString:[[NSAttributedString alloc] initWithString:newString]];
//                    [textView setSelectedRange:NSMakeRange(lineRange.location + whiteSpaces.length + 3, @"<#comment#>".length)];
//                    [textView didChangeText];
//                }
//            }
//        }
//        else
//        {
//            if ([textView shouldChangeTextInRange:NSMakeRange(insertionPoint, 0) replacementString:comment])
//            {
//                [textView.textStorage insertAttributedString:[[NSAttributedString alloc] initWithString:comment] atIndex:insertionPoint];
//                [textView setSelectedRange:NSMakeRange(insertionPoint + 3, @"<#comment#>".length)];
//                [textView didChangeText];
//            }
//        }
    }
}

@end
