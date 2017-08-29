#import "CDVApplePay.h"
#import "Stripe.framework/Headers/Stripe.h"
#import "Stripe.framework/Headers/STPAPIClient.h"
#import "Stripe.framework/Headers/STPCardBrand.h"
#import <PassKit/PassKit.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>


@implementation CDVApplePay

- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView
{
    self = (CDVApplePay*)[super init];
    return self;
}

- (void)dealloc
{

}

- (void)onReset
{

}

- (void)setMerchantId:(CDVInvokedUrlCommand*)command
{
    merchantId = [command.arguments objectAtIndex:0];
    NSLog(@"ApplePay set merchant id to %@", merchantId);
}

- (void)getStripeToken:(CDVInvokedUrlCommand*)command
{
    if (merchantId == nil) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Please call setMerchantId() with your Apple-given merchant ID."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    if (([command.arguments count]<3) || [[command.arguments objectAtIndex:0] count]<5) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Please set StripePublishableKey, Amount, Product name, Currency, Country as getStripeToken function arguments array"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    NSString * StripePublishableKey = [[command.arguments objectAtIndex:0] objectAtIndex:4];
    [[STPPaymentConfiguration sharedConfiguration] setPublishableKey:StripePublishableKey];

    PKPaymentRequest *paymentRequest = [Stripe
                                 paymentRequestWithMerchantIdentifier:merchantId
                                 country:[[command.arguments objectAtIndex:0] objectAtIndex:3]
                                 currency:[[command.arguments objectAtIndex:0] objectAtIndex:2]];

    // Configure your request here.
    //[request setRequiredShippingAddressFields:PKAddressFieldPostalAddress];
    //[request setRequiredBillingAddressFields:PKAddressFieldPostalAddress];
    //request.shippingMethods = [self.shippingManager defaultShippingMethods];
    paymentRequest.paymentSummaryItems = @[
                                    [PKPaymentSummaryItem summaryItemWithLabel:[[command.arguments objectAtIndex:0] objectAtIndex:1]
                                                                        amount:[NSDecimalNumber decimalNumberWithString:[[command.arguments objectAtIndex:0] objectAtIndex:0]]]
                                    ];

    callbackId = command.callbackId;

    if ([Stripe canSubmitPaymentRequest:paymentRequest]) {
        PKPaymentAuthorizationViewController *auth = [[PKPaymentAuthorizationViewController alloc]
                             initWithPaymentRequest:paymentRequest];
        auth.delegate = self;
        if (auth) {
            [self.viewController presentViewController:auth animated:YES completion:nil];
        } else {
            NSLog(@"Apple Pay returned a nil PKPaymentAuthorizationViewController - make sure you've configured Apple Pay correctly, as outlined at https://stripe.com/docs/mobile/apple-pay");
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Apple Pay returned a nil PKPaymentAuthorizationViewController - make sure you've configured Apple Pay correctly, as outlined at https://stripe.com/docs/mobile/apple-pay"];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            return;
        }
    } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"You dont have access to ApplePay"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [self handlePaymentAuthorizationWithPayment:payment completion:completion];
}

- (void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus))completion {

    [[STPAPIClient sharedClient] createTokenWithPayment:payment completion:^(STPToken *token, NSError *error) {
        if (error) {
            completion(PKPaymentAuthorizationStatusFailure);
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: ([error localizedDescription])];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
            return;
        } else {

            NSString* brand;

            switch (token.card.brand) {
                case STPCardBrandVisa:
                    brand = @"Visa";
                    break;
                case STPCardBrandAmex:
                    brand = @"American Express";
                    break;
                case STPCardBrandMasterCard:
                    brand = @"MasterCard";
                    break;
                case STPCardBrandDiscover:
                    brand = @"Discover";
                    break;
                case STPCardBrandJCB:
                    brand = @"JCB";
                    break;
                case STPCardBrandDinersClub:
                    brand = @"Diners Club";
                    break;
                case STPCardBrandUnknown:
                    brand = @"Unknown";
                    break;
            }

            NSDictionary* card = @{
               @"id": token.card.cardId,
               @"brand": brand,
               @"last4": [NSString stringWithFormat:@"%@", token.card.last4],
               //@"exp_month": [NSString stringWithFormat:@"%lu", token.card.expMonth],
               //@"exp_year": [NSString stringWithFormat:@"%lu", token.card.expYear]
           };

            NSDictionary* message = @{
               @"id": token.tokenId,
               @"card": card
            };

            completion(PKPaymentAuthorizationStatusSuccess);
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: message];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }

    }];
}


 - (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
     CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"user cancelled apple pay"];
     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
     [self.viewController dismissViewControllerAnimated:YES completion:nil];
 }

@end
