# cordova-plugin-applepay

This plugin is a basic implementation of Stripe and Apple Pay with the purpose of returning a useable stripe token.


## Installation

1. Follow the steps on https://stripe.com/docs/mobile/apple-pay to get your certs generated
2. In your Xcode project, go to **Capabilities** and enable **Apple Pay**
3. Install the plugin
```sh
cordova plugin add https://github.com/dr1v3/cordova-plugin-applepay/
```

## Supported Platforms

- iOS

## Methods

- ApplePay.setMerchantId
- ApplePay.getStripeToken

#### ApplePay.setMerchantId

Set your Apple-given merchant ID. This overrides the value obtained from **ApplePayMerchant** in **Info.plist**.

```js
ApplePay.setMerchantId(successCallback, errorCallback, 'merchant.apple.test');
```

#### ApplePay.getStripeToken

Request a stripe token for an Apple Pay card.
- amount (string)
- description (string)
- currency (uppercase string)
- country (uppercase string)

```js
ApplePay.getStripeToken(successCallback, errorCallback, [stripePublishableKey, amount, description, currency, country]);
```

##### Response
```json
{
	"token": "sometoken",
	"card": {
		"id": "cardid",
		"brand": "Visa",
		"last4": "1234",
		"exp_month": "01",
		"exp_year": "2050"
	}
}
```

## Example

```js
ApplePay.setMerchantId(_ => {
  console.log(_);
}, err => {
  alert(err);
}, 'merchant.apple.test');

ApplePay.getStripeToken(function (token) {
  alert('Stripe token ID is: ' + token.id);
}, function (err) {
  alert(err);
}, ['pk_test34857kqhsbzg84443', '5.00', 'Sample Product', 'USD', 'US']);

```
