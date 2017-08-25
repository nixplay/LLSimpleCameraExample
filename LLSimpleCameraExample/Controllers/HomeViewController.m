//
//  HomeViewController.m
//  LLSimpleCameraExample
//
//  Created by Ömer Faruk Gül on 29/10/14.
//  Copyright (c) 2014 Ömer Faruk Gül. All rights reserved.
//

#import "HomeViewController.h"
#import "ViewUtils.h"
#import "ImageViewController.h"
#import "VideoViewController.h"
#import "MRProgress.h"
@interface HomeViewController ()
@property (strong, nonatomic) LLSimpleCamera *camera;
@property (strong, nonatomic) UILabel *errorLabel;
@property (strong, nonatomic) UILabel *timeLabel;
@property (strong, nonatomic) MRCircularProgressView *recordTimeProgress;
@property (strong, nonatomic) UIButton *snapButton;
@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UISegmentedControl *segmentedControl;
@end

@implementation HomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    // ----- initialize camera -------- //
    
    // create camera vc
    self.camera = [[LLSimpleCamera alloc] initWithQuality:AVCaptureSessionPresetHigh
                                                 position:LLCameraPositionRear
                                             videoEnabled:YES];
    self.camera.maximumVideoDuration = 10;//in second
    // attach to a view controller
    [self.camera attachToViewController:self withFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    
    // read: http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload
    // you probably will want to set this to YES, if you are going view the image outside iOS.
    self.camera.fixOrientationAfterCapture = NO;
    
    // take the required actions on a device change
    __weak typeof(self) weakSelf = self;
    [self.camera setOnDeviceChange:^(LLSimpleCamera *camera, AVCaptureDevice * device) {
        
        NSLog(@"Device changed.");
        
        // device changed, check if flash is available
        if([camera isFlashAvailable]) {
            weakSelf.flashButton.hidden = NO;
            
            if(camera.flash == LLCameraFlashOff) {
                weakSelf.flashButton.selected = NO;
            }
            else {
                weakSelf.flashButton.selected = YES;
            }
        }
        else {
            weakSelf.flashButton.hidden = YES;
        }
    }];
    
    [self.camera setOnError:^(LLSimpleCamera *camera, NSError *error) {
        NSLog(@"Camera error: %@", error);
        
        if([error.domain isEqualToString:LLSimpleCameraErrorDomain]) {
            if(error.code == LLSimpleCameraErrorCodeCameraPermission ||
               error.code == LLSimpleCameraErrorCodeMicrophonePermission) {
                
                if(weakSelf.errorLabel) {
                    [weakSelf.errorLabel removeFromSuperview];
                }
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                label.text = @"We need permission for the camera.\nPlease go to your settings.";
                label.numberOfLines = 2;
                label.lineBreakMode = NSLineBreakByWordWrapping;
                label.backgroundColor = [UIColor clearColor];
                label.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:13.0f];
                label.textColor = [UIColor whiteColor];
                label.textAlignment = NSTextAlignmentCenter;
                [label sizeToFit];
                label.center = CGPointMake(screenRect.size.width / 2.0f, screenRect.size.height / 2.0f);
                weakSelf.errorLabel = label;
                [weakSelf.view addSubview:weakSelf.errorLabel];
            }
        }
    }];
    
    [self.camera setOnRecordingTime:^(double recordedTime, double maxTime) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(weakSelf.camera.isRecording){
                if(weakSelf.recordTimeProgress == nil ){
                    UILabel *timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 12)];
                    timeLabel.layer.cornerRadius = timeLabel.size.height*0.5f;
                    timeLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
                    timeLabel.center = CGPointMake(screenRect.size.width / 2.0f, screenRect.size.height / 2.0f);
                    timeLabel.top = timeLabel.size.height+10;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.text = [weakSelf timeFormatted:floor(recordedTime)];
                    [timeLabel sizeToFit];
                    weakSelf.timeLabel = timeLabel;
                    [weakSelf.view addSubview:weakSelf.timeLabel];
                    
                    MRCircularProgressView *recordTimeProgress = [[MRCircularProgressView alloc] initWithFrame:CGRectZero];
                    recordTimeProgress.center = CGPointMake(screenRect.size.width / 2.0f, screenRect.size.height / 2.0f);
                    recordTimeProgress.tintColor = [UIColor whiteColor];
                    recordTimeProgress.lineWidth = 5;
                    [recordTimeProgress setProgress:recordedTime/maxTime animated:YES];
                    [recordTimeProgress setMayStop:YES];
                    [recordTimeProgress setUserInteractionEnabled:NO];
                    
                    recordTimeProgress.size = CGSizeMake(weakSelf.snapButton.width, weakSelf.snapButton.width);
                    weakSelf.recordTimeProgress = recordTimeProgress;
                    
                    [weakSelf.view addSubview:weakSelf.recordTimeProgress];
                }else{
                    if(self.recordTimeProgress.superview == nil){
                        [weakSelf.view addSubview:weakSelf.recordTimeProgress];
                    }
                    if(self.timeLabel.superview ==nil){
                        [weakSelf.view addSubview:weakSelf.timeLabel];
                    }else{
                        weakSelf.timeLabel.text = [weakSelf timeFormatted:floor(recordedTime)];
                    }
                    [weakSelf.recordTimeProgress setProgress:recordedTime/maxTime animated:YES];
                }
            }
        });
        
        
        
    }];
    
    
    // ----- camera buttons -------- //
    
    // snap button to capture image
    self.snapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.snapButton.frame = CGRectMake(0, 0, 70.0f, 70.0f);
    self.snapButton.clipsToBounds = YES;
    self.snapButton.layer.cornerRadius = self.snapButton.width / 2.0f;
    self.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.snapButton.layer.borderWidth = 2.0f;
    self.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.snapButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.snapButton.layer.shouldRasterize = YES;
    [self.snapButton addTarget:self action:@selector(snapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.snapButton addGestureRecognizer:longPress];
    
    [self.view addSubview:self.snapButton];
    
    // button to toggle flash
    self.flashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.flashButton.frame = CGRectMake(0, 0, 16.0f + 20.0f, 24.0f + 20.0f);
    self.flashButton.tintColor = [UIColor whiteColor];
    [self.flashButton setImage:[UIImage imageNamed:@"camera-flash.png"] forState:UIControlStateNormal];
    self.flashButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.flashButton addTarget:self action:@selector(flashButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashButton];
    
    if([LLSimpleCamera isFrontCameraAvailable] && [LLSimpleCamera isRearCameraAvailable]) {
        // button to toggle camera positions
        self.switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.switchButton.frame = CGRectMake(0, 0, 29.0f + 20.0f, 22.0f + 20.0f);
        self.switchButton.tintColor = [UIColor whiteColor];
        [self.switchButton setImage:[UIImage imageNamed:@"camera-switch.png"] forState:UIControlStateNormal];
        self.switchButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
        [self.switchButton addTarget:self action:@selector(switchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.switchButton];
    }
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Picture",@"Video"]];
    self.segmentedControl.frame = CGRectMake(12.0f, screenRect.size.height - 67.0f, 120.0f, 32.0f);
    self.segmentedControl.selectedSegmentIndex = 0;
    self.segmentedControl.tintColor = [UIColor whiteColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.segmentedControl];
}


- (NSString *)timeFormatted:(int)totalSeconds
{
    
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}


- (void)segmentedControlValueChanged:(UISegmentedControl *)control
{
    NSLog(@"Segment value changed!");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // start the camera
    [self.camera start];
}

/* camera button methods */

- (void)switchButtonPressed:(UIButton *)button
{
    [self.camera togglePosition];
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)flashButtonPressed:(UIButton *)button
{
    if(self.camera.flash == LLCameraFlashOff) {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOn];
        if(done) {
            self.flashButton.selected = YES;
            self.flashButton.tintColor = [UIColor yellowColor];
        }
    }
    else {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOff];
        if(done) {
            self.flashButton.selected = NO;
            self.flashButton.tintColor = [UIColor whiteColor];
        }
    }
}

- (void)snapButtonPressed:(UIButton *)button
{
    __weak typeof(self) weakSelf = self;
    
    if(self.segmentedControl.selectedSegmentIndex == 0) {
        // capture
        [self.camera capture:^(LLSimpleCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error) {
            if(!error) {
                ImageViewController *imageVC = [[ImageViewController alloc] initWithImage:image];
                [weakSelf presentViewController:imageVC animated:NO completion:nil];
            }
            else {
                NSLog(@"An error has occured: %@", error);
            }
        } exactSeenImage:YES];
        
    } else {
        [self toggleVideoRecording];
    }
}

-(void) longPress:(UILongPressGestureRecognizer*)sender {
    switch(sender.state){
        case UIGestureRecognizerStatePossible:
            NSLog(@"UIGestureRecognizerStatePossible.");
            break;
        case UIGestureRecognizerStateBegan:
            NSLog(@"UIGestureRecognizerStateBegan.");
            if(!self.camera.isRecording) {
                [self startRecording];
                
            }
            break;
        case
        UIGestureRecognizerStateChanged:
            NSLog(@"UIGestureRecognizerStateChanged.");
            break;
        case UIGestureRecognizerStateEnded:
            NSLog(@"UIGestureRecognizerStateEnded.");
            if(self.camera.isRecording){
                [self stopRecording];
            }

            break;
        case UIGestureRecognizerStateCancelled:
            NSLog(@"UIGestureRecognizerStateCancelled.");
            break;
        case UIGestureRecognizerStateFailed:
            NSLog(@"UIGestureRecognizerStateFailed.");
            break;
    }
}

-(void) toggleVideoRecording{
    
    if(!self.camera.isRecording) {
        [self startRecording];
        
    } else {
        [self stopRecording];
    }
}

-(void) startRecording{
    __weak typeof(self) weakSelf = self;
    if(!self.camera.isRecording) {
        self.segmentedControl.hidden = YES;
        self.flashButton.hidden = YES;
        self.switchButton.hidden = YES;
        if(self.timeLabel){
            self.timeLabel.hidden = NO;
        }
        self.snapButton.layer.borderColor = [UIColor redColor].CGColor;
        self.snapButton.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
        
        // start recording
        NSURL *outputURL = [[[self applicationDocumentsDirectory]
                             URLByAppendingPathComponent:@"test1"] URLByAppendingPathExtension:@"mov"];
        [self.camera startRecordingWithOutputUrl:outputURL didRecord:^(LLSimpleCamera *camera, NSURL *outputFileUrl, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.segmentedControl.hidden = NO;
                weakSelf.flashButton.hidden = NO;
                weakSelf.switchButton.hidden = NO;
                if(weakSelf.timeLabel){
                    weakSelf.timeLabel.hidden = YES;
                }
                weakSelf.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
                weakSelf.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
                [weakSelf.recordTimeProgress setProgress:0 animated:NO];
                [weakSelf.recordTimeProgress removeFromSuperview];
            });
            VideoViewController *vc = [[VideoViewController alloc] initWithVideoUrl:outputFileUrl];
            [weakSelf.navigationController pushViewController:vc animated:YES];
        }];
    }
}

-(void) stopRecording{
    if(self.camera.isRecording){
        self.segmentedControl.hidden = NO;
        self.flashButton.hidden = NO;
        self.switchButton.hidden = NO;
        if(self.timeLabel){
            self.timeLabel.hidden = YES;
        }
        self.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
        self.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        
        [self.camera stopRecording];
    }
}

/* other lifecycle methods */

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.camera.view.frame = self.view.contentBounds;
    
    self.snapButton.center = self.view.contentCenter;
    self.snapButton.bottom = self.view.height - 15.0f;
    if(self.recordTimeProgress != nil){
        self.recordTimeProgress.center = self.view.contentCenter;
        self.recordTimeProgress.bottom = self.view.height - 15.0f;
    }
    if(self.timeLabel != nil){
        self.timeLabel.center = self.view.contentCenter;
        self.timeLabel.bottom = self.timeLabel.size.height+10;
    }
    self.flashButton.center = self.view.contentCenter;
    self.flashButton.top = 5.0f;
    
    self.switchButton.top = 5.0f;
    self.switchButton.right = self.view.width - 5.0f;
    
    self.segmentedControl.left = 12.0f;
    self.segmentedControl.bottom = self.view.height - 35.0f;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
