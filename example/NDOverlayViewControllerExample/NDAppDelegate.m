//
//  NDAppDelegate.m
//  NDOverlayViewControllerExample
//
//  Created by Neil Davis on 24/05/2014.
//  Copyright (c) 2014 Neil Davis. All rights reserved.
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

#import "NDAppDelegate.h"
#import "NDOverlayViewController.h"
#import "UIViewController+NDOverlayViewController.h"
#import "NDViewController.h"

@implementation NDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    // Create window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    // Create 4 instances of NDOverlayViewController, one for each edge
    NSMutableArray *overlayViewControllers = [[NSMutableArray alloc] initWithCapacity:4];
    NSArray *titles = @[@"Top", @"Bottom", @"Left", @"Right"];
    for (NDOverlayEdge edge = NDOverlayEdgeTop; edge <= NDOverlayEdgeRight; edge++)
    {
        NDViewController *underlyingVC = [[NDViewController alloc] init];
        underlyingVC.view.backgroundColor = [UIColor blueColor];
        [underlyingVC.controlView addTarget:self action:@selector(didTouchUpInsideUnderlyingViewContoller:) forControlEvents:UIControlEventTouchUpInside];
        // Start with ONLY an underlying view controller. Tapping in this view will add (or remove) the overlaying view controller
        NDOverlayViewController * overlayVC = [[NDOverlayViewController alloc] initWithUnderlyingViewController:underlyingVC overlayingViewController:nil];
        overlayVC.viewsOverlapAtOffset = (edge % 2 == 0);   // One of each orientation overlaps
        overlayVC.overlayViewRecognizesPanGestures = YES;
        overlayVC.overlayFromEdge = edge;
        if (UIUserInterfaceIdiomPad == [UIDevice currentDevice].userInterfaceIdiom)
        {
            // On iPad limit the extent of the overlaying view
            overlayVC.maxOverlayExtent = 400;
        }
        NSString *title = titles[edge];
        UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:nil tag:edge];
        overlayVC.title = title;
        overlayVC.tabBarItem = tabBarItem;
        [overlayViewControllers addObject:overlayVC];
    }
    
    // Put 4 overlay controller into a tab bar controller.
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    if ([tabBarController.tabBar respondsToSelector:@selector(setTranslucent:)])
    {
        // iOS 7+ only
        tabBarController.tabBar.translucent = NO;
        tabBarController.tabBar.barStyle = UIBarStyleBlackOpaque;
    }
    tabBarController.viewControllers = overlayViewControllers;
    tabBarController.title = @"Overlay VC Example";
    
    // Put tab bar controller into a navigation controller.
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:tabBarController];
    navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    navigationController.navigationBar.translucent = NO;
    
    // Make navigation controller the root view controller for the window
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Private methods

- (NDViewController*) overlyingViewController
{
    NDViewController *overlayingVC = [[NDViewController alloc] init];
    overlayingVC.view.backgroundColor = [UIColor greenColor];
    [overlayingVC.controlView addTarget:self action:@selector(didTouchUpInsideOverlayingViewContoller:) forControlEvents:UIControlEventTouchUpInside];
    // Reduce alpha of overlaying view so we can clearly see when underlying view frame is modified
    // in response to setting viewsOverlapAtOffset property of NDOverlayViewController
    overlayingVC.view.alpha = 0.66;
    return overlayingVC;
}

- (UINavigationController*) navigationController
{
    return (UINavigationController*)self.window.rootViewController;
}

- (UITabBarController*) tabBarController
{
    return self.navigationController.viewControllers[0];
}

- (void) didTouchUpInsideUnderlyingViewContoller:(UIControl*)sender
{
    // Touching in the underlying view controller's view will toggle add/remove of the overlaying view controller
    NDOverlayViewController *overlayVC = (NDOverlayViewController*)self.tabBarController.selectedViewController;
    if (overlayVC.overlayingViewController)
    {
        [overlayVC setOverlayingViewController:nil animated:YES completion:^(BOOL finished){
            NSLog(@"Removed overlying view controller");
        }];
    }
    else
    {
        [overlayVC setOverlayingViewController:[self overlyingViewController] animated:YES completion:^(BOOL finished){
            NSLog(@"Added overlying view controller");
        }];
    }
}

- (void) didTouchUpInsideOverlayingViewContoller:(UIControl*)sender
{
    // Touching in the overlaying view controller's view will toggle open/close of overlaying view
    __weak NDOverlayViewController *overlayVC = (NDOverlayViewController*)self.tabBarController.selectedViewController;
    BOOL overlayOpen = overlayVC.overlayingViewControllerOpen;
    [overlayVC setOverlayingViewControllerOpen:!overlayOpen animated:YES completion:^(BOOL finished){
        NSLog(@"Overlay complete, overlayOpen=%d", overlayVC.overlayingViewControllerOpen);
    }];
}

@end
