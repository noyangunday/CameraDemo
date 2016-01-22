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
#import "CaptureManager.h"
#import "RenderManager.h"

@interface CaptureManager()
{
        AVCaptureSession                *mSession;
        AVCaptureDevice                 *mCamera;
        AVCaptureDeviceInput            *mInput;
        AVCaptureVideoDataOutput        *mOutput;
        CVOpenGLESTextureRef            mTexture;
        CVOpenGLESTextureCacheRef       mTextureCache;
        EAGLContext                     *mContext;
}

- (BOOL) findBackCamera;
- (BOOL) findDefaultCamera;
- (BOOL) attachInputToSession;
- (BOOL) attachOutputToSession;

@end

@implementation CaptureManager

- (id) initWithContext: (EAGLContext *) context;
{
        self = [super init];
        if (self)
        {
                mContext = context;
                CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, mContext, NULL, &mTextureCache);
                mSession = [[AVCaptureSession alloc] init];
                [mSession beginConfiguration];
                [self findDefaultCamera];
                [self attachInputToSession];
                [self attachOutputToSession];
                [mSession commitConfiguration];
                [mSession startRunning];
        }
        return self;
}

- (void) cleanUp
{
        if (mTexture)
        {
                CFRelease(mTexture);
        }
        CFRelease(mTextureCache);
}

/*
        Find back camera from capture devices */
- (BOOL) findBackCamera
{
        NSArray *devices = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];

        for (AVCaptureDevice *device in devices)
        {
                if ([device position] == AVCaptureDevicePositionBack)
                {
                        mCamera = device;
                        return YES;
                }
        }

        /* TODO: Handle error */
        mCamera = nil;
        return NO;
}

/*
        Get the default camera */
- (BOOL) findDefaultCamera
{
        mCamera = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];
        if (mCamera == nil)
        {
                /* TODO: Handle error */
                return NO;
        }
        return YES;
}

/*
        Attach Camera Input to Current Capture Session */
- (BOOL) attachInputToSession
{
        NSError * error = NULL;
        mInput = [AVCaptureDeviceInput deviceInputWithDevice: mCamera error: &error];

        if (error)
        {
                /* TODO: Handle Error */
                return NO;
        }

        [mSession addInput: mInput];
        return YES;
}

/*
        Attach Output Frame to Current Capture Session */
- (BOOL) attachOutputToSession
{
        mOutput = [[AVCaptureVideoDataOutput alloc] init];
        mOutput.alwaysDiscardsLateVideoFrames = NO;
        mOutput.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                            forKey: (id) kCVPixelBufferPixelFormatTypeKey];

        /* We want the captured image to be delivered to the thread where OpenGL context lives
           (currently main thread) */
        [mOutput setSampleBufferDelegate: self queue:dispatch_get_main_queue()];

        [mSession addOutput: mOutput];
        return YES;
}

/*
        Derived from AVCaptureOutput */
- (void) captureOutput: (AVCaptureOutput *) captureOutput
         didOutputSampleBuffer: (CMSampleBufferRef) sampleBuffer
         fromConnection: (AVCaptureConnection *) connection
{
        CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);

        if (mTexture)
        {
                CFRelease(mTexture);
                mTexture = NULL;
        }
        CVOpenGLESTextureCacheFlush(mTextureCache, 0);

        glActiveTexture(GL_TEXTURE0);

        /* According to apple documentation this call will generate mTexture
           Don't need to create the texture manually.
         */
        CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                     mTextureCache,
                                                     buffer,
                                                     NULL,
                                                     GL_TEXTURE_2D,
                                                     GL_RGBA,
                                                     (int) CVPixelBufferGetWidth(buffer),
                                                     (int) CVPixelBufferGetHeight(buffer),
                                                     GL_BGRA,
                                                     GL_UNSIGNED_BYTE,
                                                     0,
                                                     &mTexture);

        glBindTexture(CVOpenGLESTextureGetTarget(mTexture), CVOpenGLESTextureGetName(mTexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

@end
