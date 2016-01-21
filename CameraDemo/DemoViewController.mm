/*

  The MIT License (MIT)

  Copyright (c) 2016 VISUEM LTD

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

*/

#import "DemoViewController.h"
#import "RenderManager.h"
#import "CaptureManager.h"

@interface DemoViewController ()
{
        RenderManager       *mRenderManager;
        CaptureManager      *mCaptureManager;
}
@property (strong, nonatomic) EAGLContext *mGLContext;

@end

@implementation DemoViewController

/*
        Destructor */
- (void) dealloc
{
        [EAGLContext setCurrentContext:self.mGLContext];
        [mCaptureManager cleanUp];
        delete mRenderManager;
        [EAGLContext setCurrentContext:nil];
}

/*
        Derived from UIViewController        */
- (void) viewDidLoad
{
        [super viewDidLoad];

        self.mGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!self.mGLContext)
        {
        // TODO: Handle Error
        }

        GLKView *view = (GLKView *)self.view;
        view.context = self.mGLContext;
        view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

        [EAGLContext setCurrentContext:self.mGLContext];
        mRenderManager = new RenderManager();
        mCaptureManager = [[CaptureManager alloc] initWithContext:self.mGLContext];
}

/*
        Derived from UIViewController        */
- (void) didReceiveMemoryWarning
{
        [super didReceiveMemoryWarning];

        if ([self isViewLoaded] && ([[self view] window] == nil))
        {
                self.view = nil;

                [EAGLContext setCurrentContext:self.mGLContext];
                [mCaptureManager cleanUp];
                delete mRenderManager;
                [EAGLContext setCurrentContext:nil];
        }
}

/*
        Derived from UIViewController        */
- (BOOL) prefersStatusBarHidden
{
        return YES;
}

/*
        Derived from UIViewController        */
- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
        return UIInterfaceOrientationMaskPortrait;
}

/*
        Derived from GLKViewController        */
- (void) update
{
        mRenderManager->UpdateEffect();
}

/*
        Derived from GLKView        */
- (void) glkView:(GLKView *)view drawInRect:(CGRect)rect
{
        mRenderManager->Render();
}

@end
