
#import "RNMlKit.h"

#import <React/RCTBridge.h>

#import <FirebaseCore/FirebaseCore.h>
#import <FirebaseMLVision/FirebaseMLVision.h>

@implementation RNMlKit

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

static NSString *const detectionNoResultsMessage = @"Something went wrong";


RCT_REMAP_METHOD(deviceBarcodeRecognition, deviceBarcodeRecognition:(NSString *)imagePath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    if (!imagePath) {
        resolve(@NO);
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FIRVisionBarcodeDetectorOptions *options = [[FIRVisionBarcodeDetectorOptions alloc] initWithFormats: FIRVisionBarcodeFormatPDF417 | FIRVisionBarcodeFormatCode128 | FIRVisionBarcodeFormatEAN8];
        FIRVision *vision = [FIRVision vision];
        FIRVisionBarcodeDetector *barcodeDetector = [vision barcodeDetectorWithOptions: options];
        NSDictionary *d = [[NSDictionary alloc] init];
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imagePath]];
        UIImage *image = [UIImage imageWithData:imageData];
        
        if (!image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resolve(@NO);
            });
            return;
        }
        
        FIRVisionImage *handler = [[FIRVisionImage alloc] initWithImage:image];

        [barcodeDetector detectInImage:handler completion:^(NSArray<FIRVisionBarcode *> *barcodes, NSError *_Nullable error) {
            if (error != nil) {
                NSString *errorString = error ? error.localizedDescription : detectionNoResultsMessage;
                NSDictionary *pData = @{
                                        @"error": [NSMutableString stringWithFormat:@"On-Device text detection failed with error: %@", errorString],
                                        };
                // Running on background thread, don't call UIKit
                dispatch_async(dispatch_get_main_queue(), ^{
                    resolve(pData);
                });
                return;
            }

            NSMutableArray *output = [NSMutableArray array];
            for (FIRVisionBarcode *barcode in barcodes) {
                NSArray *corners = barcode.cornerPoints;

                NSString *displayValue = barcode.displayValue;
                NSString *rawValue = barcode.rawValue;
                [output addObject:displayValue]
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                resolve(output);
            });
        }];
    });
}

RCT_REMAP_METHOD(deviceTextRecognition, deviceTextRecognition:(NSString *)imagePath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    if (!imagePath) {
        resolve(@NO);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FIRVision *vision = [FIRVision vision];
        FIRVisionTextRecognizer *textRecognizer = [vision onDeviceTextRecognizer];
        NSDictionary *d = [[NSDictionary alloc] init];
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imagePath]];
        UIImage *image = [UIImage imageWithData:imageData];
        
        if (!image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resolve(@NO);
            });
            return;
        }
        
        FIRVisionImage *handler = [[FIRVisionImage alloc] initWithImage:image];

        [textRecognizer processImage:handler completion:^(FIRVisionText *_Nullable result, NSError *_Nullable error) {
            if (error != nil || result == nil) {
                NSString *errorString = error ? error.localizedDescription : detectionNoResultsMessage;
                NSDictionary *pData = @{
                                        @"error": [NSMutableString stringWithFormat:@"On-Device text detection failed with error: %@", errorString],
                                        };
                // Running on background thread, don't call UIKit
                dispatch_async(dispatch_get_main_queue(), ^{
                    resolve(pData);
                });
                return;
            }

            CGRect boundingBox;
            CGSize size;
            CGPoint origin;
            NSMutableArray *output = [NSMutableArray array];

            for (FIRVisionTextBlock *block in result.blocks) {
                NSMutableDictionary *blocks = [NSMutableDictionary dictionary];
                NSMutableDictionary *bounding = [NSMutableDictionary dictionary];
                NSString *blockText = block.text;

                blocks[@"resultText"] = result.text;
                blocks[@"blockText"] = block.text;
                blocks[@"bounding"] = bounding;
                [output addObject:blocks];

                for (FIRVisionTextLine *line in block.lines) {
                    NSMutableDictionary *lines = [NSMutableDictionary dictionary];
                    lines[@"lineText"] = line.text;
                    [output addObject:lines];

                    for (FIRVisionTextElement *element in line.elements) {
                        NSMutableDictionary *elements = [NSMutableDictionary dictionary];
                        elements[@"elementText"] = element.text;
                        [output addObject:elements];

                    }
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                resolve(output);
            });
        }];
    });
    
}

@end