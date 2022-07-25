//
//  ApplicationRunLoop.h
//  FaizMeuLambda
//
//  Created by Júlio César Flores on 24/07/2022.
//

#pragma once

@import Foundation;

typedef void (^ _Nonnull ApplicationExecution)(void);

@interface ApplicationRunLoop: NSObject

-(_Nonnull instancetype)init;
-(void)execute:(ApplicationExecution)block;
-(void)stop;

@end
