import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  final String productId;
  const ReviewsScreen({super.key, required this.productId});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  final _commentController = TextEditingController();
  double _rating = 5;
  bool _isSubmitting = false;
  final _api = ApiClient();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await _api.post(ApiConstants.reviews, data: {
        'product_id': widget.productId, 'rating': _rating.round(), 'comment': _commentController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!'), backgroundColor: AppColors.success));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Text('Rate this product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 40,
              itemBuilder: (_, __) => const Icon(Icons.star, color: AppColors.star),
              onRatingUpdate: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Your review', hintText: 'Share your experience...'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
