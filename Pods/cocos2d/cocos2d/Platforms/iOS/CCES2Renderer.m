/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2011 Ricardo Quesada
 * Copyright (c) 2011 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 *
 * File autogenerated with Xcode. Adapted for cocos2d needs.
 */

// Only compile this code on iOS. These files should NOT be included on your Mac project.
// But in case they are included, it won't be compiled.
#import "../../ccMacros.h"
#ifdef __CC_PLATFORM_IOS

#import "CCES2Renderer.h"

#import "../../Support/OpenGL_Internal.h"
#import "../../ccMacros.h"

@implementation CCES2Renderer

@synthesize context=_context;
@synthesize defaultFramebuffer=_defaultFramebuffer;
@synthesize colorRenderbuffer=_colorRenderbuffer;
@synthesize msaaColorbuffer=_msaaColorbuffer;
@synthesize msaaFramebuffer=_msaaFramebuffer;

// Create an OpenGL ES 2.0 context
- (id) initWithDepthFormat:(unsigned int)depthFormat withPixelFormat:(unsigned int)pixelFormat withSharegroup:(EAGLSharegroup*)sharegroup withMultiSampling:(BOOL) multiSampling withNumberOfSamples:(unsigned int) requestedSamples
{
    self = [super init];
    if (self)
    {
		if( ! sharegroup )
			_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		else
			_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:sharegroup];

        if (!_context || ![EAGLContext setCurrentContext:_context] )
        {
            [self release];
            return nil;
        }
		
		_depthFormat = depthFormat;
		_pixelFormat = pixelFormat;
		_multiSampling = multiSampling;

        // Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
        glGenFramebuffers(1, &_defaultFramebuffer);
		NSAssert( _defaultFramebuffer, @"Can't create default frame buffer");

        glGenRenderbuffers(1, &_colorRenderbuffer);
		NSAssert( _colorRenderbuffer, @"Can't create default render buffer");

        glBindFramebuffer(GL_FRAMEBUFFER, _defaultFramebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);

		if (_multiSampling)
		{
			GLint maxSamplesAllowed;
			glGetIntegerv(GL_MAX_SAMPLES_APPLE, &maxSamplesAllowed);
			_samplesToUse = MIN(maxSamplesAllowed,requestedSamples);
			
			/* Create the MSAA framebuffer (offscreen) */
			glGenFramebuffers(1, &_msaaFramebuffer);
			NSAssert( _msaaFramebuffer, @"Can't create default MSAA frame buffer");
			glBindFramebuffer(GL_FRAMEBUFFER, _msaaFramebuffer);
			
		}

		CHECK_GL_ERROR_DEBUG();
    }

    return self;
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
	// Allocate color buffer backing based on the current layer size
	glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);

	if( ! [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer] )
		CCLOG(@"failed to call context");

	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);

	CCLOG(@"cocos2d: surface size: %dx%d", (int)_backingWidth, (int)_backingHeight);

	if (_multiSampling)
	{
		if ( _msaaColorbuffer) {
			glDeleteRenderbuffers(1, &_msaaColorbuffer);
			_msaaColorbuffer = 0;
		}
		
		/* Create the offscreen MSAA color buffer.
		 After rendering, the contents of this will be blitted into ColorRenderbuffer */
		
		//msaaFrameBuffer needs to be binded
		glBindFramebuffer(GL_FRAMEBUFFER, _msaaFramebuffer);
		glGenRenderbuffers(1, &_msaaColorbuffer);
		NSAssert(_msaaFramebuffer, @"Can't create MSAA color buffer");
		
		glBindRenderbuffer(GL_RENDERBUFFER, _msaaColorbuffer);
		
		glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, _samplesToUse, _pixelFormat , _backingWidth, _backingHeight);
		
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _msaaColorbuffer);
		
		GLenum error;
		if ( (error=glCheckFramebufferStatus(GL_FRAMEBUFFER)) != GL_FRAMEBUFFER_COMPLETE)
		{
			CCLOG(@"Failed to make complete framebuffer object 0x%X", error);
			return NO;
		}
	}

	CHECK_GL_ERROR();

	if (_depthFormat)
	{
		if( ! _depthBuffer ) {
			glGenRenderbuffers(1, &_depthBuffer);
			NSAssert(_depthBuffer, @"Can't create depth buffer");
		}

		glBindRenderbuffer(GL_RENDERBUFFER, _depthBuffer);
		
		if( _multiSampling )
			glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, _samplesToUse, _depthFormat,_backingWidth, _backingHeight);
		else
			glRenderbufferStorage(GL_RENDERBUFFER, _depthFormat, _backingWidth, _backingHeight);

		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);

		if (_depthFormat == GL_DEPTH24_STENCIL8_OES) {
			glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
		}
        
		// bind color buffer
		glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);		
	}

	CHECK_GL_ERROR();

	GLenum error;
	if( (error=glCheckFramebufferStatus(GL_FRAMEBUFFER)) != GL_FRAMEBUFFER_COMPLETE)
	{
		CCLOG(@"Failed to make complete framebuffer object 0x%X", error);
		return NO;
	}

	return YES;
}

-(CGSize) backingSize
{
	return CGSizeMake( _backingWidth, _backingHeight);
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@ = %p | size = %ix%i>", [self class], self, _backingWidth, _backingHeight];
}

- (unsigned int) colorRenderBuffer
{
	return _colorRenderbuffer;
}

- (unsigned int) defaultFrameBuffer
{
	return _defaultFramebuffer;
}

- (unsigned int) msaaFrameBuffer
{
	return _msaaFramebuffer;
}

- (unsigned int) msaaColorBuffer
{
	return _msaaColorbuffer;
}

- (void)dealloc
{
	CCLOGINFO(@"cocos2d: deallocing %@", self);

    // Tear down GL
    if (_defaultFramebuffer) {
        glDeleteFramebuffers(1, &_defaultFramebuffer);
        _defaultFramebuffer = 0;
    }

    if (_colorRenderbuffer) {
        glDeleteRenderbuffers(1, &_colorRenderbuffer);
        _colorRenderbuffer = 0;
    }

	if( _depthBuffer ) {
		glDeleteRenderbuffers(1, &_depthBuffer );
		_depthBuffer = 0;
	}
	
	if ( _msaaColorbuffer)
	{
		glDeleteRenderbuffers(1, &_msaaColorbuffer);
		_msaaColorbuffer = 0;
	}
	
	if ( _msaaFramebuffer)
	{
		glDeleteRenderbuffers(1, &_msaaFramebuffer);
		_msaaFramebuffer = 0;
	}

    // Tear down context
    if ([EAGLContext currentContext] == _context)
        [EAGLContext setCurrentContext:nil];

    [_context release];
    _context = nil;

    [super dealloc];
}

@end

#endif // __CC_PLATFORM_IOS
