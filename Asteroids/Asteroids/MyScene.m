//
//  MyScene.m
//  Asteroids
//
//  Created by Chris Lesch on 6/9/14.
//  Copyright (c) 2014 iD Tech. All rights reserved.
//

#import "MyScene.h"
#import "GameOver.h"

#define MAX_VELOCITY 25.0

@implementation MyScene



-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        rocketCategory = 0x1 << 0;
        asteroidCategory = 0x1 << 1;
        wallCategory = 0x1 << 3;
        
        /* Setup your scene here */
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        self.scaleMode = SKSceneScaleModeAspectFill;
        self.physicsWorld.contactDelegate = self;

        //Create the DPad
        [self createDPad];
        
        //Let's keeep our spaceship within the bounds of the screen!
        SKPhysicsBody* borderBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsBody = borderBody;
        self.physicsBody.friction = 0.0f;
        self.physicsBody.categoryBitMask = wallCategory;
        
        //Set up the player spaceship sprite.
        self.playerSprite = [Spaceship spriteNodeWithImageNamed:@"Spaceship"];
        [self.playerSprite setScale:0.15];
        [self.playerSprite setMVelocity:0];
        [self.playerSprite setRVelocity:0];
        [self.playerSprite setPosition: CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))];
        [self.playerSprite setName:@"playerSprite"];
        
        [self.playerSprite setPhysicsBody:[SKPhysicsBody bodyWithCircleOfRadius:self.playerSprite.frame.size.width/2.3]];
        [self.playerSprite.physicsBody setLinearDamping:1.0];
        [self.playerSprite.physicsBody setUsesPreciseCollisionDetection:YES];
        [self.playerSprite.physicsBody setAllowsRotation:NO];
        [self.playerSprite.physicsBody setDynamic:YES];
        
        self.playerSprite.physicsBody.categoryBitMask = rocketCategory;
        self.playerSprite.physicsBody.collisionBitMask = wallCategory;
        self.playerSprite.physicsBody.contactTestBitMask = asteroidCategory;
        [self addChild:self.playerSprite];
        
        self.currentDirection = none;
        
        [self.physicsWorld setGravity:CGVectorMake(0.0, 0.0)];
        
        
        
        NSString* emitterPath = [[NSBundle mainBundle]pathForResource:@"RocketFlame" ofType:@"sks"];
        self.playerSprite.flameEmitter = [NSKeyedUnarchiver unarchiveObjectWithFile:emitterPath];
        self.playerSprite.flameEmitter.position = CGPointMake(0, -150);
        [self.playerSprite.flameEmitter setZPosition:-1];
        [self.playerSprite.flameEmitter setScale:2.0];
        self.playerSprite.flameEmitter.hidden = YES;
        [self.playerSprite addChild:self.playerSprite.flameEmitter];
        
        self.gameOver = NO;
        
        //Instantiate the asteroid array.
        self.asteroids = [[NSMutableArray alloc]init];
        
        //Add the timer to the run loop.
        timer = [NSTimer timerWithTimeInterval:2 target:self selector:@selector(spawnAsteroid) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
    return self;
}

//After all of the physics calculations are done, limit the veloctiy if need be.
-(void)didEvaluateActions{
    double cur_velocity = sqrt(pow(self.playerSprite.physicsBody.velocity.dy,2)+pow(self.playerSprite.physicsBody.velocity.dx,2));
    float vDir = atan2(self.playerSprite.physicsBody.velocity.dy,self.playerSprite.physicsBody.velocity.dx);
    if(cur_velocity > MAX_VELOCITY){
        [self.playerSprite.physicsBody setVelocity:CGVectorMake(cos(vDir)*MAX_VELOCITY, sin(vDir)*MAX_VELOCITY)];
    }
}

//For each of the touches on the screen check to see if it is within the bounds of a button.
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        if (CGRectContainsPoint(self.upButtonSprite.frame, location)) {
            self.currentDirection = up;
            [self playSound:@"Thrusters" type:@"mp3"];
            self.playerSprite.flameEmitter.hidden = NO;
        }
        if (CGRectContainsPoint(self.downButtonSprite.frame, location)) {
            self.currentDirection = down;
        }
        if (CGRectContainsPoint(self.leftButtonSprite.frame, location)) {
            self.currentDirection = left;
        }
        if (CGRectContainsPoint(self.rightButtonSprite.frame, location)) {
            self.currentDirection = right;
        }
    }
}

//For each of the touches that moved, check to see if it is still on a button.
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        if (CGRectContainsPoint(self.upButtonSprite.frame, location)) {
            self.currentDirection = up;
        }
        else if (CGRectContainsPoint(self.downButtonSprite.frame, location)) {
            self.currentDirection = down;
        }
        else if (CGRectContainsPoint(self.leftButtonSprite.frame, location)) {
            self.currentDirection = left;
        }
        else if (CGRectContainsPoint(self.rightButtonSprite.frame, location)) {
            self.currentDirection = right;
        }
    }
}

//Note:  The way this is written, if you release two fingers at same time 
//velocities will never get set to zero!  So we need to know how many touches are left on the screen a more robust way.
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSSet *allTouches = [event allTouches];
    if (allTouches.count - touches.count == 0) {
        self.currentDirection = none;
    }
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        if (CGRectContainsPoint(self.upButtonSprite.frame, location) ||
            CGRectContainsPoint(self.downButtonSprite.frame, location)){
            //Why is it a good idea to make this hidden when not seen?  Look at your node count!!!
            self.playerSprite.flameEmitter.hidden = YES;
        }
        if (CGRectContainsPoint(self.leftButtonSprite.frame, location) ||
            CGRectContainsPoint(self.rightButtonSprite.frame, location)){
        }
    }
}

//Determines how to move the spaceship based on buttons pressed.  This makes the ship not move based on physics
//but things that hit it respond with physics.
-(void)update:(CFTimeInterval)currentTime {
    float currentZ = self.playerSprite.zRotation;
    if(self.currentDirection == up){
        [self.playerSprite.physicsBody applyForce:CGVectorMake(sinf(currentZ)*-500.0, cosf(currentZ)*500.0)];
    }else if(self.currentDirection == down){
        [self.playerSprite.physicsBody applyForce:CGVectorMake(sinf(currentZ)*500.0, cosf(currentZ)*-500.0)];
    }else if(self.currentDirection == left){
        [self.playerSprite setZRotation:currentZ+M_PI*2.0/180.0];
    }else if(self.currentDirection == right){
        [self.playerSprite setZRotation:currentZ-M_PI*2.0/180.0];
    }
}

//A function that is called to create a DPad controller.
-(void)createDPad {
    //Connect the images to the sprites.
    self.upButtonSprite = [SKSpriteNode spriteNodeWithImageNamed:@"Arrow"];
    self.downButtonSprite = [SKSpriteNode spriteNodeWithImageNamed:@"Arrow"];
    self.leftButtonSprite = [SKSpriteNode spriteNodeWithImageNamed:@"Arrow"];
    self.rightButtonSprite = [SKSpriteNode spriteNodeWithImageNamed:@"Arrow"];
    
    //Position the arrows in the bottom left corner.  Note where (0,0) is.
    [self.upButtonSprite setPosition:CGPointMake(41,75)];
    [self.downButtonSprite setPosition:CGPointMake(41,25)];
    [self.leftButtonSprite setPosition:CGPointMake(16,50)];
    [self.rightButtonSprite setPosition:CGPointMake(65,50)];

    
    //Rotate the arrows to point the right direction.
    [self.downButtonSprite setZRotation:M_PI];
    [self.leftButtonSprite setZRotation:M_PI_2];
    [self.rightButtonSprite setZRotation:-M_PI_2];
    
    //Add the sprites to the view.
    [self addChild:self.upButtonSprite];
    [self addChild:self.downButtonSprite];
    [self addChild:self.leftButtonSprite];
    [self addChild:self.rightButtonSprite];
}

//A function that is called to spawn an asteroid.
//This function is on a timer created in init.
-(void)spawnAsteroid {
    //Create a new Asteroid.
    Asteroid *asteroid = [Asteroid spriteNodeWithImageNamed:@"Asteroid"];
    //Shrink the scale
    [asteroid setScale:0.25];
    
    //Pick a random x-position to start at, and determine the height to start at.
    float randomXStartingPosition = (arc4random() % 280) + 50;
    [asteroid setPosition:CGPointMake(randomXStartingPosition, [UIScreen mainScreen].bounds.size.height+asteroid.size.height)];
    
    //Set the physics body properties.
    //Pick the velocity of the asteroid.
    float randomY = -((arc4random() % 20)/10.0f)-4.0;
    [asteroid setYVelocity:randomY];
    [asteroid setPhysicsBody:[SKPhysicsBody bodyWithCircleOfRadius:self.playerSprite.frame.size.width/3.0]];
    asteroid.physicsBody.usesPreciseCollisionDetection = YES;
    asteroid.physicsBody.categoryBitMask = asteroidCategory;
    [asteroid.physicsBody setCollisionBitMask:rocketCategory];
    [asteroid.physicsBody setContactTestBitMask:0];
    [asteroid.physicsBody setDynamic:YES];
    [asteroid.physicsBody setLinearDamping:0.0];
    
    
    [self.asteroids addObject:asteroid];
    [self addChild:asteroid];
    
    [asteroid.physicsBody applyImpulse:CGVectorMake(0.0, randomY)];
}

//The function handler that is called when two physics bodies come in contact.
- (void) didBeginContact:(SKPhysicsContact *)contact{
    SKSpriteNode *firstNode, *secondNode;
    
    firstNode = (SKSpriteNode *)contact.bodyA.node;
    secondNode = (SKSpriteNode *) contact.bodyB.node;
    
    //If the rocket is involved in a contact, we want to know about it.
    if (((contact.bodyA.categoryBitMask == rocketCategory)
        || (contact.bodyB.categoryBitMask == rocketCategory)) && (contact.bodyB.categoryBitMask != wallCategory && contact.bodyA.categoryBitMask != wallCategory))
    {
        self.gameOver = YES;
        [self playSound:@"Explosion" type:@"wav"];
        [self removeAllChildren];
        [timer invalidate];
        
        SKScene *gameOverScreen = [[GameOver alloc] initWithSize:self.size];
        SKTransition *sceneTrans = [SKTransition moveInWithDirection:SKTransitionDirectionUp duration:1.0];
        [self.view presentScene:gameOverScreen transition:sceneTrans];
    }

}

//A function to call the low level audio services and play a short sound.
- (void)playSound:(NSString *)fileName type:(NSString*)fileType{
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath],
                                     &soundID);
    AudioServicesPlaySystemSound (soundID);
}

@end
