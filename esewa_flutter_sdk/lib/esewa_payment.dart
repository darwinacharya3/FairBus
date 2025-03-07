/*
 *  Use callback URL to verify the transaction via the valid POST api provided
 *  For mobile plaform, it is recommended to use the eSewa transaction verification API to verify the transaction
 *  EBP number is an optional parameter, used for government merchant payments
 */
class EsewaPayment {
  final String productId;
  final String productName;
  final String productPrice;
  final String? callbackUrl;
  final String? ebpNo;

  EsewaPayment(
      {required this.productId,
      required this.productName,
      required this.productPrice,
      this.callbackUrl = "",
      this.ebpNo});
}

extension PaymentExt on EsewaPayment {
  Map<String, dynamic> toMap() => {
        "product_id": productId,
        "product_name": productName,
        "product_price": productPrice,
        "callback_url": callbackUrl,
        "ebp_no": ebpNo
      };
}
