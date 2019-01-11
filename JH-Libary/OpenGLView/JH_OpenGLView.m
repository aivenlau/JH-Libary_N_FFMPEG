//
//  OpenGLView.m
//  MyTest
//
//  Created by smy on 12/20/11.
//  Copyright (c) 2011 ZY.SYM. All rights reserved.
//

#import "JH_OpenGLView.h"
extern BOOL bGoble_3D;
extern BOOL bWhitClolor;
extern BOOL   bRotaHV;
extern int    nRotation;


void *blackData_goble;

enum AttribEnum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXTURE
    //ATTRIB_COLOR,
};

enum TextureType
{
    TEXY = 0,
    TEXU,
    TEXV
   // TEXC
};

//#define PRINT_CALL 1

@interface JH_OpenGLView()
{
    /**
     OpenGL绘图上下文
     */
    
    
    /**
     帧缓冲区
     */
    GLuint                  _framebuffer;
    
    /**
     渲染缓冲区
     */
    GLuint                  _renderBuffer;
    
    /**
     着色器句柄
     */
    GLuint                  _program;
    
    /**
     YUV纹理数组
     */
    GLuint                  _textureYUV[4];
    
    /**
     视频宽度
     */
    GLuint                  _videoW;
    
    /**
     视频高度
     */
    GLuint                  _videoH;
    
    
	   
    //void                    *_pYuvData;
    
    CGSize     bounds_size;
    
    GLuint nDispType;
    
    
    
    
#ifdef DEBUG
    struct timeval      _time;
    NSInteger           _frameRate;
#endif
}

@property  (strong,nonatomic)  EAGLContext             *glContext;

@property  (assign,nonatomic)  GLsizei                 viewScale;


@property  (assign,nonatomic)  int                  vWidth;
@property  (assign,nonatomic)  int                  vHeight;


/*
 *   0 正常
 *   1 黑白
 *   2 淡红
 *   3 淡黄
 *   4 淡绿
 *   5 褐色
 *   6 淡蓝
 */
/** 
 初始化YUV纹理
 */
- (void)setupYUVTexture;

/** 
 创建缓冲区
 @return 成功返回TRUE 失败返回FALSE
 */
- (BOOL)createFrameAndRenderBuffer;

/** 
 销毁缓冲区
 */
- (void)destoryFrameAndRenderBuffer;

//加载着色器
/** 
 初始化YUV纹理
 */
- (void)loadShader;

/** 
 编译着色代码
 @param shader        代码
 @param shaderType    类型
 @return 成功返回着色器 失败返回－1
 */
- (GLuint)compileShader:(NSString*)shaderCode withType:(GLenum)shaderType;

/** 
 渲染
 */
- (void)render;


- (void)setVideoSize:(GLuint)width height:(GLuint)height;


//@property(assign,nonatomic) int nRota;
//@property(assign,nonatomic) BOOL bRotaHV;


@end

@implementation JH_OpenGLView

/*
-(void)SetRotation:(int)n RotaHV:(BOOL)b
{
    nRotation = n;
    bRotaHV = b;
}
*/
- (BOOL)doInit
{
    blackData_goble = NULL;
    _nDispStyle = 0;
    nRotation = 0;
    bRotaHV = NO;
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGB565, kEAGLDrawablePropertyColorFormat,
                                    nil];
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    _viewScale = [UIScreen mainScreen].scale;
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if(!_glContext || ![EAGLContext setCurrentContext:_glContext])
    {
        return NO;
    }
    [self setupYUVTexture];
    [self loadShader];
    glUseProgram(_program);
    GLuint textureUniformY = glGetUniformLocation(_program, "SamplerY");
    GLuint textureUniformU = glGetUniformLocation(_program, "SamplerU");
    GLuint textureUniformV = glGetUniformLocation(_program, "SamplerV");
    nDispType =glGetUniformLocation(_program, "nDislplay");
    glUniform1i(textureUniformY, 0);
    glUniform1i(textureUniformU, 1);
    glUniform1i(textureUniformV, 2);
    
    
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        if (![self doInit])
        {
            self = nil;
        }
        
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        if (![self doInit])
        {
            self = nil;
        }
    }
    return self;
}

int gwwwww_=1;
int ghhhhh_=1;
int gdddddd_=0;

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect bounds =self.bounds;
    bounds_size = bounds.size;
    __weak JH_OpenGLView *weakself = self;

    [EAGLContext setCurrentContext:weakself.glContext];
    [self destoryFrameAndRenderBuffer];
    [self createFrameAndRenderBuffer];
    /*
    if(_bRotaHV && _nRota != 0 &&  _nRota != 180) {
        glViewport(gdddddd_, 0, gwwwww_, ghhhhh_);
    }
     */
    /*
    float df = ((float)(instance->vHeight))/instance->vWidth;
    ghhhhh_ =  instance->vHeight;
    gwwwww_ =  (int)(ghhhhh_*df);
    
    gdddddd_ =  (instance->vWidth-gwwwww_)/2;
     */
    
    
    _vWidth =bounds.size.width*_viewScale;
    _vHeight = bounds.size.height*_viewScale;
    
    float df = ((float)(_vHeight))/_vWidth;
    ghhhhh_ =  _vHeight;
    gwwwww_ =  (int)(ghhhhh_*df);
    gdddddd_ =  (_vWidth-gwwwww_)/2;
    
    
    
    //glViewport(1, 1, bounds.size.width*weakself.viewScale - 2, bounds.size.height*weakself.viewScale - 2);

}

- (void)setupYUVTexture
{
    if (_textureYUV[TEXY])
    {
        glDeleteTextures(4, _textureYUV);
    }
    glGenTextures(4, _textureYUV);
    if (!_textureYUV[TEXY] || !_textureYUV[TEXU] || !_textureYUV[TEXV])
    {
        NSLog(@"<<<<<<<<<<<<纹理创建失败!>>>>>>>>>>>>");
        return;
    }
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
    
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    
}
#define  TEXTURE_COOR_UNIT 1
#define  UNIT 1
- (void)render
{
    [EAGLContext setCurrentContext:_glContext];
    static const GLfloat squareVertices[] = {
        //-1.0f, -1.0f,
        //1.0f, -1.0f,
        //-1.0f,  1.0f,
        //1.0f,  1.0f,
        
        -1 * UNIT, 1 * UNIT,
        -1 * UNIT, -1 * UNIT,
        1 * UNIT, 1 * UNIT,
        1 * UNIT, -1 * UNIT
    };
    
    static const GLfloat squareVertices_90[] = {
        //-1.0f, 1.0f,
        //-1.0f, -1.0f,
        //1.0f,  1.0f,
        //1.0f,  -1.0f,
        1 * UNIT, 1 * UNIT,
        -1 * UNIT, 1 * UNIT,
        1 * UNIT, -1 * UNIT,
        -1 * UNIT, -1 * UNIT
    };
    
    static const GLfloat dataVertex_Flip[] =
    {
        1 * UNIT, -1 * UNIT,
        1 * UNIT, 1 * UNIT,
        -1 * UNIT, -1 * UNIT,
        -1 * UNIT, 1 * UNIT
    };
    
    static const GLfloat squareVertices__90[] = {
        /*
        1.0f, -1.0f,
        1.0f, 1.0f,
        -1.0f,  -1.0f,
        -1.0f,  1.0f,
         */
        -1 * UNIT, -1 * UNIT,
        1 * UNIT, -1 * UNIT,
        -1 * UNIT, 1 * UNIT,
        1 * UNIT, 1 * UNIT
    };
    
    
    static const GLfloat coordVertices[] = {
        //0.0f, 1.0f,
        //1.0f, 1.0f,
        //0.0f,  0.0f,
        //1.0f,  0.0f,
        0 * TEXTURE_COOR_UNIT, 0 * TEXTURE_COOR_UNIT,
        0 * TEXTURE_COOR_UNIT, 1 * TEXTURE_COOR_UNIT,
        1 * TEXTURE_COOR_UNIT, 0 * TEXTURE_COOR_UNIT,
        1 * TEXTURE_COOR_UNIT, 1 * TEXTURE_COOR_UNIT
    };
    
    if(!bRotaHV)
    {
        if(nRotation==90)
        {
            glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices_90);
        }
        else if(nRotation==-90 || nRotation==270)
        {
            glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices__90);
        }
        else
        {
            glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
        }
    }
    else
    {
        if (nRotation == 90) {
            glVertexAttribPointer(ATTRIB_VERTEX,
                                  2,//GLint size X Y Z
                                  GL_FLOAT,//GLenum type
                                  GL_FALSE,//GLboolean normalized
                                  0,//GLsizei stride
                                  squareVertices_90//const GLvoid * ptr
                                  );
        } else if (nRotation == -90 || nRotation == 270) {
            glVertexAttribPointer(ATTRIB_VERTEX,
                                  2,//GLint size X Y Z
                                  GL_FLOAT,//GLenum type
                                  GL_FALSE,//GLboolean normalized
                                  0,//GLsizei stride
                                  squareVertices__90//const GLvoid * ptr
                                  );
        }else if (nRotation == 180) {
            glVertexAttribPointer(ATTRIB_VERTEX,
                                  2,//GLint size X Y Z
                                  GL_FLOAT,//GLenum type
                                  GL_FALSE,//GLboolean normalized
                                  0,//GLsizei stride
                                  dataVertex_Flip//const GLvoid * ptr
                                  );
        }
        else {
            glVertexAttribPointer(ATTRIB_VERTEX,
                                  2,//GLint size X Y Z
                                  GL_FLOAT,//GLenum type
                                  GL_FALSE,//GLboolean normalized
                                  0,//GLsizei stride
                                  squareVertices//const GLvoid * ptr
                                  );
        }
        
    }
    glVertexAttribPointer(ATTRIB_TEXTURE, 2, GL_FLOAT, 0, 0, coordVertices);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glEnableVertexAttribArray(ATTRIB_TEXTURE);
    // Draw
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - 设置openGL
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (BOOL)createFrameAndRenderBuffer
{
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_renderBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    __block BOOL bOK=YES;
    

    if (![_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer])
    {
        NSLog(@"attach渲染缓冲区失败");
    }
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"创建缓冲区错误 0x%x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }

    
    return bOK;
}

- (void)destoryFrameAndRenderBuffer
{
    if (_framebuffer)
    {
        glDeleteFramebuffers(1, &_framebuffer);
    }
    
    if (_renderBuffer)
    {
        glDeleteRenderbuffers(1, &_renderBuffer);
    }
    
    _framebuffer = 0;
    _renderBuffer = 0;
}
/*
 float y = texture2D(yTexture, vTexCoor).r;
 float u = texture2D(uTexture, vTexCoor).r;
 float v = texture2D(vTexture, vTexCoor).r;
 vec3 yuv = vec3(y, u, v);
 vec3 offset = vec3(0.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0);
 mat3 mtr = mat3(1.0, 1.0, 1.0, -0.001, -0.39, 2.03, 1.1402, -0.58, 0.001);
 vec4 curColor = vec4(mtr * (yuv - offset), 1);
 gl_FragColor = curColor;
 
 
 
 
 */
/*
 mediump vec3 yuv;\
 lowp vec3 rgb;\
 \
 yuv.x = texture2D(SamplerY, TexCoordOut).r; \
 yuv.y = texture2D(SamplerU, TexCoordOut).r;  \
 yuv.z = texture2D(SamplerV, TexCoordOut).r; \
 \
 rgb = mat3( 1,       1,         1, \
 0,       -0.39465,  2.03211, \
 1.13983, -0.58060,  0) * yuv; \
 \
 gl_FragColor = vec4(rgb, 1); \
 \
 */
#if 0
#define FSH @"precision mediump float;\
varying lowp vec2 TexCoordOut;\
uniform sampler2D SamplerY;\
uniform sampler2D SamplerU;\
uniform sampler2D SamplerV;\
uniform int  nDislplay;\
void modifyColor(vec4 color)\
{\
    color.r=max(min(color.r,1.0),0.0);\
    color.g=max(min(color.g,1.0),0.0);\
    color.b=max(min(color.b,1.0),0.0);\
    color.a=max(min(color.a,1.0),0.0);\
}\
\
void main(void)\
{\
    float y = texture2D(SamplerY, TexCoordOut).r; \
    float u = texture2D(SamplerU, TexCoordOut).r; \
    float v = texture2D(SamplerV, TexCoordOut).r; \
    if(nDislplay==1) {\
        u = 0.5;\
        v = 0.5;\
    }\
    vec3 yuv = vec3(y, u, v); \
    vec3 offset = vec3(16.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0); \
    mat3 mtr = mat3(1.0, 1.0, 1.0, -0.000, -0.344, 1.772, 1.402, -0.714, 0.00); \
    vec4 curColor = vec4(mtr * (yuv - offset), 1); \
    vec4 mask = vec4(0.0,0.0,0.0,0.0);\
    if(nDislplay==2)\
    {\
        mask = vec4(1.0,0.0,0.0,0.21); //淡红\
    }\
    else if(nDislplay==3)\
    {\
        mask = vec4(1.0,1.0,0.0,0.2); //淡黄\
    }\
    else if(nDislplay==4)\
    {\
        mask = vec4(0.0,1.0,0.0,0.2); //淡绿\
    }\
    else if(nDislplay==5)\
    {\
        mask = vec4(128.0/256.0, 69.0/256.0, 9.0/256.0, 0.5); //褐色\
    }\
    else if(nDislplay==6)\
    {\
        mask = vec4(0.0, 0.0, 1.0, 0.20); //淡蓝\
    }\
    float r = mask.a*mask.r+(1.0-mask.a)*curColor.r;\
    float g = mask.a*mask.g+(1.0-mask.a)*curColor.g;\
    float b = mask.a*mask.b+(1.0-mask.a)*curColor.b;\
    vec4 color1 = vec4(r,g,b,1.0);\
    modifyColor(color1);\
    gl_FragColor=color1;\
}"
#else

#define FSH @"precision mediump float;\
    varying lowp vec2 TexCoordOut;\
    uniform sampler2D SamplerY;\
    uniform sampler2D SamplerU;\
    uniform sampler2D SamplerV;\
    uniform int  nDislplay;\
    void modifyColor(vec4 color)\
    {\
        color.r=max(min(color.r,1.0),0.0);\
        color.g=max(min(color.g,1.0),0.0);\
        color.b=max(min(color.b,1.0),0.0);\
        color.a=max(min(color.a,1.0),0.0);\
    }\
    void main(void)\
    {\
    float y = texture2D(SamplerY, TexCoordOut).r; \
    float u = texture2D(SamplerU, TexCoordOut).r; \
    float v = texture2D(SamplerV, TexCoordOut).r; \
    if(nDislplay==1)\
    {\
        u=0.5;\
        v=0.5;\
    }\
    vec3 yuv = vec3(y, u, v); \
    vec3 offset = vec3(16.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0); \
    mat3 mtr = mat3(1.0, 1.0, 1.0, -0.000, -0.344, 1.772, 1.402, -0.714, 0.00); \
    vec4 curColor = vec4(mtr * (yuv - offset), 1); \
    vec4 mask = vec4(0.0,0.0,0.0,0.0);\
    if(nDislplay==2)\
    {\
        mask = vec4(1.0,0.0,0.0,0.21);\
    }\
    else if(nDislplay==3)\
    {\
        mask = vec4(1.0,1.0,0.0,0.2);\
    }\
    else if(nDislplay==4)\
    {\
        mask = vec4(0.0,1.0,0.0,0.2);\
    }\
    else if(nDislplay==5)\
    {\
        mask = vec4(128.0/256.0, 69.0/256.0, 9.0/256.0, 0.5);\
    }\
    else if(nDislplay==6)\
    {\
        mask = vec4(0.0, 0.0, 1.0, 0.20); \
    }\
    float r = mask.a*mask.r+(1.0-mask.a)*curColor.r;\
    float g = mask.a*mask.g+(1.0-mask.a)*curColor.g;\
    float b = mask.a*mask.b+(1.0-mask.a)*curColor.b;\
    vec4 color1 = vec4(r,g,b,1.0);\
    modifyColor(color1);\
    gl_FragColor=color1;\
}"
#endif

#define VSH @"attribute vec4 position;\
attribute vec2 TexCoordIn;\
varying vec2 TexCoordOut;\
\
void main(void)\
{\
    gl_Position = position;\
    TexCoordOut = TexCoordIn;\
}"



#define FSH2 @"attribute vec4 Position; \
attribute vec2 TextureCoords; \
varying vec2 TextureCoordsOut; \
void main(void) \
{ \
//用来展现纹理的多边形顶点 \
gl_Position = Position; \
//表示使用的纹理的范围的顶点，因为是2D纹理，所以用vec2类型 \
TextureCoordsOut = TextureCoords; \
}"

#define VSH2 @"precision mediump float; \
uniform sampler2D Texture; \
varying vec2 TextureCoordsOut; \
void main(void) \
{ \
//获取纹理的像素 \
vec4 mask = texture2D(Texture, TextureCoordsOut); \
gl_FragColor = vec4(mask.rgb, 1.0); \
}"




/**
 加载着色器
 */
- (void)loadShader
{
	/** 
	 1
	 */
    GLuint vertexShader = [self compileShader:VSH withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:FSH withType:GL_FRAGMENT_SHADER];

	/**
	 2
	 */
    _program = glCreateProgram();
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);


	/**
	 绑定需要在link之前
	 */
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXTURE, "TexCoordIn");
    glLinkProgram(_program);
    
	/** 
	 3
	 */
    GLint linkSuccess;
    glGetProgramiv(_program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"<<<<着色器连接失败 %@>>>", messageString);
        //exit(1);
    }
    
    if (vertexShader)
		glDeleteShader(vertexShader);
    if (fragmentShader)
		glDeleteShader(fragmentShader);
}

- (GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType
{
    
   	/** 
	 1
	 */
    if (!shaderString) {
       // NSLog(@"Error loading shader: %@", error.localizedDescription);
       // exit(1);
    }
    else
    {
        //NSLog(@"shader code-->%@", shaderString);
    }
    
	/** 
	 2
	 */
    GLuint shaderHandle = glCreateShader(shaderType);    
    
	/** 
	 3
	 */
    const char * shaderStringUTF8 = [shaderString UTF8String];    
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
	/** 
	 4
	 */
    glCompileShader(shaderHandle);
    
	/** 
	 5
	 */
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        NSLog(@"Load error!");
        exit(1);
    }
    return shaderHandle;
}


#pragma mark - 接口
- (void)displayYUV420pData:(void *)data width:(NSInteger)w height:(NSInteger)h
{
    @synchronized(self)
    {
        if (w != _videoW || h != _videoH)
        {
            GLenum err = glGetError();
            if (err != GL_NO_ERROR)
            {
                //printf("GL_ERROR111=======>%d\n", err);
            }
            [self setVideoSize:(GLuint)w height:(GLuint)h];
        }
        if(data == NULL)
        {
            GLenum err = glGetError();
            if(err != GL_NO_ERROR)
            {
                printf("GL_ERROR111222=======>%d\n", err);
            }
            
        }
        else
        {
            memcpy(blackData_goble,data,w*h*1.5);
        }
        
        //GL_RED_EXT
        [EAGLContext setCurrentContext:_glContext];
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLuint)w, (GLuint)h, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData_goble);
        
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLuint)w/2, (GLuint)h/2, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData_goble + w * h);
        
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLuint)w/2, (GLuint)h/2, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData_goble + w * h * 5 / 4);
        
        
        glUniform1i(nDispType, _nDispStyle);
        
        if(!bWhitClolor)
        {
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        } else
        {
            glClearColor(0.95f, 0.95f, 0.95f, 1.0f);
        }
        glClear(GL_COLOR_BUFFER_BIT);
#if 1
        
        
        if(bGoble_3D)
        {
            int ww,hh;
            ww = _vWidth/2;
            hh = _vHeight/2;
            glViewport(0, hh/2, ww, hh);
            [self render];
            glViewport(ww, hh/2, ww, hh);
            [self render];
        }
        else
        {
            if(bRotaHV && nRotation != 0 &&  nRotation != 180) {
                glViewport(gdddddd_, 0, gwwwww_, ghhhhh_);
            } else {
                glViewport(0, 0, _vWidth, _vHeight);
            }
            [self render];
        }
#else
       // [self render];
#endif
        
    }
    
#ifdef DEBUG
    
    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
    {
        printf("GL_ERROR=======>%d\n", err);
    }
    
    struct timeval nowtime;
    gettimeofday(&nowtime, NULL);
    if (nowtime.tv_sec != _time.tv_sec)
    {
        //printf("视频 %ld 帧率:   %ld\n", (long)self.tag, (long)_frameRate);
        memcpy(&_time, &nowtime, sizeof(struct timeval));
        _frameRate = 1;
    }
    else
    {
        _frameRate++;
    }
    
#endif
}

- (void)setVideoSize:(GLuint)width height:(GLuint)height
{
    _videoW = width;
    _videoH = height;
    if(blackData_goble!=NULL)
    {
        free(blackData_goble);
    }
    
    blackData_goble = malloc(width * height * 1.5);
	if(blackData_goble!=NULL)
    {
        memset(blackData_goble, 0x0, width * height * 1.5);
        [EAGLContext setCurrentContext:_glContext];
        //GL_RED_EXT
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width, height, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData_goble);
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData_goble + width * height);
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData_goble + width * height * 5 / 4);
        //free(blackData_goble);
    }
    
    //free(blackData);
}


- (void)clearFrame
{
    if ([self window])
    {
        [EAGLContext setCurrentContext:_glContext];
        glClearColor(0.0, 0.0, 0.0, 0.1);
        glClear(GL_COLOR_BUFFER_BIT);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
        [_glContext presentRenderbuffer:GL_RENDERBUFFER];
    }
    
}


#if 0
- (void)clearFrame:(UIImage *)img
{
    void *blackData = malloc(640 * 360 * 1.5);
    if(blackData)
        //bzero(blackData, width * height * 1.5);
        memset(blackData, 0x0, 640 * 360 * 1.5);
    
    GLuint texture = [self createOGLTexture:img];
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, 640, 360, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData);
    free(blackData);
    
    //glBegin(GL_QUADS);
    //glTexCoord2d(0.0, 0.0);
    //glVertex2d(-1.0, -1.0);
    //glTexCoord2d(1.0, 0.0); glVertex2d(+1.0, -1.0);
    //glTexCoord2d(1.0, 1.0); glVertex2d(+1.0, +1.0);
    //glTexCoord2d(0.0, 1.0); glVertex2d(-1.0, +1.0);
    //glEnd();
}




-(GLuint)createOGLTexture:(UIImage *)image
{
    //转换为CGImage，获取图片基本参数
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    //绘制图片
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);
    //纹理一些设置，可有可无
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //生成纹理
    glEnable(GL_TEXTURE_2D);
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    //绑定纹理位置
    glBindTexture(GL_TEXTURE_2D, 0);
    //释放内存
    CGContextRelease(context);
    free(imageData);
    return textureID;
}
#endif

@end
