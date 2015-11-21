//
//  ViewController.m
//  openglesinc
//
//  Created by Harold Serrano on 2/9/15.
//  Copyright (c) 2015 www.roldie.com. All rights reserved.
//

#import "ViewController.h"
#include "Character.h"
#include "Button.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //1, Allocate a EAGLContext object and initialize a context with a specific version.
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //2. Check if the context was successful
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    //3. Set the view's context to the newly created context
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    glViewport(0, 0, view.frame.size.height, view.frame.size.width);
    
    //4. This will call the rendering method glkView 60 Frames per second
    view.enableSetNeedsDisplay=60.0;
    
    //5. Make the newly created context the current context.
    [EAGLContext setCurrentContext:self.context];
    
    //6. create a Character class instance
    //Note, since the ios device will be rotated, the input parameters of the character constructor
    //are swapped.
    character=new Character(self.view.bounds.size.height,self.view.bounds.size.width);
    
    //7. Begin the OpenGL setup for the character
    character->setupOpenGL();
    
    //8. create an instance (buttonA) of the button class
    buttonA=new Button(80,740,100.0,100.0,"ButtonA.png","ButtonAPressed.png",self.view.bounds.size.height,self.view.bounds.size.width);
    
    //9. set the vertex and UV coordinates for the button
    buttonA->setButtonVertexAndUVCoords();
    
    //10. begin the OpenGL setup for the button
    buttonA->setupOpenGL();
    
    //11. create an instance (buttonB) of the button class
    buttonB=new Button(680,740,100.0,100.0,"ButtonB.png","ButtonBPressed.png",self.view.bounds.size.height,self.view.bounds.size.width);
    
    //12.set the vertex and UV coordinates for the buttonB
    buttonB->setButtonVertexAndUVCoords();
    
    //13. begin the OpenGL setup for the buttonB
    buttonB->setupOpenGL();
    
    currentXTouchPoint=0.0;
    currentYTouchPoint=0.0;
    
    touchBegan=false;
    
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    //1. test if the touch falls within the coordinates of the button
    if (touchBegan==true) {
        
        //2. update the button with the current touch position
        buttonA->update(currentXTouchPoint, currentYTouchPoint);
        buttonB->update(currentXTouchPoint, currentYTouchPoint);
        
        //3. test if the touch falls within the coordinates of the buttonA
        if(buttonA->getButtonIsPress()==true){

        //4. update the character to rotate clockwise
            character->update(0.1);
        
        }

        //5. test if the touch falls within the coordinates of the buttonB
        if(buttonB->getButtonIsPress()==true){
            
        //6. update the character to rotate counter-clockwise
            character->update(-0.1);
            
        }
        
    }
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //1. Clear the color to black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    
    //2. Clear the color buffer and depth buffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //3. Render the buttons
    buttonA->draw();
    buttonB->draw();
    
    //3. Render the character
    character->draw();
    
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    for (UITouch *myTouch in touches) {
        CGPoint touchPosition = [myTouch locationInView: [myTouch view]];
        
        touchBegan=true;
       
        float xPoint=(touchPosition.x-self.view.bounds.size.width/2)/(self.view.bounds.size.width/2);
        float yPoint=(self.view.bounds.size.height/2-touchPosition.y)/(self.view.bounds.size.height/2);
        
        currentXTouchPoint=xPoint;
        currentYTouchPoint=yPoint;
        
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
    for (UITouch *myTouch in touches) {
        CGPoint touchPosition = [myTouch locationInView: [myTouch view]];
        
        touchBegan=false;
        currentXTouchPoint=0.0;
        currentYTouchPoint=0.0;
        
    }
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    for (UITouch *myTouch in touches) {
        CGPoint touchPosition = [myTouch locationInView: [myTouch view]];
        
        
    }
}

- (void)dealloc
{
    //call teardown
    character->teadDownOpenGL();
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    [_context release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        //call teardown
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
    
    // Dispose of any resources that can be recreated.
}



@end
