//
//  JH_OpenGLView.h
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#include <sys/time.h>

@interface JH_OpenGLView : UIView
{
	
}
@property  (assign,nonatomic)  int              nDispStyle;
#pragma mark  ----- ----
- (void)displayYUV420pData:(void *)data width:(NSInteger)w height:(NSInteger)h;
- (void)clearFrame;
//-(void)SetRotation:(int)n;
@end
