//
//  SCSiriWaveformView.m
//  SCSiriWaveformView
//
//  Created by Stefan Ceriu on 12/04/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//
//  Modifed by KT.
//

#import "SCSiriWaveformView.h"

static const CGFloat kDefaultFrequency          = 1.5f;             // 진동수
static const CGFloat kDefaultAmplitude          = 0.0001f; //1.0f; // 진폭의 초기값
static const CGFloat kDefaultIdleAmplitude      = 0.00f;//0.01f;
static const CGFloat kDefaultNumberOfWaves      = 8.0f;    // 웨이브의 갯수
static const CGFloat kDefaultPhaseShift         = -0.05f;//-0.15f;
static const CGFloat kDefaultDensity            = 1.0f;
static const CGFloat kDefaultPrimaryLineWidth   = 0.f;//3.0f;
static const CGFloat kDefaultSecondaryLineWidth = 0.f;//1.0f;

@interface SCSiriWaveformView ()

@property (nonatomic, assign) CGFloat phase;
@property (nonatomic, assign) CGFloat amplitude;

@end

@implementation SCSiriWaveformView

- (instancetype)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		[self setup];
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super initWithCoder:aDecoder]) {
		[self setup];
	}
	
	return self;
}

- (void)setup
{
	//self.waveColor = [UIColor whiteColor];
	
	self.frequency = kDefaultFrequency;
	
	self.amplitude = kDefaultAmplitude;
	self.idleAmplitude = kDefaultIdleAmplitude;
	
	self.numberOfWaves = kDefaultNumberOfWaves;
	self.phaseShift = kDefaultPhaseShift;
	self.density = kDefaultDensity;
	
	self.primaryWaveLineWidth = kDefaultPrimaryLineWidth;
	self.secondaryWaveLineWidth = kDefaultSecondaryLineWidth;
}

- (void)updateWithLevel:(CGFloat)level
{
#if 0
    // kt kws lib 사용시
    self.phase += self.phaseShift;
    //CGFloat normalizedValue = [self _normalizedPowerLevelFromDecibels:level];
    //self.amplitude = fmax(normalizedValue, self.idleAmplitude);
    self.amplitude = fmax(level*200.0f, self.idleAmplitude);
#else
    // 기본 record 사용시
    self.phase += self.phaseShift;
    CGFloat normalizedValue = [self _normalizedPowerLevelFromDecibels:level];
    self.amplitude = fmax(normalizedValue, self.idleAmplitude);
#endif

    [self setNeedsDisplay];
}

- (CGFloat)_normalizedPowerLevelFromDecibels:(CGFloat)decibels
{
    if (decibels < -60.0f || decibels == 0.0f) {
        return 0.0f;
    }
    
    return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
}

// Thanks to Raffael Hannemann https://github.com/raffael/SISinusWaveView
- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, self.bounds);
    CGContextSetFillColorSpace(context, CGColorSpaceCreateDeviceRGB());
	
    self.backgroundColor = [UIColor clearColor];
	[self.backgroundColor set];
	CGContextFillRect(context, rect);
	
	// We draw multiple sinus waves, with equal phases but altered amplitudes, multiplied by a parable function.
    for (int i = 0; i < self.numberOfWaves; i++) {
		CGFloat strokeLineWidth = (i == 0 ? self.primaryWaveLineWidth : self.secondaryWaveLineWidth);
		CGContextSetLineWidth(context, strokeLineWidth);
		
		CGFloat halfHeight = CGRectGetHeight(self.bounds) / 2;
        CGFloat width = CGRectGetWidth(self.bounds);
		CGFloat mid = width / 2.0f;
		
        const CGFloat maxAmplitude = halfHeight - 10;
		
		CGFloat progress = 1.0f - (CGFloat)i / self.numberOfWaves;
        CGFloat normedAmplitude = (1.5f * progress - (2.0f / self.numberOfWaves)) * self.amplitude;
        
        switch (i) {
            case 1:
                self.waveColor = [UIColor redColor];
                break;
            case 2:
                self.waveColor = [UIColor purpleColor];
                break;
            case 3:
                self.waveColor = [UIColor redColor];
                break;
            case 4:
                self.waveColor = [UIColor magentaColor];
                break;
            case 5:
                self.waveColor = [UIColor purpleColor];
                break;
            case 6:
                self.waveColor = [UIColor purpleColor];
                break;
            case 7:
                self.waveColor = [UIColor magentaColor];
                break;
            default:
            case 0:
                self.waveColor = [UIColor redColor];
        }
        CGFloat multiplier = MIN(0.15 , (progress / 3.0f * 2.0f) + (1.0f / 3.0f));
        
        [[self.waveColor colorWithAlphaComponent:multiplier * CGColorGetAlpha(self.waveColor.CGColor)] set];
		
        CGMutablePathRef pathRef = CGPathCreateMutable();

        for (CGFloat x = 0; x < (width + self.density); x += self.density) {
			// We use a parable to scale the sinus wave, that has its peak in the middle of the view.
			CGFloat scaling = -pow(1 / mid * (x - mid), 2) + 1;
			
			CGFloat y = 0.f;
            switch (i) {
                case 1:
                    y = -scaling * maxAmplitude * normedAmplitude * sinf(3.5 * M_PI *(x / width) * self.frequency + self.phase) + halfHeight;
                    break;
                case 2:
                    y = scaling * maxAmplitude * normedAmplitude * cosf(3.4 * M_PI *(x / width) * self.frequency + self.phase) + halfHeight;
                    break;
                case 3:
                    y = -scaling * maxAmplitude * normedAmplitude * cosf(3.2 * M_PI *(x / width) * self.frequency + self.phase) + halfHeight;
                    break;
                case 4:
                    y = scaling * maxAmplitude * normedAmplitude * cosf(-3.1 * M_PI *(x / width) * self.frequency + self.phase) + halfHeight;
                    break;
                case 5:
                    y = scaling * maxAmplitude * normedAmplitude * sinf(-3.7 * M_PI *(x / width) * self.frequency + self.phase) + halfHeight;
                    break;
                case 6:
                    y = scaling * maxAmplitude * normedAmplitude * sinf(-2.7 * M_PI *(x / width) * self.frequency + self.phase) + halfHeight;
                    break;
                case 7:
                    y = scaling * maxAmplitude * normedAmplitude * cosf(-1.7 * M_PI *(x / width) * self.frequency + self.phase) + halfHeight;
                    break;
                default:
                    y = scaling * maxAmplitude * normedAmplitude * sinf(2 * M_PI *(x / width) * self.frequency + self.phase) + halfHeight;
                    break;
            }

			if (x == 0) {
                CGPathMoveToPoint(pathRef, NULL, x, y);//(context, x, y);
			} else {
                CGPathAddLineToPoint(pathRef, NULL, x , y);//(context, x, y);
			}

        }
        CGContextAddPath(context, pathRef);
        CGContextClosePath(context);
        
        CGContextSetBlendMode(context, kCGBlendModeColor);
        CGContextDrawPath(context, kCGPathFill);
        
        CGPathRelease(pathRef);
	}
}

@end
