import 'package:Spotter_mobile/models/product.dart';
import 'package:Spotter_mobile/utils/utils_widgets.dart';
import 'package:flutter/material.dart';

import 'package:carousel_slider/carousel_slider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Product details"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CarouselSlider(
              items: widget.product.assets.isNotEmpty
                  ? widget.product.assets
                        .map(
                          (e) => imageFromBase64String(e.base64Content ?? ""),
                        )
                        .toList()
                  : [placeholderImage()],
              options: CarouselOptions(
                height: 400,
                viewportFraction: 1,
                initialPage: 0,
                enableInfiniteScroll: false,
                scrollDirection: Axis.horizontal,
              ),
            ),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
              ),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  Text(
                    'Free shipping',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          softWrap: true,
                          maxLines: 3,
                          widget.product.name ?? "No name",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.product.price?.toStringAsFixed(2)} \$',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
