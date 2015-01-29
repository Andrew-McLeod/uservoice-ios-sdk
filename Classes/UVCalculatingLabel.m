 //
//  UVCalculatingLabel.m
//  UserVoice
//
//  Created by Austin Taylor on 12/4/12.
//  Copyright (c) 2012 UserVoice Inc. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "UVCalculatingLabel.h"
#import "UVDefines.h"
#import "UVUtils.h"

@implementation UVCalculatingLabel

- (CGRect)rectForLetterAtIndex:(NSUInteger)index lines:(NSArray *)lines width:(CGFloat)frameWidth {
    if (index > [self.text length] - 1)
        return CGRectZero;

    NSString *letter = [self.text substringWithRange:NSMakeRange(index, 1)];
    CGSize letterSize = [UVUtils string:letter sizeWithFont:self.font];

    int targetLineNumber = 0, targetColumnNumber = 0, elapsedChars = 0;
    NSString *targetLine = nil;
    for (int i = 0; i < [lines count]; i++) {
        NSString *line = [lines objectAtIndex:i];
        if (index >= elapsedChars + [line length]) {
            elapsedChars += [line length];
            targetLineNumber++;
        } else {
            targetLine = line;
            targetColumnNumber = (int)index - elapsedChars;
            break;
        }
    }

    int linesThatFit = (int)floor(self.frame.size.height / self.font.lineHeight);
    int totalLines = (int)(self.numberOfLines == 0 ? [lines count] : MIN([lines count], self.numberOfLines));
    int linesDisplayed = MIN(linesThatFit, totalLines);
    CGFloat targetLineWidth = [UVUtils string:targetLine sizeWithFont:self.font].width;
    
    CGFloat x = [UVUtils string:[targetLine substringWithRange:NSMakeRange(0, targetColumnNumber)] sizeWithFont:self.font].width;
    CGFloat y = self.frame.size.height/2 - (linesDisplayed*self.font.lineHeight)/2 + self.font.lineHeight*targetLineNumber;
    
    if (self.textAlignment == NSTextAlignmentCenter)
        x = x + (frameWidth-targetLineWidth)/2;
    else if (self.textAlignment == NSTextAlignmentCenter)
        x = frameWidth-(targetLineWidth-x);
    
    return CGRectMake(x, y, letterSize.width, letterSize.height);
}

- (NSArray *)breakString:(CGFloat)frameWidth {
    NSMutableArray *lines = [NSMutableArray array];
    NSAttributedString *s = [[NSAttributedString alloc]
                             initWithString:self.text
                             attributes:@{NSFontAttributeName:self.font}];

    if (IOS7) {
        // >= iOS7 - use NSLayoutManager to determine lines that fit within frameWidth
        NSTextContainer* tc = [[NSTextContainer alloc] initWithSize:CGSizeMake(frameWidth,CGFLOAT_MAX)];
        NSLayoutManager* lm = [NSLayoutManager new];
        NSTextStorage* tm = [[NSTextStorage alloc] initWithAttributedString:s];
        [tm addLayoutManager:lm];
        [lm addTextContainer:tc];
        [lm enumerateLineFragmentsForGlyphRange:NSMakeRange(0,lm.numberOfGlyphs)
                                     usingBlock:^(CGRect rect, CGRect usedRect,
                                                  NSTextContainer *textContainer,
                                                  NSRange glyphRange, BOOL *stop) {
                                         NSRange r = [lm characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];
                                         [lines addObject:[s.string substringWithRange:r]];
                                     }];
    } else {
        // Use CoreText instead to find lines that fit in frameWidth
        CTFramesetterRef fs =
        CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)s);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0,0,frameWidth,CGFLOAT_MAX));
        CTFrameRef f = CTFramesetterCreateFrame(fs, CFRangeMake(0, 0), path, NULL);
        CTFrameDraw(f, NULL);

        NSArray* ctlines = (__bridge NSArray*)CTFrameGetLines(f);
        for (id aLine in ctlines) {
            CTLineRef theLine = (__bridge CTLineRef)aLine;
            CFRange range = CTLineGetStringRange(theLine);
            NSRange r = NSMakeRange(range.location, range.length);
            [lines addObject:[s.string substringWithRange:r]];
        }
        CGPathRelease(path);
        CFRelease(f);
        CFRelease(fs);
    }

    return lines;
}

@end
