import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/orders.dart';
import '../widgets/app_drawer.dart';
import '../widgets/order_item.dart';

class OrderScreen extends StatelessWidget {
  static const routeName = '/orders';

  // var _isLoading = false;
  // @override
  // void initState() {
  //   Future.delayed(Duration.zero).then(
  //     (_) async {
  //       setState(() {
  //         _isLoading = true;
  //       });
  //       await Provider.of<Orders>(context, listen: false).fetchAndSetOrder();
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     },
  //   );
  //   super.initState();

  @override
  Widget build(BuildContext context) {
    //  final orderData = Provider.of<Orders>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Order',
        ),
      ),
      drawer: AppDrawer(),
      body: FutureBuilder(
        future: Provider.of<Orders>(context, listen: false).fetchAndSetOrder(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.error != null) {
              return Center(
                child: Text('An error occurred'),
              );
            } else {
              return Consumer<Orders>(
                builder: (ctx, orderData, child) => ListView.builder(
                  itemCount: orderData.orders.length,
                  itemBuilder: (ctx, i) => OrderItem(
                    orderData.orders[i],
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
