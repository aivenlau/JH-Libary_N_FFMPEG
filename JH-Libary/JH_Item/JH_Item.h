//
//  JH_Item.h
//  JH_WifiCamera
//
//  Created by AivenLau on 2016/12/6.
//  Copyright © 2016年 joyhonest. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface JH_Item : NSObject
{
    
}
@property(strong,nonatomic)NSString         *sName;
@property(assign,nonatomic)int              nType;                 //0 - dir   1-  photo       2-video
@property(assign,nonatomic)uint64_t         nSize;
@property(strong,nonatomic)JH_Item          *Paraent;
@property(strong,nonatomic)NSMutableArray   *Child;


-(void)Clean;
-(NSInteger)InserChild:(JH_Item*)item;

@end
