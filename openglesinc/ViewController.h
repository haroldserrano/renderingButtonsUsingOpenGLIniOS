//
//  ViewController.h
//  openglesinc
//
//  Created by Harold Serrano on 2/9/15.
//  Copyright (c) 2015 www.roldie.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#include "Character.h"
#include "Button.h"


@interface ViewController : GLKViewController{
    
    Character* character;
    Button* buttonA;
    Button* buttonB;
    
    float currentXTouchPoint;
    float currentYTouchPoint;
    
    bool touchBegan;
}

@property (strong, nonatomic) EAGLContext *context;

@end
