//
//  JH_Item.m
//  JH_WifiCamera
//
//  Created by AivenLau on 2016/12/6.
//  Copyright © 2016年 joyhonest. All rights reserved.
//

#import "JH_Item.h"

@implementation JH_Item



-(id)init
{
    self=[super init];
    if(self)
    {
        _nSize = 0;
        _sName=nil;
        _Paraent = nil;
        _Child = [[NSMutableArray alloc] init];
    }
    return self;
}
-(void)Clean
{
    if(self.Child)
    {
        for(JH_Item *item in self.Child)
        {
            [item Clean];
        }
        self.Child=nil;
    }
}

-(NSInteger)InserChild:(JH_Item*)item
{
    if(item==nil)
        return -1;
    if(self.Child==nil)
    {
        _Child = [[NSMutableArray alloc] init];
    }
    [self.Child addObject:item];
    return self.Child.count;
}

@end
