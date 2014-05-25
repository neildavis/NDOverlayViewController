//
//  NDOverlayViewController.h
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

#import <UIKit/UIKit.h>

/** Defines the edge that the overlaying view is anchored to */
typedef NS_ENUM(NSUInteger, NDOverlayEdge)
{
    /** Overlay positioned above and animates on downwards  */
    NDOverlayEdgeTop = 0,
    /** Overlay positioned below and animates on upwards */
    NDOverlayEdgeBottom,
    /** Overlay positioned to left and animates on to right */
    NDOverlayEdgeLeft,
    /** Overlay positioned to right and animates on to left */
    NDOverlayEdgeRight
};

/** Completion block used for animations */
typedef void (^NDOverlayAnimationCompletion)(BOOL finished);

/**
 A container view controller overlaying one view controller over another, with animated transitions
 An experiment to create a container view controller
 */
@interface NDOverlayViewController : UIViewController

/** Designated initializer */
- (instancetype) initWithUnderlyingViewController:(UIViewController*)underlyingVC overlayingViewController:(UIViewController*)overlayingVC;

/** The 'bottom' view controller that is displayed when not being overlaid */
@property (nonatomic, strong) UIViewController *underlyingViewController;
/** the 'top' view controller that is overlaid over underlyingViewController */
@property (nonatomic, strong) UIViewController *overlayingViewController;
/** Set the overlaying view controller and animate from edge of view into offset postion */
- (void) setOverlayingViewController:(UIViewController *)overlayingViewController animated:(BOOL)animated completion:(NDOverlayAnimationCompletion)completion;
/** The animation curve to use when animating the addition of the overlaying view via setOverlayingViewController:animated:completion: Defaults to UIViewAnimationCurveEaseOut */
@property (nonatomic) UIViewAnimationCurve addOverlayingViewAnimationCurve;
/** The animation curve to use when animating the removal of the overlaying view via setOverlayingViewController:animated:completion: Defaults to UIViewAnimationCurveEaseIn */
@property (nonatomic) UIViewAnimationCurve removeOverlayingViewAnimationCurve;
/** The duration to use when animating the adding or removal of the overlaying view via setOverlayingViewController:animated:completion: Defaults to 0.333 secs */
@property (nonatomic) NSTimeInterval addRemoveOverlayingViewAnimationDuration;

/** The distance in points that the overlayingViewController.view should extend from overlayEdge in the closed position. Default=44.0 */
@property (nonatomic) CGFloat overlayOffset;
/** The edge that the overlaying view controller is anchored too. Also determines the animation direction. Default=NDOverlayEdgeBottom */
@property (nonatomic) NDOverlayEdge overlayFromEdge;
/** Determines whether the frame of underlyingViewController.view is reduced (NO) by overlayOffset at the corresponding edge. Default is NO */
@property (nonatomic) BOOL viewsOverlapAtOffset;

/**
 Determines the maximum extent to which the overlaying view will cover the underlying view (including the value of overlayOffset)
 Only valid if > 0.0, otherwise, overlaying view will take full extent. Defaults to 0.0 (disabled)
 Minimum valid value is >= overlayOffset. Values between 0.0 and overlayOffset will be rounded up to overlayOffset
 */
@property (nonatomic) CGFloat maxOverlayExtent;

/** Determines whether the overlaying view recognizes pan gestures to set open/close state (animated) Default is NO */
@property (nonatomic) BOOL overlayViewRecognizesPanGestures;
/** Access to the overlay vew pan gesture recognizer, if active */
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *overlayViewPanGestureRecognizer;
/** The threshold ratio of translation required to trigger a pan gesture for the appropriate edge (horiz/vert or vert/horiz depending on overlayFromEdge) Default=2.0 */
@property (nonatomic) CGFloat overlayPanGestureRatioTriggerThreshold;

/** Determines whether the overlaying view controller is open (covering underlying to maxOverlayExtent) or closed (at overlayOffset) */
@property (nonatomic) BOOL overlayingViewControllerOpen;
/** Set overlayingControllerOpen state, animating from current position */
- (void) setOverlayingViewControllerOpen:(BOOL)open animated:(BOOL)animated completion:(NDOverlayAnimationCompletion)completion;
/** The animation curve to use when animating the opening of the overlaying view via setOverlayingViewControllerOpen:animated:completion: Defaults to UIViewAnimationCurveEaseOut */
@property (nonatomic) UIViewAnimationCurve openOverlayingViewAnimationCurve;
/** The animation curve to use when animating the closing of the overlaying view via setOverlayingViewControllerOpen:animated:completion: Defaults to UIViewAnimationCurveEaseOut */
@property (nonatomic) UIViewAnimationCurve closeOverlayingViewAnimationCurve;
/** The duration to use when animating the opening/closing of the overlaying view via setOverlayingViewControllerOpen:animated:completion: Defaults to 0.333 secs */
@property (nonatomic) NSTimeInterval defaultOpenCloseOverlayingViewAnimationDuration;
/** The minimum duration to use when animating the opening/closing of the overlaying view via a pan gesture (determines max velocity of gesture) Defaults to 0.1 secs*/
@property (nonatomic) NSTimeInterval minimumPanOpenCloseOverlayingViewAnimationDuration;
/** The maximum duration to use when animating the opening/closing of the overlaying view via a pan gesture (determines min velocity of gesture) Defaults to 0.333 secs */
@property (nonatomic) NSTimeInterval maximumPanOpenCloseOverlayingViewAnimationDuration;

@end
