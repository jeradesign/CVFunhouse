//
//  CVFMainViewController.m
//  CVFunhouse
//
//  Created by John Brewer on 3/7/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import "CVFMainViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CVFFlipsideViewController.h"

#import "CVFCannyDemo.h"
#import "CVFFaceDetect.h"
#import "CVFFarneback.h"
#import "CVFLaplace.h"
#import "CVFLukasKanade.h"
#import "CVFMotionTemplates.h"

#import "CVFSephiaDemo.h"
#import "CVFPassThru.h"
#import "CVFAugmentedReality.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

GLfloat gCubeVertexData[216] =
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,          1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,
    
    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,
    
    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
};

@interface CVFMainViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

- (void)setupCamera;
- (void)turnCameraOn;
- (void)turnCameraOff;
- (void)resetImageProcessor;
- (void)drawBackground;

@property (strong,nonatomic) NSArray *modelView;

@end

@implementation CVFMainViewController {
    AVCaptureDevice *_cameraDevice;
    AVCaptureSession *_session;
    AVCaptureVideoPreviewLayer *_previewLayer;
    CVFImageProcessor *_imageProcessor;
    NSDate *_lastFrameTime;
    CGPoint _descriptionOffScreenCenter;
    CGPoint _descriptionOnScreenCenter;
    bool _useBackCamera;
    GLKTextureInfo *_texture;
}

@synthesize fpsLabel = _fpsLabel;
@synthesize flipCameraButton = _flipCameraButton;
@synthesize descriptionView = _descriptionView;
@synthesize flipsidePopoverController = _flipsidePopoverController;
@synthesize imageView = _imageView;
@synthesize modelView = _modelView;
//@synthesize imageProcessor = _imageProcessor;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self showHideFPS];
    [self initializeDescription];
    [self resetImageProcessor];
    _useBackCamera = [[NSUserDefaults standardUserDefaults] boolForKey:@"useBackCamera"];
    [self setupCamera];
    [self turnCameraOn];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetImageProcessor)
                                                 name:@"demoNumber"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showHideFPS)
                                                 name:@"showFPS"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showHideDescription)
                                                 name:@"showDescription"
                                               object:nil];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.view.layer;
    eaglLayer.opaque = NO;
    
    self.glkView.context = self.context;
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.glkView.opaque = NO;
    self.glkView.delegate = self;
    
    [self setupGL];
}

- (void)resetImageProcessor {
    int demoNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"demoNumber"];

    switch (demoNumber) {
        case 0:
            self.imageProcessor = [[CVFCannyDemo alloc] init];
            break;
            
        case 1:
            self.imageProcessor = [[CVFFaceDetect alloc] init];
            break;
            
        case 2:
            self.imageProcessor = [[CVFFarneback alloc] init];
            break;
            
        case 3:
            self.imageProcessor = [[CVFLaplace alloc] init];
            break;
            
        case 4:
            self.imageProcessor = [[CVFLukasKanade alloc] init];
            break;
            
        case 5:
            self.imageProcessor = [[CVFMotionTemplates alloc] init];
            break;
            
        case 6:
            self.imageProcessor = [[CVFSephiaDemo alloc] init];
            break;
            
        case 7:
            self.imageProcessor = [[CVFAugmentedReality alloc] init];
            break;
            
        case 8:
        default:
            self.imageProcessor = [[CVFPassThru alloc] init];
            break;
    }
    
    NSString *className = NSStringFromClass([self.imageProcessor class]);
    NSURL *descriptionUrl = [[NSBundle mainBundle] URLForResource:className withExtension:@"html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:descriptionUrl];
    [self.descriptionView loadRequest:request];
}

- (void)showHideFPS {
    bool showFPS = [[NSUserDefaults standardUserDefaults] boolForKey:@"showFPS"];
    [self.fpsLabel setHidden:!showFPS];
}

- (void)initializeDescription {
    self.descriptionView.layer.borderColor = [UIColor blackColor].CGColor;
    self.descriptionView.layer.borderWidth = 1.0;
    
    _descriptionOnScreenCenter = self.descriptionView.center;
    _descriptionOffScreenCenter = self.descriptionView.center;
    int descriptionTopY = self.descriptionView.center.y -
    self.descriptionView.bounds.size.height / 2;
    _descriptionOffScreenCenter.y += self.view.bounds.size.height - descriptionTopY;

    bool showDescription = [[NSUserDefaults standardUserDefaults] boolForKey:@"showDescription"];
    self.descriptionView.hidden = !showDescription;
}

- (void)showHideDescription {
    bool showDescription = [[NSUserDefaults standardUserDefaults] boolForKey:@"showDescription"];
    if (showDescription && self.descriptionView.isHidden) {
        self.descriptionView.center = _descriptionOffScreenCenter;
        [self.descriptionView setHidden:false];
        [UIView animateWithDuration:0.5 animations:^{
            self.descriptionView.center = _descriptionOnScreenCenter;
        }];
    } else if (!showDescription && !self.descriptionView.isHidden) {
        [UIView animateWithDuration:0.5 animations:^{
            self.descriptionView.center = _descriptionOffScreenCenter;
        } completion:^(BOOL finished) {
            self.descriptionView.hidden = true;
        }];
    }
}

- (void)setImageProcessor:(CVFImageProcessor *)imageProcessor
{
    if (_imageProcessor != imageProcessor) {
        _imageProcessor.delegate = nil;
        _imageProcessor = imageProcessor;
        _imageProcessor.delegate = self;
    }
}

- (CVFImageProcessor *)imageProcessor {
    return _imageProcessor;
}


- (void)viewDidUnload
{
    [self turnCameraOff];
    [self setImageView:nil];
    [self setFpsLabel:nil];
    [self setFlipCameraButton:nil];
    [self setDescriptionView:nil];
    [self setGlkView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(CVFFlipsideViewController *)controller
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
        self.flipsidePopoverController = nil;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.flipsidePopoverController = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            self.flipsidePopoverController = popoverController;
            popoverController.delegate = self;
        }
    }
}

#pragma mark - UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
    if ([[url scheme] isEqual: @"about"]) {
        return YES;
    }
    if ([[url scheme] isEqual:@"file"]) {
        return YES;
    }

    [[UIApplication sharedApplication] openURL:url];
    return NO;
}

#pragma mark - IBAction methods

- (IBAction)flipAction:(id)sender
{
    _useBackCamera = !_useBackCamera;
    [[NSUserDefaults standardUserDefaults] setBool:_useBackCamera forKey:@"useBackCamera"];
    [self turnCameraOff];
    [self setupCamera];
    [self turnCameraOn];
}

- (IBAction)togglePopover:(id)sender
{
    if (self.flipsidePopoverController) {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
        self.flipsidePopoverController = nil;
    } else {
        [self performSegueWithIdentifier:@"showAlternate" sender:sender];
    }
}

- (IBAction)swipeUpAction:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"showDescription"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showDescription" object:nil];
}

- (IBAction)swipeDownAction:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"showDescription"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showDescription" object:nil];
}

#pragma mark - CVFImageProcessorDelegate

-(void)imageProcessor:(CVFImageProcessor*)imageProcessor didCreateImage:(UIImage*)image
{
//    NSLog(@"Image Received");
    [self.imageView setImage:image];
    NSDate *now = [NSDate date];
    NSTimeInterval frameDelay = [now timeIntervalSinceDate:_lastFrameTime];
    double fps = 1.0/frameDelay;
    if (fps != fps) {
        self.fpsLabel.text = @"";
    } else {
        self.fpsLabel.text = [NSString stringWithFormat:@"%05.2f FPS", fps];
    }
    _lastFrameTime = now;
}

-(void)imageProcessor:(CVFImageProcessor *)imageProcessor didProvideData:(NSObject *)data
{
    NSArray *array = (NSArray *)data;
//    if (array.count > 0) {
//        NSLog(@"didProvideData:%@", data);
//    }
    
    self.modelView = array;
    [self update];
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);

    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);

    if (self.modelView.count > 0) {
        NSData *projectionData = [self.modelView objectAtIndex:0];
        NSLog(@"modelViewData.length = %d", projectionData.length);
        const double *projectionArray = [projectionData bytes];
        float projectionFloatArray[16];
        for (int i = 0; i < 16; i++) {
            projectionFloatArray[i] = projectionArray[i];
        }
        projectionMatrix = GLKMatrix4MakeWithArray(projectionFloatArray);
        NSLog(@"AR projectionMatrix =\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n",
              projectionMatrix.m00, projectionMatrix.m01, projectionMatrix.m02, projectionMatrix.m03,
              projectionMatrix.m10, projectionMatrix.m11, projectionMatrix.m12, projectionMatrix.m13,
              projectionMatrix.m20, projectionMatrix.m21, projectionMatrix.m22, projectionMatrix.m23,
              projectionMatrix.m30, projectionMatrix.m31, projectionMatrix.m32, projectionMatrix.m33
              );
    }
    
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
//    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
//    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
//    NSLog(@"Default modelViewMatrix =\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n",
//          modelViewMatrix.m00, modelViewMatrix.m01, modelViewMatrix.m02, modelViewMatrix.m03,
//          modelViewMatrix.m10, modelViewMatrix.m11, modelViewMatrix.m12, modelViewMatrix.m13,
//          modelViewMatrix.m20, modelViewMatrix.m21, modelViewMatrix.m22, modelViewMatrix.m23,
//          modelViewMatrix.m30, modelViewMatrix.m31, modelViewMatrix.m32, modelViewMatrix.m33
//          );

    if (self.modelView.count > 0) {
        NSData *modelViewData = [self.modelView objectAtIndex:1];
        NSLog(@"modelViewData.length = %d", modelViewData.length);
        const double *modelViewArray = [modelViewData bytes];
        float modelViewFloatArray[16];
        for (int i = 0; i < 16; i++) {
            modelViewFloatArray[i] = modelViewArray[i];
        }
        modelViewMatrix = GLKMatrix4MakeWithArray(modelViewFloatArray);
        NSLog(@"AR modelViewMatrix =\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n",
              modelViewMatrix.m00, modelViewMatrix.m01, modelViewMatrix.m02, modelViewMatrix.m03,
              modelViewMatrix.m10, modelViewMatrix.m11, modelViewMatrix.m12, modelViewMatrix.m13,
              modelViewMatrix.m20, modelViewMatrix.m21, modelViewMatrix.m22, modelViewMatrix.m23,
              modelViewMatrix.m30, modelViewMatrix.m31, modelViewMatrix.m32, modelViewMatrix.m33
              );
    }

//    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);

    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
//    // Compute the model view matrix for the object rendered with ES2
//    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
//    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
//    
//    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
//    
//    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
//    _rotation += self.timeSinceLastUpdate * 0.5f;
    [self.glkView setNeedsDisplay];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object with GLKit
    [self.effect prepareToDraw];
    
    if (self.modelView.count > 0) {
        glDrawArrays(GL_TRIANGLES, 0, 36);
    }
//    // Render the object again with ES2
//    glUseProgram(_program);
//    
//    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
//    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
//    
//    glDrawArrays(GL_TRIANGLES, 0, 36);
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_NORMAL, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Camera support

- (void)setupCamera {
    _cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSArray *devices = [AVCaptureDevice devices];
    if (devices.count == 1) {
        
    }
    for (AVCaptureDevice *device in devices) {
        if (device.position == AVCaptureDevicePositionFront && !_useBackCamera) {
            
            _cameraDevice = device;
            break;
        }
        if (device.position == AVCaptureDevicePositionBack && _useBackCamera) {
            
            _cameraDevice = device;
            break;
        }
    }
}

- (void)turnCameraOn {
    NSError *error;
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    [_session setSessionPreset:AVCaptureSessionPresetMedium];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_cameraDevice
                                                                        error:&error];
    if (input == nil) {
        NSLog(@"%@", error);
    }
    
    [_session addInput:input];
    
    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [_session addOutput:output];
    
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    // Specify the pixel format
    output.videoSettings = 
    [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    output.alwaysDiscardsLateVideoFrames = YES;
    //kCVPixelFormatType_32BGRA
    
//    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
//    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;
//    [_previewLayer setOrientation:orientation];
//    _previewLayer.frame = self.previewView.bounds;
//    [self.previewView.layer addSublayer:_previewLayer];
    
    // Start the session running to start the flow of data
    [_session commitConfiguration];
    [_session startRunning];
}

- (void)turnCameraOff {
    [_previewLayer removeFromSuperlayer];
    _previewLayer = nil;
    [_session stopRunning];
    _session = nil;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        [self.imageProcessor processImageBuffer:imageBuffer
                                  withMirroring:(_cameraDevice.position ==
                                                 AVCaptureDevicePositionFront)];
    }
}

@end
