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

#import <KVO-MVVM/KVOUIControl.h>

#import "DWSeedPhraseType.h"

NS_ASSUME_NONNULL_BEGIN

extern NSTimeInterval const DW_VERIFY_APPEAR_ANIMATION_DURATION;

@class DWSeedWordModel;

@interface DWSeedWordView : KVOUIControl

@property (nullable, nonatomic, strong) DWSeedWordModel *model;

- (instancetype)initWithType:(DWSeedPhraseType)type NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (void)animateDiscardedSelectionWithCompletion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
