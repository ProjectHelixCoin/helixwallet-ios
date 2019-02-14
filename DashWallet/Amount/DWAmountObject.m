//
//  Created by Andrew Podkovyrin
//  Copyright © 2019 Dash Core Group. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "DWAmountObject.h"

#import <DashSync/DSPriceManager.h>
#import <DashSync/NSString+Dash.h>

NS_ASSUME_NONNULL_BEGIN

static CGSize const DashSymbolBigSize = {24.07, 19.0};
static CGSize const DashSymbolSmallSize = {12.67, 10.0};

@implementation DWAmountObject

- (instancetype)initWithDashAmountString:(NSString *)dashAmountString {
    self = [super init];
    if (self) {
        _amountInternalRepresentation = [dashAmountString copy];

        if (dashAmountString.length == 0) {
            dashAmountString = @"0";
        }

        NSDecimalNumber *dashNumber = [NSDecimalNumber decimalNumberWithString:dashAmountString locale:[NSLocale currentLocale]];
        NSParameterAssert(dashNumber);
        NSDecimalNumber *duffsNumber = (NSDecimalNumber *)[NSDecimalNumber numberWithLongLong:DUFFS];
        int64_t plainAmount = [dashNumber decimalNumberByMultiplyingBy:duffsNumber].longLongValue;
        _plainAmount = plainAmount;

        DSPriceManager *priceManager = [DSPriceManager sharedInstance];
        NSString *dashFormatted = [priceManager.dashFormat stringFromNumber:dashNumber];

        _dashFormatted = [self.class formattedAmountWithInputString:dashAmountString
                                                    formattedString:dashFormatted
                                                    numberFormatter:priceManager.dashFormat];
        _localCurrencyFormatted = [priceManager localCurrencyStringForDashAmount:plainAmount];

        _dashAttributedString = [_dashFormatted attributedStringForDashSymbolWithTintColor:[UIColor whiteColor] dashSymbolSize:DashSymbolBigSize];
        _localCurrencyAttributedString = [self.class attributedStringForLocalCurrencyFormatted:_localCurrencyFormatted];
    }
    return self;
}

- (nullable instancetype)initWithLocalAmountString:(NSString *)localAmountString {
    self = [super init];
    if (self) {
        _amountInternalRepresentation = [localAmountString copy];

        if (localAmountString.length == 0) {
            localAmountString = @"0";
        }

        NSDecimalNumber *localNumber = [NSDecimalNumber decimalNumberWithString:localAmountString locale:[NSLocale currentLocale]];
        NSParameterAssert(localNumber);

        DSPriceManager *priceManager = [DSPriceManager sharedInstance];
        NSAssert(priceManager.localCurrencyDashPrice, @"Prices should be loaded");
        NSString *localCurrencyFormatted = [priceManager.localFormat stringFromNumber:localNumber];
        uint64_t plainAmount = [priceManager amountForLocalCurrencyString:localCurrencyFormatted];
        if (plainAmount == 0 && ![localNumber isEqual:NSDecimalNumber.zero]) {
            return nil;
        }

        _plainAmount = plainAmount;
        _dashFormatted = [priceManager stringForDashAmount:plainAmount];
        _localCurrencyFormatted = [self.class formattedAmountWithInputString:localAmountString
                                                             formattedString:localCurrencyFormatted
                                                             numberFormatter:priceManager.localFormat];
        _dashAttributedString = [_dashFormatted attributedStringForDashSymbolWithTintColor:[UIColor whiteColor] dashSymbolSize:DashSymbolSmallSize];
        _localCurrencyAttributedString = [self.class attributedStringForLocalCurrencyFormatted:_localCurrencyFormatted];
    }
    return self;
}

- (instancetype)initAsLocalWithPreviousAmount:(DWAmountObject *)previousAmount {
    self = [super init];
    if (self) {
        _plainAmount = previousAmount.plainAmount;
        _amountInternalRepresentation = [self.class rawAmountStringFromFormattedString:previousAmount.localCurrencyFormatted];
        _dashFormatted = [previousAmount.dashFormatted copy];
        _localCurrencyFormatted = [previousAmount.localCurrencyFormatted copy];
        _dashAttributedString = [_dashFormatted attributedStringForDashSymbolWithTintColor:[UIColor whiteColor] dashSymbolSize:DashSymbolSmallSize];
        _localCurrencyAttributedString = previousAmount.localCurrencyAttributedString;
    }
    return self;
}

- (instancetype)initAsDashWithPreviousAmount:(DWAmountObject *)previousAmount {
    self = [super init];
    if (self) {
        _plainAmount = previousAmount.plainAmount;
        _amountInternalRepresentation = [self.class rawAmountStringFromFormattedString:previousAmount.dashFormatted];
        _dashFormatted = [previousAmount.dashFormatted copy];
        _localCurrencyFormatted = [previousAmount.localCurrencyFormatted copy];
        _dashAttributedString = [_dashFormatted attributedStringForDashSymbolWithTintColor:[UIColor whiteColor] dashSymbolSize:DashSymbolBigSize];
        _localCurrencyAttributedString = previousAmount.localCurrencyAttributedString;
    }
    return self;
}

#pragma mark - Private

+ (NSAttributedString *)attributedStringForLocalCurrencyFormatted:(NSString *)localCurrencyFormatted {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:localCurrencyFormatted];
    NSLocale *locale = [NSLocale currentLocale];
    NSString *decimalSeparator = locale.decimalSeparator;
    NSString *insufficientFractionDigits = [NSString stringWithFormat:@"%@00", decimalSeparator];
    NSRange insufficientFractionDigitsRange = [localCurrencyFormatted rangeOfString:insufficientFractionDigits];
    NSDictionary *defaultAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    [attributedString beginEditing];
    if (insufficientFractionDigitsRange.location != NSNotFound) {
        if (insufficientFractionDigitsRange.location > 0) {
            NSRange beforeFractionRange = NSMakeRange(0, insufficientFractionDigitsRange.location);
            [attributedString setAttributes:defaultAttributes range:beforeFractionRange];
        }
        [attributedString setAttributes:@{ NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.5] }
                                  range:insufficientFractionDigitsRange];
        NSUInteger afterFractionIndex = insufficientFractionDigitsRange.location + insufficientFractionDigitsRange.length;
        if (afterFractionIndex < localCurrencyFormatted.length) {
            NSRange afterFractionRange = NSMakeRange(afterFractionIndex, localCurrencyFormatted.length - afterFractionIndex);
            [attributedString setAttributes:defaultAttributes range:afterFractionRange];
        }
    }
    else {
        [attributedString setAttributes:defaultAttributes
                                  range:NSMakeRange(0, localCurrencyFormatted.length)];
    }
    [attributedString endEditing];

    return [attributedString copy];
}

+ (NSString *)rawAmountStringFromFormattedString:(NSString *)formattedString {
    NSLocale *locale = [NSLocale currentLocale];
    NSString *decimalSeparator = locale.decimalSeparator;
    NSMutableCharacterSet *allowedCharacterSet = [NSMutableCharacterSet decimalDigitCharacterSet];
    [allowedCharacterSet addCharactersInString:decimalSeparator];

    NSString *result = [[formattedString componentsSeparatedByCharactersInSet:[allowedCharacterSet invertedSet]]
        componentsJoinedByString:@""];

    NSDecimalNumber *decimalNumber = [NSDecimalNumber decimalNumberWithString:result locale:locale];
    if ([decimalNumber isEqual:NSDecimalNumber.zero]) { // edge case
        result = @"0";
    }

    return result;
}

+ (NSString *)formattedAmountWithInputString:(NSString *)inputString
                             formattedString:(NSString *)formattedString
                             numberFormatter:(NSNumberFormatter *)numberFormatter {
    NSAssert(numberFormatter.numberStyle == NSNumberFormatterCurrencyStyle, @"Invalid number formatter");

    NSString *decimalSeparator = [NSLocale currentLocale].decimalSeparator;
    NSAssert([numberFormatter.decimalSeparator isEqualToString:decimalSeparator], @"Custom decimal separators are not supported");
    NSUInteger inputSeparatorIndex = [inputString rangeOfString:decimalSeparator].location;
    if (inputSeparatorIndex == NSNotFound) {
        return formattedString;
    }

    NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    NSRange currencySymbolRange = [formattedString rangeOfString:numberFormatter.currencySymbol];
    NSAssert(currencySymbolRange.location != NSNotFound, @"Invalid formatted string");

    BOOL isCurrencySymbolAtTheBeginning = currencySymbolRange.location == 0;
    NSString *currencySymbolNumberSeparator = nil;
    if (isCurrencySymbolAtTheBeginning) {
        currencySymbolNumberSeparator = [formattedString substringWithRange:NSMakeRange(currencySymbolRange.length, 1)];
    }
    else {
        currencySymbolNumberSeparator = [formattedString substringWithRange:NSMakeRange(currencySymbolRange.location - 1, 1)];
    }
    if ([currencySymbolNumberSeparator rangeOfCharacterFromSet:whitespaceCharacterSet].location == NSNotFound) {
        currencySymbolNumberSeparator = @"";
    }

    NSString *formattedStringWithoutCurrency =
        [[formattedString stringByReplacingCharactersInRange:currencySymbolRange withString:@""]
            stringByTrimmingCharactersInSet:whitespaceCharacterSet];

    NSString *inputFractionPartWithSeparator = [inputString substringFromIndex:inputSeparatorIndex];
    NSUInteger formattedSeparatorIndex = [formattedStringWithoutCurrency rangeOfString:decimalSeparator].location;
    if (formattedSeparatorIndex == NSNotFound) {
        formattedSeparatorIndex = formattedStringWithoutCurrency.length;
        formattedStringWithoutCurrency = [formattedStringWithoutCurrency stringByAppendingString:decimalSeparator];
    }
    NSRange formattedFractionPartRange = NSMakeRange(formattedSeparatorIndex, formattedStringWithoutCurrency.length - formattedSeparatorIndex);

    NSString *formattedStringWithFractionInput = [formattedStringWithoutCurrency stringByReplacingCharactersInRange:formattedFractionPartRange withString:inputFractionPartWithSeparator];

    NSString *result = nil;
    if (isCurrencySymbolAtTheBeginning) {
        result = [NSString stringWithFormat:@"%@%@%@",
                                            numberFormatter.currencySymbol,
                                            currencySymbolNumberSeparator,
                                            formattedStringWithFractionInput];
    }
    else {
        result = [NSString stringWithFormat:@"%@%@%@",
                                            formattedStringWithFractionInput,
                                            currencySymbolNumberSeparator,
                                            numberFormatter.currencySymbol];
    }

    return result;
}

@end

NS_ASSUME_NONNULL_END
