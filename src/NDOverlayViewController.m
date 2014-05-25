//
//  NDOverlayViewController.m
//

/*
 Copyright (c) 2014 Neil Davis
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is furnished
 to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "NDOverlayViewController.h"
#import "UIViewController+NDOverlayViewController.h"

static const CGFloat        kDefaultOverlayOffset = 44.0;
static const NDOverlayEdge  kDefaultOverlayFromEdge = NDOverlayEdgeBottom;
static const CGFloat        kDefaultPanGestureRatioTriggerThreshold = 2.0;
static const UIViewAnimationCurve kDefaultAddOverlayingViewAnimationCurve = UIViewAnimationCurveEaseOut;
static const UIViewAnimationCurve kDefaultRemoveOverlayingViewAnimationCurve = UIViewAnimationCurveEaseIn;
static const NSTimeInterval kDefaultAddRemoveOverlayingViewAnimationDuration = 0.333;
static const UIViewAnimationCurve kDefaultOpenOverlayingViewAnimationCurve = UIViewAnimationCurveEaseOut;
static const UIViewAnimationCurve kDefaultCloseOverlayingViewAnimationCurve = UIViewAnimationCurveEaseIn;
static const NSTimeInterval kDefaultOpenCloseOverlayingViewAnimationDuration = 0.333;
static const NSTimeInterval kDefaultMinPanOpenCloseOverlayingViewAnimationDuration = 0.1;
static const NSTimeInterval kDefaultMaxPanOpenCloseOverlayingViewAnimationDuration = 0.333;

static inline UIViewAnimationOptions animationOptionsForAnimationCurve(UIViewAnimationCurve animationCurve)
{
    // This exploits the fact that the animation curve options are defined this way in UIView.h
    return animationCurve << 16;
}

@interface NDOverlayViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UIPanGestureRecognizer *overlayViewPanGestureRecognizer;

@end

@implementation NDOverlayViewController

@synthesize underlyingViewController = _underlyingViewController;
@synthesize overlayingViewController = _overlayingViewController;
@synthesize overlayingViewControllerOpen = _overlayingViewControllerOpen;
@synthesize overlayFromEdge = _overlayFromEdge;
@synthesize overlayOffset = _overlayOffset;
@synthesize viewsOverlapAtOffset = _viewsOverlapAtOffset;
@synthesize maxOverlayExtent = _maxOverlayExtent;
@synthesize overlayViewRecognizesPanGestures = _overlayViewRecognizesPanGestures;
@synthesize overlayViewPanGestureRecognizer = _overlayViewPanGestureRecognizer;
@synthesize overlayPanGestureRatioTriggerThreshold = _overlayPanGestureRatioTriggerThreshold;
@synthesize addOverlayingViewAnimationCurve = _addOverlayingViewAnimationCurve;
@synthesize removeOverlayingViewAnimationCurve = _removeOverlayingViewAnimationCurve;
@synthesize addRemoveOverlayingViewAnimationDuration = _addRemoveOverlayingViewAnimationDuration;
@synthesize openOverlayingViewAnimationCurve = _openOverlayingViewAnimationCurve;
@synthesize closeOverlayingViewAnimationCurve = _closeOverlayingViewAnimationCurve;
@synthesize defaultOpenCloseOverlayingViewAnimationDuration = _defaultOpenCloseOverlayingViewAnimationDuration;
@synthesize minimumPanOpenCloseOverlayingViewAnimationDuration = _minimumPanOpenCloseOverlayingViewAnimationDuration;
@synthesize maximumPanOpenCloseOverlayingViewAnimationDuration = _maximumPanOpenCloseOverlayingViewAnimationDuration;

- (instancetype) initWithUnderlyingViewController:(UIViewController*)underlyingVC overlayingViewController:(UIViewController*)overlayingVC
{
    self = [super init];
    if (self)
    {
        // Set defaults
        _overlayFromEdge = kDefaultOverlayFromEdge;
        _overlayOffset = kDefaultOverlayOffset;
        _overlayPanGestureRatioTriggerThreshold = kDefaultPanGestureRatioTriggerThreshold;
        _addOverlayingViewAnimationCurve = kDefaultAddOverlayingViewAnimationCurve;
        _removeOverlayingViewAnimationCurve = kDefaultRemoveOverlayingViewAnimationCurve;
        _addRemoveOverlayingViewAnimationDuration = kDefaultAddRemoveOverlayingViewAnimationDuration;
        _openOverlayingViewAnimationCurve = kDefaultOpenOverlayingViewAnimationCurve;
        _closeOverlayingViewAnimationCurve = kDefaultCloseOverlayingViewAnimationCurve;
        _defaultOpenCloseOverlayingViewAnimationDuration = kDefaultOpenCloseOverlayingViewAnimationDuration;
        _minimumPanOpenCloseOverlayingViewAnimationDuration = kDefaultMinPanOpenCloseOverlayingViewAnimationDuration;
        _maximumPanOpenCloseOverlayingViewAnimationDuration = kDefaultMaxPanOpenCloseOverlayingViewAnimationDuration;
        
        // Set view controllers. They are added during viewDidLoad:
        _underlyingViewController = underlyingVC;
        _overlayingViewController = overlayingVC;
    }
    return self;
}

- (void) setUnderlyingViewController:(UIViewController *)underlyingViewController
{
    [self removeUnderlyingViewController];
    _underlyingViewController = underlyingViewController;
    if (self.isViewLoaded)
    {
        [self addUnderlyingViewController];
    }
}

- (void) setOverlayingViewController:(UIViewController *)overlayingViewController
{
    [self setOverlayingViewController:overlayingViewController animated:NO completion:nil];
}

- (void) setOverlayingViewController:(UIViewController *)overlayingViewController animated:(BOOL)animated completion:(NDOverlayAnimationCompletion)completion
{
    if (overlayingViewController)
    {
        // when replacing we don't animate removal
        [self removeOverlayingViewControllerAnimated:NO completion:nil];
        _overlayingViewController = nil;
        [self updatePanGestureRecognizer];
    }
    else
    {
        // when setting to nil we can animate the removal
        [self removeOverlayingViewControllerAnimated:animated completion:^(BOOL finished){
            if (completion)
            {
                completion(finished);
            }
        }];
        _overlayingViewControllerOpen = NO;
    }
    _overlayingViewController = overlayingViewController;
    [self updatePanGestureRecognizer];
    
    if (self.isViewLoaded && _overlayingViewController)
    {
        [self addOverlayingViewControllerAnimated:animated completion:^(BOOL finished){
            if (completion)
            {
                completion(finished);
            }
        }];
    }
}

- (void) setViewsOverlapAtOffset:(BOOL)viewsOverlapAtOffset
{
    _viewsOverlapAtOffset = viewsOverlapAtOffset;
    [self.view setNeedsLayout];
}

- (void) setOverlayOffset:(CGFloat)overlayOffset
{
    _overlayOffset = MAX(0.0, overlayOffset);   // prevent -ve values
    if (_maxOverlayExtent > 0.0)
    {
        _maxOverlayExtent = MAX(_maxOverlayExtent, _overlayOffset); // constrain _maxOverlayExtent
    }
    [self.view setNeedsLayout];
}


- (void) setOverlayFromEdge:(NDOverlayEdge)overlayFromEdge
{
    _overlayFromEdge = overlayFromEdge;
    [self.view setNeedsLayout];
}

- (void) setMaxOverlayExtent:(CGFloat)maxOverlayExtent
{
    _maxOverlayExtent = maxOverlayExtent;
    if (maxOverlayExtent > 0.0)
    {
        _maxOverlayExtent = MAX(maxOverlayExtent, _overlayOffset); // constrain _maxOverlayExtent
    }
    [self.view setNeedsLayout];
}

- (void) setOverlayingViewControllerOpen:(BOOL)overlayingViewControllerOpen
{
    [self setOverlayingViewControllerOpen:NO animated:NO completion:nil];
}

- (void) setOverlayingViewControllerOpen:(BOOL)open animated:(BOOL)animated completion:(NDOverlayAnimationCompletion)completion
{
    if (_overlayingViewController)
    {
        UIViewController *overlayingViewController = _overlayingViewController;
        _overlayingViewControllerOpen = open;
        
        if (open)
        {
            [overlayingViewController willOpenAsOverlay];
        }
        else
        {
            [overlayingViewController willCloseAsOverlay];
        }
        
        void (^completionBlock)(BOOL) = ^(BOOL finished) {
            if (open)
            {
                [overlayingViewController didOpenAsOverlay];
            }
            else
            {
                [overlayingViewController didCloseAsOverlay];
            }
            if (completion)
            {
                completion(finished);
            }
        };
        
        CGRect overlayingFrame = open ? [self frameForOverlayingViewOpen] : [self frameForOverlayingViewOffsetAnimationEnd];
        if (animated)
        {
            UIViewAnimationCurve curve = open ? _openOverlayingViewAnimationCurve : _closeOverlayingViewAnimationCurve;
            UIViewAnimationOptions animOpts = animationOptionsForAnimationCurve(curve);
            
            [self animateOverlayingViewFrame:overlayingFrame duration:_defaultOpenCloseOverlayingViewAnimationDuration options:animOpts completion:^(BOOL finished) {
                completionBlock(finished);
            }];
        }
        else
        {
            overlayingViewController.view.frame = overlayingFrame;
            completionBlock(YES);
        }
    }
    else
    {
        _overlayingViewControllerOpen = NO;
        if (completion)
        {
            completion(YES);
        }
    }
}

- (void) animateOverlayingViewFrame:(CGRect)frame duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options completion:(NDOverlayAnimationCompletion)completion
{
    UIView *overlayingView = _overlayingViewController.view;
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        overlayingView.frame = frame;
    } completion:^(BOOL finished) {
        if (completion)
        {
            completion(finished);
        }
    }];
}

- (void) setOverlayViewRecognizesPanGestures:(BOOL)overlayViewRecognizesPanGestures
{
    _overlayViewRecognizesPanGestures = overlayViewRecognizesPanGestures;
    [self updatePanGestureRecognizer];
}

#pragma Private methods

- (void) removeUnderlyingViewController
{
    if (_underlyingViewController)
    {
        [_underlyingViewController willMoveToParentViewController:nil];
        [_underlyingViewController.view removeFromSuperview];
        [_underlyingViewController removeFromParentViewController];
        _underlyingViewController = nil;
    }
}

- (void) addUnderlyingViewController
{
    if (_underlyingViewController)
    {
        [self addChildViewController:_underlyingViewController];
        _underlyingViewController.view.frame = [self frameForUnderlyingView];
        [self.view insertSubview:_underlyingViewController.view atIndex:0];
        [_underlyingViewController didMoveToParentViewController:self];
    }
}

- (void) removeOverlayingViewControllerAnimated:(BOOL)animated completion:(NDOverlayAnimationCompletion)completion
{
    
    UIViewController *overlayingViewController = _overlayingViewController;
    void (^removeBlock)(BOOL) = ^(BOOL finished){
        [overlayingViewController willMoveToParentViewController:nil];
        [overlayingViewController.view removeFromSuperview];
        [overlayingViewController removeFromParentViewController];
        
        if (completion)
        {
            completion(finished);
        }
    };
    
    UIView *underlyingView = _underlyingViewController.view;
    CGRect underlyingFrame = self.view.bounds;
    if (animated && _overlayingViewController)
    {
        CGRect overlayingFrame = [self frameForOverlayingViewOffsetAnimationStart];
        UIViewAnimationOptions options = animationOptionsForAnimationCurve(_removeOverlayingViewAnimationCurve);
        [UIView animateWithDuration:_addRemoveOverlayingViewAnimationDuration delay:0.0 options:options animations:^{
            overlayingViewController.view.frame = overlayingFrame;
            underlyingView.frame = underlyingFrame;
        } completion:^(BOOL finished) {
            removeBlock(finished);
        }];
    }
    else
    {
        underlyingView.frame = underlyingFrame;
        removeBlock(YES);
    }
}

- (void) addOverlayingViewControllerAnimated:(BOOL)animated completion:(NDOverlayAnimationCompletion)completion
{
    if (_overlayingViewController)
    {
        [self addChildViewController:_overlayingViewController];
        CGRect overlayingFrame = animated ? [self frameForOverlayingViewOffsetAnimationStart] : [self frameForOverlayingViewOffsetAnimationEnd];
        CGRect underlyingFrame = [self frameForUnderlyingView];
        UIView *overlayingView = _overlayingViewController.view;
        UIView *underlyingView = _underlyingViewController.view;
        overlayingView.frame = overlayingFrame;
        [self.view addSubview:overlayingView];
        [_overlayingViewController didMoveToParentViewController:self];
        if (animated)
        {
            overlayingFrame = [self frameForOverlayingViewOffsetAnimationEnd];
            UIViewAnimationOptions options = animationOptionsForAnimationCurve(_addOverlayingViewAnimationCurve);
            [UIView animateWithDuration:_addRemoveOverlayingViewAnimationDuration delay:0.0 options:options animations:^{
                overlayingView.frame = overlayingFrame;
                underlyingView.frame = underlyingFrame;
            } completion:^(BOOL finished) {
                if (completion)
                {
                    completion(finished);
                }
            }];
        }
        else
        {
            underlyingView.frame = underlyingFrame;
            if (completion)
            {
                completion(YES);
            }
        }
    }
}

- (CGRect) frameForUnderlyingView
{
    CGRect frame = self.view.bounds;
    if (_overlayingViewController && !_viewsOverlapAtOffset)
    {
        switch (_overlayFromEdge)
        {
            case NDOverlayEdgeTop:
                frame.origin.y += _overlayOffset;
                // Intentional fall through
             case NDOverlayEdgeBottom:
                frame.size.height -= _overlayOffset;
                break;
            case NDOverlayEdgeLeft:
                frame.origin.x += _overlayOffset;
                // Intentional fall through
            case NDOverlayEdgeRight:
                frame.size.width -= _overlayOffset;
                break;
            default:
                break;
        }
    }
    return frame;
}

- (CGRect) frameForOverlayingViewOffsetAnimationStart
{
    CGRect frame = [self frameForOverlayingViewOpen];
    switch (_overlayFromEdge)
    {
        case NDOverlayEdgeTop:
            frame.origin.y -= (frame.size.height);
            break;
        case NDOverlayEdgeBottom:
            frame.origin.y += (frame.size.height);
            break;
        case NDOverlayEdgeLeft:
            frame.origin.x -= (frame.size.width);
            break;
        case NDOverlayEdgeRight:
            frame.origin.x += (frame.size.width);
            break;
        default:
            break;
    }
    return frame;
}

- (CGRect) frameForOverlayingViewOffsetAnimationEnd
{
    CGRect frame = [self frameForOverlayingViewOffsetAnimationStart];
    switch (_overlayFromEdge)
    {
        case NDOverlayEdgeTop:
            frame.origin.y += _overlayOffset;
            break;
        case NDOverlayEdgeBottom:
            frame.origin.y -= _overlayOffset;
            break;
        case NDOverlayEdgeLeft:
            frame.origin.x += _overlayOffset;
            break;
        case NDOverlayEdgeRight:
            frame.origin.x -= _overlayOffset;
            break;
        default:
            break;
    }
    return frame;
}

- (CGRect) frameForOverlayingViewOpen
{
    CGRect frame = self.view.bounds;
    if (_maxOverlayExtent > 0.0)
    {
        switch (_overlayFromEdge)
        {
            case NDOverlayEdgeBottom:
                frame.origin.y = frame.size.height - _maxOverlayExtent;
                // Intentional fall through
            case NDOverlayEdgeTop:
                frame.size.height = MIN(frame.size.height, _maxOverlayExtent);
                break;
            case NDOverlayEdgeRight:
                frame.origin.x = frame.size.width - _maxOverlayExtent;
                // Intentional fall through
            case NDOverlayEdgeLeft:
                frame.size.width = MIN(frame.size.width, _maxOverlayExtent);
                break;
            default:
                break;
        }
    }
    return frame;
}

- (void) updatePanGestureRecognizer
{
    if (_overlayViewRecognizesPanGestures && _overlayingViewController)
    {
        if (!_overlayViewPanGestureRecognizer)
        {
            _overlayViewPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didRecognizePanGesture:)];
            _overlayViewPanGestureRecognizer.delegate = self;
        }
        // Add pan recognizer to overlay view
        if (![_overlayingViewController.view.gestureRecognizers containsObject:_overlayViewPanGestureRecognizer])
        {
            [_overlayingViewController.view addGestureRecognizer:_overlayViewPanGestureRecognizer];
        }
    }
    else if (_overlayViewPanGestureRecognizer)
    {
        // Remove pan recognizer
        [_overlayingViewController.view removeGestureRecognizer:_overlayViewPanGestureRecognizer];
        _overlayViewPanGestureRecognizer = nil;
    }
}

#pragma mark - Gesture Handling

- (void) didRecognizePanGesture:(UIPanGestureRecognizer*)panGestureRecgognizer
{
    if (panGestureRecgognizer == _overlayViewPanGestureRecognizer)
    {
        switch (panGestureRecgognizer.state)
        {
            case UIGestureRecognizerStateBegan:
                [self handleGestureBeganWithRecognizer:panGestureRecgognizer];
                break;
                
            case UIGestureRecognizerStateChanged:
                [self handleGestureChangedWithRecognizer:panGestureRecgognizer];
                break;
                
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateCancelled:
            case UIGestureRecognizerStateFailed:
                [self handleGestureEndedWithRecognizer:panGestureRecgognizer];
                break;
                
            default:
                panGestureRecgognizer.enabled = YES;
                break;
        }
    }
}

- (void)handleGestureBeganWithRecognizer:(UIPanGestureRecognizer *)recognizer
{
    /*
    CGPoint velocity = [recognizer velocityInView:recognizer.view];
    CGPoint translation = [recognizer translationInView:recognizer.view];
    CGPoint translatedFrameOrigin = CGPointMake(recognizer.view.frame.origin.x + translation.x,
                                                recognizer.view.frame.origin.y + translation.y);
    NSLog(@"BEGIN translation=(%.0f,%.0f) translatedFrameOrigin=(%.0f,%.0f) velocity=(%.0f,%.0f)", translation.x, translation.y, translatedFrameOrigin.x, translatedFrameOrigin.y, velocity.x, velocity.y);
     */
}

- (void)handleGestureChangedWithRecognizer:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:recognizer.view];
    /*
    CGPoint translatedFrameOrigin = CGPointMake(recognizer.view.frame.origin.x + translation.x,
                                                recognizer.view.frame.origin.y + translation.y);
    CGPoint velocity = [recognizer velocityInView:recognizer.view];
    NSLog(@"CHANGED translation=(%.0f,%.0f) translatedFrameOrigin=(%.0f,%.0f) velocity=(%.0f,%.0f)", translation.x, translation.y, translatedFrameOrigin.x, translatedFrameOrigin.y, velocity.x, velocity.y);
     */
    
    // We need to constrain the translation between the fully open and fully closed frames
    CGRect openFrame = [self frameForOverlayingViewOpen];
    CGRect closedFrame = [self frameForOverlayingViewOffsetAnimationEnd];
    CGRect startFrame = _overlayingViewControllerOpen ? openFrame : closedFrame;    // Where the view was when gesture began
    // Apply translation within limits of start & limit frames
    CGRect newOverlayingViewFrame = startFrame;
    switch (_overlayFromEdge)
    {
        case NDOverlayEdgeTop:
            newOverlayingViewFrame.origin.y = MIN(openFrame.origin.y, MAX(closedFrame.origin.y, startFrame.origin.y + translation.y));
            break;
        case NDOverlayEdgeBottom:
            newOverlayingViewFrame.origin.y = MIN(closedFrame.origin.y, MAX(openFrame.origin.y, startFrame.origin.y + translation.y));
            break;
        case NDOverlayEdgeLeft:
            newOverlayingViewFrame.origin.x = MIN(openFrame.origin.x, MAX(closedFrame.origin.x, startFrame.origin.x + translation.x));
            break;
        case NDOverlayEdgeRight:
            newOverlayingViewFrame.origin.x = MIN(closedFrame.origin.x, MAX(openFrame.origin.x, startFrame.origin.x + translation.x));
            break;
        default:
            break;
    }
    _overlayingViewController.view.frame = newOverlayingViewFrame;
}

- (void)handleGestureEndedWithRecognizer:(UIPanGestureRecognizer *)recognizer
{
    CGPoint velocityVector = [recognizer velocityInView:recognizer.view];
    /*
    CGPoint translation = [recognizer translationInView:recognizer.view];
    CGPoint translatedFrameOrigin = CGPointMake(recognizer.view.frame.origin.x + translation.x,
                                                recognizer.view.frame.origin.y + translation.y);
    NSLog(@"ENDED translation=(%.0f,%.0f) translatedFrameOrigin=(%.0f,%.0f) velocity=(%.0f,%.0f)", translation.x, translation.y, translatedFrameOrigin.x, translatedFrameOrigin.y, velocityVector.x, velocityVector.y);
     */
    
    // Determine if final action is to leave the overlay view in the open or closed position based on velocity and edge and calculate duration
    BOOL open =     ((NDOverlayEdgeTop == _overlayFromEdge && velocityVector.y > 0.0) ||
                     (NDOverlayEdgeBottom == _overlayFromEdge && velocityVector.y < 0.0) ||
                     (NDOverlayEdgeLeft == _overlayFromEdge && velocityVector.x > 0.0) ||
                     (NDOverlayEdgeRight == _overlayFromEdge && velocityVector.x < 0.0));
    
    BOOL report = (open != _overlayingViewControllerOpen);
    if (report)
    {
        // Report via UIViewController (NDOverlayViewController) category
        if (open)
        {
            [_overlayingViewController willOpenAsOverlay];
        }
        else
        {
            [_overlayingViewController willCloseAsOverlay];
        }
    }
    
    CGRect newFrame = open ? [self frameForOverlayingViewOpen] : [self frameForOverlayingViewOffsetAnimationEnd];
    // Calculate duration to get from current frame to newFrame based on velocity
    CGPoint currentPos = recognizer.view.frame.origin;
    CGFloat distance = 0.0;
    CGFloat velocity = 0.0;
    switch (_overlayFromEdge)
    {
        case NDOverlayEdgeTop:
        case NDOverlayEdgeBottom:
            distance = fabs(newFrame.origin.y - currentPos.y);
            velocity = fabs(velocityVector.y);
            break;
        case NDOverlayEdgeLeft:
        case NDOverlayEdgeRight:
            distance = fabs(newFrame.origin.x - currentPos.x);
            velocity = fabs(velocityVector.x);
            break;
        default:
            break;
    }
    NSTimeInterval duration = MAX(_minimumPanOpenCloseOverlayingViewAnimationDuration, MIN(_maximumPanOpenCloseOverlayingViewAnimationDuration, distance / velocity));
    UIViewAnimationCurve curve = open ? _openOverlayingViewAnimationCurve : _closeOverlayingViewAnimationCurve;
    UIViewAnimationOptions animOpts = animationOptionsForAnimationCurve(curve);
    UIViewController *overlayVC = _overlayingViewController;
    [self animateOverlayingViewFrame:newFrame duration:duration options:animOpts completion:^(BOOL finished) {
        if (report)
        {
            // Report via UIViewController (NDOverlayViewController) category
            if (open)
            {
                [overlayVC didOpenAsOverlay];
            }
            else
            {
                [overlayVC didCloseAsOverlay];
            }
        }
    }];
    _overlayingViewControllerOpen = open;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == _overlayViewPanGestureRecognizer)
    {
        // Ensure the gesture meets the threshold translation for the appropriate orientation
        CGPoint translation = [_overlayViewPanGestureRecognizer translationInView:_overlayingViewController.view];
        BOOL horizEdge = (_overlayFromEdge == NDOverlayEdgeLeft || _overlayFromEdge == NDOverlayEdgeRight);
        return  (horizEdge && (fabs(translation.x)/fabs(translation.y) > _overlayPanGestureRatioTriggerThreshold)) ||
                (!horizEdge && (fabs(translation.y)/fabs(translation.x) > _overlayPanGestureRatioTriggerThreshold));
    }
    return YES;
}

#pragma mark - UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addUnderlyingViewController];
    [self addOverlayingViewControllerAnimated:NO completion:nil];
    [self updatePanGestureRecognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.underlyingViewController.view.frame = [self frameForUnderlyingView];
    if (_overlayingViewController)
    {
        if (_overlayingViewControllerOpen)
        {
            _overlayingViewController.view.frame = [self frameForOverlayingViewOpen];
        }
        else
        {
            _overlayingViewController.view.frame = [self frameForOverlayingViewOffsetAnimationEnd];
        }
    }
}

// iOS6+ Applications should use supportedInterfaceOrientations and/or shouldAutorotate..
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    BOOL underlying = [_underlyingViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
    BOOL overlaying = _overlayingViewController ? [_overlayingViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation] : YES;
    return underlying && overlaying;
}

// New Autorotation support (iOS6+)
- (BOOL)shouldAutorotate
{
    if (_overlayingViewController)
    {
        return [_underlyingViewController shouldAutorotate] && [_overlayingViewController shouldAutorotate];
    }
    return [_underlyingViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger supportedOrientations = [_underlyingViewController supportedInterfaceOrientations];
    if (_overlayingViewController)
    {
        supportedOrientations &= [_overlayingViewController supportedInterfaceOrientations];
    }
    return supportedOrientations;
}


@end
